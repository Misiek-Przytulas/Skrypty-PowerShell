# Aktualny stan

## Cel
Zbiór niezależnych skryptów PowerShell. Skrypty zawodowe są w `!PRACA/`, pozostałe foldery projektów zawierają skrypty prywatne. Każdy projekt ma własne README.

## Potwierdzony stan
- Projekty: `Przeszukiwarka PDF` oraz `!PRACA/Service Box Logs Reporting`; opisy i uruchomienie są w ich README.
- Gałąź `Dodanie-godziny-przed-linia`: Service Box ma jasny raport HTML do użycia jako treść maila, pastelowe podsumowanie, osobne dni i karty grup błędów. Nagłówek i temat maila zawierają konfigurowalny hostname; karty pokazują nazwy plików, godziny właściwych wpisów i linie wszystkich zachowanych źródeł. Dni, grupy i źródła są od najnowszych; zachowano priorytet Access Denied. TXT nadal zawiera kompletne szczegóły i może być załącznikiem. Zmiana nie została w ramach tego zadania połączona do `develop` ani `main`.
- Sprawdzenia w Windows PowerShell 5.1 na sztucznych logach: zgodność szczegółów TXT, grupowanie/daty, puste wyniki, niepełny odczyt, długie i specjalne komunikaty oraz HTML/załącznik z atrapą SMTP. Brak prawdziwej wysyłki i wizualnej weryfikacji w klientach pocztowych; podgląd lokalnego pliku przez przeglądarkę był zablokowany.
- Testy i podglądy znajdują się lokalnie w ignorowanym `!codex-temp/Service Box Logs Reporting/`. Normalne działanie nie zależy od warsztatu.

## Zasady aktualizacji
- Przed kolejną pracą sprawdź bieżącą gałąź, status i historię Git; powyższy zapis nie zastępuje tego sprawdzenia.
- Ten plik opisuje kontekst swojej gałęzi. README i status aktualizuj wraz ze zmianami kodu; przenoszą się przez commit i merge, nie przez ręczne kopiowanie.
- Stałe zasady są w `AGENTS.md`, ogólny opis w głównym README, a szczegóły skryptu w jego README.
- Nowe zadania zaczynaj z aktualnego `develop`, chyba że użytkownik wskazuje istniejącą gałąź. Nie wykonuj merge bez wyraźnego polecenia.

## Ograniczenia
- Dane testowe, wyniki, pobrane pakiety i lokalne sekrety nie trafiają do Git. Istniejące lokalne pliki pozostają zachowane.
- Nie potwierdzono SMTP ani działania raportera na rzeczywistych logach.
