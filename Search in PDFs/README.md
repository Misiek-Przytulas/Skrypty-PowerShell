# Document Search v1.0

Search LOG, TXT and text-based PDF files for a literal phrase. Requires Windows PowerShell 5.1 or newer.

## Run interactively

Place Search-Documents.ps1 and Run-Search-v1.0.cmd in the folder to search. Keep the tools folder beside them. Double-click Run-Search-v1.0.cmd and enter a phrase. The script searches that folder and its subfolders. The window stays open after completion or an error; type exit to close it.

Results use separate numbered blocks with full paths, followed by a separate issues section. Paths wrap naturally to the window width without table truncation. There are no animated progress lines. The summary counts matching files, not phrase occurrences. Files with issues must be reviewed separately; they are not confirmed negative results.

You can also open PowerShell in your document folder and run:

```powershell
.\Search-Documents.ps1
```

The CMD launcher uses ExecutionPolicy Bypass for its own PowerShell process only; it does not change the saved system policy. Organization policies can still prevent execution.

## PDF support

The portable tools folder is detected automatically. To install the dependency on another computer, place Install-PdfTools.ps1 and Install-PDF-v1.0.cmd beside the search script and double-click Install-PDF-v1.0.cmd. Internet access is required. The installer downloads the latest Windows package from https://github.com/oschwartz10612/poppler-windows/releases and verifies SHA256 when the release provides a digest. It checks that pdftotext starts. No administrator rights are needed.

Move the entire tools folder when moving the script. Alternatively, use pdftotext from PATH, place pdftotext.exe and its DLL dependencies directly in tools, or specify -PdfToTextPath.

Image-only/scanned PDFs require OCR. Version 1.0 does not perform OCR. Empty extracted text is reported as an issue; mixed image/text PDFs are searched only in the available text. Fonts, columns and word wrapping can affect matches. A phrase split across lines is not matched. Original documents are not modified; extracted PDF text uses temporary files that are removed after reading.

## Parameters and automation baseline

```powershell
# No prompt; results are PowerShell objects, with warnings for file issues.
$phrase = 'Connection failed'
$results = .\Search-Documents.ps1 -Phrase $phrase -Path 'D:\Logs' -NonInteractive -CsvPath '.\results.csv'
$results | Select-Object -ExpandProperty FullPath

# Only the selected folder, case-sensitive search:
.\Search-Documents.ps1 -Phrase 'ERROR' -NoRecurse -CaseSensitive

# Select file types (all non-PDF types are read as plain text):
.\Search-Documents.ps1 -Phrase 'Error' -Extensions log,txt,csv

# Legacy text encoding for files without a BOM:
.\Search-Documents.ps1 -Phrase 'error' -Encoding windows-1250

# Return objects as well as displaying the interactive report:
$results = .\Search-Documents.ps1 -Phrase 'error' -PassThru

# Explicit PDF executable:
.\Search-Documents.ps1 -PdfToTextPath 'C:\Poppler\Library\bin\pdftotext.exe'
```

Default: case-insensitive literal search, recursive, .log/.txt/.pdf, UTF-8 for text without BOM. UTF-8/UTF-16 BOM detection is automatic. Each matching file appears once. CSV overwrites an existing target and includes a header even with no matches.

Invalid parameters stop execution. Individual file failures generate issues and scanning continues. Noninteractive mode produces objects and warning records, with no interactive report. It does not yet define dedicated automation exit codes or a persistent error report. Read completed logs where possible: a file being written may change during reading or be locked.

The older Polish CMD filenames remain compatibility launchers for the English interface.
