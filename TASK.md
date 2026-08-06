# Task: F0 — Fondazione DataSource Supabase

## Contesto

Repo `iter`, app Flutter. Progetto Supabase pronto (ref `ijefngmutwigfmpfwsrc`,
schema+seed applicati: tabelle `destinations`, `pois`, `profiles`, `trips`,
`trip_versions`, `conversations`, `messages` con RLS). `.env` locale con
`SUPABASE_URL` e `SUPABASE_ANON_KEY` (mai committare). Mock resta default in
debug/test.

Riferimenti da leggere prima: `ITER_APP_PLAN.md` (F0), `supabase/README.md`,
`lib/app/app_config.dart` (già esistente: `backend`, `supabaseUrl`,
`supabaseAnonKey`, `usesSupabase`).

## Obiettivo

Creare il seam `DataSource`: il controller chat-first parla con un'interfaccia,
mai col DB direttamente. Due implementazioni: Mock (default) e Supabase.

## Checklist

- [ ] `flutter pub add supabase_flutter` (usa la versione stabile compatibile)
- [ ] Creare `lib/features/chat_first_prototype/data_source.dart`:
      - `abstract class IterDataSource` con i metodi necessari al prototipo
        chat-first (minimo per F0): `Future<List<JourneyRoute>> fetchJourneys()`
        e `Future<void> init()`.
      - `IterDataSource resolveDataSource()` che ritorna `MockDataSource`
        sempre, tranne quando `AppConfig.fromEnvironment().usesSupabase` è true
        → `SupabaseDataSource`.
- [ ] Creare `lib/features/chat_first_prototype/mock_data_source.dart`:
      implementa `IterDataSource` riusando i dati esistenti di
      `ChatFirstDemoData` (nessun cambiamento di comportamento del mock).
- [ ] Creare `lib/features/chat_first_prototype/supabase_data_source.dart`:
      implementa `IterDataSource`; in `init()` fa `Supabase.initialize` con
      `AppConfig` url/anonKey e `auth.signInAnonymously()` (solo se non già
      autenticato); `fetchJourneys()` legge `destinations` (city + route) e
      mappa in `JourneyRoute` (stessa shape del mock: `name`, `stops`,
      `travelMode`, `season`, `durationLabel`, `matchScore`, `whyItFits`,
      `posterAsset`, `videoAssets`, `destinationIds`). Se la tabella è vuota o
      la rete fallisce, ritorna lista vuota senza crash.
- [ ] Cablare il resolve: in `lib/main.dart` o `chat_first_app.dart` (file del
      prototipo), risolvere la DataSource all'avvio e passarla al controller
      `ChatFirstPrototypeController`. Il percorso mock deve restare identico a
      oggi (stessi dati, stessi test).
- [ ] NON modificare file legacy (`lib/screens/`, `lib/app/iter_app.dart`).
- [ ] Verifica: `flutter analyze` → 0 issue; `flutter test` → 71 verdi (mock
      invariato); `flutter build web --release` → ok.

## Vincoli

- NON fare commit o push.
- NON mettere chiavi nel codice; si usano solo `AppConfig`/dart-define e il
  `.env` locale.
- Se l'API di `supabase_flutter` v2 richiede qualcosa di diverso (es. nome
  parametri), adeguati alla versione reale e annota la differenza nel report.
- Termina la risposta con `STATUS: DONE` quando l'intera checklist è
  completata e la verifica passa, altrimenti `STATUS: CONTINUE`.
