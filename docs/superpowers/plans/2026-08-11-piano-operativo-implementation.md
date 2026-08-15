# Piano operativo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trasformare il `TripSnapshot` chat-first nel Piano operativo canonico, visuale, modificabile, versionato e persistibile definito nella specifica approvata del 10 agosto 2026.

**Architecture:** Il dominio resta immutabile e serializzabile: `TripSnapshot` si sposta in un modulo dedicato, un editor puro produce anteprime revisionate e il controller applica/persiste solo conferme non stale. Le superfici Flutter consumano controller e snapshot senza mutare liste; link esterni, lifecycle e video passano da seam iniettabili e testabili. Il JSONB esistente resta il formato di persistenza: non si aggiungono colonne, ma si corregge l'RLS di `trip_versions` e si rende osservabile il risultato delle scritture.

**Tech Stack:** Flutter/Dart 3.12, Material 3, `video_player`, `url_launcher`, Supabase Flutter 2.x/Postgres 17, widget test Flutter, asset locali.

## Global Constraints

- Android è il target prodotto; Web è soltanto harness QA.
- Il prototipo resta dietro `ITER_CHAT_FIRST_PROTOTYPE` e non scrive in `IterStore`.
- Nessuna nuova dipendenza: riusare Flutter, `video_player` e `url_launcher`.
- Nessun checkout, pagamento, dato bancario, PNR, ricevuta o documento.
- Inventario, prezzi e suggerimenti sono mock deterministici e dichiarati con `Dati demo · prezzi e disponibilità non sono in tempo reale.`
- Ogni modifica materiale, inclusa la rimozione, richiede anteprima e conferma esplicita.
- Una conferma è valida solo per lo stesso `conversationId` e la stessa `revision`; una conferma stale viene rifiutata e ricalcolata.
- `Non ancora` ripristina lo stato precedente `selezionato`; soltanto process death o uscita senza ritorno lascia `acquisto aperto`.
- `Chiedi` e `Chiedi a Iter` aprono lo stesso thread, aggiungono contesto removibile, non inviano messaggi e non mutano il Piano.
- Foto e reel hanno attribuzioni strutturate separate e visibili; nessun fetch media a runtime.
- Target minimi `48×48 dp`; gate responsive `320`, `360`, `390 dp`, testo `1.5`, chiaro/scuro e `disableAnimations=true`.
- Riduci movimento elimina autoplay, loop e trasformazioni del pannello.
- Back chiude prima reel, pannello, tastiera o anteprima, poi la route.
- Tutti i colori provengono da `ColorScheme`/`IterColorRoles`; niente raw color, gradienti, glass o raggi oltre 16 dp.
- Le modifiche locali restano visibili se la persistenza fallisce; mostrare `Non salvato` e `Riprova`.
- Il DB live `ijefngmutwigfmpfwsrc` usa JSONB compatibile per `trips` e `conversations`, ma non contiene `trip_versions`: la migrazione deve creare la tabella canonica e il suo indice prima di policy `SELECT`/`INSERT` owner-scoped e RPC.

---

### Task 1: Modello canonico del Piano e JSON retrocompatibile

**Owner:** `worker` con review `flutter_engineer`.

**Files:**
- Create: `lib/features/chat_first_prototype/plan_models.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_models.dart`
- Create: `test/plan_models_test.dart`

**Interfaces:**
- Consumes: i costruttori legacy di `TripSnapshot`, `TripDaySnapshot` e `TripItemSnapshot` usati dalle fixture correnti.
- Produces: `TripSnapshot`, `TripDaySnapshot`, `TripItemSnapshot`, `PlanPlaceDetails`, `PlanMedia`, `MediaAttribution`, `TravelOption`, `StayOption`, `TravelPlanSelection`, `StayPlanSelection`, `PlanCostSummary`, `PlanRevisionMetadata`, `PurchaseState`, `PlanChangeOrigin`, `PlanItemSource` esportati da `chat_first_models.dart`.

- [ ] **Step 1: Scrivere test fallenti per compatibilità e round trip**

  Coprire: JSON legacy senza campi nuovi; fixture completa; enum ignoto con default sicuro; liste non modificabili; attribuzioni foto/reel distinte; costi EUR; `revision == 0` sul legacy.

  ```dart
  test('legacy snapshot remains readable', () {
    final snapshot = TripSnapshot.fromJson(const <String, dynamic>{
      'destinationTitle': 'Porto',
      'country': 'Portogallo',
      'durationLabel': '4 giorni',
      'statusLabel': 'In pianificazione',
      'dates': '14–17 ottobre',
      'transport': 'da definire',
      'stay': 'da definire',
      'placeLabels': <String>['Ribeira'],
      'days': <Map<String, dynamic>>[],
    });
    expect(snapshot.revision, 0);
    expect(snapshot.costSummary.projectedTotalCents, 0);
  });
  ```

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/plan_models_test.dart`
  Expected: FAIL perché i tipi/campi non esistono.

- [ ] **Step 3: Estrarre e ampliare i modelli**

  Importare e riesportare `plan_models.dart` da `chat_first_models.dart`. Conservare i parametri legacy; il costruttore Dart usa `revision: 1` per le fixture correnti, mentre `fromJson` usa `revision: 0` quando il campo è assente. Usare centesimi interi e ISO-8601 nel JSON. `TripItemSnapshot.startTime` sostituisce semanticamente `time`, mantenendo `String get time => startTime` durante la migrazione.

  ```dart
  enum PurchaseState { estimate, selected, purchaseOpened, purchased }
  enum PlanChangeOrigin { manual, chat, share }
  enum PlanItemSource { iter, manual, chat, share }

  @immutable
  class PlanRevisionMetadata {
    const PlanRevisionMetadata({
      required this.id,
      required this.number,
      required this.timestamp,
      required this.origin,
      required this.label,
    });
    final String id;
    final int number;
    final DateTime timestamp;
    final PlanChangeOrigin origin;
    final String label;
  }
  ```

  `TripSnapshot` deve avere `revision`, `revisionMetadata`, `destinationMedia`, `travelSelection`, `staySelection`, `costSummary`, `unplacedItems`; `TripDaySnapshot` deve avere `id` e `date`; `TripItemSnapshot` deve avere `id`, `place`, `startTime`, `durationMinutes`, `source` e `locked`.

- [ ] **Step 4: Rieseguire test mirati e regressione modelli**

  Run: `flutter test test/plan_models_test.dart test/chat_first_prototype_controller_test.dart test/adaptive_home_model_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/plan_models.dart lib/features/chat_first_prototype/chat_first_models.dart test/plan_models_test.dart
  git commit -m "feat(plan): add canonical trip snapshot models"
  ```

### Task 2: Editor puro, anteprime, revisioni e undo

**Owner:** `worker-hard` con review `flutter_engineer`.

**Files:**
- Create: `lib/features/chat_first_prototype/plan_editor.dart`
- Create: `test/plan_editor_test.dart`

**Interfaces:**
- Consumes: modelli Task 1.
- Produces: `PlanPatchPreview`, `PlanPatchKind`, `PlanPatchEffect`, `PlanPatchStatus`, `PlanEditor.previewAddPlace`, `previewMoveStop`, `previewRemoveStop`, `previewChangeTime`, `previewToggleLock`, `rebase`, `apply`.

- [ ] **Step 1: Scrivere test fallenti per ogni comando**

  Coprire aggiunta in slot, `Da sistemare`, riordino con ricalcolo, conflitto, locked/acquistato con conferma rafforzata, rimozione sempre confermata, cambio orario, lock/unlock, stale/rebase e snapshot originale immutato.

  ```dart
  final preview = editor.previewMoveStop(
    conversationId: 'c-porto',
    snapshot: snapshot,
    itemId: 'lello',
    targetDayId: 'day-2',
    targetIndex: 1,
  );
  expect(preview.baseRevision, snapshot.revision);
  expect(snapshot.days.first.items.first.id, 'lello');
  expect(preview.effects, contains('Ribeira slitta di 45 min'));
  ```

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/plan_editor_test.dart`
  Expected: FAIL per file/tipi mancanti.

- [ ] **Step 3: Implementare trasformazioni pure**

  Nessuna notifica, I/O o mutazione. `apply` deve rifiutare `baseRevision != current.revision`, incrementare di uno, creare metadata e restituire prima/dopo. `rebase` ricalcola la stessa intenzione sulla revisione corrente.

- [ ] **Step 4: Test verdi**

  Run: `flutter test test/plan_editor_test.dart test/plan_models_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/plan_editor.dart test/plan_editor_test.dart
  git commit -m "feat(plan): add revision-safe plan editor"
  ```

### Task 3: Persistenza osservabile e RLS delle versioni

**Owner:** `worker-hard`; review `quality_reviewer`; Git owner del task: implementer solo sui percorsi elencati. Applicazione live riservata all'orchestratore dopo review.

**Files:**
- Modify: `lib/features/chat_first_prototype/data_source.dart`
- Modify: `lib/features/chat_first_prototype/mock_data_source.dart`
- Modify: `lib/features/chat_first_prototype/supabase_data_source.dart`
- Modify: `supabase/schema.sql`
- Modify generated migration: `supabase/migrations/20260810235146_add_trip_version_owner_policies.sql`
- Modify: `test/chat_first_prototype_controller_test.dart`

**Interfaces:**
- Consumes: `Conversation`, `TripSnapshot` Task 1.
- Produces: `PlanSaveResult`, `IterDataSource.saveTripVersion({conversationId, conversation, snapshot}) -> Future<PlanSaveResult>`.

- [ ] **Step 1: Scrivere test fallenti sul risultato di salvataggio**

  Coprire success/failure osservabile, payload RPC esatto, aggiornamento `conversations.summary`, retry idempotente per `snapshot.revision`, revisioni fuori ordine, mock success e conservazione locale sul fallimento.

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/chat_first_prototype_controller_test.dart`
  Expected: FAIL sul nuovo contratto.

- [ ] **Step 3: Implementare il contratto Dart**

  ```dart
  @immutable
  class PlanSaveResult {
    const PlanSaveResult.success() : succeeded = true, errorCode = null;
    const PlanSaveResult.failure(this.errorCode) : succeeded = false;
    final bool succeeded;
    final String? errorCode;
  }
  ```

  In Supabase: invocare una sola RPC `save_trip_revision`; demandare alla transazione Postgres creazione/link del viaggio, aggiornamento monotono di `trips.snapshot`, insert idempotente con `version_number == snapshot.revision` e aggiornamento di `conversations.summary` con `conversation.toJson()`; restituire failure tipizzata senza assorbire il risultato.

- [ ] **Step 4: Generare e scrivere la migrazione RLS additiva**

  ```sql
  create table if not exists public.trip_versions (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references public.trips (id) on delete cascade,
    version_number integer not null check (version_number > 0),
    draft jsonb not null,
    created_at timestamptz not null default now(),
    unique (trip_id, version_number)
  );

  create index if not exists idx_trip_versions_trip
    on public.trip_versions (trip_id, created_at desc);

  alter table public.trip_versions enable row level security;

  revoke all privileges on table public.trip_versions from anon, authenticated;
  grant select, insert on table public.trip_versions to authenticated;

  drop policy if exists "trip versions owner select" on public.trip_versions;
  drop policy if exists "trip versions owner insert" on public.trip_versions;

  create policy "trip versions owner select"
  on public.trip_versions for select to authenticated
  using (
    (select (auth.jwt()->>'is_anonymous')::boolean) is false
    and exists (
    select 1 from public.trips t
    where t.id = trip_versions.trip_id
      and t.user_id = (select auth.uid())
    )
  );

  create policy "trip versions owner insert"
  on public.trip_versions for insert to authenticated
  with check (
    (select (auth.jwt()->>'is_anonymous')::boolean) is false
    and exists (
    select 1 from public.trips t
    where t.id = trip_versions.trip_id
      and t.user_id = (select auth.uid())
    )
  );

  create or replace function public.save_trip_revision(...)
  returns uuid
  language plpgsql
  security invoker
  set search_path = ''
  as $$
  -- lock conversazione e viaggio; link atomico; guardia revisione monotona;
  -- insert versione con on conflict do nothing; summary solo non-stale.
  $$;

  revoke all on function public.save_trip_revision(...) from public, anon;
  grant execute on function public.save_trip_revision(...) to authenticated;
  ```

- [ ] **Step 5: Verificare Dart e SQL locale**

  Run: `flutter test test/chat_first_prototype_controller_test.dart test/plan_models_test.dart`
  Run: `git diff --check`
  Expected: PASS.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/chat_first_prototype/data_source.dart lib/features/chat_first_prototype/mock_data_source.dart lib/features/chat_first_prototype/supabase_data_source.dart supabase/schema.sql supabase/migrations test/chat_first_prototype_controller_test.dart
  git commit -m "fix(plan): persist observable trip revisions"
  ```

- [ ] **Step 7: Gate MCP dell'orchestratore**

  Prima dell'applicazione: `get_advisors(security)`; applicare la migrazione con nome `add_trip_version_owner_policies`; rieseguire query read-only su `pg_policies`; non toccare dati. Se il live diverge dalla precondizione, fermarsi.

### Task 4: Fixture complete e media locale attribuito

**Owner:** `worker` con review `product_ux`.

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_data.dart`
- Add: `assets/images/travel/porto_livraria_lello.jpg`
- Add: `assets/videos/vertical/porto_livraria_lello_reel.mp4`
- Modify: `assets/videos/SOURCES.md`
- Modify: `test/plan_models_test.dart`

**Interfaces:**
- Consumes: modelli Task 1.
- Produces: Porto e Roma completi; catalogo luogo per destinazione; almeno 4 voli e 4 hotel deterministici per Porto.

- [ ] **Step 1: Scrivere test fixture fallenti**

  Verificare IDs unici, coordinate valide, 2 giorni Porto, `Livraria Lello`, media locale, attribuzione foto JaimeMSilva/Commons/CC BY-SA 4.0, alternative volo/hotel, costi coerenti e URI HTTPS allowlisted.

- [ ] **Step 2: Scaricare, ottimizzare e derivare il media senza fetch runtime**

  Origine esatta: `https://commons.wikimedia.org/wiki/File:Porto_-_Livraria_Lello.jpg`. Salvare come JPEG locale, mantenere rapporto utile per hero/sheet e generare con `ffmpeg` un breve MP4 verticale silenzioso con solo pan/zoom calmo della stessa foto. Registrare autore, licenza, URL e entrambe le trasformazioni in `SOURCES.md`; il reel deve dichiarare di essere un montaggio demo derivato dalla fotografia, non footage live.

- [ ] **Step 3: Ampliare le fixture**

  Tutte le fixture nuove compilano i campi tipizzati. Prezzi in centesimi EUR; `quotedAt` fisso; opzioni volo includono aeroporti, date/orari, durata, scali, bagaglio, provider, compromesso e URL; hotel includono zona, notti, totale, condizioni, distanza media, atmosfera e compromesso.

- [ ] **Step 4: Verificare**

  Run: `flutter test test/plan_models_test.dart test/chat_first_prototype_controller_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/chat_first_data.dart assets/images/travel/porto_livraria_lello.jpg assets/videos/vertical/porto_livraria_lello_reel.mp4 assets/videos/SOURCES.md test/plan_models_test.dart
  git commit -m "feat(plan): add operational trip fixtures"
  ```

### Task 5: Controller del Piano, cronologia, retry e contesto chat

**Owner:** `worker-hard` con review `flutter_engineer`.

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_data.dart`
- Modify: `test/chat_first_prototype_controller_test.dart`

**Interfaces:**
- Consumes: `PlanEditor`, `PlanSaveResult`, fixture Task 4.
- Produces: `previewAddPlace`, `previewMoveStop`, `previewRemoveStop`, `previewChangeTime`, `previewToggleLock`, `confirmPlanPatch`, `cancelPlanPatch`, `undoLastPlanRevision`, `retryPlanPersistence`, `setPlaceComposerContext`, `clearPlaceComposerContext`, `selectTravelOption`, `selectStayOption`.

- [ ] **Step 1: Scrivere test fallenti del controller**

  Coprire anteprima senza mutazione; apply singolo; stale ricalcolato; cancel; history limit 10; undo; success/failure/retry; stessa conversazione; contesto luogo consumato dal successivo send e removibile; scelta volo/hotel con alternative persistite.

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/chat_first_prototype_controller_test.dart`

- [ ] **Step 3: Implementare stato per-conversazione**

  Usare mappe private per pending patch, stack before/after, stato persistenza e composer context. Ogni apply aggiorna subito `thread.summary.snapshot`, notifica, poi persiste in modo serializzato. Il fallimento non effettua rollback.

- [ ] **Step 4: Test verdi**

  Run: `flutter test test/chat_first_prototype_controller_test.dart test/plan_editor_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/chat_first_controller.dart lib/features/chat_first_prototype/chat_first_data.dart test/chat_first_prototype_controller_test.dart
  git commit -m "feat(plan): add revisioned plan commands"
  ```

### Task 6: Racconto + timeline, scheda luogo, reel e indicazioni

**Owner:** `worker-hard`; review `product_ux` e `platform_engineer`.

**Files:**
- Rewrite: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Create: `lib/features/chat_first_prototype/plan_timeline.dart`
- Create: `lib/features/chat_first_prototype/place_detail_sheet.dart`
- Create: `lib/features/chat_first_prototype/place_reel_screen.dart`
- Create: `lib/features/chat_first_prototype/plan_external_launcher.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Create: `test/trip_snapshot_screen_test.dart`

**Interfaces:**
- Consumes: controller Task 5 e media Task 4.
- Produces: `TripSnapshotScreen(controller, conversationId)`, `GoogleMapsDirectionsUri.build`, `PlanExternalLauncher.open`, place context sopra il composer.

- [ ] **Step 1: Caricare Impeccable craft floor**

  Run: `rtk read .agents/skills/impeccable/reference/craft-floor.md`

- [ ] **Step 2: Scrivere widget test fallenti**

  Coprire assenza mappa, app bar titolo, hero, chip giorni, timeline, empty state, barra globale SafeArea 48dp, sheet ordine/focus/testo 1.5, reel muto/pausa/audio/fonte/fallback/Back/riduzione moto, Maps valido/invalido, `Chiedi a Iter` stesso thread senza invio.

- [ ] **Step 3: Verificare il rosso**

  Run: `flutter test test/trip_snapshot_screen_test.dart`

- [ ] **Step 4: Implementare superficie e seam esterni**

  `TripSnapshotScreen` legge sempre `controller.conversationOf(conversationId).snapshot`; non riceve una copia stale. Il pannello usa `DraggableScrollableSheet`; a testo 1.5 parte esteso. Il reel non fa autoplay/loop con `disableAnimations`; immagine e fonte restano nel fallback. URI Maps solo HTTPS con coordinate finite e range validi.

- [ ] **Step 5: Verificare UI mirata**

  Run: `flutter test test/trip_snapshot_screen_test.dart test/chat_first_prototype_widget_test.dart`
  Expected: PASS.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/chat_first_prototype/trip_snapshot_screen.dart lib/features/chat_first_prototype/plan_timeline.dart lib/features/chat_first_prototype/place_detail_sheet.dart lib/features/chat_first_prototype/place_reel_screen.dart lib/features/chat_first_prototype/plan_external_launcher.dart lib/features/chat_first_prototype/chat_first_shell.dart lib/features/chat_first_prototype/chat_first_thread_screen.dart test/trip_snapshot_screen_test.dart
  git commit -m "feat(plan): build visual operational workspace"
  ```

### Task 7: Aggiunta, riordino, rimozione, orario e lock accessibili

**Owner:** `worker-hard`; review `product_ux` e `quality_reviewer`.

**Files:**
- Create: `lib/features/chat_first_prototype/place_picker_sheet.dart`
- Create: `lib/features/chat_first_prototype/plan_patch_sheet.dart`
- Modify: `lib/features/chat_first_prototype/plan_models.dart`
- Modify: `lib/features/chat_first_prototype/plan_timeline.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `test/plan_models_test.dart`
- Modify: `test/trip_snapshot_screen_test.dart`

**Interfaces:**
- Consumes: comandi controller Task 5.
- Produces: ricerca nome/categoria, proposta slot/`Da sistemare`, drag handle, menu `Sposta`, preview effetti, `Applica`/`Annulla`, conferma rafforzata.

- [ ] **Step 1: Scrivere widget test fallenti**

  Coprire normalizzazione deterministica degli ID legacy, ricerca/scheda/selezione, zero mutazione prima di Applica, `Da sistemare`, equivalenza drag/menu, annulla/applica, stale, rimozione sempre confermata, locked/acquistato rafforzato, change time, toggle lock, focus e snackbar `Modifica applicata` con `Annulla`.

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/trip_snapshot_screen_test.dart`

- [ ] **Step 3: Implementare interazioni Material**

  Il drag produce soltanto `PlanPatchPreview`. Il menu contestuale espone `Sposta`, `Cambia orario`, `Blocca/Sblocca`, `Rimuovi`. Nessuna fila permanente di pulsanti. Le azioni usano bottom sheet/dialog nativi e restano raggiungibili a 320 dp/testo 1.5.

- [ ] **Step 4: Verificare**

  Run: `flutter test test/trip_snapshot_screen_test.dart test/chat_first_prototype_controller_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/place_picker_sheet.dart lib/features/chat_first_prototype/plan_patch_sheet.dart lib/features/chat_first_prototype/plan_models.dart lib/features/chat_first_prototype/plan_timeline.dart lib/features/chat_first_prototype/trip_snapshot_screen.dart test/plan_models_test.dart test/trip_snapshot_screen_test.dart
  git commit -m "feat(plan): add confirmed manual editing"
  ```

### Task 8: Moduli chat ricchi per volo e hotel

**Owner:** `worker-hard`; review `product_ux` e `flutter_engineer`.

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_models.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_data.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`
- Modify: `test/chat_first_prototype_controller_test.dart`

**Interfaces:**
- Consumes: `TravelOption`, `StayOption` e controller Task 5.
- Produces: raccomandazione principale, elenco completo fixture, scelta esplicita e proposta coordinata hotel/date.

- [ ] **Step 1: Scrivere test fallenti**

  Volo: raccomandazione + tutte le opzioni; aeroporti, date/orari, durata, scali, bagaglio, prezzo/freschezza, provider, compromesso; alternative data/aeroporto/scalo; scelta e alternative persistite. Hotel: tutte le opzioni; zona/notti/totale/condizioni/distanza/atmosfera/compromesso; cambio notti produce `PlanProposal`; reject invariato.

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/chat_first_prototype_widget_test.dart test/chat_first_prototype_controller_test.dart`

- [ ] **Step 3: Ampliare i moduli senza ridisegnare la chat iniziale**

  Conservare i kind esistenti dove possibile; il completo inventario fixture vive in un pannello/expansion Material leggibile, non in caroselli densi. Ogni CTA aggiorna il Piano solo attraverso controller o proposta confermata.

- [ ] **Step 4: Verificare**

  Run: `flutter test test/chat_first_prototype_widget_test.dart test/chat_first_prototype_controller_test.dart test/plan_models_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/chat_first_models.dart lib/features/chat_first_prototype/chat_first_data.dart lib/features/chat_first_prototype/chat_first_thread_screen.dart lib/features/chat_first_prototype/chat_first_controller.dart test/chat_first_prototype_widget_test.dart test/chat_first_prototype_controller_test.dart
  git commit -m "feat(plan): add guided flight and stay choices"
  ```

### Task 9: Costi, acquisti esterni e lifecycle Android

**Owner:** `worker-hard`; review `platform_engineer` e `quality_reviewer`.

**Files:**
- Create: `lib/features/chat_first_prototype/plan_cost_sheet.dart`
- Modify: `lib/features/chat_first_prototype/plan_external_launcher.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_app.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `test/trip_snapshot_screen_test.dart`
- Modify: `test/chat_first_prototype_controller_test.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- Consumes: selezioni/costi e persistenza.
- Produces: `openExternalPurchase`, `handleAppLifecycleState`, `purchaseReturnPrompt`, `confirmExternalPurchase`, `dismissExternalPurchasePrompt`.

- [ ] **Step 1: Scrivere test fallenti**

  Coprire sezioni lineari costi/stati/totali; URL non HTTPS o host non allowlisted disabilitato; registrazione ritorno prima del launch; launch fallito non marca aperto; resume atteso una volta; resume normale/cold start nessun prompt; sì aggiorna solo provider/opzione/prezzo/timestamp/stato; `Non ancora` ripristina `selezionato`; process death lascia `acquisto aperto`.

- [ ] **Step 2: Verificare il rosso**

  Run: `flutter test test/trip_snapshot_screen_test.dart test/chat_first_prototype_controller_test.dart test/chat_first_prototype_widget_test.dart`

- [ ] **Step 3: Implementare lifecycle e UI**

  `ChatFirstPrototypeApp` osserva `WidgetsBinding`; il controller trasforma `resumed` in prompt solo se il launch è riuscito nella sessione. Il dialog viene consumato una sola volta dalla shell. Nessun dato sensibile; label dei link annuncia apertura esterna.

- [ ] **Step 4: Verificare**

  Run: `flutter test test/trip_snapshot_screen_test.dart test/chat_first_prototype_controller_test.dart test/chat_first_prototype_widget_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat_first_prototype/plan_cost_sheet.dart lib/features/chat_first_prototype/plan_external_launcher.dart lib/features/chat_first_prototype/chat_first_controller.dart lib/features/chat_first_prototype/chat_first_app.dart lib/features/chat_first_prototype/chat_first_shell.dart lib/features/chat_first_prototype/trip_snapshot_screen.dart test/trip_snapshot_screen_test.dart test/chat_first_prototype_controller_test.dart test/chat_first_prototype_widget_test.dart
  git commit -m "feat(plan): add external purchase lifecycle"
  ```

### Task 10: Documentazione, matrice accessibilità e gate finali

**Owner:** `worker` per docs/test; review finale `quality_reviewer`; orchestratore Git owner per integrazione.

**Files:**
- Modify: `HANDOFF.md`
- Modify: `PRODUCT.md`
- Modify: `DESIGN.md`
- Modify: `docs/superpowers/specs/2026-08-10-piano-operativo-design.md` solo per note d'implementazione verificata, senza cambiare decisioni approvate
- Modify: `test/trip_snapshot_screen_test.dart`

**Interfaces:**
- Consumes: tutti i task.
- Produces: documentazione coerente e matrice completa.

- [ ] **Step 1: Aggiungere test matrice e stress**

  Eseguire 320/360/390 dp, light/dark, testo 1.5, `disableAnimations`; piano vuoto; 7 giorni; 10 tappe/giorno; label italiane lunghe; semantica; Back overlays; nessun overflow.

- [ ] **Step 2: Aggiornare documenti**

  Rimuovere affermazioni read-only. Documentare Piano canonico, comandi confermati, persistenza osservabile, acquisto esterno e confini mock. Conservare fuori scope invariato.

- [ ] **Step 3: Eseguire gate statici e test**

  Run: `flutter analyze`
  Run: `flutter test`
  Expected: PASS.

- [ ] **Step 4: QA Browser integrato**

  Avviare `./tool/run_web.sh`; verificare `http://127.0.0.1:7357` in Browser integrato: chiaro/scuro, pannello/scroll, reel/fallback, aggiunta, riordino, costi, ritorno provider simulato. Fermare il server.

- [ ] **Step 5: Build**

  Run: `flutter build web --release`
  Run: `flutter build apk --debug`
  Expected: entrambi riusciti.

- [ ] **Step 6: Verifica Supabase finale**

  Con MCP: policy `trip_versions` presenti; advisor security/performance senza finding introdotti dal task; query di test autenticata soltanto se disponibile senza inventare credenziali. Non inserire dati di produzione per il smoke test.

- [ ] **Step 7: Commit**

  ```bash
  git add HANDOFF.md PRODUCT.md DESIGN.md docs/superpowers/specs/2026-08-10-piano-operativo-design.md test/trip_snapshot_screen_test.dart
  git commit -m "docs(plan): align operational workspace"
  ```

## Self-review coverage map

- Spec §4 luogo/reel/maps/chat: Task 4 + Task 6.
- Spec §5 modifica/versioni/undo: Task 2 + Task 5 + Task 7.
- Spec §6 volo/hotel: Task 1 + Task 4 + Task 8.
- Spec §7 costi/acquisti/ritorno: Task 1 + Task 9.
- Spec §8 modello/comandi/persistenza: Task 1 + Task 2 + Task 3 + Task 5.
- Spec §9 errori: Task 5–9.
- Spec §10 accessibilità/Android: Task 6 + Task 7 + Task 9 + Task 10.
- Spec §11 gate: Task 10.
- Spec §12 fuori scope: Global Constraints.
- Spec §13 accettazione: tutti i task, review per task e review finale.
