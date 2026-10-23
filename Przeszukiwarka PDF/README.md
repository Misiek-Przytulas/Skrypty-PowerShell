# Przeszukiwarka PDF — Document Search v1.0

## Co robi skrypt

`Search-Documents.ps1` wyszukuje dosłowną frazę w plikach LOG, TXT i tekstowych PDF. Domyślnie przeszukuje również podfoldery i nie rozróżnia wielkości liter. Nie używa wyrażeń regularnych.

Wynik wskazuje pasujące pliki, a nie wszystkie wystąpienia frazy. Każdy plik pojawia się raz, z pełną ścieżką. Problemy odczytu i brak dostępnego tekstu PDF są pokazane osobno; taki plik nie jest potwierdzonym wynikiem negatywnym.

## Pliki projektu

- `Search-Documents.ps1` — wyszukiwanie, raport w konsoli i opcjonalny CSV.
- `Run-Search-v1.0.cmd` — uruchomienie interaktywne z folderu skryptu.
- `Install-PdfTools.ps1` i `Install-PDF-v1.0.cmd` — instalacja Popplera dla PDF.
- `Uruchom-Wyszukiwanie.cmd`, `Install-PDF.cmd`, `Zainstaluj-PDF.cmd` — zgodnościowe launchery wcześniejszych nazw.

## Wymagania i instalacja zależności

Wymagany Windows PowerShell 5.1 lub nowszy oraz dostęp do odczytu przeszukiwanych plików. Do LOG/TXT Poppler nie jest potrzebny. Do PDF wymagany jest `pdftotext.exe` z jego zależnościami.

Po pobraniu repozytorium na nowym komputerze doinstaluj Popplera tylko wtedy, gdy chcesz czytać PDF. Uruchom `Install-PDF-v1.0.cmd` obok `Install-PdfTools.ps1`. Instalator potrzebuje internetu, pobiera bieżące wydanie z `oschwartz10612/poppler-windows` na GitHubie, sprawdza SHA256, jeśli wydanie udostępnia digest, rozpakowuje pakiet i sprawdza uruchomienie `pdftotext`. Nie wymaga administratora, ale wymaga możliwości zapisu w folderze projektu.

Instalator tworzy lokalny `tools/` obok skryptu i zapisuje względną ścieżkę w `tools/pdftotext-path.txt`. Ta zależność uruchomieniowa jest ignorowana przez Git. Nie jest częścią `!codex-temp/` i nie jest pobierana automatycznie podczas wyszukiwania. Przy przenoszeniu gotowego zestawu lokalnie zachowaj cały folder `tools/`, nie samo EXE.

Możesz też zainstalować Popplera poza projektem i udostępnić `pdftotext` przez `PATH` albo przekazać `-PdfToTextPath`. Kolejność wyboru narzędzia: jawny parametr, lokalny `tools/` (także plik konfiguracji), następnie `PATH`. Nieprawidłowy jawny parametr może zatrzymać skrypt nawet przy wyszukiwaniu tylko LOG/TXT.

## Konfiguracja

| Parametr | Domyślnie | Znaczenie |
|---|---|---|
| `Phrase` | pytanie w konsoli | Dosłowna fraza; wymagana przy `-NonInteractive`. |
| `Path` | `.` | Folder do przeszukania, względem bieżącego katalogu PowerShell. |
| `Extensions` | `.log`, `.txt`, `.pdf` | Rozszerzenia; typy inne niż PDF są czytane jak tekst. |
| `NoRecurse` | wyłączony | Podanie przełącznika wyłącza podfoldery. |
| `CaseSensitive` | wyłączony | Podanie przełącznika włącza rozróżnianie wielkości liter. |
| `NonInteractive` | wyłączony | Bez pytań i raportu interaktywnego; zwraca obiekty i ostrzeżenia. |
| `Encoding` | `utf-8` | Kodowanie tekstu bez BOM, np. `windows-1250`; BOM wykrywany automatycznie. |
| `PdfToTextPath` | wykrywanie automatyczne | Pełna ścieżka do `pdftotext.exe`. |
| `CsvPath` | brak | Opcjonalny CSV: `Folder`, `FileName`, `FullPath`. Folder docelowy musi istnieć. |
| `PassThru` | wyłączony | Zwraca obiekty także przy raporcie interaktywnym. |

## Uruchomienie

Kliknij `Run-Search-v1.0.cmd` i wpisz frazę. Launcher ustawia katalog roboczy na folder skryptu, więc przeszukuje właśnie ten folder i jego podfoldery. Okno pozostaje otwarte po zakończeniu; wpisz `exit`, aby je zamknąć. Wskazanie innego folderu nie wymaga kopiowania skryptu — użyj PowerShell i `-Path`.

Przykłady uruchamiane z folderu projektu:

```powershell
# Interaktywnie, we wskazanym folderze:
.\Search-Documents.ps1 -Path 'D:\Dokumenty'

# Bez pytań, z CSV i obiektami wynikowymi:
$results = .\Search-Documents.ps1 -Phrase 'Connection failed' -Path 'D:\Logs' -NonInteractive -CsvPath 'D:\Raporty\wyniki.csv'
$results | Select-Object -ExpandProperty FullPath

# Bez podfolderów, z rozróżnianiem wielkości liter:
.\Search-Documents.ps1 -Phrase 'ERROR' -Path 'D:\Logs' -NoRecurse -CaseSensitive

# Tylko pliki tekstowe, kodowanie starszych logów:
.\Search-Documents.ps1 -Phrase 'error' -Path 'D:\Logs' -Extensions log,txt,csv -Encoding windows-1250

# Jawna lokalizacja narzędzia PDF:
.\Search-Documents.ps1 -Phrase 'invoice' -Path 'D:\Dokumenty' -PdfToTextPath 'C:\Poppler\Library\bin\pdftotext.exe'
```

Launchery używają `ExecutionPolicy Bypass` tylko dla swojego procesu; nie zmieniają zapisanej polityki systemu. Polityki organizacji mogą nadal blokować uruchomienie.

## Czy zmienia dane lub wykonuje działania zewnętrzne

- Oryginalne dokumenty są wyłącznie odczytywane; skrypt nie zmienia ich treści i nie wysyła maili.
- `CsvPath` zapisuje lub nadpisuje wskazany CSV. Nawet przy braku trafień zapisuje nagłówek.
- Przy PDF tworzony jest plik tekstowy w systemowym katalogu tymczasowym, usuwany po przetworzeniu w bloku `finally`.
- Samo wyszukiwanie nie pobiera narzędzi. Instalator łączy się z GitHubem i zapisuje pakiet oraz konfigurację w lokalnym `tools/`.

## Bezpieczne sprawdzenie i lokalny warsztat Codex

Do ręcznego sprawdzenia LOG/TXT wystarczy sztuczny plik. Poniższy przykład uruchom z katalogu głównego repozytorium, w nowym, pustym folderze warsztatu:

```powershell
$repoRoot = (Get-Location).Path
$work = Join-Path $repoRoot ('!codex-temp\Przeszukiwarka PDF\check-' + [guid]::NewGuid().ToString('N'))
$inputDir = Join-Path $work 'input'
New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
'Synthetic example: Connection failed' | Set-Content -LiteralPath (Join-Path $inputDir 'sample.log') -Encoding UTF8
& (Join-Path $repoRoot 'Przeszukiwarka PDF\Search-Documents.ps1') -Phrase 'Connection failed' -Path $inputDir -Extensions log,txt -NonInteractive -CsvPath (Join-Path $work 'results.csv')
```

Oczekiwany wynik: jeden pasujący plik `sample.log` i CSV z jednym rekordem. Brak Popplera nie przeszkadza w tym przykładzie. Osobno warto sprawdzić brak trafień i rozróżnianie wielkości liter; dla PDF użyj niewrażliwego tekstowego dokumentu, którego zawartość znasz.

Narzędzia pobierane wyłącznie do pracy Codex trzymaj w głównym `!codex-temp/Przeszukiwarka PDF/tools/` i wskazuj przez `-PdfToTextPath`. Do prób nie uruchamiaj instalatora w folderze projektu, jeśli celem jest zapis pakietu wyłącznie w warsztacie; użyj tymczasowej kopii instalatora wewnątrz warsztatu albo już dostępnego narzędzia. Przy testach PDF skieruj `TEMP` i `TMP` na podfolder warsztatu w procesie testowym, ponieważ kod używa systemowego katalogu tymczasowego. Normalne używanie nie wymaga `!codex-temp/`.

Po klonowaniu warsztatu nie będzie — to prawidłowe. Odtwórz tylko potrzebne sztuczne dane i narzędzia. Nie dodawaj danych, wyników, pobranych pakietów ani sekretów do Git; opis i instalator pozostają wersjonowane przy projekcie.

## Znane ograniczenia

- Brak OCR. Skanowane PDF mogą nie zawierać czytelnego tekstu; puste wyniki ekstrakcji trafiają do sekcji problemów. Przy mieszanej treści tekst/obraz przeszukiwany jest wyłącznie dostępny tekst.
- Dopasowanie odbywa się w jednej linii; fraza rozdzielona na linie nie zostanie znaleziona. Układ kolumn, czcionki i ekstrakcja PDF mogą wpływać na dopasowanie.
- Skrypt kończy czytanie pliku po pierwszym trafieniu, nie liczy wszystkich wystąpień i nie zwraca numerów linii.
- Plik aktualnie zapisywany może zmienić się w trakcie odczytu lub być zablokowany.
- Błędy parametrów zatrzymują skrypt. Problemy pojedynczych plików i enumeracji są raportowane, a skan trwa dalej. Nie ma dedykowanego niezerowego kodu zakończenia dla każdego niepełnego skanowania ani trwałego raportu problemów; CSV zawiera wyłącznie trafienia.
- Bez `pdftotext` pliki PDF zostaną zgłoszone jako problem, ale odczyt LOG/TXT może być kontynuowany.

## Stan weryfikacji

Ten opis porównano z kodem PS1 i launcherami CMD. Aktualizacja dokumentacji nie obejmuje ponownego uruchomienia instalatora, testu pobierania ani testów ekstrakcji PDF. Zasady repozytorium: [AGENTS.md](../AGENTS.md), [status](../docs/STATUS.md).
