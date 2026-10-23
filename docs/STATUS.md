# Aktualny stan

## Cel
Zbiór niezależnych skryptów PowerShell. Skrypty zawodowe są w `!PRACA/`, pozostałe foldery projektów zawierają skrypty prywatne. Każdy projekt ma własne README.

## Potwierdzony stan
- Dostępne projekty: `Przeszukiwarka PDF` oraz `!PRACA/Service Box Logs Reporting`.
- Przy sprawdzeniu 23.10.2026 gałęzie lokalne `main`, `develop` i `Poprawienie-HTML` oraz lokalne referencje `origin/main` i `origin/develop` wskazywały commit `dbd00ab`. Nie odświeżano referencji przez fetch.
- Bieżące zadanie kontynuujemy na `Poprawienie-HTML`, zgodnie z poleceniem użytkownika. Uporządkowano opis podziału skryptów i pracy na gałęziach; właściwe poprawki HTML czekają na szczegóły.

- Lokalny warsztat testów i narzędzi to główny `!codex-temp/`, ignorowany przez Git. Dawne `test-log-report` i `tools` z projektu Service Box są w `!codex-temp/Service Box Logs Reporting/`; kod nie został zmieniony. Zasady odtworzenia po klonowaniu są w głównym README, a opis skryptu pozostaje w README projektu.

- README obu projektów ujednolicono: cel, pliki, wymagania, konfiguracja, uruchomienie, działania zewnętrzne, bezpieczne sprawdzenie i ograniczenia. Opisy porównano z kodem; nie wykonywano testów działania ani instalacji. Normalne uruchomienie nie zależy od warsztatu; Poppler jest opcjonalną zależnością użytkową wyszukiwarki PDF.

## Zasady aktualizacji
- Przed kolejną pracą sprawdź bieżącą gałąź, status i historię Git; powyższy zapis nie zastępuje tego sprawdzenia.
- Ten plik opisuje kontekst swojej gałęzi. README i status aktualizuj wraz ze zmianami kodu; przenoszą się przez commit i merge, nie przez ręczne kopiowanie.
- Stałe zasady są w `AGENTS.md`, ogólny opis w głównym README, a szczegóły skryptu w jego README.
- Nowe zadania zaczynaj z aktualnego `develop`, chyba że użytkownik wskazuje istniejącą gałąź. Nie wykonuj merge bez wyraźnego polecenia.

## Ograniczenia
- Dane testowe, wyniki, pobrane pakiety i lokalne sekrety nie trafiają do Git. Istniejące lokalne pliki pozostają zachowane.
- Nie potwierdzono SMTP ani działania raportera na rzeczywistych logach.
