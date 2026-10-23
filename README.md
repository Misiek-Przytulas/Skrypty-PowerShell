# Skrypty PowerShell

Repozytorium niezależnych skryptów. Każdy projekt ma własny folder z kodem i README opisującym uruchomienie.

- [Search in PDFs](<Search in PDFs/README.md>) — wyszukiwanie fraz w LOG, TXT i tekstowych PDF.
- [Praca / Service Box Logs Reporting](<Praca/Service Box Logs Reporting/README.md>) — raporty błędów z logów Service Box / IQService.

## Organizacja

Nowy skrypt ogólnego zastosowania umieszczaj w osobnym folderze w katalogu głównym. Skrypty przydatne do pracy umieszczaj w `Praca/<nazwa projektu>/`. Nazwy „Skrypt A”, „Skrypt B” są przykładami, nie wymaganymi katalogami.

Instrukcje i kontekst skryptu trzymaj w jego README. Dane wejściowe, wyniki i pobrane narzędzia są lokalne; repozytorium zawiera kod, instalatory i dokumentację. Po pobraniu na innej maszynie przeczytaj README wybranego skryptu i zainstaluj tylko potrzebne zależności.

## Praca z Git i Codex

Gałąź robocza integracyjna to `develop`. Każde zadanie zaczynaj na osobnej gałęzi z aktualnego `develop`. Pull request kieruj do `develop`; merge wymaga wyraźnego polecenia użytkownika.

- [Stałe zasady](AGENTS.md)
- [Aktualny stan repozytorium](docs/STATUS.md)
