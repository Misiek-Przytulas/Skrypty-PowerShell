<#
.SYNOPSIS
    Scan Service Box logs and generate daily reports with optional email delivery.
.DESCRIPTION
    Default range: yesterday at midnight through script startup today.
    Recognizes ERROR entries and XML Errors/String messages, including DEBUG entries.
    Each day shows Access Denied first, followed by other errors.
    Edit the settings below, then launch Run-ServiceBoxLogReport.cmd.
    Replace example paths and SMTP values. Booleans use $true or $false.

    Block 1 - Configuration:
        Set input/output paths, file selection, date range, error detection,
        duplicate handling, saved formats and SMTP delivery options.

    Block 2 - Initialization and validation:
        Capture the startup time, calculate date boundaries, initialize collections
        and validate the combination of date and file-selection settings.

    Block 3 - Interpret a complete multiline entry:
        Apply date and phrase filters, extract XML errors, identify the affected CN
        and classify Access Denied and other errors into in-memory records.

    Block 4 - Discover input files:
        Select files by wildcard patterns or exact names, optionally including
        subfolders, and record missing files or directory enumeration failures.

    Block 5 - Stream files and reconstruct multiline entries:
        Read files line by line, recognize timestamps, collect continuation lines
        and pass complete entries to Block 3. Record read and timestamp problems.

    Block 6 - Merge exact copies and prioritize Access Denied:
        Optionally combine matching records while retaining their source locations,
        then sort the retained events and separate Access Denied from other errors.

    Block 7 - Build report header and daily content:
        Generate TXT and HTML content with separate daily sections, daily counts,
        Access Denied first, grouped HTML tables, TXT details and scan issues.

    Block 8 - Optional disk output:
        Save enabled TXT/HTML formats in the output folder. When neither format
        is saved, print the TXT report to the console instead.

    Block 9 - Optional SMTP delivery:
        Apply email delivery rules, validate SMTP settings and send the HTML body
        with the saved TXT attachment when attachment settings allow it.

    Block 10 - Final status:
        Fail the run if scan issues were recorded, after reporting partial results.
        The CMD launcher passes the failure exit code to the caller or scheduler.
#>

# ============================================================================
# BLOCK 1 - CONFIGURATION (editable defaults; command-line overrides also supported)
# ============================================================================
[CmdletBinding()]
param(
    # --- Locations and file selection ---
    # Source directory: local or UNC path. Keep report output outside this tree.
    [string]$LogFolder = 'C:\SailPoint\IQService\logs',

    # Destination used only when disk saving and at least one format are enabled.
    [string]$ReportFolder = '\\serwer\raporty\ServiceBox',

    # Wildcards used only with ScanAllFiles=true. Use @('*') for every extension.
    [string[]]$FilePatterns = @('*.log', '*.txt'),

    # $true  - Scan files matching $FilePatterns, e.g. all *.log and *.txt files.
    # $false - Scan only files named in $FileNames, e.g. IQService.log.
    [bool]$ScanAllFiles = $true,

    # Names only, not full paths or wildcards. Missing requested names are scan issues.
    [string[]]$FileNames = @('IQService.log'),

    # TRUE: include subfolders. FALSE: scan only the top level of LogFolder.
    [bool]$Recurse = $false,

    # Literal case-insensitive exclusions, e.g. @('known harmless message', 'another phrase').
    # A match skips the whole entry and all its XML messages. Empty phrases are ignored.
    # Example: $IgnorePhrases = @('The handshake failed', 'forcibly closed by the remote host')
    # This skips entries containing either phrase; both phrases do not need to occur together.
    [string[]]$IgnorePhrases = @(),

    # --- Date window ---
    # COMMON SETTINGS (ReportDate defaults to yesterday):
    # Yesterday + today: PreviousDayOnly=true, IncludeToday=true,  AllErrors=false.
    # Yesterday only:    PreviousDayOnly=true, IncludeToday=false, AllErrors=false.
    # Every date:        AllErrors=true (the other date switches are ignored).
    #
    # $true  - Report yesterday's errors; also include today if $IncludeToday = $true.
    #          Example: run on 22 Oct with IncludeToday=true -> 21 Oct 00:00 to startup on 22 Oct.
    #          With IncludeToday=false -> the full day of 21 Oct only.
    #          These examples assume $ReportDate is left at its default (yesterday).
    # $false - You must set $AllErrors = $true to report errors from every date.
    #          If both $PreviousDayOnly and $AllErrors are false, the script stops.
    # NOTE: $AllErrors = $true always takes priority and disables the date filter.
    [bool]$PreviousDayOnly = $true,

    # TRUE: add today's entries up to script startup to the selected period.
    # Example: run on 21 Oct at 10:00 -> 20 Oct 00:00 through 21 Oct 10:00.
    # FALSE: include only ReportDate, from 00:00 to midnight at the start of the next day.
    # Example: run on 21 Oct -> the full day of 20 Oct only.
    # Ignored when AllErrors=true.
    # A historical ReportDate with TRUE also includes every intervening day.
    [bool]$IncludeToday = $true,

    # TRUE: report errors from EVERY date present in the selected files.
    # Example: a file contains September and October entries -> include both months.
    # This overrides PreviousDayOnly, IncludeToday and ReportDate.
    # FALSE: report only the period configured above (normally yesterday + today).
    # This selects dates, not files; ScanAllFiles separately selects files.
    [bool]$AllErrors = $false,

    # --- Error detection ---
    # TRUE: also detect nonempty XML Errors/String messages in DEBUG/INFO entries.
    # FALSE: detect only entries with ERROR : on their timestamped first line.
    # Date filtering uses the outer timestamp, never XML attribute dates.
    # Example: DEBUG followed by <Errors><List><String>Access is denied.</String>
    # is included with TRUE, but skipped with FALSE when the entry is not marked ERROR.
    [bool]$IncludeXmlErrors = $true,

    # TRUE: merge matching timestamp, CN, operation and whitespace-normalized message.
    # Comparison is case-insensitive. Keep every source in TXT and the first raw entry.
    # Different timestamps or wording remain separate; they may be repeated attempts.
    # FALSE: keep all occurrences. HTML still groups similar events and shows counts.
    # Example: a.log and b.log both contain the same CN/update error at 00:16:23.
    # TRUE -> one event with both source locations. FALSE -> two events.
    # The same error at 00:16:24 is a separate event even with TRUE.
    [bool]$MergeExactDuplicates = $true,

    # Start day for date-limited mode. Default: yesterday on the machine running this script.
    [datetime]$ReportDate = (Get-Date).Date.AddDays(-1),

    # --- Delivery and formats ---
    # TRUE: allow HTML email, subject to EmailOnlyWhenErrors. FALSE: do not contact SMTP.
    # Works independently of saving files to disk.
    [bool]$SendEmail = $true,

    # TRUE: allow SaveHtml/SaveTxt output. FALSE: create no report files/directory.
    # With no saved files, TXT is printed to the console; HTML email can still be sent.
    [bool]$SaveToDisk = $true,

    # TRUE: save HTML if SaveToDisk=true. FALSE: skip the HTML file.
    # Does not disable the HTML email body.
    [bool]$SaveHtml = $true,

    # TRUE: save detailed TXT if SaveToDisk=true. FALSE: skip TXT and its attachment.
    # TXT contains original entries and retained source file/line references.
    [bool]$SaveTxt = $true,

    # TRUE: attach TXT only if SendEmail, SaveToDisk and SaveTxt are all true.
    # FALSE: no TXT attachment. No temporary attachment is created if saving is off.
    [bool]$AttachTxtToEmail = $true,

    # TRUE: send only for retained errors OR scan issues; skip clean successful scans.
    # FALSE: send even with zero errors. Ignored when SendEmail=false.
    [bool]$EmailOnlyWhenErrors = $false,

    # --- SMTP settings: required only when an email is actually sent ---
    # Multiple recipients: @('first@example.com', 'second@example.com').
    [string[]]$To = @('user2@example.com'),

    [string]$From = 'smtp@example.com',

    [string]$SMTPServer = 'smtp.example.com',

    [int]$SMTPPort = 25,

    # TRUE: request SSL/TLS through Send-MailMessage. FALSE: do not request SSL/TLS.
    # Match the port and SSL setting to your SMTP relay requirements.
    [bool]$UseSsl = $false,

    # Optional SMTP credentials. Leave unset for a relay that does not require them.
    [pscredential]$Credential,

    # Host displayed in the HTML title and email subject. Defaults to this machine.
    # Override when reporting logs collected from a different server.
    [string]$ReportHostName = [Environment]::MachineName,

    # Subject label: final format is "<ReportHostName> <Subject> - <reporting period>".
    # Example in all-dates mode: SERVER01 Logs report - ALL DATES.
    [string]$Subject = 'Logs report'
)

# ============================================================================
# BLOCK 2 - INITIALIZATION AND VALIDATION
# Capture one startup time for consistent filtering and headings. Use log times
# as written and the runner's local calendar; no time zone conversion is performed.
# ============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$day = $ReportDate.Date
$runTime = Get-Date
# Exclusive upper boundary; adding one tick includes the captured startup instant.
$rangeEnd = if ($IncludeToday) { $runTime.AddTicks(1) } else { $day.AddDays(1) }
$events = [System.Collections.Generic.List[object]]::new()
$issues = [System.Collections.Generic.List[string]]::new()
$stats = @{ Ignored = 0; Read = 0 }
$culture = [Globalization.CultureInfo]::InvariantCulture
if (-not $AllErrors -and -not $PreviousDayOnly) { throw 'Enable PreviousDayOnly or AllErrors.' }
if (-not $ScanAllFiles -and @($FileNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) { throw 'FileNames is required when ScanAllFiles is false.' }
$period = if ($AllErrors) { 'ALL DATES' } elseif ($IncludeToday) { "$($day.ToString('yyyy-MM-dd HH:mm:ss')) to $($runTime.ToString('yyyy-MM-dd HH:mm:ss'))" } else { $day.ToString('dd.MM.yyyy') }

# ============================================================================
# BLOCK 3 - INTERPRET A COMPLETE MULTILINE ENTRY
# Filter dates/exclusions, extract XML messages and classify records in memory.
# Despite its name, this function does not write files or send email.
# ============================================================================
function Save-LogEvent($entry) {
    if ($null -eq $entry) { return }
    if (-not $AllErrors -and ($entry.Date -lt $day -or $entry.Date -ge $rangeEnd)) { return }
    $raw = $entry.Lines -join [Environment]::NewLine
    # Read only Errors/String messages, never CN values from unrelated request attributes.
    $xmlMessages = [System.Collections.Generic.List[string]]::new()
    # Read XML fragments embedded in log text. Empty Errors elements are not failures.
    # Each distinct nonempty String becomes a report record with the outer timestamp.
    if ($IncludeXmlErrors) {
        foreach ($block in [regex]::Matches($raw, '(?is)<Errors\b[^>]*>(.*?)</Errors>')) {
            foreach ($node in [regex]::Matches($block.Groups[1].Value, '(?is)<String\b[^>]*>(.*?)</String>')) {
                $value = [Net.WebUtility]::HtmlDecode($node.Groups[1].Value).Trim()
                if ($value) { $xmlMessages.Add($value) }
            }
        }
    }
    if (-not $entry.IsError -and $xmlMessages.Count -eq 0) { return }
    # Exclusions apply to the complete original entry before duplicate merging.
    foreach ($phrase in $IgnorePhrases) {
        if (-not [string]::IsNullOrWhiteSpace($phrase) -and $raw.IndexOf($phrase, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $stats.Ignored++
            return
        }
    }
    $messages = if ($xmlMessages.Count) { @($xmlMessages | Select-Object -Unique) } else { @(($entry.Lines[0] -replace '^.*?\bERROR\s*:\s*', '').Trim(' ', '"')) }
    foreach ($message in $messages) {
    $text = if ($xmlMessages.Count) { $message } else { $raw }
    $denied = $text -match '(?i)Access\s+(?:is\s+)?denied|UnauthorizedAccessException|0x80070005'
    # Extract CN from the error text, not an unrelated AccountRequest in the XML.
    # The pattern permits escaped characters such as an escaped comma in a CN.
    $cn = '(no CN)'
    if ($text -match '(?i)\bCN=((?:\\.|[^,\r\n])+)') { $cn = $Matches[1].Trim() }
    # Classification is ordered: Access Denied has priority over all other categories.
    $operation = 'Other operation'
    $category = 'Other error'
    if ($denied) {
        $category = 'Access Denied'
        if ($text -match '(?i)disabling') { $operation = 'Disable account' }
        elseif ($text -match '(?i)Modify|update attributes') { $operation = 'Update attributes' }
    }
    elseif ($text -match '(?i)used by another process') { $category = 'File locked' }
    elseif ($text -match '(?i)Exchange') { $category = 'Exchange' }
    elseif ($text -match '(?i)common algorithm') { $category = 'SSPI - no common algorithm' }
    elseif ($text -match '(?i)token supplied.*invalid') { $category = 'SSPI - invalid token' }
    elseif ($text -match '(?i)handshake') { $category = 'Handshake' }
    elseif ($text -match '(?i)forcibly closed') { $category = 'Connection closed' }
    elseif ($text -match '(?i)SSPI|AuthenticationException') { $category = 'Authentication' }
    $summary = ($message -replace '\s+', ' ').Trim()
    $events.Add([pscustomobject]@{
        Date = $entry.Date; CN = $cn; Operation = $operation; Category = $category
        Denied = $denied; Summary = $summary; Raw = $raw; File = $entry.File; Line = $entry.Line
    })
    }
}

# ============================================================================
# BLOCK 4 - DISCOVER INPUT FILES
# Choose wildcard or exact-name mode. Record enumeration/missing-file issues so
# an incomplete scan is never presented as a successful zero-error result.
# ============================================================================
if (-not (Test-Path -LiteralPath $LogFolder -PathType Container)) { throw "Log folder does not exist: $LogFolder" }
# Enumerate before creating reports; keep the output folder separate from the logs.
$scanErrors = @()
$files = @(Get-ChildItem -LiteralPath $LogFolder -File -Recurse:$Recurse -ErrorAction SilentlyContinue -ErrorVariable scanErrors |
    Where-Object {
        if ($ScanAllFiles) { $name = $_.Name; @($FilePatterns | Where-Object { $name -like $_ }).Count -gt 0 }
        else { $_.Name -in $FileNames }
    })
if (-not $ScanAllFiles) {
    foreach ($requested in $FileNames) {
        if (@($files | Where-Object { $_.Name -eq $requested }).Count -eq 0) { $issues.Add("Requested file not found: $requested") }
    }
}
foreach ($scanError in $scanErrors) { $issues.Add("Enumeration: $scanError") }
if ($files.Count -eq 0) { $issues.Add('No files matched the selection.') }

# ============================================================================
# BLOCK 5 - STREAM FILES AND RECONSTRUCT MULTILINE ENTRIES
# A timestamp starts a new entry; subsequent lines belong to it until the next
# timestamp or end of file. File modification dates do not determine inclusion.
# Only the current entry is buffered while reading; accepted records are retained.
# ============================================================================
foreach ($file in $files) {
    $reader = $null
    $entry = $null
    $lineNumber = 0
    try {
        # BOM is detected automatically; files without BOM are treated as UTF-8.
        $reader = [IO.StreamReader]::new($file.FullName, [Text.Encoding]::UTF8, $true)
        while ($null -ne ($line = $reader.ReadLine())) {
            $lineNumber++
            # Optional "Line N:" prefix also supports pasted search results.
            if ($line -match '^\s*(?:Line\s+\d+:\s*)?(?<stamp>\d{2}[/.]\d{2}[/.]\d{4}\s+\d{2}:\d{2}:\d{2})\s*:') {
                # Finalize the preceding entry before starting the newly timestamped entry.
                Save-LogEvent $entry
                $entry = $null
                $stamp = $Matches['stamp']
                # Explicit formats avoid machine-locale ambiguity: slash dates are US order.
                $format = if ($stamp.Contains('/')) { 'MM/dd/yyyy HH:mm:ss' } else { 'dd.MM.yyyy HH:mm:ss' }
                $parsed = [datetime]::MinValue
                if (-not [datetime]::TryParseExact($stamp, $format, $culture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
                    $issues.Add("Invalid timestamp: $($file.FullName):$lineNumber")
                    continue
                }
                $entry = @{ Date = $parsed; IsError = ($line -match '\bERROR\s*:'); Lines = [System.Collections.Generic.List[string]]::new(); File = $file.FullName; Line = $lineNumber }
                $entry.Lines.Add($line)
            }
            elseif ($null -ne $entry -and ($entry.IsError -or $IncludeXmlErrors) -and ($AllErrors -or ($entry.Date -ge $day -and $entry.Date -lt $rangeEnd))) {
                $entry.Lines.Add($line)
            }
            elseif ($line -match '\bERROR\s*:') {
                $issues.Add("ERROR without recognized timestamp: $($file.FullName):$lineNumber")
            }
        }
        # Flush the last entry: there is no following timestamp to trigger processing.
        Save-LogEvent $entry
        $stats.Read++
    }
    catch { $issues.Add("Read failed: $($file.FullName): $($_.Exception.Message)") }
    # Release the file handle even when reading or interpretation fails.
    finally { if ($null -ne $reader) { $reader.Dispose() } }
}

# ============================================================================
# BLOCK 6 - MERGE EXACT COPIES AND PRIORITIZE ACCESS DENIED
# Matching records keep all file/line references. Later report grouping summarizes
# similar errors separately; grouping does not remove distinct attempts.
# ============================================================================
# Exact-copy merging is deliberately conservative: different timestamps or wording remain separate.
$reported = [System.Collections.Generic.List[object]]::new()
$seen = @{}
$duplicateCount = 0
foreach ($event in $events) {
    # Serialize fields to avoid ambiguous keys caused by delimiters inside messages.
    $key = @($event.Date.Ticks, $event.CN, $event.Operation, $event.Summary) | ConvertTo-Json -Compress
    if ($MergeExactDuplicates -and $seen.ContainsKey($key)) {
        $seen[$key].Sources.Add("$($event.File):$($event.Line)")
        $duplicateCount++
    }
    else {
        $sources = [System.Collections.Generic.List[string]]::new()
        $sources.Add("$($event.File):$($event.Line)")
        $event | Add-Member -NotePropertyName Sources -NotePropertyValue $sources
        $reported.Add($event)
        $seen[$key] = $event
    }
}
$ordered = @($reported | Sort-Object @{ Expression = 'Denied'; Descending = $true }, @{ Expression = 'Date'; Descending = $true }, CN)
$access = @($ordered | Where-Object Denied)
$other = @($ordered | Where-Object { -not $_.Denied })
# ============================================================================
# BLOCK 7 - BUILD REPORT HEADER AND DAILY CONTENT (TXT AND HTML IN MEMORY)
# Use the same HTML for the saved page and email. Encode log text before inserting
# it into HTML, so embedded XML and special characters display as text.
# ============================================================================
$status = if ($issues.Count) { 'INCOMPLETE - check scan issues' } else { 'OK' }
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("SERVICE BOX - REPORT: $period")
$lines.Add("Status: $status | Files read: $($stats.Read)/$($files.Count) | Ignored entries: $($stats.Ignored) | Exact copies merged: $duplicateCount")
$lines.Add('Dates use the outer log timestamp, not dates inside XML attributes. No time zone conversion is performed.')

function Encode-Html([string]$value) { [Net.WebUtility]::HtmlEncode($value) }

# Presentation tables and inline CSS work without scripts, external fonts or images.
# The conditional wrapper provides a fixed-width fallback in classic Outlook.
$html = [Text.StringBuilder]::new()
[void]$html.Append('<!DOCTYPE html><html lang="en" xmlns:o="urn:schemas-microsoft-com:office:office"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="light"><title>Service Box | Log report</title><!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]--></head>')
[void]$html.Append('<body bgcolor="#F3F5F9" style="margin:0;padding:0;background-color:#F3F5F9;color:#25334A;font-family:Segoe UI,Arial,sans-serif;-webkit-text-size-adjust:100%;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#F3F5F9" style="width:100%;border-collapse:collapse;"><tr><td align="center" style="padding:24px 12px;"><!--[if mso]><table role="presentation" width="840" cellpadding="0" cellspacing="0" border="0"><tr><td><![endif]--><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#FFFFFF" style="width:100%;max-width:840px;background-color:#FFFFFF;border:1px solid #E1E6EF;border-radius:16px;border-collapse:separate;">')
[void]$html.Append('<tr><td bgcolor="#EEF0FC" style="padding:28px 24px;background-color:#EEF0FC;border-top:4px solid #8E99CF;"><p style="margin:0 0 8px;font-size:11px;line-height:16px;letter-spacing:2px;font-weight:700;color:#626F9D;">SERVICE BOX / IQSERVICE</p><h1 style="margin:0;font-size:28px;line-height:36px;font-weight:700;color:#25334A;">Daily log report: ')
[void]$html.Append("$(Encode-Html $ReportHostName)</h1>")
[void]$html.Append("<p style='margin:10px 0 0;font-size:13px;line-height:21px;color:#59677E;'>Reporting period: $(Encode-Html $period)</p></td></tr>")
$scanBackground = if ($issues.Count) { '#FFF4D9' } else { '#EAF6EF' }
$scanColor = if ($issues.Count) { '#79571B' } else { '#32634A' }
$scanTitle = if ($issues.Count) { 'Scan incomplete' } else { 'Scan complete' }
$scanDescription = if ($issues.Count) { 'Some files could not be checked. Review the scan issues below before interpreting the counts.' } else { 'All selected files were read. Error counts are shown below.' }
[void]$html.Append("<tr><td style='padding:20px 24px 0;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td bgcolor='$scanBackground' style='padding:14px 16px;background-color:$scanBackground;border-radius:8px;color:$scanColor;font-size:13px;line-height:20px;'><strong>$scanTitle</strong><br>$scanDescription</td></tr></table></td></tr>")
$affectedCount = @($access | Where-Object { $_.CN -ne '(no CN)' } | Select-Object -ExpandProperty CN -Unique).Count
[void]$html.Append("<tr><td style='padding:16px 24px 0;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0' style='table-layout:fixed;'><tr>")
foreach ($metric in @(
    @{ Label = 'ACCESS DENIED'; Value = $access.Count; Detail = "$affectedCount affected objects"; Background = '#FBECEE'; Color = '#914758' },
    @{ Label = 'OTHER ERRORS'; Value = $other.Count; Detail = 'Retained events'; Background = '#EBF2FC'; Color = '#42658F' },
    @{ Label = 'FILES READ'; Value = "$($stats.Read)/$($files.Count)"; Detail = 'Selected log files'; Background = '#F0EFFA'; Color = '#655C92' }
)) {
    [void]$html.Append("<td width='33%' valign='top' style='padding:0 3px;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td bgcolor='$($metric.Background)' style='padding:14px 10px;background-color:$($metric.Background);border-radius:8px;'><p style='margin:0;font-size:10px;line-height:16px;font-weight:700;letter-spacing:0.5px;color:$($metric.Color);'>$($metric.Label)</p><p style='margin:6px 0;font-size:28px;line-height:34px;font-weight:700;color:#25334A;'>$($metric.Value)</p><p style='margin:0;font-size:11px;line-height:16px;color:#59677E;'>$($metric.Detail)</p></td></tr></table></td>")
}
[void]$html.Append("</tr></table><p style='margin:12px 0 0;font-size:11px;line-height:18px;color:#68758B;'>Ignored entries: $($stats.Ignored) &nbsp; | &nbsp; Exact copies merged: $duplicateCount &nbsp; | &nbsp; Counts reflect retained events.</p></td></tr>")

# Group within each day; date-limited mode also displays empty days.
$reportDays = if ($AllErrors) {
    @($ordered | ForEach-Object { $_.Date.Date } | Sort-Object -Unique)
} else {
    $lastDay = if ($IncludeToday) { $runTime.Date } else { $day }
    for ($date = $day; $date -le $lastDay; $date = $date.AddDays(1)) { $date }
}
if (@($reportDays).Count -eq 0) {
    $lines.Add('No errors found in the selected date range.')
    $emptyMessage = if ($issues.Count) { 'No errors detected in the readable logs; scan is incomplete.' } else { 'No errors found in the selected date range.' }
    [void]$html.Append("<tr><td style='padding:24px;font-size:14px;line-height:22px;'>$(Encode-Html $emptyMessage)</td></tr>")
}
# Show the newest day first in HTML and TXT.
foreach ($reportDay in @($reportDays | Sort-Object -Descending)) {
    $dayLabel = if ($reportDay -eq $runTime.Date) { 'TODAY' } elseif ($reportDay -eq $runTime.Date.AddDays(-1)) { 'YESTERDAY' } else { 'DATE' }
    $heading = "$dayLabel - $($reportDay.ToString('yyyy-MM-dd'))"
    $dayAccess = @($access | Where-Object { $_.Date.Date -eq $reportDay })
    $dayOther = @($other | Where-Object { $_.Date.Date -eq $reportDay })
    $lines.Add("`r`n$heading")
    $lines.Add("Access Denied: $($dayAccess.Count) | Other errors: $($dayOther.Count)")
    [void]$html.Append("<tr><td style='padding:28px 24px 0;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td style='padding:0 0 12px;border-bottom:2px solid #E6EAF2;'><p style='margin:0 0 4px;font-size:11px;line-height:16px;letter-spacing:1.5px;font-weight:700;color:#697994;'>$dayLabel</p><h2 style='margin:0;font-size:21px;line-height:29px;color:#25334A;'>$($reportDay.ToString('dd MMMM yyyy', $culture))</h2><p style='margin:6px 0 0;font-size:12px;line-height:19px;color:#68758B;'>Access Denied: $($dayAccess.Count) &nbsp; | &nbsp; Other errors: $($dayOther.Count)</p></td></tr></table>")
    foreach ($section in @(@{ Name = 'ACCESS DENIED'; Items = $dayAccess }, @{ Name = 'OTHER ERRORS'; Items = $dayOther })) {
        $lines.Add("`r`n============================================================")
        $lines.Add("$($section.Name): $($section.Items.Count) events")
        $isDeniedSection = $section.Name -eq 'ACCESS DENIED'
        $sectionTitle = if ($isDeniedSection) { 'Access Denied' } else { 'Other errors' }
        $sectionColor = if ($isDeniedSection) { '#914758' } else { '#42658F' }
        $sectionBackground = if ($isDeniedSection) { '#FBECEE' } else { '#EBF2FC' }
        [void]$html.Append("<h3 style='margin:20px 0 10px;font-size:15px;line-height:22px;color:$sectionColor;'>$sectionTitle <span style='font-size:12px;font-weight:400;'>/ $($section.Items.Count) events</span></h3>")
        if ($section.Items.Count -eq 0) {
            $message = if ($isDeniedSection) { 'No Access Denied errors found' } else { 'No other errors found' }
            if ($issues.Count) { $message = 'No errors detected in the readable logs; scan is incomplete' }
            $lines.Add($message)
            $emptyBackground = if ($issues.Count) { '#FFF4D9' } else { '#EAF6EF' }
            $emptyColor = if ($issues.Count) { '#79571B' } else { '#32634A' }
            [void]$html.Append("<table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td bgcolor='$emptyBackground' style='padding:12px 14px;background-color:$emptyBackground;border-radius:7px;color:$emptyColor;font-size:12px;line-height:20px;'>$(Encode-Html $message).</td></tr></table>")
            continue
        }
        $groups = if ($isDeniedSection) { @($section.Items | Group-Object CN, Operation) } else { @($section.Items | Group-Object Category, Summary) }
        # Order cards by the most recent event in each group.
        $groups = @($groups | Sort-Object @{ Expression = { ($_.Group | Measure-Object -Property Date -Maximum).Maximum }; Descending = $true })
        foreach ($group in $groups) {
            $items = @($group.Group | Sort-Object Date -Descending)
            $first = $items[0]
            $label = if ($first.Denied) { $first.Operation } else { $first.Category }
            $cardTitle = if ($isDeniedSection) { $first.CN } else { $first.Category }
            $timeRange = if ($items.Count -eq 1) { $first.Date.ToString('HH:mm:ss') } else { "$($items[-1].Date.ToString('HH:mm:ss')) - $($first.Date.ToString('HH:mm:ss'))" }
            # Shorten only HTML excerpts. TXT always retains the complete original.
            $excerpt = $first.Summary
            $wasTruncated = $excerpt.Length -gt 420
            if ($wasTruncated) { $excerpt = $excerpt.Substring(0, 420) + ' ...' }
            # Soft breaks prevent long DNs and tokens from stretching email tables.
            $excerpt = [regex]::Replace($excerpt, '(\S{48})(?=\S)', ('$1' + [char]0x200B))
            $safeTitle = [regex]::Replace($cardTitle, '(\S{32})(?=\S)', ('$1' + [char]0x200B))
            # Show every retained source location, including copies merged across files.
            # Split at the final colon so Windows drive letters remain part of the path.
            $sourceHtml = [Text.StringBuilder]::new()
            # Pair each location with its own timestamp, including merged copies.
            $groupSources = @($items | ForEach-Object {
                $eventDate = $_.Date
                foreach ($location in $_.Sources) {
                    [pscustomobject]@{ Location = $location; Date = $eventDate }
                }
            } | Sort-Object -Property Date -Descending)
            $seenLocations = @{}
            foreach ($sourceLocation in $groupSources) {
                if ($seenLocations.ContainsKey($sourceLocation.Location)) { continue }
                $seenLocations[$sourceLocation.Location] = $true
                $sourceTime = $sourceLocation.Date.ToString('HH:mm:ss')
                if ($sourceLocation.Location -match '^(.*):(\d+)$') {
                    $sourceFile = [IO.Path]::GetFileName($Matches[1])
                    $sourceLine = $Matches[2]
                    $sourceFile = [regex]::Replace($sourceFile, '(\S{48})(?=\S)', ('$1' + [char]0x200B))
                    [void]$sourceHtml.Append("<p style='margin:0 0 8px;font-size:11px;line-height:18px;color:#68758B;overflow-wrap:anywhere;word-wrap:break-word;'>File: $(Encode-Html $sourceFile) &nbsp; | &nbsp; $sourceTime &nbsp; | &nbsp; Line: $sourceLine</p>")
                }
            }
            [void]$html.Append("<table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0' style='table-layout:fixed;border:1px solid #E1E6EF;border-left:3px solid $sectionColor;border-radius:8px;margin-bottom:10px;'><tr><td bgcolor='$sectionBackground' style='padding:12px 14px;background-color:$sectionBackground;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0' style='table-layout:fixed;'><tr><td valign='top' style='font-size:15px;line-height:22px;font-weight:700;color:#25334A;overflow-wrap:anywhere;word-wrap:break-word;'>$(Encode-Html $safeTitle)</td><td width='82' align='right' valign='top' style='font-size:12px;line-height:22px;font-weight:700;color:$sectionColor;'>$($items.Count) event$(if ($items.Count -ne 1) { 's' })</td></tr></table></td></tr><tr><td style='padding:12px 14px;'><p style='margin:0 0 8px;font-size:11px;line-height:18px;color:#68758B;'>$(Encode-Html $label) &nbsp; | &nbsp; $timeRange</p>$($sourceHtml.ToString())<p style='margin:0;font-family:Consolas,Courier New,monospace;font-size:12px;line-height:20px;color:#42516A;overflow-wrap:anywhere;word-wrap:break-word;'>$(Encode-Html $excerpt)</p>")
            if ($wasTruncated) { [void]$html.Append("<p style='margin:8px 0 0;font-size:11px;line-height:18px;color:#68758B;'>Message shortened for readability. Full details are available in the TXT report when saved.</p>") }
            [void]$html.Append('</td></tr></table>')
        }
        foreach ($item in $section.Items) {
            $lines.Add("`r`nCN: $($item.CN) | $($item.Operation) | $($item.Category)")
            $lines.Add("Time: $($item.Date.ToString('yyyy-MM-dd HH:mm:ss')) | Sources: $($item.Sources -join '; ')")
            $lines.Add("Message: $($item.Summary)")
            $lines.Add("Original entry (first copy):`r`n$($item.Raw)")
        }
    }
    [void]$html.Append('</td></tr>')
}
if ($issues.Count) {
    $lines.Add("`r`nSCAN ISSUES:")
    [void]$html.Append("<tr><td style='padding:24px 24px 0;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td bgcolor='#FFF4D9' style='padding:16px;background-color:#FFF4D9;border:1px solid #EDDEB6;border-radius:8px;'><h3 style='margin:0 0 10px;font-size:15px;line-height:22px;color:#79571B;'>Scan issues / $($issues.Count)</h3>")
    foreach ($issue in $issues) {
        $lines.Add($issue)
        [void]$html.Append("<p style='margin:8px 0;font-size:12px;line-height:20px;color:#79571B;word-break:break-all;'>$(Encode-Html $issue)</p>")
    }
    [void]$html.Append('</td></tr></table></td></tr>')
}
# ============================================================================
# BLOCK 8 - OPTIONAL DISK OUTPUT
# The master switch gates both formats. Disabled formats have no path, preventing
# references to nonexistent files and preventing an unavailable TXT attachment.
# ============================================================================
$txtPath = $null
$htmlPath = $null
$filePeriod = if ($AllErrors) { 'AllDates' } else { $day.ToString('yyyy-MM-dd') }
$baseName = "ServiceBox_${filePeriod}_$(Get-Date -Format 'yyyyMMdd_HHmmss_fff')"
if ($SaveToDisk -and ($SaveTxt -or $SaveHtml)) {
    if ([string]::IsNullOrWhiteSpace($ReportFolder)) { throw 'ReportFolder is required when saving reports.' }
    [void][IO.Directory]::CreateDirectory($ReportFolder)
    if ($SaveTxt) { $txtPath = Join-Path $ReportFolder "$baseName.txt" }
    if ($SaveHtml) { $htmlPath = Join-Path $ReportFolder "$baseName.html" }
}
# Describe the attachment only when this run is configured to send it.
[void]$html.Append("<tr><td style='padding:24px;'><table role='presentation' width='100%' cellpadding='0' cellspacing='0' border='0'><tr><td bgcolor='#F5F7FB' style='padding:16px;background-color:#F5F7FB;border-radius:8px;'>")
$detailNote = if ($SendEmail -and $AttachTxtToEmail -and $txtPath) { 'TXT report attached: full messages, timestamps and source file locations.' } elseif ($txtPath) { "Full details saved in TXT: $txtPath" } else { 'TXT file output is disabled. Complete event details are available in the console when no files are saved.' }
[void]$html.Append("<p style='margin:0;font-size:12px;line-height:20px;color:#42516A;word-break:break-all;'>$(Encode-Html $detailNote)</p><p style='margin:10px 0 0;font-size:11px;line-height:18px;color:#68758B;'>Generated $($runTime.ToString('yyyy-MM-dd HH:mm:ss')) &nbsp; | &nbsp; Times as recorded in the logs; no time zone conversion.</p></td></tr></table></td></tr></table><!--[if mso]></td></tr></table><![endif]--></td></tr></table></body></html>")
# UTF-8 with BOM supports Unicode text in common Windows text editors.
$utf8 = [Text.UTF8Encoding]::new($true)
if ($txtPath) {
    [IO.File]::WriteAllLines($txtPath, $lines, $utf8)
    Write-Host "TXT saved: $txtPath" -ForegroundColor Green
}
if ($htmlPath) {
    [IO.File]::WriteAllText($htmlPath, $html.ToString(), $utf8)
    Write-Host "HTML saved: $htmlPath" -ForegroundColor Green
}
if (-not $txtPath -and -not $htmlPath) {
    Write-Host 'Disk saving disabled. Report follows:' -ForegroundColor Cyan
    Write-Host ($lines -join [Environment]::NewLine)
}

# ============================================================================
# BLOCK 9 - OPTIONAL SMTP DELIVERY
# Send only when permitted by both email flags. Validate SMTP settings only if
# sending, attach an existing TXT if enabled, and propagate delivery failures.
# ============================================================================
if ($SendEmail -and (-not $EmailOnlyWhenErrors -or $events.Count -gt 0 -or $issues.Count -gt 0)) {
    if (-not $To -or @($To | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -ne $To.Count -or [string]::IsNullOrWhiteSpace($From) -or [string]::IsNullOrWhiteSpace($SMTPServer)) {
        throw 'Email delivery requires To, From and SMTPServer.'
    }
    $mail = @{
        To = $To; From = $From; SmtpServer = $SMTPServer; Port = $SMTPPort
        Subject = "$ReportHostName $Subject - $period"
        Body = $html.ToString(); BodyAsHtml = $true
        Encoding = [Text.Encoding]::UTF8; ErrorAction = 'Stop'; UseSsl = [bool]$UseSsl
    }
    if ($AttachTxtToEmail -and $txtPath) { $mail.Attachments = $txtPath }
    if ($Credential) { $mail.Credential = $Credential }
    Send-MailMessage @mail
    Write-Host "Email sent to: $($To -join ', ')" -ForegroundColor Green
}
else { Write-Host 'Email delivery skipped.' -ForegroundColor Cyan }
# ============================================================================
# BLOCK 10 - FINAL STATUS
# After reporting any partial results, fail the run if the scan had issues.
# The CMD launcher propagates this failure exit code to callers/schedulers.
# ============================================================================
if ($issues.Count) { throw "Scan incomplete ($($issues.Count) issues): $($issues -join '; ')" }
