# Task: F3 — Profilo e memoria persistiti

## Contesto

F0–F2 completati e committati su `codex/chat-first-prototype` (HEAD `56cf2d5`,
pushati su origin). `IterDataSource` copre catalogo, conversazioni, messaggi e
piani. Il tema oggi vive in `SharedPreferencesAsync` (`appearance:theme-mode:v1`)
in `chat_first_app.dart`; i tag memoria sono costanti `_learned` in
`chat_first_profile_screen.dart`.

Schema: `public.profiles (id, theme_mode check light|dark|system default system,
memory_tags text[] default '{}', updated_at)` con RLS `profiles owner
select/insert/update` già applicato su `iter`.

## Obiettivo F3

Con backend Supabase: `theme_mode` e `memory_tags` letti e scritti su
`profiles` (riga per `auth.uid()`); tema applicato al riavvio; memoria mostrata
come tag (non interattivi, come ora). Il percorso mock resta byte-identico:
stesso default chiaro e stessi tag demo.

## Checklist

- [x] `IterDataSource`: aggiungere contratto profilo:
      - `Future<ProfileRow?> fetchProfile()` — tema + memoria del proprietario;
      - `Future<void> upsertProfile({ThemeMode? themeMode, List<String>? memoryTags})`
        — insert-or-update sulla riga `auth.uid()`;
      modello leggero `ProfileRow` (themeMode, memoryTags) nei modelli.
- [x] `MockDataSource`: `fetchProfile` → null (default demo), `upsertProfile` no-op.
- [x] `SupabaseDataSource`: `fetchProfile` legge `profiles` per `auth.uid()`
      (null se assente); `upsertProfile` fa `upsert` su `profiles` (id =
      `auth.uid()`). Su errore: null / no-op, mai crash.
- [x] Controller: esporre `themeMode`, `memoryTags`, `Future<void> loadProfile()`
      e `Future<void> setThemeMode(ThemeMode)`. `setThemeMode` aggiorna stato +
      notifica e persiste via data source (best effort). `loadProfile` su
      Supabase valorizza tema e tag dal DB; su mock lascia i default demo.
- [x] App (`chat_first_app.dart`): in `initState` chiamare `loadProfile()`
      insieme a `loadTrendJourneys()`/`restoreConversations()` e applicare il
      tema letto. `onThemeChanged` della shell chiama `controller.setThemeMode`.
      SharedPreferences **rimosso**: il tema ora ha un'unica fonte di verità
      (controller → data source; mock = chiaro a ogni avvio, Supabase =
      `profiles.theme_mode`).
- [x] Profilo: `ChatFirstProfileScreen` mostra i tag da `memoryTags` (param con
      default vuoto, la shell passa `controller.memoryTags`); rimosso `_learned`.
      SegmentedButton alimentato da `themeMode` (prop invariata).
- [x] Test nuovi (gruppo "Profilo e memoria (F3)", 5 test + spy
      `_ProfileSpyDataSource`): fetchProfile/upsert mock no-op; loadProfile mock
      mantiene default; setThemeMode aggiorna stato e persiste via spy; stesso
      valore non persiste di nuovo; loadProfile valorizza tema/tag dallo spy.
- [x] Verifica: `flutter analyze` → 0 issue; `flutter test` → 94/94 verdi
      (89 baseline + 5 F3); `flutter build web --release` → ok.
- [~] QA live: non eseguito in questo loop (servono credenziali Supabase reali;
      `profiles` è già applicato su `iter`). Evidenza: analyze 0, test 94/94,
      build web ok, mapping `theme_mode`/`memory_tags` coperti da spy e
      serializzazione round-trip.

## Vincoli

- NON committare (il Git owner decide a fine loop).
- Nessuna chiave nel codice.
- Un file = un solo writer; serializzare `data_source.dart`,
  `supabase_data_source.dart`, `chat_first_controller.dart`,
  `chat_first_app.dart`, `chat_first_profile_screen.dart`.
- Mock resta la verità per i test: output osservabile invariato.
- Termina con `STATUS: DONE` quando la checklist è completa e la verifica passa,
  altrimenti `STATUS: CONTINUE`.
