#requires -Version 5.1
# Document Search v1.0
<#
.SYNOPSIS
Search LOG, TXT and PDF files for a literal phrase.
.EXAMPLE
.\Search-Documents.ps1
.EXAMPLE
.\Search-Documents.ps1 -Phrase 'Connection failed' -Path 'D:\Logs' -NonInteractive
#>
[CmdletBinding()]
param(
    [string]$Phrase,
    [string]$Path = '.',
    [string[]]$Extensions = @('.log', '.txt', '.pdf'),
    [switch]$NoRecurse,
    [switch]$CaseSensitive,
    [switch]$NonInteractive,
    [string]$PdfToTextPath,
    [string]$Encoding = 'utf-8',
    [string]$CsvPath,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $NonInteractive) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  DOCUMENT SEARCH v1.0' -ForegroundColor Cyan
    Write-Host '  LOG / TXT / PDF - literal phrase search'
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}
if ([string]::IsNullOrWhiteSpace($Phrase)) {
    if ($NonInteractive) { throw 'Parameter -Phrase is required with -NonInteractive.' }
    $Phrase = Read-Host 'Enter search phrase'
    if ([string]::IsNullOrWhiteSpace($Phrase)) { throw 'The search phrase must not be empty.' }
}
$root = Get-Item -LiteralPath $Path
if (-not $root.PSIsContainer) { throw 'Parameter -Path must point to a folder.' }
$textEncoding = [System.Text.Encoding]::GetEncoding($Encoding)
$comparison = [StringComparison]::OrdinalIgnoreCase
if ($CaseSensitive) { $comparison = [StringComparison]::Ordinal }
$allowed = @($Extensions | ForEach-Object { '.' + $_.TrimStart('.').ToLowerInvariant() })
if (-not $NonInteractive) {
    Write-Host ''
    Write-Host "Search folder: $($root.FullName)"
    Write-Host "Search phrase: $Phrase"
    Write-Host "File types:    $($allowed -join ', ')"
    Write-Host "Subfolders:    $(-not $NoRecurse)"
    Write-Host "Case sensitive: $([bool]$CaseSensitive)"
    Write-Host ''
    Write-Host 'Scanning files... Please wait.' -ForegroundColor Cyan
}

# Prefer an explicitly supplied tool, then a portable copy beside the script, then PATH.
$pdfTool = $null
if ($PdfToTextPath) {
    $pdfTool = (Get-Item -LiteralPath $PdfToTextPath).FullName
} else {
    $portable = Join-Path $PSScriptRoot 'tools\pdftotext.exe'
    $toolConfig = Join-Path $PSScriptRoot 'tools\pdftotext-path.txt'
    if (Test-Path -LiteralPath $toolConfig -PathType Leaf) {
        $configured = Join-Path (Join-Path $PSScriptRoot 'tools') ((Get-Content -LiteralPath $toolConfig -Raw).Trim())
        if (Test-Path -LiteralPath $configured -PathType Leaf) { $portable = $configured }
    }
    if (Test-Path -LiteralPath $portable -PathType Leaf) { $pdfTool = $portable }
    else {
        $command = Get-Command pdftotext -CommandType Application -ErrorAction SilentlyContinue
        if ($command) { $pdfTool = $command.Source }
    }
}

$enumerationErrors = @()
$files = @(Get-ChildItem -LiteralPath $root.FullName -File -Recurse:(-not $NoRecurse) `
    -ErrorAction SilentlyContinue -ErrorVariable enumerationErrors | Where-Object {
        $allowed -contains $_.Extension.ToLowerInvariant()
    })
$matches = [System.Collections.Generic.List[object]]::new()
$issues = [System.Collections.Generic.List[object]]::new()
$scanned = 0
$emptyPdfs = 0
foreach ($file in $files) {
    $reader = $null
    $tempFile = $null
    try {
        $source = $file.FullName
        $isPdf = $file.Extension -ieq '.pdf'
        if ($isPdf) {
            if (-not $pdfTool) { throw 'pdftotext is missing. Run Install-PDF-v1.0.cmd or use -PdfToTextPath.' }
            $tempFile = [IO.Path]::GetTempFileName()
            $diagnostic = & $pdfTool '-enc' 'UTF-8' '-layout' $file.FullName $tempFile 2>&1
            if ($LASTEXITCODE -ne 0) { throw "pdftotext: $diagnostic" }
            $source = $tempFile
        }
        $readEncoding = $textEncoding
        if ($isPdf) { $readEncoding = [Text.Encoding]::UTF8 }
        # BOM detection handles UTF-8/UTF-16; other legacy encodings use -Encoding.
        $reader = [IO.StreamReader]::new($source, $readEncoding, $true)
        $found = $false
        $hasText = $false
        while ($null -ne ($line = $reader.ReadLine())) {
            if (-not [string]::IsNullOrWhiteSpace($line)) { $hasText = $true }
            if ($line.IndexOf($Phrase, $comparison) -ge 0) { $found = $true; break }
        }
        $scanned++
        if ($found) {
            $matches.Add([pscustomobject]@{ Folder = $file.DirectoryName; FileName = $file.Name; FullPath = $file.FullName })
        } elseif ($isPdf -and -not $hasText) {
            $emptyPdfs++
            $issues.Add([pscustomobject]@{ FullPath = $file.FullName; Reason = 'PDF has no readable text; OCR may be required.' })
        }
    } catch {
        $issues.Add([pscustomobject]@{ FullPath = $file.FullName; Reason = $_.Exception.Message })
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($tempFile -and (Test-Path -LiteralPath $tempFile)) { Remove-Item -LiteralPath $tempFile -Force }
    }
}
foreach ($failure in $enumerationErrors) {
    $issues.Add([pscustomobject]@{ FullPath = [string]$failure.TargetObject; Reason = $failure.Exception.Message })
}
if ($CsvPath) {
    # Write a header even when there are no matches.
    $rows = @($matches.ToArray() | ConvertTo-Csv -NoTypeInformation)
    if ($rows.Count -eq 0) { $rows = @('"Folder","FileName","FullPath"') }
    $rows | Set-Content -LiteralPath $CsvPath -Encoding UTF8
}
if (-not $NonInteractive) {
    Write-Host ''
    Write-Host '------------------------ SUMMARY ---------------------------' -ForegroundColor Cyan
    Write-Host "Files found:         $($files.Count)"
    Write-Host "Files read:          $scanned"
    Write-Host "Matching files:      $($matches.Count)"
    Write-Host "Issues / incomplete: $($issues.Count)"
    Write-Host ''
    Write-Host '--------------------- MATCHING FILES -----------------------' -ForegroundColor Green
    if ($matches.Count -eq 0) { Write-Host 'No matches in the text that could be read.' }
    $number = 0
    foreach ($match in $matches) {
        $number++
        Write-Host ''
        Write-Host ("[{0}] {1}" -f $number, $match.FileName) -ForegroundColor Green
        Write-Host 'Full path:'
        Write-Host $match.FullPath
    }
    if ($issues.Count -gt 0) {
        Write-Host ''
        Write-Host '------------------- ISSUES / SKIPPED TEXT ------------------' -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host ''
            Write-Host 'File / folder:' -ForegroundColor Yellow
            Write-Host $issue.FullPath
            Write-Host 'Reason:' -ForegroundColor Yellow
            Write-Host $issue.Reason
        }
    }
    Write-Host ''
    if ($CsvPath) { Write-Host "CSV report: $CsvPath" }
    Write-Host 'Search complete.' -ForegroundColor Cyan
    Write-Host ''
} else {
    foreach ($issue in $issues) { Write-Warning ("{0}: {1}" -f $issue.FullPath, $issue.Reason) }
}
# Interactive output uses blocks, avoiding truncated automatic table columns.
if ($PassThru -or $NonInteractive) { $matches.ToArray() }
