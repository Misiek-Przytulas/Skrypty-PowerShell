# Skrypty PowerShell

Repozytorium niezależnych skryptów. Każdy projekt ma własny folder z kodem i README opisującym uruchomienie.

- [Przeszukiwarka PDF](<Przeszukiwarka PDF/README.md>) — wyszukiwanie fraz w LOG, TXT i tekstowych PDF.
- [!PRACA / Service Box Logs Reporting](<!PRACA/Service Box Logs Reporting/README.md>) — raporty błędów z logów Service Box / IQService.

## Organizacja

Folder `!PRACA/` zawiera skrypty zawodowe, umieszczane w `!PRACA/<nazwa projektu>/`. Pozostałe foldery projektów zawierają skrypty prywatne; nowy skrypt prywatny umieszczaj w osobnym folderze w katalogu głównym. Katalog `docs/` zawiera wspólną dokumentację, a nie osobny projekt. Katalog `!codex-temp/` to lokalny warsztat techniczny, również nie projekt. Nazwy „Skrypt A”, „Skrypt B” są przykładami, nie wymaganymi katalogami.

Instrukcje i kontekst skryptu trzymaj w jego README. Dane wejściowe, wyniki i pobrane narzędzia są lokalne; repozytorium zawiera kod, instalatory i dokumentację. Po pobraniu na innej maszynie przeczytaj README wybranego skryptu i zainstaluj tylko potrzebne zależności.

## Lokalny warsztat Codex i rozpoczęcie po pobraniu

Każdy folder projektu ma własny wersjonowany `README.md`: opis celu skryptu, wymagania, konfigurację, uruchomienie i ważne ograniczenia. Opisy i kontekst pozostają przy skryptach, poza katalogiem tymczasowym.

Testy Codex, sztuczne logi, wygenerowane raporty, pliki pomocnicze i pobrane narzędzia trzymaj wyłącznie w `!codex-temp/<nazwa projektu>/` w katalogu głównym repozytorium. Przykład: `!codex-temp/Service Box Logs Reporting/test-log-report/` oraz `!codex-temp/Service Box Logs Reporting/tools/`. Cały `!codex-temp/` jest ignorowany przez Git; nie dodawaj go przez `git add -f`. Kod testów potrzebny stale do odtwarzalnej walidacji może być wersjonowany przy projekcie, ale dane i wyniki pozostają lokalne.

Skrypty przeznaczone do normalnego używania nie mogą wymagać istnienia ani zawartości `!codex-temp/`. Ten katalog służy wyłącznie do lokalnej pracy i testów Codex. Zależności potrzebne użytkownikowi muszą mieć instrukcję instalacji i konfiguracji w README danego projektu, niezależną od warsztatu Codex.

Po pobraniu repozytorium na innym komputerze:

1. Przeczytaj `AGENTS.md`, `docs/STATUS.md` oraz README wybranego projektu i sprawdź gałąź oraz stan Git.
2. Jeśli testy lub narzędzia są potrzebne, utwórz `!codex-temp/<nazwa projektu>/` lokalnie. Brak tego folderu po klonowaniu jest prawidłowy; nie jest wymagany do samego uruchomienia skryptów.
3. Odtwórz tylko potrzebne sztuczne dane i pobierz wyłącznie wymagane narzędzia według README projektu. Nie kopiuj starych logów produkcyjnych ani sekretów do repozytorium.
4. Przy testach podawaj jawne ścieżki wejścia i wyjścia w `!codex-temp/`, wyłączając wysyłkę maili i inne działania zewnętrzne.
5. Przed commitem sprawdź `git status` i `git check-ignore` dla nowych plików lokalnych. Wersjonuj kod, potrzebne instalatory oraz dokumentację, a nie zawartość warsztatu.

Service Box nie potrzebuje narzędzi PDF. Historyczne narzędzia przeniesione do warsztatu są zachowane lokalnie; nie trzeba ich odtwarzać. Istniejące wymagania uruchomieniowe innych projektów opisują ich README; nie przenoś ich zależności bez dostosowania konfiguracji.

## Praca z Git i Codex

Pracujemy na różnych gałęziach zależnie od zadania. Gałąź integracyjna to `develop`. Nowe zadanie zaczynaj na osobnej gałęzi z aktualnego `develop`, chyba że użytkownik wskazuje kontynuację istniejącej gałęzi. Pull request kieruj do `develop`; merge wymaga wyraźnego polecenia użytkownika.

Przed każdą pracą odczytaj bieżącą gałąź, stan zmian i historię Git. Nie zakładaj, że gałąź pozostała taka jak w poprzedniej rozmowie. Dokumentacja opisuje zawartość swojej gałęzi i przechodzi razem z nią przez commit, pull request oraz merge; samo przełączenie gałęzi nie przenosi commitów. Niezacommitowane zmiany mogą pozostać w katalogu roboczym po przełączeniu, dlatego najpierw sprawdź ich stan i nie nadpisuj ich ani nie chowaj automatycznie do stash.

Po istotnej zmianie aktualizuj README danego skryptu oraz krótki `docs/STATUS.md`, jeśli zmienił się opisany tam stan. W statusie rozróżniaj zmiany tylko na gałęzi od połączonych do `develop` lub `main`; informacje o gałęzi i merge potwierdzaj w Git. Stałe reguły utrzymuj w `AGENTS.md`.

- [Stałe zasady](AGENTS.md)
- [Aktualny stan repozytorium](docs/STATUS.md)
