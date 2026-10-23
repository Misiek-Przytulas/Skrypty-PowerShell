# Aktualny stan

## Cel
Zbiór niezależnych skryptów PowerShell, z osobnymi folderami i dokumentacją. Skrypty zawodowe znajdują się w `Praca/`.

## Potwierdzony stan
- Dostępne projekty: `Search in PDFs` oraz `Praca/Service Box Logs Reporting`; opis uruchomienia znajduje się w ich README.
- Początkowe lokalny `main` i `origin/main` mają oddzielne historie, ale identyczną zawartość. Lokalny `main` zachowano bez zmian.
- `develop` utworzono z `origin/main`; porządkowanie jest na gałęzi `chore/kontekst-projektu`. Nie wykonano merge do `develop` ani `main`.
- Porównano skrypt Service Box ze starym folderem: różnił się tylko komentarzem zakresu dat; zachowano dokładniejsze objaśnienie.

## Decyzje i ograniczenia
- Gałęzią integracyjną jest `develop`, a nowe zadania powstają na osobnych gałęziach.
- Kontekst i uruchomienie konkretnego skryptu pozostają w jego README; zasady pracy są w głównym AGENTS.md.
- Dane testowe, wyniki, pobrane pakiety i lokalne sekrety nie trafiają do Git. Istniejące lokalne pliki zachowano.
- Nie potwierdzono działania SMTP ani uruchomienia raportera na rzeczywistych logach. Nie dodawano konfiguracji z sekretami.

## Następny krok
Przejrzeć pull request porządkujący repozytorium do `develop`. Merge wykonać wyłącznie na wyraźne polecenie. Następne zmiany skryptów prowadzić zgodnie z AGENTS.md.
