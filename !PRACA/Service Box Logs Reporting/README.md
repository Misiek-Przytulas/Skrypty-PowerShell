# Service Box Logs Reporting

Skrypt `Get-ServiceBoxLogReport.ps1` czyta logi Service Box / IQService i przygotowuje raport TXT oraz HTML. Wykrywa wpisy ERROR i niepuste komunikaty XML Errors/String, także we wpisach DEBUG/INFO. Najpierw pokazuje Access Denied, następnie pozostałe błędy.

## Uruchomienie

Wymagany Windows PowerShell 5.1 lub nowszy. Skrypt nie potrzebuje Popplera ani narzędzi do PDF.

1. Przejrzyj parametry w sekcji `BLOCK 1` skryptu. Ustaw folder logów, folder raportów i ewentualne parametry SMTP.
2. Uruchom `Run-ServiceBoxLogReport.cmd` lub wywołaj skrypt z PowerShell.

Domyślnie włączone są zapis raportów i wysyłanie poczty. Adresy SMTP oraz ścieżka raportów w kodzie są przykładami i wymagają konfiguracji. Do lokalnego sprawdzenia bez poczty użyj własnych ścieżek:

```powershell
& '.\Get-ServiceBoxLogReport.ps1' -LogFolder 'C:\Logs' -ReportFolder 'C:\Reports\ServiceBox' -SendEmail $false
```

Nie zapisuj haseł w kodzie. Jeśli SMTP wymaga logowania, przekaż `-Credential (Get-Credential)`. Lokalne ustawienia z sekretami trzymaj poza Git. Plik CMD używa ExecutionPolicy Bypass tylko dla uruchamianego procesu i przekazuje kod zakończenia.

## Zakres i wyniki

- Domyślnie: od wczoraj 00:00 do chwili uruchomienia dzisiaj.
- Tylko poprzedni dzień: `-IncludeToday $false`.
- Wszystkie daty: `-AllErrors $true` (ma pierwszeństwo przed pozostałymi ustawieniami dat).
- `FilePatterns`, `FileNames`, `ScanAllFiles` i `Recurse` sterują wyborem plików; `IgnorePhrases` pomija całe wpisy zawierające podane frazy.
- `MergeExactDuplicates` łączy identyczne zdarzenia z zachowaniem źródeł. Różne znaczniki czasu pozostają osobnymi zdarzeniami.
- `SaveToDisk`, `SaveHtml`, `SaveTxt` i `SendEmail` sterują zapisem i pocztą. Bez zapisanych plików raport TXT trafia do konsoli.
- Problemy odczytu trafiają do raportu i powodują niezerowy kod zakończenia. Wyniki mogą być wtedy niepełne.

Daty są interpretowane w lokalnym czasie komputera, bez przeliczania stref. Czytaj w miarę możliwości zakończone logi. Szczegóły parametrów znajdują się przy ich deklaracjach w skrypcie.

## Stan i dalsza praca

Kod został przeniesiony do `!PRACA/Service Box Logs Reporting`. Zachowano dokładniejszy komentarz `PreviousDayOnly` ze starego folderu; porównanie wersji nie wykazało różnic w działaniu. Stary folder pozostaje bez zmian.

Foldery `test-log-report` i `tools` są lokalne i pomijane przez Git. Kolejne zmiany funkcjonalne należy sprawdzać na sztucznych logach, bez wysyłania poczty i bez dodawania wyników do repozytorium. W ramach uporządkowania nie sprawdzano rzeczywistego SMTP ani działania na produkcyjnych logach.
