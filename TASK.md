# Task: F4 — Nuovo viaggio reale (intake inline nel thread + Edge Function mock)

## Contesto

F0–F3 completati e committati su `codex/chat-first-prototype` (HEAD `3c072ed`).
Il prototipo chat-first ha thread deterministici (ChatThread + ScriptedBeat +
PlanProposal), persistenza conversazioni/messaggi/piani su Supabase e profilo.
Il Lab Nuovo viaggio (Semplice) è separato e isolato.

`supabase/functions/plan/README.md` documenta già il contratto server
(POST /functions/v1/plan, SSE eventi stage|proposal|patch|warning|complete|error,
mock default, JWT obbligatorio, quota via `consume_ai_credit`, mai creare
versioni lato server). La funzione **non è implementata** (solo README).

Scope F4 (ITER_APP_PLAN): intake Semplice **inline nel thread** (domande una
alla volta via scelte/messaggi); proposta finale; scelta → creazione `trips` +
`conversations` + primo messaggio; Edge Function AI proxy con mock server-side
default. Chiavi solo server-side.

## Obiettivo F4 (questo batch)

Due sotto-task indipendenti, file disgiunti:

**F4a (client, flutter_engineer)** — "Inizia un viaggio" dalla Home apre un
thread con intake guidato inline: domande una alla volta come messaggi con
`choices`, risposte del viaggiatore, proposta finale (`PlanProposal` con
`TripSnapshot`), accettazione che persiste la conversazione, il piano
(trip_versions) e il primo messaggio via il data source esistente. Mock
invariato: il percorso demo resta byte-identico.

**F4b (Edge Function, platform_engineer)** — implementare
`supabase/functions/plan/index.ts` conforme al README: validazione JWT,
parsing request, provider mock deterministico di default (risponde con un
draft valido), SSE con gli eventi della allowlist, guardie quota best-effort,
mai secrets nel client. Chiavi solo server-side.

## Vincoli

- NON committare (il Git owner decide a fine loop).
- File disgiunti tra F4a e F4b; un solo writer per file.
- Nessuna chiave nel codice client.
- Il mock/client demo resta la verità per i test esistenti.
- Termina con `STATUS: DONE` quando la checklist è completa e la verifica
  passa, altrimenti `STATUS: CONTINUE`.

## Checklist F4

- [x] **F4a — intake inline nel thread**
  - [x] `IntakeThread extends ChatThread` in `chat_first_data.dart`:
    `advance()` con id stabili dei beat, `answers` keyed `q-*`,
    `travelerMessage` cattura la risposta dopo ogni domanda.
  - [x] `intakeThreadFor(JourneyRoute)` (5 domande: durata, ritmo, base,
    trasporto, budget) + proposta finale (`PlanProposal`/`tripSummary`/
    `operational`) assemblata da `answers` con fallback default.
  - [x] `ChatFirstFirstPrototypeController.startFromJourney` usa
    `intakeThreadFor` (percorso demo `planningThreadFor` invariato).
  - [x] 5 test controller + 1 widget test F4a (ritmo → tappe/giorno,
    accettazione persiste `trip_versions` via spy).
- [x] **F4b — Edge Function `plan`**
  - [x] `supabase/functions/plan/index.ts`: POST+OPTIONS, JWT obbligatorio
    (401), validazione body (400), SSE allowlist, provider mock deterministico,
    `revise_itinerary` con `move_item` su slot non bloccati, quota best-effort
    via `consume_ai_credit`, warning `provider_not_implemented` per gemini.
  - [x] `supabase/config.toml` con `[functions.plan] verify_jwt = true`.
  - [x] `README.md` allineato al codice (schema `PlanDraftV1`, RPC quota).
  - [x] `deno check` e `deno lint` puliti.

## QA

- [~] `flutter analyze` 0 issue; `flutter test` 100/100; `flutter build web
  --release` ok.
- [~] `deno check` EXIT 0; `deno lint` 1 file ok.
- [~] QA live non eseguibile da qui: serve deploy manuale di
  `supabase/functions/plan` (con `verify_jwt`) e migrazione
  `consume_ai_credit` (già in `supabase/migrations/0001_iter.sql`), più
  `trip_versions` già in `schema.sql` applicato su `iter`.
- [~] Review quality_reviewer: nessun finding bloccante.

## Rischi residui

- `IntakeThread.advance()` duplica la logica base di `ChatThread.advance()`;
  tenere sincronizzato se evolve la base.
- `startFromJourney` con `destinationIds` vuoto fallisce con `first` (preesistente).
- Edge Function non eseguita a runtime in CI (no Supabase locale); verificata
  solo con `deno check`/`lint`.
- `consume_ai_credit` vive solo in `migrations/`; se si applica solo
  `schema.sql` la quota degrada a `unavailable` (warning, non crash).

## Evidenze

- `flutter analyze` 0; `flutter test` 100/100; `flutter build web --release` ok.
- `deno check` EXIT:0; `deno lint` "Checked 1 file".
- Subagent: flutter_engineer (F4a) e platform_engineer (F4b), file disgiunti.
- `git diff --check` pulito sui sorgenti.

## STATUS: DONE
