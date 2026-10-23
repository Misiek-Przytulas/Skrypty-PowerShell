# Zasady pracy w repozytorium

- Wyjaśniaj krótko, prostym językiem i po polsku.
- Przed pracą przeczytaj `docs/STATUS.md`, README danego skryptu oraz sprawdź stan Git. Stan repozytorium ma pierwszeństwo przed nieaktualnymi notatkami.
- Każde nowe zadanie wykonuj na osobnej gałęzi z aktualnego `develop`, chyba że użytkownik wyraźnie poleci kontynuować istniejącą gałąź. Aktualizuj `develop` wyłącznie przez fast-forward; przy rozbieżnościach lub lokalnych commitach nieobecnych na GitHubie zatrzymaj się i poinformuj użytkownika.
- Nie nadpisuj ani nie usuwaj niezapisanych zmian użytkownika; nie chowaj ich automatycznie do stash.
- Nie wykonuj merge bez wyraźnego polecenia. Nie używaj force push ani destrukcyjnych operacji Git bez wyraźnej zgody.
- Zmieniaj wyłącznie pliki potrzebne do zadania. Nie twórz dodatkowych plików z kontekstem, planów, notatek ani raportów.
- Utrzymuj `docs/STATUS.md` krótki. Po istotnych zmianach opisuj końcowy stan, nie przebieg rozmowy. Kontekst konkretnego skryptu zapisuj w jego README; nie powielaj informacji.
- Rozróżniaj zmiany na gałęzi od zmian połączonych do `develop` lub `main`. Nie oznaczaj merge jako zakończonego przed wykonaniem.
- Ogólny opis repozytorium utrzymuj w głównym README; opis i uruchomienie skryptu w README jego folderu.
- Nie zapisuj w repozytorium haseł, tokenów, kluczy ani rzeczywistych danych uwierzytelniających. Nie odczytuj ani nie wypisuj sekretów bez potrzeby związanej z zadaniem.
- Lokalną konfigurację z sekretami pomijaj w Git. Wersjonuj wyłącznie potrzebny przykład bez sekretów, np. `.env.example`. Nie twórz konfiguracji na zapas.
- Nie dodawaj do Git danych testowych, rzeczywistych logów, wygenerowanych raportów ani pobranych pakietów narzędzi. Zachowuj użyteczny kod, instalatory oraz potrzebną dokumentację. Nie usuwaj istniejących danych bez zgody.
- Przed commitem sprawdź diff i listę plików pod kątem zakresu oraz sekretów. Dodawaj pliki jawnie, wyłącznie związane z zadaniem.
- Wykonuj sprawdzenia odpowiednie do zmiany. Nie twórz testów dla samych zmian dokumentacji. Nie deklaruj testów, których nie wykonano.
- Po zakończeniu krótko podaj: co zmieniono, jak sprawdzono, na jakiej gałęzi oraz czy wykonano commit i push.
- Nie instaluj narzędzi i zależności, jeśli nie są potrzebne do zadania.
