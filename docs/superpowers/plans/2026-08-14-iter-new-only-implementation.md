# Iter new-only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendere `codex/iter-new-only` l'unica app avviabile, rimuovere il percorso legacy e completare i flussi mock di Piano, Profilo, costi e importazione Reel/TikTok.

**Architecture:** `ChatFirstPrototypeApp` diventa il root unico. Il controller chat-first conserva conversazioni, snapshot e persistenza opzionale; nuovi modelli puri separano disponibilità, statistiche e ispirazioni dal rendering. Le UI chiamano comandi del controller e ogni mutazione importante passa da test, anteprima o conferma.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Material 3, `flutter_test`, `url_launcher`, `video_player`, mock locale deterministico e sorgente Supabase già esistente come percorso opzionale.

## Global Constraints

- Il branch di lavoro è `codex/iter-new-only`; modifiche e file già presenti nel worktree vanno preservati.
- Il branch mantiene dati e provider mock deterministici; non introduce pagamenti reali, account di pagamento, Android Share Target o provider live.
- `lib/main.dart` avvia direttamente `ChatFirstPrototypeApp`; i flag `ITER_CHAT_FIRST_PROTOTYPE` e `ITER_NEW_TRIP_LAB` non scelgono più l'app.
- Il nuovo controller non scrive in `IterStore`; ogni dato demo deve essere dichiarato come mock quando può sembrare reale.
- La shell espone esattamente `Oggi`, `Viaggi`, `Tu`; il Piano si apre dal thread e il thread resta raggiungibile dal viaggio.
- Il Piano non mostra una mappa in alto; mantiene hero media, timeline, modifica manuale, schede luoghi e indicazioni esterne.
- Ogni target interattivo è almeno 48 dp e ogni gesto ha un'alternativa semantica.
- Non usare gradienti, glassmorphism, ombre decorative o una palette parallela a `ColorScheme`/Rotta viva.
- Dopo ogni ciclo TDD eseguire il test mirato; alla fine eseguire `flutter analyze`, `flutter test`, `flutter build web --release` e QA Browser.
- Non creare commit o push automatici: lasciare il batch verificato nel worktree per la decisione dell'utente.

---

## Task 1: Boot new-only e rimozione del percorso legacy

**Files:**
- Create: `lib/app/app_entry.dart`
- Create: `test/app_entry_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app_config.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Delete after import-graph verification: `lib/app/iter_app.dart`, `lib/state/iter_store.dart`, `lib/screens/availability_screen.dart`, `lib/screens/destination_discovery_screen.dart`, `lib/screens/discover_tab.dart`, `lib/screens/home_screen.dart`, `lib/screens/itinerary_screen.dart`, `lib/screens/place_curation_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/stay_selection_screen.dart`, `lib/screens/transport_selection_screen.dart`, `lib/screens/trips_screen.dart`, `lib/features/new_trip_lab/`, `lib/widgets/ai_composer.dart`, `lib/widgets/iter_ui.dart`, `lib/widgets/trip_card.dart`
- Delete tests dedicated only to the old path: `test/widget_test.dart`, `test/iter_store_test.dart`, `test/new_trip_lab_controller_test.dart`, `test/new_trip_lab_widget_test.dart`

**Interfaces:**
- `Widget buildIterApp({ChatFirstPrototypeController? controller})` in `lib/app/app_entry.dart` returns `ChatFirstPrototypeApp(controller: controller)`.
- `AppConfig` exposes only `backend`, `supabaseUrl`, `supabaseAnonKey`, and `usesSupabase`.
- `TripSnapshotScreen` accepts only `controller` and `conversationId`; remove the deprecated `snapshot` and `legacyControllerFactory` path.

- [ ] **Step 1: Add the failing root-contract test**

```dart
testWidgets('root app is always the new three-destination shell', (tester) async {
  final controller = ChatFirstPrototypeController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(buildIterApp(controller: controller));

  expect(find.text('Oggi'), findsOneWidget);
  expect(find.text('Viaggi'), findsOneWidget);
  expect(find.text('Tu'), findsOneWidget);
  expect(find.text('Scopri'), findsNothing);
});
```

Run: `flutter test test/app_entry_test.dart -r expanded`

Expected: FAIL because `buildIterApp` does not exist.

- [ ] **Step 2: Implement the smallest root entry**

```dart
Widget buildIterApp({ChatFirstPrototypeController? controller}) {
  return ChatFirstPrototypeApp(controller: controller);
}
```

Change `main()` to call `runApp(buildIterApp())`, remove the `IterApp` import and delete the two runtime flag fields from `AppConfig`.

- [ ] **Step 3: Run the root test and the analyzer**

Run: `flutter test test/app_entry_test.dart -r expanded && flutter analyze`

Expected: PASS and no analyzer issues.

- [ ] **Step 4: Remove compatibility-only code and old files**

Run the import check before deletion:

```bash
rg -n "app/iter_app|state/iter_store|features/new_trip_lab|screens/|widgets/(ai_composer|iter_ui|trip_card)" lib test
```

Remove only the listed old modules after the check confirms that remaining references are confined to the old files/tests. Keep `lib/models/trip_models.dart`, `lib/data/mock_data.dart` and `lib/widgets/journey_media.dart` because the new feature still imports them. Remove the legacy constructor branch from `TripSnapshotScreen` and update its tests to the controller/conversation API.

- [ ] **Step 5: Prove the cleanup and leave the checkpoint uncommitted**

Run: `rg -n "ITER_CHAT_FIRST_PROTOTYPE|ITER_NEW_TRIP_LAB|IterApp|IterStore|legacyControllerFactory|legacySnapshot" lib test || true && flutter test`

Expected: no runtime/test references to the removed app or flags, and the remaining new-app suite passes.

## Task 2: Modelli puri per disponibilità, statistiche e ispirazioni

**Files:**
- Create: `lib/features/chat_first_prototype/profile_models.dart`
- Create: `lib/features/chat_first_prototype/inspiration_models.dart`
- Create: `lib/features/chat_first_prototype/inspiration_importer.dart`
- Create: `test/profile_models_test.dart`
- Create: `test/inspiration_importer_test.dart`

**Interfaces:**
- `enum AvailabilityKind { free, work }`.
- `class AvailabilityEntry` with `id`, `date`, `kind`, `timeRange`, `note`, `toJson()` and `fromJson()`.
- `class TravelStats` with `completedTrips`, `visitedPlaces`, `estimatedKilometers`.
- `enum InspirationPlatform { instagram, tiktok, generic }`.
- `class InspirationDraft` with `platform`, `url`, `title`, `placeName`, `destinationId`, `moment`, `suggestedCategory`, `mediaAsset`.
- `class SavedInspiration` extends the draft with `id`, `conversationId`, `savedAt`, and `attachedToPlan`.
- `class InspirationImportResult` with nullable `draft`, nullable `error`, `isValid`, and `errorMessage`/`valid` named constructors.
- `InspirationImportResult parseMockInspiration(String rawUrl)` accepts the two fixture hosts and returns an error result for empty, malformed or unsupported URLs.

- [ ] **Step 1: Write model round-trip and normalization tests**

```dart
test('availability entry normalizes the date and round-trips', () {
  final entry = AvailabilityEntry(
    id: 'free-1',
    date: DateTime(2026, 10, 24, 18),
    kind: AvailabilityKind.free,
    timeRange: 'Dopo le 18:00',
    note: 'Fine turno',
  );
  final rebuilt = AvailabilityEntry.fromJson(entry.toJson());
  expect(rebuilt.date, DateTime(2026, 10, 24));
  expect(rebuilt.kind, AvailabilityKind.free);
});
```

```dart
test('mock importer extracts Instagram and TikTok fixtures', () {
  final instagram = parseMockInspiration('https://www.instagram.com/reel/iter-porto');
  final tiktok = parseMockInspiration('https://www.tiktok.com/@iter/roma-foro');
  expect(instagram.draft?.platform, InspirationPlatform.instagram);
  expect(tiktok.draft?.destinationId, 'roma');
  expect(parseMockInspiration('https://example.com/video').draft, isNull);
});
```

Run: `flutter test test/profile_models_test.dart test/inspiration_importer_test.dart -r expanded`

Expected: FAIL because the new model and parser files do not exist.

- [ ] **Step 2: Implement immutable models and the deterministic parser**

Use normalized midnight dates, unmodifiable collections, and exactly two valid fixtures:

```dart
InspirationImportResult parseMockInspiration(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || uri.scheme != 'https') {
    return InspirationImportResult.error('Inserisci un link HTTPS.');
  }
  final key = '${uri.host}${uri.path}';
  switch (key) {
    case 'www.instagram.com/reel/iter-porto':
      return InspirationImportResult.valid(
        const InspirationDraft(
          platform: InspirationPlatform.instagram,
          url: 'https://www.instagram.com/reel/iter-porto',
          title: 'Una mattina lenta a Porto',
          placeName: 'Livraria Lello',
          destinationId: 'porto',
          moment: 'Mattina',
          suggestedCategory: 'Cultura',
          mediaAsset: 'assets/images/travel/porto_livraria_lello.jpg',
        ),
      );
    case 'www.tiktok.com/@iter/roma-foro':
      return InspirationImportResult.valid(
        const InspirationDraft(
          platform: InspirationPlatform.tiktok,
          url: 'https://www.tiktok.com/@iter/roma-foro',
          title: 'Roma al tramonto',
          placeName: 'Foro Romano',
          destinationId: 'roma',
          moment: 'Tramonto',
          suggestedCategory: 'Archeologia',
          mediaAsset: 'assets/images/travel/rome_city.jpg',
        ),
      );
    default:
      return InspirationImportResult.error('Questo link demo non è supportato.');
  }
}
```

Reject unsupported hosts without network access. Keep the media asset bundled in the repository.

- [ ] **Step 3: Run the focused model tests and format**

Run: `dart format lib/features/chat_first_prototype/profile_models.dart lib/features/chat_first_prototype/inspiration_models.dart lib/features/chat_first_prototype/inspiration_importer.dart test/profile_models_test.dart test/inspiration_importer_test.dart && flutter test test/profile_models_test.dart test/inspiration_importer_test.dart -r expanded`

Expected: PASS with no formatting changes left.

## Task 3: Controller state for profile, inspirations and mock confirmation

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_data.dart`
- Modify: `lib/features/chat_first_prototype/plan_models.dart`
- Modify: `test/chat_first_prototype_controller_test.dart`
- Modify: `test/plan_models_test.dart`

**Interfaces:**
- `List<AvailabilityEntry> get availability`.
- `TravelStats get travelStats`.
- `List<SavedInspiration> get savedInspirations`.
- `String addAvailability({required DateTime date, required AvailabilityKind kind, required String timeRange, String note = ''})`.
- `bool removeAvailability(String id)`.
- `SavedInspiration? saveInspiration({required String conversationId, required InspirationDraft draft})`.
- `bool proposeInspiration(String conversationId, String inspirationId)` appends a confirmable plan proposal when the conversation owns a snapshot.
- `bool confirmMockPurchases(String conversationId)` changes selected flight/hotel options to `PurchaseState.purchased` and returns false when the plan has no selected purchasable option.
- `bool mockPurchasesConfirmed(String conversationId)` reports whether all selected purchase options are marked purchased.

- [ ] **Step 1: Add failing controller tests**

```dart
test('availability can be added and removed without IterStore', () {
  final controller = ChatFirstPrototypeController();
  addTearDown(controller.dispose);
  final id = controller.addAvailability(
    date: DateTime(2026, 10, 24),
    kind: AvailabilityKind.free,
    timeRange: 'Tutto il giorno',
  );
  expect(controller.availability.single.id, id);
  expect(controller.removeAvailability(id), isTrue);
  expect(controller.availability, isEmpty);
});
```

```dart
test('mock confirmation settles selected travel and stay options', () {
  final controller = _planController();
  addTearDown(controller.dispose);
  expect(controller.confirmMockPurchases('c-plan-ui'), isTrue);
  expect(controller.mockPurchasesConfirmed('c-plan-ui'), isTrue);
});
```

Use the existing `_planController()` helper in `test/chat_first_prototype_controller_test.dart`; it already seeds the operational Porto conversation used by the purchase tests.

Run the named tests. Expected: FAIL because the getters and commands do not exist.

- [ ] **Step 2: Implement local controller state**

Seed availability and `TravelStats` from deterministic demo fixtures. Keep lists unmodifiable at the public boundary and call `notifyListeners()` after every mutation. Save inspirations in memory and add a concise assistant message or `PlanProposal` with `PlanChangeOrigin.share`; do not mutate the snapshot before acceptance.

- [ ] **Step 3: Implement mock purchase settlement through existing immutable selections**

Reuse `TravelPlanSelection`, `StayPlanSelection` and the existing snapshot revision path. Set only selected options to `PurchaseState.purchased`, create one revision labeled `Conferma acquisti demo`, and preserve alternatives. Do not call `url_launcher` from this command.

- [ ] **Step 4: Run focused controller/model tests**

Run: `flutter test test/chat_first_prototype_controller_test.dart test/plan_models_test.dart -r expanded`

Expected: PASS, including existing purchase and revision tests.

## Task 4: Profilo distillato, disponibilità e statistiche

**Files:**
- Create: `lib/features/chat_first_prototype/profile_availability_sheet.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_profile_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- `ChatFirstProfileScreen` receives `List<AvailabilityEntry> availability`, `TravelStats stats`, `ValueChanged<AvailabilityEntry> onAddAvailability` and `ValueChanged<String> onRemoveAvailability` in addition to theme, memory and chat callbacks.
- `ProfileAvailabilitySheet.show(BuildContext, {required ValueChanged<AvailabilityEntry> onSubmit})` returns through the callback only after a valid local form.

- [ ] **Step 1: Add failing widget tests for the new profile contract**

```dart
testWidgets('profilo mostra statistiche e disponibilità senza griglia di card', (tester) async {
  await tester.pumpWidget(_profileApp(
    availability: const <AvailabilityEntry>[],
    stats: TravelStats(completedTrips: 3, visitedPlaces: 18, estimatedKilometers: 1240),
  ));
  expect(find.text('3 viaggi'), findsOneWidget);
  expect(find.text('18 luoghi'), findsOneWidget);
  expect(find.text('1.240 km'), findsOneWidget);
  expect(find.text('Disponibilità'), findsOneWidget);
  expect(find.text('Memoria appresa'), findsOneWidget);
});
```

Expected: FAIL because the profile still renders only theme, memory, privacy and chat.

- [ ] **Step 2: Replace repeated `_Card` containers with sections and action rows**

Keep one compact header, a horizontal stats row, emoji memory chips, and plain `ListTile` links for `Aspetto`, `Disponibilità`, `FAQ` and `Privacy`. The screen must remain scrollable at 320 dp and text scale 1.5.

- [ ] **Step 3: Add the availability sheet and wire it to the controller**

Use a date picker plus a segmented `Libero/Turno` choice, a time-range field and an optional note. Disable submit for missing date or time range. Add delete actions with semantic labels to existing entries.

- [ ] **Step 4: Run profile widget tests at compact sizes and themes**

Run: `flutter test test/chat_first_prototype_widget_test.dart --plain-name 'profilo' -r expanded`

Expected: PASS without overflow or `tester.takeException()` output.

## Task 5: Importazione ispirazioni mock e proposta nel Piano

**Files:**
- Create: `lib/features/chat_first_prototype/inspiration_import_sheet.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`
- Modify: `test/trip_snapshot_screen_test.dart`

**Interfaces:**
- `InspirationImportSheet` receives `List<String> demoUrls`, `InspirationImportResult Function(String) parse`, and `Future<void> Function(InspirationDraft) onSave`.
- `TripSnapshotScreen` adds an overflow action `Importa ispirazione` that opens the sheet for its conversation.
- The thread attachment sheet adds `Importa link Reel/TikTok` alongside photo/video demo.

- [ ] **Step 1: Add failing end-to-end widget tests**

```dart
testWidgets('importa un reel mock, associa il viaggio e mostra la proposta', (tester) async {
  final controller = _controllerFor(
    ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
  );
  addTearDown(controller.dispose);
  await _pumpPlan(tester, controller: controller);
  await tester.tap(find.text('Importa ispirazione'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Instagram demo'));
  await tester.pumpAndSettle();
  expect(find.text('Ispirazione salvata'), findsOneWidget);
  expect(find.text('Proponi integrazione'), findsOneWidget);
});
```

Expected: FAIL because neither entry point nor sheet exists. Reuse the existing `_controllerFor` and `_pumpPlan` helpers in `test/trip_snapshot_screen_test.dart`; do not create a second plan harness.

- [ ] **Step 2: Implement the sheet as a three-state flow**

State 1 accepts pasted URL or demo fixture. State 2 shows extracted title/place/moment and an explicit trip association. State 3 confirms the save and exposes `Proponi integrazione`; invalid links show an inline recovery message.

- [ ] **Step 3: Wire the proposal without silent plan mutation**

Saving creates a `SavedInspiration` and a chat context. `Proponi integrazione` calls `proposeInspiration`; accepting the resulting `PlanProposal` is the only path that adds a place or changes the plan. The origin and source are `share` in the existing plan metadata.

- [ ] **Step 4: Verify compact accessibility and back behaviour**

Run: `flutter test test/chat_first_prototype_widget_test.dart test/trip_snapshot_screen_test.dart --plain-name 'ispiraz' -r expanded`

Expected: PASS with the sheet closing before the underlying route and no overflow at 320 dp/text scale 1.5.

## Task 6: Mock cost confirmation and plan/chat polish

**Files:**
- Modify: `lib/features/chat_first_prototype/plan_cost_sheet.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Modify: `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`
- Modify: `test/trip_snapshot_screen_test.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- `PlanCostSheet` receives `bool mockPurchasesConfirmed` and `VoidCallback onConfirmMockPurchases`.
- The plan screen opens a confirmation dialog titled `Conferma acquisti demo` with the selected flight, hotel and total; positive action calls the controller command.
- The thread composer remains multiline with attachment, microphone and send controls; its compact update card exposes `Vedi il piano completo` as the only primary action.

- [ ] **Step 1: Add failing cost-confirmation tests**

```dart
testWidgets('costi conferma tutte le scelte solo dopo il riepilogo demo', (tester) async {
  final controller = _controllerFor(
    ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
  );
  addTearDown(controller.dispose);
  await _pumpPlan(tester, controller: controller);
  await tester.tap(find.text('Costi'));
  await tester.pumpAndSettle();
  expect(find.text('Conferma acquisti demo'), findsOneWidget);
  await tester.tap(find.text('Conferma acquisti demo'));
  await tester.pumpAndSettle();
  expect(find.text('Demo: nessun pagamento reale'), findsOneWidget);
  expect(controller.mockPurchasesConfirmed('c-plan-ui'), isTrue);
});
```

Expected: FAIL because the sheet currently exposes only external purchase actions.

- [ ] **Step 2: Implement the mock confirmation dialog and settled state**

Keep external provider buttons optional. The final CTA must show the selected rows, total and the no-payment disclaimer; cancel leaves every state untouched. After success, replace the CTA with `Scelte confermate` and a session-local status line.

- [ ] **Step 3: Refine the thread composer and concise update card**

Use the current floating navigation and neutral surfaces already present in the dirty worktree. Remove duplicate labels/actions rather than adding another toolbar. Ensure send/mic icon semantics stay unique and the update card has no paragraph wall.

- [ ] **Step 4: Replace any remaining blue home surface with semantic neutral roles**

Add a regression assertion for `surfaceContainerHighest`/theme-derived color instead of a raw blue fill and keep the existing `home ... superficie neutra` tests green.

- [ ] **Step 5: Run plan/chat tests**

Run: `flutter test test/trip_snapshot_screen_test.dart -r expanded` and `flutter test test/chat_first_prototype_widget_test.dart -r expanded`

Expected: PASS without overflow in the existing matrix tests.

## Task 7: Documentation alignment and final verification

**Files:**
- Modify: `PRODUCT.md`
- Modify: `DESIGN.md`
- Modify: `HANDOFF.md`
- Modify: `README.md`
- Modify: `tool/run_web.sh`
- Modify: `test/app_entry_test.dart`

- [ ] **Step 1: Remove obsolete flag instructions and old-app claims**

Replace all operational references to `ITER_CHAT_FIRST_PROTOTYPE` and `ITER_NEW_TRIP_LAB` with the new-only startup command. Document the mock confirmation and mock inspiration import, the profile availability/statistics surface, the three-destination shell and the no-real-payment boundary. Keep historical specs untouched where they are explicitly archival, but label them as history if they are linked from current docs.

- [ ] **Step 2: Make the web harness use the new-only command**

Remove both `ITER_CHAT_FIRST_PROTOTYPE` and `ITER_NEW_TRIP_LAB` defines from `tool/run_web.sh`. The normal command must build the app without selecting an alternative root or a second Lab path.

- [ ] **Step 3: Run formatting, static checks and the full suite**

Run:

```bash
dart format lib test
git diff --check
flutter analyze
flutter test
flutter build web --release
```

Expected: all commands exit 0; the full suite reports no failures.

- [ ] **Step 4: Perform Browser QA on the release build**

Build and serve the release artifact, then inspect Home → Viaggi → Nuova chat → Piano → luogo → indicazioni/reel → Costi → conferma demo, plus Tu → disponibilità → statistiche and importazione inspiration. Repeat at 320, 360 and 390 dp, light/dark, text scale 1.5 and reduced motion. Confirm there is no old shell, no duplicated bottom action and no page that depends on the debug DDC.

- [ ] **Step 5: Leave a handoff report in the final response**

Report changed files, exact verification output, any known caveat and the uncommitted branch state. Do not claim a release, merge or push.

## Post-audit closure — 14 agosto 2026

Questa sezione traccia il secondo passaggio richiesto dopo la verifica visuale.
Non sostituisce i gate precedenti e non autorizza commit o push automatici.

- [x] Aggiungere un luogo personalizzato dal picker mantenendo preview,
  conferma e IDs stabili.
- [x] Rimuovere il pulsante **Viaggi** duplicato dalla testata Home.
- [x] Rendere compatta la proposta chat e aggiungere il CTA al Piano completo.
- [x] Mostrare le ispirazioni salvate nel Piano con stato esplicito.
- [x] Offrire immagini e reel della destinazione in un foglio progressivo dalla
  hero, senza spostare la timeline iniziale.
- [x] Disabilitare la conferma demo quando non esistono opzioni volo/hotel e
  correggere ogni copy che poteva far pensare a prezzi live.
- [x] Correggere la disclosure della demo nel percorso free talk.
- [x] Verificare con TDD mirato, `flutter analyze`, `flutter test`, build web
  release e `git diff --check`.
