# Iter — Handoff

Aggiornato il 2 settembre 2026. Questo è il punto di ingresso per il lavoro sul branch `feat/real-iter-app`.

## Stato

L'app Iter è in fase di implementazione del primo verticale completo di organizzazione reale, basato su chat-first guidata da AI (Google Gemini via Supabase Edge Function a costo zero) con card interattive, scelte visive chiare e piano generato dalle decisioni confermate.

- **Branch attivo:** `feat/real-iter-app` (baseline visiva a `9007e49`).
- **Entrypoint:** `lib/main.dart` avvia l'applicazione tramite `buildIterApp()`.
- **Target operativo:** implementazione in corso di [2026-09-02-iter-organization-vertical.md](docs/superpowers/plans/2026-09-02-iter-organization-vertical.md) secondo la [specifica di prodotto](docs/superpowers/specs/2026-09-01-iter-organization-vertical.md).

Prima di toccare altro controllare sempre:

```bash
git status --short --branch
```

## Configurazione Backend & Sicurezza

Il file `.env.example` fornisce i valori predefiniti sicuri:

- **`ITER_BACKEND=mock` (predefinito):** esecuzione locale e deterministica, ideale per sviluppo offline e suite di test senza dipendenze di rete.
- **`ITER_BACKEND=supabase` (opzionale):** connessione al backend Supabase per persistenza remota e invocazione delle Edge Functions (`supabase/functions/organize/` e `plan/`).
- **Google Gemini API (Free Tier):** le chiamate AI avvengono esclusivamente lato backend via Edge Function autenticata con il token JWT dell'utente; nessuna chiave API Gemini o segreto di servizio risiede nel client Flutter.

## Moduli & Stato Reale delle Funzionalità

Per trasparenza e integrità del codice, ogni modulo è classificato in base al suo effettivo stato di verifica:

### Integrazioni Live Verificate (API Aperte a Costo Zero)
- **🗺️ Mappa & Routing Pedonale (`lib/features/map/`)**: `flutter_map` con tile layer live `tile.openstreetmap.org`, calcolo percorsi su strada OSRM e geocodifica Nominatim.
- **🏛️ Schede Luoghi & Foto (`lib/features/places/`)**: `RealPlaceService` con dati enciclopedici e foto ad alta risoluzione da Wikipedia REST API.
- **🌤️ Meteo Live (`lib/features/weather/`)**: `WeatherService` con previsioni a 7 giorni da API pubblica Open-Meteo.
- **💶 Spese & Tassi di Cambio (`lib/features/expenses/`)**: `TripExpenseService` con conversione valute dai tassi ufficiali BCE.
- **🗣️ Frasario & Traduttore (`lib/features/translator/`)**: frasario da viaggio e integrazione MyMemory Translation API.
- **🧳 Checklist Intelligente (`lib/features/checklist/`)**: packing list interattiva locale con categorie per tipologia di viaggio.
- **📅 Esportazione Calendario (`PlanExporter`)**: condivisione testo e file standard RFC 5545 (`.ics`).
- **💾 Preferenze Locali (`LocalPreferencesService`)**: persistenza preferenze e tema via `SharedPreferences`.

### Moduli con Dati Demo / Mock Strutturati
- **✈️ Ricerca Voli (`lib/features/flights/`)**: tratte, orari e tariffe di riferimento basate su fixture deterministiche (etichettate come dati demo); link esterni verso Skyscanner e Google Flights. L'integrazione backend con provider reale è definita dal piano di fattibilità.
- **🏨 Ricerca Alloggi (`lib/features/stays/`)**: comparatore hotel e B&B per quartiere basato su dati demo strutturati con filtri servizi e link partner.
- **🍲 Guida Gastronomica (`lib/features/food/`)**: catalogo piatti tipici e locali autentici basato su dati demo curati.

### Verticale di Organizzazione (`lib/features/organization/`)
Completato e verificato al 100% secondo il piano [2026-09-02-iter-organization-vertical.md](docs/superpowers/plans/2026-09-02-iter-organization-vertical.md):
- Macchina a stati tipizzata (`OrganizationSession`, `OrganizationState`, `TripIntent`).
- Budget rigoroso di domande (3–4 essenziali, massimo 2 adattive con chip `Non lo so` / `Decidi tu`).
- Card interattive visuali nel thread di chat (`IntentSummaryCardView`, `QuestionCardView`, `SearchStatusCardView`, `FlightComparisonCardView`, `ZonePickerCardView`, `StayPickerCardView`, `PlanReadyCardView`).
- Flusso acquisto voli con `ExternalPurchaseDialog` a 3 vie (Sì aggiorna, Non ancora, Ho scelto un'altra opzione) senza mai marcare l'acquisto all'apertura del link esterno.
- Selezione zone arricchita con spiegazioni "Perché per te" e selezione alloggi guidata dal profilo.
- Generazione piano garantita tramite `TripPlanMapper` e transizione pulita a `TripSnapshotScreen` solo dopo conferma di volo e alloggio.
- Edge Function Supabase `supabase/functions/organization-step/index.ts` con fallback trasparente locale `OrganizationAiGateway` in assenza di credenziali backend. Zero segreti nel client.
- Test E2E completo e stress test responsive a 320dp (`test/organization/organization_vertical_e2e_test.dart`).

## Verifica & Qualità

La test suite è mantenuta verde al 100%:

```bash
dart format --output=none --set-exit-if-changed lib test
git diff --check
flutter analyze
flutter test
```

- **Stato Analisi:** 0 errori, 0 warning (`flutter analyze` -> `No issues found!`).
- **Stato Test:** **347 test superati su 347 (100% green)**.

Per testare l'interfaccia su browser web (release):
```bash
flutter build web --release
python3 -m http.server 7359 --directory build/web
```
L'app è servita su `http://127.0.0.1:7359`.
