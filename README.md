# Czytella 📚✨

**Czytella** to nowoczesna aplikacja w technologii **Flutter**, stworzona z myślą o społeczności miłośników książek, którzy chcą w prosty i bezpieczny sposób wymieniać się lub sprzedawać książki lokalnie.

---

## 📱 Pobierz Aplikację Mobilną na Androida (APK)

Oficjalna aplikacja mobilna Czytella jest dostępna do pobrania w formacie `.apk` bezpośrednio z **GitHub Releases**:

🔗 **[Pobierz najnowszą wersję Czytella APK z GitHub Releases](https://github.com/aucikkosmonaucik-boop/czytella/releases)**

### Dlaczego warto zainstalować aplikację mobilną na telefonie?
- 📷 **Aparat jako skaner kodów ISBN**: Błyskawiczne rozpoznawanie kodów kreskowych z okładek i grzbietów książek za pomocą aparatu w telefonie (automatyczne pobieranie metadanych z Google Books & Open Library).
- 📍 **Lokalny radar 5 km**: Bądź na bieżąco z ogłoszeniami sąsiadów w Twojej dzielnicy i wymieniaj się książkami po drodze z pracy lub spaceru.
- 💬 **Prywatny komunikator w kieszeni**: Umawiaj spotkania i dogaduj wymiany bez udostępniania prywatnego numeru telefonu czy kont społecznościowych.
- ⚡ **100% darmowa i otwarta**: Projekt open-source, wolny od trackerów i reklam.

---

## 🌟 Główne Funkcjonalności

### 1. 🔍 Skaner Kodów ISBN i Pobieranie Metadanych
- **Szybkie rozpoznawanie kodów kreskowych ISBN**:
  - Symulacja skanera z laserową animacją celownika i podświetleniem.
  - Szybkie kody testowe popularnych pozycji (Tokarczuk, Sapkowski, Dukaj, Lem, Orwell, King, Tolkien).
  - Ręczne pole wprowadzania lub wklejania numeru ISBN (10 lub 13 cyfr).
- **Automatyczne pobieranie metadanych książki**:
  - Integracja z **Google Books API** oraz **Open Library API** w czasie rzeczywistym.
  - Automatyczne uzupełnianie okładki, tytułu, autora, roku wydania, liczby stron, kategorii i opisu.
  - Szybkie akcje po zeskanowaniu: dodanie do półki na wymianę/sprzedaż, dodanie do listy życzeń lub natychmiastowe wystawienie ogłoszenia.

### 2. 📍 Moduł Ogłoszeń i Wyszukiwanie z Filtrem Lokalizacji
- **Wyszukiwarka ofert społeczności**:
  - Filtrowanie po tytule, autorze, numerze ISBN i kategoriach.
  - Filtrowanie po typie oferty: *Tylko wymiana*, *Tylko sprzedaż*, *Obie opcje*.
- **Precyzyjny filtr odległości i miast**:
  - **Filtrowanie „W promieniu 5 km”** (zgodnie z wymaganiem użytkownika).
  - Możliwość wyboru promienia: 5 km, 10 km, 25 km lub bez limitu odległości.
  - Wybór konkretnego miasta (Warszawa, Kraków, Wrocław, Poznań, Gdańsk, Łódź, Katowice, itd.).
  - Obliczanie rzeczywistych odległości za pomocą **formuły Haversine**.
  - Wskaźnik bliskości na kartach książek (oznaczenie `< 5 km` i odległości np. *0.9 km stąd*).

### 3. 📖 Moja Półka Czytelnika (Podział na 2 zakładki)
1. **Zakładka 1: „Moje książki na wymianę/sprzedaż”**:
   - Przegląd książek posiadanych przez użytkownika.
   - Status książki: *Na wymianę*, *Na sprzedaż (kwota PLN)*, *Wymiana lub sprzedaż*.
   - Stan fizyczny: *Jak nowa*, *Bardzo dobry*, *Dobry*, *Ślady używania*.
   - Status widoczności: *🟢 W ogłoszeniach* lub *⚪ Tylko na mojej półce*.
   - Opcja 1-kliknięciem: publikacja książki z półki bezpośrednio jako ogłoszenie w społeczności.
2. **Zakładka 2: „Książki których szukam” (Lista życzeń / Wishlist)**:
   - Tytuły, autorzy, priorytety (*Wysoki*, *Średni*, *Niski*), maksymalny budżet i notatki o wydaniu.
   - **Radar Dopasowań Czytelli**: gdy w społeczności pojawi się ogłoszenie pasujące do książki z Twojej listy życzeń, aplikacja wyświetla powiadomienie i link do ogłoszenia!

### 4. 🔒 Bezpieczny Czat Wewnętrzny (Bez telefonu i Facebooka)
- Dedykowany, wewnętrzny komunikator stworzony specjalnie do bezpiecznego dogadywania szczegółów wymiany lub odbioru.
- **Pełna prywatność**: brak konieczności podawania swojego numeru telefonu, profilu na Facebooku czy Messengera.
- **Strukturalna propozycja wymiany (`ExchangeProposal`)**:
  - Karty propozycji wymiany bezpośrednio w dymku czatu (np. *„Moja książka [Solaris] za Twoją [Bieguni]”*).
  - Proponowane bezpieczne miejsce spotkania (np. *stacja metra, kawiarnia, biblioteka*).
  - Przyciski akcji: *Akceptuj wymianę* / *Odrzuć*.
- Podpowiedzi szybkich odpowiedzi (np. *„Czy oferta jest aktualna?”*, *„Mogę wymienić się jutro”*).
- Bezpieczne wskazówki Czytelli dotyczące spotkań w miejscach publicznych.

---

## 🏗️ Architektura Projektu

```text
lib/
├── main.dart                          # Główny punkt wejściowy, motyw Material 3
├── models/
│   ├── book.dart                      # Model książki, enum BookCondition
│   ├── user_book.dart                 # Model książki użytkownika (Tab 1)
│   ├── wishlist_book.dart             # Model listy życzeń (Tab 2)
│   ├── listing.dart                   # Model ogłoszenia społeczności
│   └── chat_message.dart              # Model wiadomości, czatu i propozycji wymiany
├── services/
│   ├── isbn_lookup_service.dart       # Integracja z Google Books API & Open Library API
│   ├── distance_service.dart          # Formuła Haversine, odległości km, presety miast
│   └── sample_data.dart               # Bogate dane startowe (ogłoszenia, półka, czat)
├── providers/
│   └── czytella_provider.dart         # Stan ChangeNotifier (filtry, 5 km, półka, czat)
├── views/
│   ├── home_screen.dart               # Główna nawigacja NavigationBar
│   ├── listings_view.dart             # Moduł ogłoszeń, filtr 5 km, wyszukiwarka
│   ├── listing_detail_screen.dart     # Szczegóły ogłoszenia, propozycja wymiany
│   ├── my_shelf_view.dart             # 2 zakładki: Wymiana/Sprzedaż & Lista życzeń
│   ├── isbn_scanner_view.dart         # Laserowy skaner kodów ISBN + pobieranie API
│   ├── chat_list_view.dart            # Lista bezpiecznych rozmów
│   ├── chat_detail_screen.dart        # Szczegóły czatu z propozycjami wymiany
│   ├── create_listing_dialog.dart     # Formularz publikacji ogłoszenia
│   └── add_book_dialog.dart           # Dodawanie książek na półkę lub do życzeń
└── widgets/
    ├── book_card.dart                 # Karta ogłoszenia z odległością i etykietami
    ├── location_filter_sheet.dart     # Arkusz wyboru miasta i promienia (5 km)
    └── safe_exchange_badge.dart       # Pasek informacji o bezpieczeństwie bez tel/FB
```

---

## 🚀 Uruchomienie Aplikacji

Aby uruchomić aplikację:

```bash
# Uruchomienie na przeglądarce Edge / Chrome
flutter run -d edge

# Uruchomienie na Windows Desktop
flutter run -d windows

# Uruchomienie testów
flutter test

# Sprawdzenie analizy kodu
flutter analyze
```

---

## 🌐 Wdrożenie na Vercel i Railway.com

Aplikacja jest w pełni przystosowana do działania jako strona WWW (Flutter Web) i posiada gotowe pliki konfiguracyjne do wdrożenia na **Vercel** oraz **Railway.com**.

### 🔺 Opcja 1: Wdrożenie na Vercel
1. Zaloguj się na [Vercel.com](https://vercel.com) i kliknij **"Add New Project"**.
2. Zaimportuj repozytorium `aucikkosmonaucik-boop/czytella`.
3. Vercel automatycznie wykryje plik `vercel.json` i skrypt `build_vercel.sh`.
4. Kliknij **"Deploy"** — Vercel skompiluje wersję webową i wygeneruje publiczny adres HTTPS (np. `czytella.vercel.app`).

### 🚂 Opcja 2: Wdrożenie na Railway.com
1. Zaloguj się na [Railway.com](https://railway.com) i kliknij **"New Project"**.
2. Wybierz **"Deploy from GitHub repo"** i wskaż `aucikkosmonaucik-boop/czytella`.
3. Railway automatycznie wykryje plik `Dockerfile` (wieloetapowy build Flutter + Nginx).
4. Przejdź do zakładki **Settings** w Railway i w sekcji **Networking** kliknij **"Generate Domain"**.
5. Twoja aplikacja będzie dostępna pod adresem np. `czytella-production.up.railway.app`!

