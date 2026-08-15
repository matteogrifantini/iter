# Iter UI Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the previous sparse, full-width shell composition with a visibly different Apple-inspired Iter UI while preserving the existing mock flows and controller contracts.

**Architecture:** Add a small set of shared Flutter primitives for the centered page frame, translucent floating material, section headings, and route dividers. Apply those primitives first to the shell and adaptive Home, then reuse them in Chat, Piano, Viaggi, and Tu without moving state or navigation into the primitives.

**Tech Stack:** Flutter Material 3, existing Iter theme extensions, local travel image assets, widget tests, release web build, integrated Browser.

## Global Constraints

- Keep the new-only entrypoint: `main.dart` → `buildIterApp()` → `ChatFirstPrototypeApp`.
- Keep mock data deterministic and isolated from `IterStore` and real providers.
- Do not add dependencies, real payment/map/social integrations, or a second navigation architecture.
- Preserve accessible 48 dp targets, readable text at 1.5 scale, light/dark themes, and reduced motion.
- Use `#F9F7EF` / `#0B1028` canvas roles, Bricolage Grotesque/Figtree, and blue only for actions and selection.
- Verify every UI slice with a focused widget test before the full suite.

---

### Task 1: Shared visual primitives

**Files:**
- Create: `lib/features/chat_first_prototype/iter_ui_primitives.dart`
- Modify: `lib/app/iter_theme.dart`
- Test: `test/iter_ui_primitives_test.dart`

**Interfaces:**
- `IterPageFrame({required Widget child, EdgeInsets padding, double maxWidth})` centers content on wide windows and remains full-width on phones.
- `IterMaterialSurface({required Widget child, EdgeInsets padding, BorderRadius borderRadius, bool translucent})` supplies one controlled floating material with an opaque fallback.
- `IterSectionHeading({required String title, String? eyebrow, Widget? trailing})` renders one consistent heading hierarchy.
- `IterRouteDivider({required bool active})` renders the vertical route line and its stop marker without owning stop data.

- [x] Add failing widget tests for max width, surface semantics, heading text, and route divider state.
- [x] Run `flutter test test/iter_ui_primitives_test.dart` and confirm the new API is absent or failing.
- [x] Implement the primitives with Material 3, safe-area-safe spacing, and no hardcoded raw colors outside theme roles.
- [x] Keep the existing semantic theme tokens and use the primitive-level shape/elevation defaults without changing controller behavior.
- [x] Run focused formatting and the primitive test.

### Task 2: Shell and Home rebuild

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_home_screen.dart`
- Modify: `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`
- Test: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- `ChatFirstShell` continues to expose the same controller, theme, and navigation callbacks.
- `AdaptivePlanningSection` and `ActiveTimelineSection` keep their current constructor signatures and callbacks.

- [x] Add widget assertions that Home exposes the destination stage, route timeline, large composer, and compact dock keys.
- [x] Run the focused Home tests and capture the current failure before changing the composition.
- [x] Build the active Home around one destination stage using the existing destination image mapping; keep the route and update CTA linear below it.
- [x] Rebuild the empty/planning Home states with one primary composer and inline signals instead of a repeated card stack.
- [x] Wrap shell content in `IterPageFrame` and change the bottom navigation to a centered `min(360 dp, viewport - 32 dp)` island.
- [x] Add pressed/reduced-motion behavior without delayed input or decorative entrance choreography.
- [x] Run focused widget tests at 320, 390, and wide logical pixels.

### Task 3: Chat and list surfaces

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_list_screen.dart`
- Test: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- Preserve `ChatFirstThreadScreen` navigation and `ChatFirstPrototypeController` actions.
- Preserve the list's new-chat affordance and unread semantics.

- [x] Add focused tests for the thread composer island and list new-chat state.
- [x] Run the focused tests to record the baseline.
- [x] Apply `IterPageFrame` and the shared material surface to the thread content/composer without changing send behavior.
- [x] Keep actionable proposal/media content distinct while ordinary messages remain in the linear conversation.
- [x] Apply the same frame, section heading, and compact new-chat control to Viaggi.
- [x] Run focused tests and format.

### Task 4: Piano and Profilo surfaces

**Files:**
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_profile_screen.dart`
- Test: `test/trip_snapshot_screen_test.dart`
- Test: `test/chat_first_prototype_widget_test.dart`

**Interfaces:**
- Preserve all plan callbacks, preview → confirm flow, external navigation, cost dialog, availability sheet, and profile callbacks.

- [x] Add assertions for plan hero/action island and profile linear links.
- [x] Run focused plan/profile tests.
- [x] Apply shared frame and route timeline rhythm to the plan while keeping the hero and all existing actions.
- [x] Make plan actions a compact floating control group reserved below the timeline viewport.
- [x] Replace remaining profile card stacking with a linear header/stat strip/settings list using shared dividers.
- [x] Run focused tests, format, and check narrow text scale behavior.

### Task 5: Verification and handoff

**Files:**
- Modify: `DESIGN.md`
- Modify: `PRODUCT.md`
- Modify: `HANDOFF.md`
- Modify: `docs/superpowers/specs/2026-08-15-iter-ui-rebuild-design.md`

- [x] Run `git diff --check`.
- [x] Run `flutter analyze`.
- [x] Run the focused prototype/primitives suites; full repository test remains the final gate.
- [x] Run `flutter build web --release` and serve `build/web` on a new local port.
- [x] Inspect Home → Chat → Piano → Viaggi → Tu in the integrated Browser; narrow, dark, text scale 1.5, and reduced motion are covered by widget tests.
- [x] Run the full repository `flutter test`: 243 tests passed.
- [x] Update handoff with actual verification and any remaining known limitations.
- [x] Review the final diff before deciding whether to commit or push; leave the
  branch uncommitted until the user explicitly requests publication.
