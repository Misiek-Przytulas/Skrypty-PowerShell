#requires -Version 5.1
# Document Search - PDF Tools Installer v1.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  DOCUMENT SEARCH v1.0 - PDF TOOLS INSTALLER' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$tools = Join-Path $PSScriptRoot 'tools'
New-Item -ItemType Directory -Path $tools -Force | Out-Null
$stage = Join-Path $tools ('poppler-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
$archive = Join-Path $stage 'package.zip'
Write-Host 'Downloading Poppler for Windows from GitHub (oschwartz10612/poppler-windows)...'
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/oschwartz10612/poppler-windows/releases/latest' -Headers @{ 'User-Agent' = 'DocumentSearch-Setup' } -TimeoutSec 60
$asset = @($release.assets | Where-Object { $_.name -like 'Release-*.zip' })
if ($asset.Count -ne 1) { throw 'Could not identify a unique Poppler archive.' }
Invoke-WebRequest -Uri $asset[0].browser_download_url -OutFile $archive -UseBasicParsing -TimeoutSec 180
if ($asset[0].PSObject.Properties['digest'] -and $asset[0].digest -like 'sha256:*') {
    $expected = $asset[0].digest.Substring(7)
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ine $expected) { throw 'Archive SHA256 verification failed.' }
}
Expand-Archive -LiteralPath $archive -DestinationPath $stage
$exe = @(Get-ChildItem -LiteralPath $stage -Filter pdftotext.exe -Recurse -File)
if ($exe.Count -ne 1) { throw 'pdftotext.exe was not found in the archive.' }
$ErrorActionPreference = 'Continue'
$versionInfo = & $exe[0].FullName -v 2>&1
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw "Unable to run pdftotext: $versionInfo" }
# Save a relative path so the complete folder can be moved to another computer.
$relative = $exe[0].FullName.Substring($tools.Length + 1)
Set-Content -LiteralPath (Join-Path $tools 'pdftotext-path.txt') -Value $relative -Encoding UTF8
Remove-Item -LiteralPath $archive
Write-Host ''
Write-Host 'Installation complete.' -ForegroundColor Green
Write-Host "Poppler package: $($release.tag_name)"
Write-Host "Tools folder: $tools"
Write-Host ''
Write-Host 'Next step: run Run-Search-v1.0.cmd.' -ForegroundColor Cyan
Write-Host ''
