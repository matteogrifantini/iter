# Iter — Architettura dell'Applicazione Reale di Viaggi

**Data**: 2 settembre 2026  
**Stato**: Approvato da Brainstorming  
**Target**: Rilascio di produzione (branch `feat/real-iter-app`)

---

## 1. Visione & Obiettivi di Prodotto

Iter supera definitivamente l'approccio dei prototipi "chat-first", eliminando mockup rigidi, risposte hardcoded su destinazioni fisse (come Porto o Lisbona) e il box chat piazzato a metà Home.

L'applicazione si trasforma in una **vera applicazione di viaggi per il pubblico italiano**:
1. **Home Screen pulita e orientata ai contenuti ("Oggi")**: una vetrina che valorizza le pianificazioni dell'utente, le offerte personalizzate sul profilo e la scoperta di nuove mete. Nessun campo di testo o chat permanente sulla Home.
2. **Chat dedicata e intelligente (Google Gemini)**: l'utente parla in linguaggio naturale con l'IA tramite un'interfaccia di chat a schermo intero; Gemini analizza l'intento e genera blocchi interattivi concreti (voli, alloggi per quartiere, tappe giorno per giorno).
3. **Chiave API Gemini per fase demo/test**: configurabile via `.env` o nella schermata Impostazioni per testare liberamente il modello reale (tier gratuito Google AI Studio), con architettura predisposta per il proxy backend definitivo in produzione.
4. **Persistenza locale immediata**: tutti i viaggi, le chat e le preferenze vengono salvati in modo reattivo su storage locale (`SharedPreferences` / JSON), garantendo funzionamento offline e persistenza al riavvio.

---

## 2. Architettura dell'Esperienza & Navigazione

La navigazione primaria dell'app risiede nella barra inferiore a pillola flottante con 3 sezioni chiare:

```
┌─────────────────────────────────────────────────────────────┐
│  OGGI (Home)      │  VIAGGI (Archivio)  │  TU (Profilo)     │
└─────────────────────────────────────────────────────────────┘
```

- **Oggi**: Dashboard di viaggio accogliente, con banner primario *"Organizza un nuovo viaggio"*, riepilogo delle pianificazioni in corso, consigli/offerte su misura e mete da scoprire.
- **Viaggi**: Centro di controllo di tutti i viaggi creati dall'utente, con possibilità di aprire direttamente l'itinerario o continuare la chat di pianificazione.
- **Tu**: Preferenze di viaggio (aeroporto di partenza, budget, passioni), gestione della chiave Gemini (fase demo) e privacy.

---

## 3. Specifiche delle Schermate

### 3.1 Home Screen (`HomeScreen` / Tab "Oggi")

La Home è divisa in sezioni verticali scrollabili ed elimina ogni elemento di chat:

1. **Header Superiore**:
   - Wordmark `iter` a sinistra.
   - Pulsante profilo / avatar a destra per rapido accesso a impostazioni e stato IA.
2. **Hero Banner Primario**:
   - Card visiva di impatto: *"Dove ti porta il tuo prossimo viaggio?"*
   - Sottotitolo empatico e descrittivo.
   - Pulsante CTA prominente ed elegante: **`[ ✨ Organizza un nuovo viaggio ]`**. Tap apre la schermata `TripChatScreen`.
3. **Sezione "Le tue pianificazioni"**:
   - **Stato con viaggi**: carousel o elenco di card dei viaggi salvati con foto di copertina reale, nome città, date, tappe confermate e badge di stato (*"In pianificazione"*, *"Pronto"*).
     - Tap su card: apre direttamente l'itinerario completo (`TripSnapshotScreen`).
     - Tasto secondario: riprende la chat con l'IA.
   - **Stato vuoto (primo avvio)**: card illustrata di benvenuto con invito a creare il primo itinerario.
4. **Sezione "Consigli & Offerte per te"**:
   - Legge dal profilo dell'utente la città di partenza, il budget tipico e gli interessi (es. "Weekend enogastronomici", "Voli diretti economici", "Arte e musei").
   - Card con foto, stima tariffe e link di ricerca reale (Skyscanner / Booking).
   - Tasto *"Pianifica questo viaggio"* che avvia la chat con contesto preimpostato.
5. **Sezione "Scopri nuovi posti"**:
   - Selezione curata di mete con immagini ad alta risoluzione e pillole informative da Wikipedia.

---

### 3.2 Chat Dedicata (`TripChatScreen`)

Schermata aperta a pieno schermo quando si avvia un nuovo viaggio o si riprende una conversazione:

1. **Top Bar**:
   - Freccia indietro (torna alla Home o alla tab Viaggi conservando lo stato).
   - Titolo del viaggio (*"Nuovo viaggio"* &rarr; *"Viaggio a [Destinazione]"*).
   - Azione rapida `[ 🗺️ Vedi Itinerario ]`, abilitata appena Gemini genera la prima struttura del viaggio.
2. **Area Conversazione**:
   - Bolle di messaggio in stile messaggistica moderna.
   - Messaggio di benvenuto di Gemini che invita a raccontare l'idea di viaggio.
   - Input utente libero in italiano naturale.
3. **Blocchi Interattivi Generati da Gemini**:
   - **Blocco Voli/Trasporti**: tratte consigliate con orari, prezzi stimati e link di ricerca reale esterno (Skyscanner/Google Flights).
   - **Blocco Zone/Dove Dormire**: 2–3 quartieri consigliati con spiegazione del perché sono coerenti con le preferenze dell'utente, e link hotel.
   - **Blocco Tappe Giorno per Giorno**: tappe ordinate (mattina, pomeriggio, sera) con monumenti, mercati e trattorie tipiche senza trappole per turisti.
4. **Azione di Chiusura**:
   - Tasto **"Salva e apri itinerario completo"**: converte i dati strutturati in `TripSnapshotData` e apre `TripSnapshotScreen`.

---

### 3.3 Tab "Viaggi" (`TripsListScreen`)

- Elenco cronologico di tutte le pianificazioni create.
- Ogni elemento espone:
  - Miniatura fotografica e nome della meta;
  - Periodo o durata in giorni;
  - Badge di stato;
  - Tasto *"Itinerario"* (apre `TripSnapshotScreen`);
  - Tasto *"Chat"* (apre `TripChatScreen`);
  - Menu contestuale con opzioni *"Rinomina"* ed *"Elimina"*.
- Pulsante flottante o header `[ + Nuovo Viaggio ]`.

---

### 3.4 Tab "Tu" (`ProfileScreen`)

1. **Preferenze di Viaggio Reali**:
   - Aeroporto o città di partenza predefinita (es. Milano, Roma, Napoli, Bologna).
   - Stile preferito (Cultura, Gastronomia, Trekking/Natura, Relax, Avventura).
   - Budget indicativo (Economico, Moderato, Senza limiti).
   - Ritmo delle giornate (Intenso vs Calmo con pause).
2. **Pannello Sviluppatore / Demo (Chiave Gemini)**:
   - *Nota di progetto*: questa sezione è attiva per la fase di demo/collaudo.
   - Campo di input per inserire/modificare la chiave API Google AI Studio.
   - Indicatore di stato in tempo reale (🟢 *Connesso* / ⚪ *Non configurato*).
   - Pulsante *"Testa connessione"* per verificare la validità della chiave con un ping REST.
3. **Dati & Memoria Locale**:
   - Riepilogo dello spazio occupato.
   - Pulsanti di esportazione dati JSON e ripristino/cancellazione cache locale.

---

## 4. Architettura Software & Servizi

```
lib/
├── app/
│   ├── app_config.dart          # Configurazione env (GEMINI_API_KEY, storage)
│   └── iter_theme.dart          # Design system e token colore
├── features/
│   ├── home/                    # Nuova Home screen senza chat box
│   │   ├── home_screen.dart
│   │   └── widgets/             # Hero banner, planner cards, deal cards
│   ├── chat/                    # Esperienza chat dedicata con Gemini
│   │   ├── trip_chat_screen.dart
│   │   ├── trip_chat_controller.dart
│   │   └── widgets/             # Bolle, blocchi volo, alloggio, tappe
│   ├── trips/                   # Archivio e gestione viaggi
│   │   ├── trips_list_screen.dart
│   │   └── trip_repository.dart # Persistenza locale SharedPreferences/JSON
│   ├── profile/                 # Profilo, preferenze e pannello API Demo
│   │   └── profile_screen.dart
│   └── ai/                      # Servizio client Google Gemini
│       ├── gemini_travel_service.dart
│       └── gemini_models.dart   # Parser per estrazione entità e tappe
```

### Componenti Chiave:
1. **`GeminiTravelService`**:
   - Effettua chiamate HTTP POST all'endpoint `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`.
   - Invia system prompt curato con linee guida Iter (zero trappole, consigli autentici).
   - Chiede output strutturato in formato JSON misto a testo descrittivo per popolare i blocchi interattivi.
2. **`TripRepository`**:
   - Gestisce il ciclo di vita dei viaggi: creazione, aggiornamento messaggi chat, serializzazione in `TripSnapshotData`, salvataggio su `SharedPreferences` con chiave `iter_saved_trips`.
3. **`LocalPreferencesService`**:
   - Salva aeroporto di partenza, budget, interessi e la chiave API Gemini per la fase demo.

---

## 5. Piano di Verifica & Qualità

1. **Unit Test**:
   - `GeminiTravelServiceTest`: test mock della chiamata REST con payload JSON valido e gestione quote error.
   - `TripRepositoryTest`: verifica persistenza salvataggio, modifica e cancellazione viaggi.
   - `ProfilePreferencesTest`: verifica persistenza aeroporto di partenza e budget.
2. **Widget Test**:
   - `HomeScreenTest`: verifica che la Home NON contenga nessun widget `TextField` o composer chat; verifica la presenza del banner primario, del pulsante "Organizza un nuovo viaggio" e delle sezioni viaggi e consigli.
   - `TripChatScreenTest`: verifica invio messaggio, rendering della bolla e visualizzazione del pulsante di apertura itinerario completo.
   - `ProfileScreenTest`: verifica inserimento della chiave Gemini e salvataggio preferenze.
3. **Qualità del Codice**:
   - `dart format --output=none --set-exit-if-changed lib test` (100% pulito).
   - `git diff --check` (nessun errore di whitespace).
   - `flutter analyze` (0 issue).
   - `flutter test` (suite complessiva verde).
