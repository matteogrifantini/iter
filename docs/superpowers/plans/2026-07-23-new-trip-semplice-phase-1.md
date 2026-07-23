# Nuovo viaggio Semplice — Phase 1 Implementation Plan

> **Required sub-skill:** Use `superpowers:subagent-driven-development` to execute this plan task by task, with `superpowers:test-driven-development` for every behavior change and `superpowers:verification-before-completion` before handoff.

**Goal:** Make Semplice the only New Trip Lab experience, open it directly from the Lab-enabled Home, and strengthen the intake flow for responsive layout, visible guidance, honest progress, accessibility, and reduced motion.

**Architecture:** Keep `NewTripPrototypeController`, typed date intent, deterministic proposal source, and Lab isolation unchanged. Remove the presentation-only variant contract from Home through the question widgets. Keep the current product entry unchanged when the Lab flag is off. Move reusable Semplice option layout into a focused widget while the existing screen remains the owner of controller state.

**Tech Stack:** Flutter, Dart, Material 3, `flutter_test`, existing Iter theme extensions, existing `AppConfig` Lab gate.

## Global constraints

- Work in the current checkout because the Lab implementation and product documents are pre-existing uncommitted work. Preserve every unrelated change.
- The orchestrator is the Git owner. Do not stage, commit, push, merge, rebase, or reset without a new explicit user request.
- One writer per file. Serialize edits to shared files.
- Android is the product target; Web is the local visual QA harness only.
- Do not modify `NewTripPrototypeController`, proposal ranking, typed date semantics, `IterStore`, providers, persistence, booking, or payment behavior.
- The Lab-enabled Home opens Semplice directly. The Lab-disabled Home retains the current production path.
- Use current theme tokens and Material components. Do not add packages, raw color constants, decorative gradients, or structural emoji icons.
- Each implementation task follows RED → GREEN → REFACTOR. A failing test must fail for the intended reason before production code changes.

## Ownership map

| Owner | Files / area | Result | Dependencies | Verification | Git owner |
| --- | --- | --- | --- | --- | --- |
| `flutter_engineer` | `test/new_trip_lab_widget_test.dart`, `lib/app/iter_app.dart`, `lib/screens/home_screen.dart`, `lib/features/new_trip_lab/new_trip_lab_screen.dart`, `lib/features/new_trip_lab/new_trip_lab_shells.dart`, `lib/features/new_trip_lab/new_trip_lab_models.dart` | One direct Semplice entry and no presentation variant contract | Existing Lab flag and controller | Targeted widget tests, analyze | Orchestrator |
| `flutter_engineer` | `lib/features/new_trip_lab/new_trip_simple_option_grid.dart`, `lib/features/new_trip_lab/new_trip_lab_steps.dart`, targeted tests | Responsive one/two-column intake with visible qualifiers | Task 1 complete | Width/text-scale widget tests | Orchestrator |
| `flutter_engineer` | `lib/features/new_trip_lab/new_trip_lab_screen.dart`, `lib/features/new_trip_lab/new_trip_lab_shells.dart`, `lib/features/new_trip_lab/new_trip_lab_steps.dart`, targeted tests | Progress below options; accessible, reduced-motion state | Tasks 1–2 complete | Semantics, motion, theme tests | Orchestrator |
| `product_ux` | `HANDOFF.md`, `NEW_TRIP_MASTER_PLAN.md`, `PRODUCT.md`, `DESIGN.md`, `README.md` | Documentation reflects one Semplice Lab and Phase 1 boundary | UI contract stable after Tasks 1–3 | Reference search, diff check | Orchestrator |
| `quality_reviewer` | Read-only final diff and runtime | Independent correctness, regression, a11y, responsive, light/dark review | All writers finished | Full tests, analyze, Web build, Browser QA | None |

## Task 1: Replace the prototype gallery with one direct Semplice flow

**Files:**

- Modify: `test/new_trip_lab_widget_test.dart`
- Modify: `lib/app/iter_app.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_screen.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_shells.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_steps.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_models.dart`

### Step 1: Write the failing entry-contract tests

Replace the variant-based test helpers with a single helper:

```dart
Widget newTripLabApp({
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const NewTripLabScreen(),
    ),
  );
}
```

Add tests with these exact contracts:

```dart
testWidgets('Lab Home opens the single Semplice flow directly', (tester) async {
  // Pump Home with showNewTripLab: true and a callback that opens
  // NewTripLabScreen. Tap find.byKey(const Key('new-trip-lab')).
  // Expect one NewTrip question screen and no Focus/Rotta/Semplice gallery.
});

testWidgets('normal Home keeps the existing product entry', (tester) async {
  // Pump Home with showNewTripLab: false.
  // Expect find.byKey(const Key('new-trip')) and no `new-trip-lab` key.
});
```

Remove variant loops and rewrite all existing Lab widget tests to pump the one Semplice screen. Keep all assertions that protect typed dates, origin editing, results, shortlist, comparison, back behavior, and no persistence.

### Step 2: Run the entry tests and confirm RED

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'Lab Home opens the single Semplice flow directly'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'normal Home keeps the existing product entry'
```

Expected: the first test fails because Home still renders the three-variant launcher and the screen still requires a variant. The second remains a regression guard and may already pass.

### Step 3: Remove the presentation variant contract

Make these interface changes:

```dart
// home_screen.dart
final VoidCallback? onNewTripLab;

// new_trip_lab_screen.dart
const NewTripLabScreen({super.key});

// iter_app.dart
void _startNewTripLab() {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const NewTripLabScreen()),
  );
}
```

- Delete `_NewTripLabLauncher`; when `showNewTripLab` is true, render one filled `Inizia un viaggio` button keyed `new-trip-lab` and call `onNewTripLab`.
- When `showNewTripLab` is false, leave the current `new-trip` product CTA and callback unchanged.
- Delete `NewTripPrototypeVariant`, `PrototypeOptionLayout`, `optionLayoutFor`, and the Focus/Rotta shell branches.
- Rename the surviving private shell to `_SimpleShell` only if it is not already named that way; `NewTripQuestionShell` should directly return it without a switch.
- Remove variant/layout parameters from `NewTripQuestionShell`, `_QuestionAppBar`, `_AnimatedStep`, `NewTripStepContent`, and every private step widget.
- Do not change controller construction, source injection, date values, or result behavior.

### Step 4: Run the focused suite and confirm GREEN

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_controller_test.dart
```

Expected: both files pass; there is one question-shell experience and the controller suite is unchanged.

### Step 5: Refactor and inspect the removed API

Run:

```bash
rg -n 'NewTripPrototypeVariant|PrototypeOptionLayout|optionLayoutFor|Focus|Rotta' lib test
/opt/homebrew/share/flutter/bin/dart format lib/app/iter_app.dart lib/screens/home_screen.dart lib/features/new_trip_lab test/new_trip_lab_widget_test.dart
```

Expected: no presentation-variant symbols remain in `lib` or `test`; formatting succeeds. User-facing destination content may still contain ordinary words unrelated to the deleted variant names—inspect any hit before editing.

Suggested commit if later authorized: `refactor(new-trip): promote Semplice flow`

## Task 2: Make option layout responsive and qualifiers visible

**Files:**

- Create: `lib/features/new_trip_lab/new_trip_simple_option_grid.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_steps.dart`
- Modify: `test/new_trip_lab_widget_test.dart`

### Step 1: Write failing responsive and content tests

Add one parameterized group covering the actual device width and large-text rules:

```dart
for (final scenario in <({Size size, double scale, int columns})>[
  (size: const Size(360, 800), scale: 1, columns: 1),
  (size: const Size(390, 844), scale: 1, columns: 2),
  (size: const Size(320, 720), scale: 1.5, columns: 1),
]) {
  testWidgets(
    'option grid uses ${scenario.columns} column(s) at '
    '${scenario.size.width}dp and ${scenario.scale}x text',
    (tester) async {
      // Pump the Lab at the requested MediaQuery, advance to a stable
      // illustrated-option step, and compare option left/top coordinates.
      // Assert no Flutter overflow exception.
    },
  );
}
```

Add a content test that reaches the date or budget question and asserts that its non-empty option qualifier is visible with `find.text(...)`, rather than present only in semantics.

### Step 2: Run the tests and confirm RED

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'option grid uses 1 column(s) at 360.0dp and 1.0x text'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'option qualifiers are visible'
```

Expected: the 360 dp test fails because the current breakpoint is based on 300 dp content width, and the qualifier test fails because subtitles are semantics-only.

### Step 3: Add the focused grid widget

Create `NewTripSimpleOptionGrid` with this public contract:

```dart
class NewTripSimpleOptionGrid extends StatelessWidget {
  const NewTripSimpleOptionGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  static bool usesSingleColumn(BuildContext context) {
    final media = MediaQuery.of(context);
    final scaledBody = media.textScaler.scale(16);
    return media.size.width <= 360 || scaledBody > 20;
  }
}
```

Implementation rules:

- Use `LayoutBuilder` only to calculate available child width.
- At or below 360 dp device width, render one column.
- Above 360 dp and at normal text size, render exactly two equal columns with a 10 dp gap.
- When scaled 16 sp body text exceeds 20 logical pixels, render one column.
- Preserve source order and minimum 48 dp targets.
- Do not infer device width from the post-padding constraint.

Use the widget from the existing option picker. Simplify the surviving Semplice option visual so every non-empty `subtitle` is rendered below the label using `bodySmall`, `onSurfaceVariant`, at most two lines, and no fixed text height. Keep emoji expressive content and keep the text label authoritative.

### Step 4: Run responsive tests and confirm GREEN

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'option grid uses'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'option qualifiers are visible'
```

Expected: 360/1.0 and 320/1.5 use one column, 390/1.0 uses two columns, qualifiers are visible, and no overflow exception is reported.

### Step 5: Refactor and format

Keep responsive policy in `NewTripSimpleOptionGrid`; do not duplicate the breakpoint in step widgets or tests. Prefer coordinate assertions over implementation-type assertions so tests protect behavior.

Run:

```bash
/opt/homebrew/share/flutter/bin/dart format lib/features/new_trip_lab/new_trip_simple_option_grid.dart lib/features/new_trip_lab/new_trip_lab_steps.dart test/new_trip_lab_widget_test.dart
/opt/homebrew/share/flutter/bin/flutter analyze
```

Expected: format and analyze succeed with no issues.

Suggested commit if later authorized: `feat(new-trip): refine responsive choices`

## Task 3: Put honest progress next to the decision

**Files:**

- Modify: `lib/features/new_trip_lab/new_trip_lab_shells.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_steps.dart`
- Modify: `test/new_trip_lab_widget_test.dart`

### Step 1: Write failing placement and semantics tests

Add:

```dart
testWidgets('progress follows the options inside scrollable content',
    (tester) async {
  // Pump a question with options.
  // Assert option top < progress top < contextual-action top.
  // Assert the progress is a descendant of the body scroll view and not a
  // descendant of the bottom navigation container.
});

testWidgets('progress announces current question and remaining effort',
    (tester) async {
  // Enable semantics, pump the first question, and expect a label containing
  // the current question name, `1 di N`, and `N-1 domande ancora`.
  // Advance to the last question and expect `Ultima domanda`.
});
```

### Step 2: Run and confirm RED

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'progress follows the options inside scrollable content'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'progress announces current question and remaining effort'
```

Expected: placement fails because progress is in `bottomNavigationBar`; remaining-effort semantics fail because only index, total, and label are exposed.

### Step 3: Move and enrich progress

- Move the keyed progress widget from `bottomNavigationBar` into the shell's `SingleChildScrollView`, immediately after `_AnimatedStep`.
- Leave only `NewTripContextualAction` in the bottom navigation area.
- Keep sufficient bottom padding so the progress and last option can scroll clear of the contextual action.
- Use these exact user-facing rules derived only from controller state:

```dart
final remaining = total - currentIndex - 1;
final remainingLabel = remaining == 0
    ? 'Ultima domanda'
    : remaining == 1
        ? '1 domanda ancora'
        : '$remaining domande ancora';
```

- Render `remainingLabel` visibly beside or directly below `currentLabel` and `N di total`.
- Set the merged progress semantics value to `N di total, currentLabel, remainingLabel`.
- Do not invent time estimates or completion promises.

### Step 4: Run and confirm GREEN

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'progress follows the options inside scrollable content'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart --plain-name 'progress announces current question and remaining effort'
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart
```

Expected: focused tests and the complete widget file pass.

### Step 5: Refactor

Keep progress copy in one helper or getter and use `AnimatedSize`/`AnimatedSwitcher` only if existing motion preferences are honored. Do not add a second progress source or change controller step counts.

Suggested commit if later authorized: `feat(new-trip): clarify intake progress`

## Task 4: Harden semantics, dark theme, and reduced motion

**Files:**

- Modify: `lib/features/new_trip_lab/new_trip_lab_screen.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_shells.dart`
- Modify: `lib/features/new_trip_lab/new_trip_lab_steps.dart`
- Modify: `test/new_trip_lab_widget_test.dart`

### Step 1: Write failing accessibility and motion tests

Add tests for these contracts:

```dart
testWidgets('option semantics expose one button label without emoji noise',
    (tester) async {
  // Enable semantics and inspect one option.
  // Expect button, enabled and selected state, plus label/subtitle exactly once.
});

testWidgets('origin changes immediately when animations are disabled',
    (tester) async {
  // Pump with MediaQuery.disableAnimations true, update origin, pump once,
  // and expect the new origin without a timed settle.
});

testWidgets('Semplice intake renders in dark theme at large text',
    (tester) async {
  // Pump dark theme at 320x720 and 1.5x, interact with an option, and assert
  // no overflow or exception.
});
```

### Step 2: Run and confirm RED

Run each test by its exact `--plain-name`. Expected: at least the origin motion test fails because its `AnimatedSwitcher` uses a non-zero duration even when animations are disabled; semantics may expose duplicated emoji/text depending on the current tree.

### Step 3: Implement the smallest fixes

- Derive `reduceMotion` from `MediaQuery.disableAnimationsOf(context)` for both step and origin transitions.
- Use `Duration.zero` for the origin switch when motion is disabled; keep existing calm duration otherwise.
- Wrap expressive emoji glyphs in `ExcludeSemantics`; keep the enclosing option `Semantics` as the single source of label, value/state, button, and enabled state.
- Use theme-derived colors and text roles already present; do not introduce raw black/white fallbacks in intake components.
- Ensure every selectable option has at least a 48 dp interactive dimension in both one- and two-column layouts.

### Step 4: Run and confirm GREEN

Run:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart
/opt/homebrew/share/flutter/bin/flutter analyze
```

Expected: all New Trip widget tests pass and analyze reports no issues.

### Step 5: Manual source review

Run:

```bash
rg -n 'AnimatedSwitcher|AnimatedSize|Colors\.(black|white)|Semantics|ExcludeSemantics' lib/features/new_trip_lab
```

Inspect every hit. Intake motion must honor reduced motion, option semantics must not duplicate content, and no new raw black/white use may exist in the changed intake files. Raw colors in untouched results code are deferred to the results/compare batch and must be reported, not silently expanded into this batch.

Suggested commit if later authorized: `fix(new-trip): harden intake accessibility`

## Task 5: Synchronize product documentation

**Files:**

- Modify: `HANDOFF.md`
- Modify: `NEW_TRIP_MASTER_PLAN.md`
- Modify: `PRODUCT.md`
- Modify: `DESIGN.md`
- Modify: `README.md`

### Step 1: Establish the documentation assertions

Search before editing:

```bash
rg -n 'Focus|Rotta|Semplice|varianti|prototype|prototipo|gallery|galleria' HANDOFF.md NEW_TRIP_MASTER_PLAN.md PRODUCT.md DESIGN.md README.md
```

Record each location that currently describes three selectable designs or the gallery. Do not remove historical context that is explicitly labeled completed research.

### Step 2: Update the live product contract

Document consistently:

- Semplice is the selected and only Lab presentation.
- The Lab-enabled Home opens it directly from `Inizia un viaggio`.
- The Lab-disabled product path remains unchanged until the real domain/store integration phase.
- Phase 1 changes presentation and intake only; controller, typed dates, deterministic proposals, no-persistence contract, and providers remain unchanged.
- 360 dp or less and large text use one column; wider normal-text layouts may use two.
- Progress appears after the options and states the current and remaining questions.
- Results/shortlist/comparison redesign and app-wide rollout are subsequent plans, not completed work.

Align phase status in the master plan and handoff. Do not claim live providers, persistence, Android release readiness, or Browser QA that has not occurred.

### Step 3: Verify references and formatting

Run:

```bash
rg -n 'Focus|Rotta|varianti|prototype|prototipo|gallery|galleria' HANDOFF.md NEW_TRIP_MASTER_PLAN.md PRODUCT.md DESIGN.md README.md
git diff --check
```

Expected: remaining variant mentions are historical and clearly labeled; no live instruction tells users to select among designs; diff check is clean.

Suggested commit if later authorized: `docs(new-trip): select Semplice direction`

## Task 6: Independent review and release-proportional verification

**Owner:** `quality_reviewer` is read-only. Findings return to the owning specialist; the reviewer does not patch reviewed source.

### Step 1: Review the scoped diff

Run:

```bash
git diff -- lib/app/iter_app.dart lib/screens/home_screen.dart lib/features/new_trip_lab test/new_trip_lab_widget_test.dart HANDOFF.md NEW_TRIP_MASTER_PLAN.md PRODUCT.md DESIGN.md README.md
git diff --check
```

Review against the approved specification, especially:

- direct Lab entry versus unchanged non-Lab entry;
- no controller/store/provider behavior drift;
- 360/390 dp and large-text behavior;
- progress placement and semantics;
- system back and origin editing;
- light/dark and reduced motion;
- preservation of unrelated dirty-tree changes.

### Step 2: Run automated gates

Run in order:

```bash
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_controller_test.dart
/opt/homebrew/share/flutter/bin/flutter test test/new_trip_lab_widget_test.dart
/opt/homebrew/share/flutter/bin/flutter test
/opt/homebrew/share/flutter/bin/flutter analyze
git diff --check
```

Expected: all tests pass, analyze reports no issues, and diff check is silent.

### Step 3: Run Web visual QA

Start the repository harness:

```bash
./tool/run_web.sh
```

In the integrated Browser at `http://127.0.0.1:7357`, verify:

1. Lab-enabled Home has one `Inizia un viaggio` CTA and no variant gallery.
2. 390 dp normal text uses two columns where appropriate.
3. 360 dp and 320 dp/large text use one column with no clipping.
4. Qualifiers are visible, not semantics-only.
5. Progress follows the choices and the fixed action does not cover content.
6. Origin can be changed and back returns predictably.
7. Light and dark themes remain legible.
8. Reduced motion removes timed step/origin transitions.

If the Browser integration is unavailable, record that limitation and perform only the reachable HTTP/runtime and automated checks; do not describe visual QA as passed.

Stop the harness cleanly, then run:

```bash
/opt/homebrew/share/flutter/bin/flutter build web --release
```

Expected: release Web build succeeds.

### Step 4: Run Android gate for navigation-sensitive changes

Because the batch changes the Home entry and New Trip back path, run:

```bash
/opt/homebrew/share/flutter/bin/flutter build apk --debug
```

Expected: debug APK builds successfully. Do not start an emulator unless a separate native QA request requires it.

### Step 5: Final scope audit

Run:

```bash
git status --short
git diff --stat
```

Report:

- files changed by this batch;
- commands and exact pass/fail outcomes;
- Browser QA evidence or explicit unavailability;
- pre-existing changes left untouched;
- deferred findings for results/compare and app-wide rollout;
- no staging, commit, or push performed.

No success claim is allowed until the reviewer has no unresolved P1/P2 finding and all reachable required gates above pass.
