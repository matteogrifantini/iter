# Rotta viva Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the catalog-like chat-first Home with the approved Rotta viva adaptive AI Home, while keeping the prototype isolated and every material change confirmable.

**Architecture:** The controller exposes a small immutable `AdaptiveHomeModel` resolved from the existing threads and snapshots. The Home renders one of three focused states (`empty`, `planning`, `active`) and owns only presentation/composer input; opening or creating a thread remains in `ChatFirstShell`, while the deterministic free-talk script collects clues before any destination appears.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Material 3, bundled OFL fonts, existing `ChatFirstPrototypeController` and deterministic mock data, Flutter widget/unit tests.

## Global Constraints

- Android remains the product target; Web is only the visual QA harness.
- Keep the chat-first prototype isolated from `IterStore` and live providers.
- Do not add runtime packages or remote font loading.
- Never show destination cards or city suggestions in the empty Home.
- A semantic seed enriches the composer; it never chooses a city or creates a conversation on tap.
- No save, booking, payment, plan mutation, or proactive change without explicit confirmation.
- Use Bricolage Grotesque for wordmark/display/headlines and Figtree for body, controls, chat, and itinerary.
- Light palette: Ink `#18204B`, Rotta `#2D63FF`, Segnale `#FF5C42`, Possibilita `#E7FF67`, Canvas `#F9F7EF`.
- Dark palette: Canvas `#0B1028`, Surface `#141C3B`, Rotta `#7EA0FF`, Segnale `#FF7A63`, Possibilita `#E7FF67`, text `#F9F7EF`.
- Use rounded Material icons; the route mark is the only proprietary glyph. Emoji are labeled semantic intent seeds, not decoration.
- Support 320 dp width, text scale 1.5, light/dark themes, semantic traversal, 48 dp touch targets, and reduced motion.
- Preserve the user's pre-existing `HANDOFF.md` change and do not stage it.

---

### Task 1: Canonical product and design contract

**Owner:** `product_ux`. Git owner remains `/root`.

**Files:**
- Modify: `PRODUCT.md`
- Modify: `DESIGN.md`

**Interfaces:**
- Consumes: the approved design specification and current product constraints.
- Produces: canonical written contract for later implementation tasks.

- [ ] **Step 1: Align product documentation**

Update `PRODUCT.md` so the canonical Home is adaptive and AI-led, not a city catalog. Record the three states, semantic seed behavior, explicit-confirmation rule, and navigation labels `Oggi`, `Viaggi`, `Tu`. Do not edit `HANDOFF.md`.

- [ ] **Step 2: Align design documentation**

Update `DESIGN.md` with the Rotta viva identity, type families, exact light/dark palettes, proprietary route mark, rounded Material icons, labeled emoji seeds, responsive/accessibility rules, and reduced-motion behavior.

- [ ] **Step 3: Verify and commit**

Run:

```bash
git diff --check -- PRODUCT.md DESIGN.md
```

Commit only `PRODUCT.md` and `DESIGN.md` with `docs(product): align adaptive Rotta viva home`.

---

### Task 2: Adaptive Home state model

**Owner:** `flutter_engineer`. Git owner remains `/root`.

**Files:**
- Create: `lib/features/chat_first_prototype/adaptive_home_model.dart`
- Test: `test/adaptive_home_model_test.dart`

**Interfaces:**
- Consumes: `List<ChatThread>` and existing `Conversation.snapshot` / `TripSnapshot.statusLabel`.
- Produces:

```dart
enum AdaptiveHomeKind { empty, planning, active }

@immutable
class AdaptiveHomeModel {
  const AdaptiveHomeModel.empty();
  const AdaptiveHomeModel.planning({required ChatThread thread});
  const AdaptiveHomeModel.active({required ChatThread thread});

  final AdaptiveHomeKind kind;
  final ChatThread? thread;
}

AdaptiveHomeModel resolveAdaptiveHome(List<ChatThread> threads);
```

Resolution rules, in order: first thread whose snapshot has `statusLabel == 'In viaggio'`; otherwise the most recent thread whose snapshot has `statusLabel == 'In pianificazione'`; otherwise `empty`. A seed-only free-talk thread has no snapshot and therefore remains `empty`.

- [ ] **Step 1: Write failing resolver tests**

Create literal fixtures and tests named:

```dart
test('returns empty when no thread has a trip snapshot', () { ... });
test('prefers an active trip over a planning trip', () { ... });
test('returns the newest planning trip when none is active', () { ... });
```

The production mutation caught is a wrong priority or treating free talk as a planned trip.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/adaptive_home_model_test.dart`

Expected: FAIL because `adaptive_home_model.dart` and `resolveAdaptiveHome` do not exist.

- [ ] **Step 3: Implement the minimal resolver**

Keep the model immutable and pure. Sort neither the source list nor controller state; choose by `Conversation.timestamp` without mutating input.

- [ ] **Step 4: Verify GREEN and commit**

Run:

```bash
flutter test test/adaptive_home_model_test.dart
flutter analyze
git diff --check
```

Commit only the two owned paths with `feat(home): add adaptive state model`.

---

### Task 3: Rotta viva theme and bundled typography

**Owner:** `flutter_engineer`. Git owner remains `/root`.

**Files:**
- Create: `assets/fonts/bricolage-grotesque/BricolageGrotesque-Variable.ttf`
- Create: `assets/fonts/bricolage-grotesque/OFL.txt`
- Create: `assets/fonts/figtree/Figtree-Variable.ttf`
- Create: `assets/fonts/figtree/OFL.txt`
- Modify: `pubspec.yaml`
- Modify: `lib/app/iter_theme.dart`
- Create: `test/iter_theme_test.dart`

**Interfaces:**
- Consumes: `IterTheme.light()`, `IterTheme.dark()`, `BuildContext.iterColors`.
- Produces: `IterPalette` exact colors; `IterColorRoles.possibility`; theme font family `Figtree`; headline overrides with `fontFamily: 'BricolageGrotesque'`.

- [ ] **Step 1: Add failing theme contract tests**

Assert observable theme output, not source constants:

```dart
expect(IterTheme.light().scaffoldBackgroundColor, const Color(0xFFF9F7EF));
expect(IterTheme.light().colorScheme.primary, const Color(0xFF2D63FF));
expect(IterTheme.dark().scaffoldBackgroundColor, const Color(0xFF0B1028));
expect(IterTheme.dark().colorScheme.surface, const Color(0xFF141C3B));
expect(IterTheme.light().textTheme.bodyMedium?.fontFamily, 'Figtree');
expect(IterTheme.light().textTheme.headlineLarge?.fontFamily, 'BricolageGrotesque');
expect(IterTheme.light().extension<IterColorRoles>()?.possibility,
    const Color(0xFFE7FF67));
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/iter_theme_test.dart`

Expected: FAIL on the old iOS-neutral palette, null `possibility`, and default fonts.

- [ ] **Step 3: Bundle the official font assets and licenses**

Download the variable TTF and matching `OFL.txt` for Figtree and Bricolage Grotesque from the official `google/fonts` repository. Keep original binaries unmodified. Register both families under `flutter/fonts`; do not add `google_fonts` or a network dependency.

- [ ] **Step 4: Implement the exact semantic theme**

Update `IterPalette`, `ColorScheme`, `IterColorRoles` constructor/copy/lerp, component radii, focus/outline contrast, and typography. Figtree is the base `fontFamily`; Bricolage applies only to `display*`, `headline*`, `titleLarge`, and the explicit wordmark style. Keep error/success colors accessible and do not use coral for body text.

- [ ] **Step 5: Verify GREEN and commit**

Run:

```bash
flutter pub get
flutter test test/iter_theme_test.dart test/chat_first_prototype_widget_test.dart
flutter analyze
git diff --check
```

Commit only owned assets/config/theme/test paths with `feat(theme): apply Rotta viva identity`.

---

### Task 4: AI-first intake before destinations

**Owner:** `flutter_engineer`. Git owner remains `/root`.

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_data.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `test/chat_first_prototype_controller_test.dart`

**Interfaces:**
- Consumes: existing `startFreeTalk()`, `sendText(String)`, `sendAudio()`, `sendMedia(...)`, `ChatThread` scripting.
- Produces: the same public controller API; a deterministic free-talk sequence with stable message IDs:

```text
free-talk-ack          understood clues, no city/destination
free-talk-missing      one missing constraint question
free-talk-summary      recap plus explicit confirmation choices
free-talk-proposal     destination-bearing plan proposal, only after confirmation
```

- [ ] **Step 1: Replace old free-talk assertions with failing behavior tests**

Add tests proving:

```dart
test('free talk reflects clues before naming any destination', () { ... });
test('free talk asks one missing constraint at a time', () { ... });
test('free talk names a destination only after summary confirmation', () { ... });
test('free talk keeps typed input when persistence fails', () async { ... });
```

Use literal forbidden destination labels from `trendJourneys` and assert none occur in assistant messages before the confirmation choice. For failure, use a small `IterDataSource` fake that throws during persistence while the in-memory traveler message remains present.

- [ ] **Step 2: Verify RED**

Run targeted test names with:

```bash
flutter test test/chat_first_prototype_controller_test.dart --plain-name "free talk"
```

Expected: at least the destination-timing test fails against the current early proposal sequence.

- [ ] **Step 3: Implement the minimal deterministic sequence**

Keep `startFreeTalk()` idempotent. First input emits an acknowledgment constructed from the traveler text without inventing a city. Subsequent beats request one missing constraint, then emit a compact summary with `Conferma` and `Correggi`. Only `Conferma` unlocks the destination-bearing proposal. `Correggi` keeps the same thread and asks what to change. Do not silently create a saved plan.

- [ ] **Step 4: Verify GREEN and commit**

Run:

```bash
flutter test test/chat_first_prototype_controller_test.dart
flutter analyze
git diff --check
```

Commit only the controller/data/test paths with `feat(chat): collect clues before destinations`.

---

### Task 5: Adaptive Rotta viva Home and shell

**Owner:** `flutter_engineer`. Git owner remains `/root`.

**Files:**
- Create: `lib/features/chat_first_prototype/rotta_viva_mark.dart`
- Create: `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`
- Replace: `lib/features/chat_first_prototype/chat_first_home_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- Consumes: `AdaptiveHomeModel`, controller `threads`, `startFreeTalk()`, `openConversation()`, and existing snapshot models.
- Produces:

```dart
class ChatFirstHomeScreen extends StatefulWidget {
  const ChatFirstHomeScreen({
    super.key,
    required this.model,
    required this.unread,
    required this.onSubmitIntent,
    required this.onVoiceIntent,
    required this.onPhotoIntent,
    required this.onOpenThread,
    required this.onOpenTrips,
  });

  final AdaptiveHomeModel model;
  final int unread;
  final ValueChanged<String> onSubmitIntent;
  final VoidCallback onVoiceIntent;
  final ValueChanged<String> onPhotoIntent;
  final ValueChanged<ChatThread> onOpenThread;
  final VoidCallback onOpenTrips;
}
```

`ChatFirstShell` resolves the model on every controller notification. Text submit calls `startFreeTalk()`, opens that thread, then sends the text only after navigation is bound to its stable ID. Voice starts the same thread and calls `sendAudio()`. Photo selection returns one existing demo asset path, starts the same thread, and calls `sendMedia(asset: path, isVideo: false)`. Bottom labels become `Oggi`, `Viaggi`, `Tu` while keeping the existing three routes.

- [ ] **Step 1: Write failing empty-state widget tests**

At 390x844 assert the Home exposes the `Iter` wordmark/route mark, manifesto `Dimmi che viaggio hai in mente`, one composer, photo/voice actions, and labeled seeds. Assert no `Roma`, `Porto`, `Ispirazioni per te`, horizontal journey list, or destination card. Tap a seed and verify the composer changes while no submit callback fires; submit and verify the exact enriched text fires once.

- [ ] **Step 2: Verify empty-state RED**

Run:

```bash
flutter test test/chat_first_prototype_widget_test.dart --plain-name "home vuota"
```

Expected: FAIL because the current Home requires journeys and renders catalog sections.

- [ ] **Step 3: Implement mark, composer, seeds, and empty state**

Build the proprietary mark from Flutter primitives (`CustomPainter` or positioned circles/line/arrow), wrapped in `Semantics(label: 'Iter, la rotta che prende forma')`. Use no bitmap logo. Seeds are `ActionChip`s with labels such as `🌊 Mare e pause`, `🚆 Partire in treno`, `🍝 Mangiare bene`; tapping appends/removes a clue in the editable composer. Empty submit is disabled. Input clears only after `onSubmitIntent` returns synchronously without throwing. The photo icon opens a labeled bottom sheet of existing demo images and passes the selected asset path to `onPhotoIntent`; cancellation has no side effect.

- [ ] **Step 4: Write failing planning and active-state tests**

Planning test: the next unresolved decision is the primary card, with one `Continua` action opening that thread; city appears only as context inside the existing plan, never as a suggestion.

Active test: render today's first snapshot day as a vertical timeline plus a coral confirmable update card; its action opens the thread and never mutates the snapshot directly.

At 320x640 with `TextScaler.linear(1.5)`, assert `tester.takeException()` is null. With `disableAnimations: true`, assert state changes settle without a timed slide/scale dependency. Check semantic labels for composer, voice, photo, seeds, timeline, and unread navigation badge.

- [ ] **Step 5: Verify planning/active RED**

Run all widget tests filtered by `home` and confirm failures name missing state-specific content.

- [ ] **Step 6: Implement planning, active, responsive, and shell wiring**

Use one vertical scroll surface, no horizontal content rails. Keep the manifesto/input visually dominant only in `empty`; `planning` promotes the next decision; `active` promotes today's timeline and the confirmable update. Use 24 dp side padding at 390 dp, clamp to 16 dp at 320 dp, 20/24/32 spacing rhythm, rounded Material icons, and only color-independent status cues. Respect `MediaQuery.disableAnimationsOf(context)`.

- [ ] **Step 7: Verify GREEN and commit**

Run:

```bash
flutter test test/chat_first_prototype_widget_test.dart
flutter test
flutter analyze
git diff --check
```

Commit only the Home/mark/section/shell/test paths with `feat(home): build adaptive Rotta viva experience`.

---

### Task 6: Integrated visual QA and documentation closure

**Owner:** `/root` for integration; `quality_reviewer` for independent review. The reviewer does not edit source.

**Files:**
- Modify only files required by concrete reviewer findings, routed back to their original owner.
- Do not modify or stage `HANDOFF.md`.

- [ ] **Step 1: Run complete automated gates**

```bash
flutter analyze
flutter test
flutter build web --release
```

- [ ] **Step 2: Run the local Web harness**

Start `./tool/run_web.sh`, then inspect `http://127.0.0.1:7357` only in the integrated browser. Verify 390x844 and 320x640, light/dark, text scale 1.5, reduced motion, tab semantics, composer keyboard behavior, seed behavior, and all three adaptive states using deterministic fixtures/test entry points already available in the prototype.

- [ ] **Step 3: Independent review**

Ask `quality_reviewer` to compare the diff and live UI against `docs/superpowers/specs/2026-08-09-rotta-viva-home-design.md`. Findings must include priority, exact path/line, reproduction, and expected correction. Route valid findings back to the owning specialist under TDD; rerun the affected targeted test first, then the full gates.

- [ ] **Step 4: Final Git audit**

Confirm branch/upstream/status, review every outgoing commit and diff, ensure `HANDOFF.md` remains unstaged, run `git diff --cached --check` if anything is staged, and stop before push unless the current request and Git gate authorize it.
