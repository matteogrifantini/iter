# Task: F2b — Piani persistiti (trips + trip_versions)

## Contesto

F0, F1 e F2a completati sul branch `codex/chat-first-prototype`. Il seam
`IterDataSource` copre già `conversations`/`messages` con
`SupabaseDataSource` live e `MockDataSource` no-op. Il controller persiste
messaggi e badge non letti; il piano accettato resta solo in memoria.

Scope F2 (ITER_APP_PLAN.md): `conversations`/`messages`/`trips`/`trip_versions`;
proposta accettata → nuova `trip_versions` + upsert `trips` + messaggio
conferma; annullata → messaggio, nessuna versione; riavvio → tutto ancora lì.

## Obiettivo F2b

Con backend Supabase, accettare una proposta persiste il piano come nuova
`trip_versions` (numero incrementale) e aggiorna (upsert) la riga `trips`
collegata alla conversazione (`conversations.trip_id`). Rifiutare non tocca i
piani. Mock invariato: le scritture restano no-op e i test restano verdi.

## Checklist

- [x] `schema.sql`: aggiungere `public.trip_versions` (trip_id → trips on delete
      cascade, version_number > 0, draft jsonb, unique(trip_id, version_number),
      created_at) con indice (trip_id, created_at desc), RLS abilitata e policy
      "trip_versions owner all" via trips.user_id.
- [x] `IterDataSource`: aggiungere il contratto
      `Future<void> saveTripVersion({conversationId, title, snapshot})` — upsert
      `trips` + append `trip_versions` per la conversazione indicata.
- [x] `MockDataSource`: `saveTripVersion` no-op sicuro.
- [x] `SupabaseDataSource`: implementazione. Legge `conversations.trip_id`; se
      assente crea la riga `trips` (status derivato da `statusLabel`,
      snapshot jsonb) e collega la conversazione; altrimenti aggiorna la riga
      esistente. Poi inserisce `trip_versions` con `version_number` =
      max+1. Best effort, mai crash.
- [x] Controller: `acceptProposal` (primo settlement) persiste il piano
      aggiornato (`_persistAcceptedPlan`); `rejectProposal` e ri-tentativi su
      proposta già risolta non generano versioni. `_ensureConversation`
      memoizza il future di creazione per evitare doppie righe su scritture
      concorrenti.
- [x] Test nuovi (gruppo "Persistenza piano (F2b)"): accept salva la versione
      aggiornata; reject non salva; proposta già risolta non genera una seconda
      versione; `saveTripVersion` su mock è no-op. Spy `_TripSpyDataSource`
      registra le chiamate.
- [x] Verifica: `flutter analyze` → 0 issue; `flutter test` → 89/89 verdi;
      `flutter build web --release` → ok.
- [~] QA live: non eseguito in questo loop (richiederebbe `./tool/run_web.sh`
      con `ITER_BACKEND=supabase` e credenziali reali; il nuovo schema
      `trip_versions` va applicato prima a mano/CLI su `iter`). Evidenza:
      analyze 0, test 89/89, build web ok, mapping versione+upsert coperti da
      test unitari sullo spy e round-trip serializzazione.

## Vincoli

- NON fare commit o push (il Git owner decide a fine loop).
- Nessuna chiave nel codice; solo `AppConfig`/dart-define e `.env` locale.
- Un file = un solo writer; serializzare `data_source.dart`,
  `supabase_data_source.dart`, `chat_first_controller.dart`.
- Il mock resta la verità per i test: nessuna modifica a
  `ChatFirstDemoData`/`ChatThread` che cambi l'output osservabile oggi.
- Termina la risposta con `STATUS: DONE` quando l'intera checklist è
  completata e la verifica passa, altrimenti `STATUS: CONTINUE`.
