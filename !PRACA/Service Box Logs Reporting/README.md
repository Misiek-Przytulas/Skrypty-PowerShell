# Service Box Logs Reporting

## Co robi skrypt

`Get-ServiceBoxLogReport.ps1` czyta logi Service Box / IQService i tworzy raport błędów TXT/HTML oraz opcjonalnie wysyła mail HTML. Wykrywa wpisy `ERROR :` i niepuste komunikaty `<Errors>...<String>`, również w wieloliniowych wpisach DEBUG/INFO.

Domyślnie obejmuje wczoraj od 00:00 i dzisiaj do chwili uruchomienia. Raport rozdziela dni na `YESTERDAY`, `TODAY` lub `DATE`. Każdy dzień ma osobne liczniki oraz sekcje Access Denied i pozostałych błędów. Access Denied zawiera wartość `CN=` z komunikatu błędu; CN jest nazwą obiektu AD i nie musi być loginem.

## Pliki projektu

- `Get-ServiceBoxLogReport.ps1` — ustawienia, odczyt, klasyfikacja, raport i SMTP.
- `Run-ServiceBoxLogReport.cmd` — uruchamia PS1 bez pytań i pauzy, przekazuje kod zakończenia.
- `README.md` — opis i instrukcje projektu. Szczegółowe komentarze przy parametrach i opis 10 bloków są w PS1.

## Wymagania i instalacja zależności

Windows PowerShell 5.1 lub nowszy, dostęp do odczytu logów, a przy zapisie — możliwość tworzenia folderu i plików w lokalnej lub sieciowej lokalizacji raportów. Używane są wbudowane funkcje PowerShell/.NET; nie trzeba instalować Popplera, modułów AD ani narzędzi PDF.

Mail wymaga dostępnego serwera SMTP i odpowiednich ustawień adresów, portu, SSL/TLS oraz ewentualnego uwierzytelniania. Dostęp do sieci jest potrzebny przy udziale sieciowym i/lub SMTP, nie do samej analizy lokalnych logów. W Harmonogramie zadań konto uruchamiające musi mieć własny dostęp do logów, udziału i SMTP.

Normalne działanie nie zależy od istnienia `!codex-temp/`.

## Konfiguracja

Edytuj domyślne parametry w `BLOCK 1` albo przekaż je bezpośrednio przy wywołaniu PS1. Nie zapisuj haseł w kodzie. Opcjonalne dane SMTP przekaż jako `-Credential (Get-Credential)` w interaktywnym PowerShell; nie nadaje się to do zadania bezobsługowego. Konfigurację z sekretami trzymaj poza Git.

### Foldery i wybór plików

| Parametr | Domyślnie | Znaczenie |
|---|---|---|
| `LogFolder` | przykładowy folder IQService | Folder z logami; ustaw swoją lokalizację. |
| `ReportFolder` | przykładowy udział sieciowy | Używany wyłącznie przy zapisie; trzymaj poza folderem logów. |
| `ScanAllFiles` | `$true` | `$true`: wzorce `FilePatterns`; `$false`: dokładne nazwy `FileNames`. |
| `FilePatterns` | `*.log`, `*.txt` | Wzorce dla `ScanAllFiles=$true`; `@('*')` obejmie wszystkie nazwy. |
| `FileNames` | `IQService.log` | Nazwy, nie pełne ścieżki; używane przy `ScanAllFiles=$false`. Brak nazwy jest problemem skanowania. |
| `Recurse` | `$false` | `$true` obejmuje również podfoldery w obu trybach. |
| `IgnorePhrases` | pusta lista | Dosłowne frazy bez rozróżniania wielkości liter. Jedno dopasowanie pomija cały wpis i jego komunikaty XML. |

### Daty

| Oczekiwany zakres | PreviousDayOnly | IncludeToday | AllErrors |
|---|---|---|---|
| Wczoraj + dzisiaj do uruchomienia | `$true` | `$true` | `$false` |
| Tylko pełny poprzedni dzień | `$true` | `$false` | `$false` |
| Wszystkie daty w wybranych plikach | dowolnie | dowolnie | `$true` |

Powyższe przykłady zakładają domyślny `ReportDate`, czyli wczoraj. `PreviousDayOnly` ma historyczną nazwę: z `IncludeToday=$true` obejmuje również dzisiaj. Oba `PreviousDayOnly` i `AllErrors` ustawione na `$false` powodują błąd konfiguracji.

`ReportDate` ustala początek o 00:00. Dla historycznej daty i `IncludeToday=$true` zakres obejmuje wszystkie dni aż do uruchomienia. Aby sprawdzić pojedynczy historyczny dzień, ustaw także `IncludeToday=$false`. `AllErrors=$true` wyłącza filtrowanie dat, ale nie zmienia wyboru plików.

### Wykrywanie i duplikaty

- `IncludeXmlErrors=$true`: wykrywa niepuste XML `Errors/String` nawet w DEBUG/INFO. Przy `$false` pozostają wpisy oznaczone `ERROR :`. Puste `<Errors/>` nie jest błędem.
- Access Denied rozpoznaje m.in. `Access is denied`, `Access Denied`, `UnauthorizedAccessException` i `0x80070005`. Dla XML CN pochodzi z komunikatu w `Errors`, nie z innego `AccountRequest`.
- `MergeExactDuplicates=$true`: łączy rekordy o tym samym czasie, CN, operacji i komunikacie po normalizacji odstępów; porównanie jest niewrażliwe na wielkość liter. Zachowuje wszystkie źródła w TXT i pierwszy oryginalny wpis.
- Przykład: ten sam błąd CN o 00:16:23 w dwóch plikach daje jedno zdarzenie z dwoma źródłami. Inny czas lub treść pozostają osobnymi zdarzeniami. Przy `$false` każde wystąpienie pozostaje osobno. Identyczne komunikaty String w obrębie jednego wpisu XML są redukowane niezależnie od tego przełącznika.
- HTML grupuje zachowane zdarzenia do tabel: Access Denied według CN/operacji, pozostałe według kategorii/komunikatu. Liczba w tabeli oznacza zdarzenia po opcjonalnym łączeniu kopii; TXT zachowuje szczegóły każdego z nich.

### Zapis i poczta

| Przełącznik | Domyślnie | Znaczenie |
|---|---|---|
| `SendEmail` | `$true` | Wysyłka HTML przez SMTP; niezależna od zapisu na dysku. |
| `SaveToDisk` | `$true` | Główne zezwolenie na zapis; `$false` wyłącza oba formaty. |
| `SaveHtml` | `$true` | Zapis pliku HTML przy włączonym `SaveToDisk`; nie steruje treścią maila. |
| `SaveTxt` | `$true` | Zapis szczegółowego TXT przy włączonym `SaveToDisk`. |
| `AttachTxtToEmail` | `$true` | Dołącza TXT tylko jeśli zapisano go w tym uruchomieniu. Bez zapisu nie tworzy załącznika tymczasowego. |
| `EmailOnlyWhenErrors` | `$false` | `$false`: mail także po czystym skanie; `$true`: tylko przy zachowanych błędach lub problemach skanowania. |
| `UseSsl` | `$false` | Włącza SSL/TLS dla SMTP; dostosuj razem z portem do swojego relay. |

Ustaw `To` (może zawierać kilka adresów), `From`, `SMTPServer`, `SMTPPort` (domyślnie 25), opcjonalnie `Credential` oraz prefiks `Subject`. Ścieżki i adresy w kodzie są przykładami. Gdy żaden format nie jest zapisany, raport TXT jest wyświetlany w konsoli.

## Uruchomienie

Nie uruchamiaj CMD przed konfiguracją: zapis i mail są domyślnie włączone. Po ustawieniu parametrów kliknij `Run-ServiceBoxLogReport.cmd`. Launcher nie pyta o foldery ani nie utrzymuje okna otwartego po zakończeniu. Do diagnozowania uruchom PS1 z już otwartego PowerShell.

Przykłady z folderu projektu:

```powershell
# Raport lokalny bez wysyłki maila:
.\Get-ServiceBoxLogReport.ps1 -LogFolder 'C:\Logs' -ReportFolder 'C:\Reports\ServiceBox' -SendEmail $false

# Wyłącznie analiza i wyświetlenie TXT w konsoli:
.\Get-ServiceBoxLogReport.ps1 -LogFolder 'C:\Logs' -SendEmail $false -SaveToDisk $false

# Jedna nazwa pliku i konkretny pełny dzień:
.\Get-ServiceBoxLogReport.ps1 -LogFolder 'C:\Logs' -ReportFolder 'C:\Reports\ServiceBox' -ScanAllFiles $false -FileNames 'IQService.log' -ReportDate ([datetime]::new(2026,10,21)) -IncludeToday $false -SendEmail $false
```

Dla zadania bezobsługowego można użyć `powershell.exe -NoProfile -ExecutionPolicy Bypass -File` z pełną ścieżką do skonfigurowanego PS1. Wskazane w przykładach przełączniki `$false` przekazuj z PowerShell jak wyżej; CMD uruchamia wartości domyślne zapisane w skrypcie. `ExecutionPolicy Bypass` launchera dotyczy tylko procesu, nie zapisanej polityki systemu; zasady organizacji mogą nadal blokować uruchomienie.

## Czy zmienia dane lub wykonuje działania zewnętrzne

- Logi są odczytywane; skrypt nie modyfikuje kont AD ani nie naprawia wykrytych błędów.
- Przy włączonym zapisie tworzy folder raportów, jeśli trzeba, i pliki UTF-8 z BOM. Nazwa zawiera datę początkową lub `AllDates` i czas generowania z milisekundami.
- Przy włączonej poczcie łączy się z SMTP i wysyła treść raportu oraz opcjonalny TXT. Raport może zawierać CN, ścieżki i oryginalne komunikaty.
- Brak zapisu nie blokuje poczty. Aby wyłączyć oba działania, ustaw jednocześnie `SendEmail=$false` i `SaveToDisk=$false`.

## Bezpieczne sprawdzenie i lokalny warsztat Codex

Uruchom poniższy przykład z głównego folderu repozytorium. Tworzy nowy folder warsztatu, dwa sztuczne błędy i raporty lokalne; nie wysyła maila:

```powershell
$repoRoot = (Get-Location).Path
$work = Join-Path $repoRoot ('!codex-temp\Service Box Logs Reporting\check-' + [guid]::NewGuid().ToString('N'))
$inputDir = Join-Path $work 'input'
$outputDir = Join-Path $work 'output'
New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
$yesterday = (Get-Date).Date.AddDays(-1).AddHours(12).ToString('MM/dd/yyyy HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
$today = (Get-Date).Date.ToString('MM/dd/yyyy HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
@(
    "$yesterday : Connector ERROR : Failed to update attributes for identity CN=test-user,OU=Test. Access is denied."
    "$today : Connector ERROR : Synthetic connection failure"
) | Set-Content -LiteralPath (Join-Path $inputDir 'sample.log') -Encoding UTF8
& (Join-Path $repoRoot '!PRACA\Service Box Logs Reporting\Get-ServiceBoxLogReport.ps1') -LogFolder $inputDir -ReportFolder $outputDir -SendEmail $false -SaveToDisk $true -SaveHtml $true -SaveTxt $true -PreviousDayOnly $true -AllErrors $false -IncludeToday $true -ReportDate (Get-Date).Date.AddDays(-1) -ScanAllFiles $true -FilePatterns '*.log' -IgnorePhrases @()
```

Oczekiwane: osobne sekcje dla wczoraj i dzisiaj; wczoraj jeden Access Denied dla `test-user`, dzisiaj jeden pozostały błąd. Dane pozostają w ignorowanym `!codex-temp/`. Kolejne sprawdzenia funkcjonalne powinny objąć XML w DEBUG, pusty XML, duplikaty, pomijane frazy i błędy odczytu.

Po klonowaniu w razie potrzeby odtwórz warsztat oraz sztuczne logi, bez kopiowania produkcyjnych danych. Stare foldery `test-log-report` i `tools` zostały przeniesione do głównego `!codex-temp/Service Box Logs Reporting/`. Historyczny Poppler nie jest zależnością tego skryptu i nie trzeba go odtwarzać. README i kod pozostają w folderze projektu, poza warsztatem.

## Znane ograniczenia

- Obsługiwane początki wpisów mają datę `MM/dd/yyyy HH:mm:ss` lub `dd.MM.yyyy HH:mm:ss`, po niej dwukropek; opcjonalnie poprzedza je `Line N:`. Inne formaty mogą zostać pominięte lub zgłoszone jako problem.
- Data pochodzi z początku wpisu, nie z nazwy pliku, czasu modyfikacji ani XML `requestProcessedOn`. Bez przeliczania stref; zegar i kalendarz maszyny uruchamiającej muszą odpowiadać logom.
- XML jest rozpoznawany jako fragment tekstu z domkniętymi `Errors` i `String`, a nie przez pełny parser XML. Ucięte wpisy lub inne struktury mogą nie zostać wykryte.
- Dopasowanie duplikatów jest ostrożne: wpisy ERROR i DEBUG o innej treści/czasie mogą opisywać tę samą operację i pozostać osobnymi zdarzeniami. Identyczne rekordy w tej samej sekundzie mogą zostać połączone, nawet jeśli były osobnymi próbami; wtedy wyłącz `MergeExactDuplicates`.
- Pliki aktualnie zapisywane mogą zmienić się podczas odczytu lub być zablokowane. Skrypt nie wykonuje migawki ani blokady całego zestawu.
- Pamięć zależy od liczby zatrzymanych zdarzeń i wielkości oryginalnych wpisów; skrypt zachowuje je do wygenerowania raportu.
- Niepełne skanowanie jest zgłaszane w raporcie, a na końcu powoduje błąd/niezerowy kod. Błędna ścieżka wejściowa, awaria zapisu lub SMTP mogą zatrzymać wykonanie wcześniej. Raport z zerem błędów nie oznacza kompletnego odczytu przy statusie `INCOMPLETE`.
- Brak automatycznej rotacji raportów i dedykowanego trybu próbnego SMTP. Testuj z `SendEmail=$false`.

## Stan weryfikacji

Opis porównano z bieżącym PS1 i launcherem CMD. W ramach tej aktualizacji dokumentacji nie uruchamiano testów, SMTP, zapisu na docelowym udziale ani skanowania produkcyjnych logów. Zasady repozytorium: [AGENTS.md](../../AGENTS.md), [status](../../docs/STATUS.md).
