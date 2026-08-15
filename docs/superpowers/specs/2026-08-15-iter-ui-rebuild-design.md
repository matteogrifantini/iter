# Iter UI Rebuild Design

> **Status:** approved for implementation from the user's “vai” on 15 agosto 2026.

**THESIS:** Iter is a calm route editor, not a dashboard. The first viewport must show the trip doing useful work immediately, and it refuses the previous composition of small text blocks floating in an empty canvas.

**OWN-WORLD:** Warm route canvas, ink typography, one decisive blue action color, destination photography, hairline dividers, and a compact translucent dock. Surfaces are few and purposeful; narrative content is linear, not a grid of cards.

**STORY:** The traveler sees where they are, what happens next, and how to change it. They can ask Iter from the same surface without losing the plan.

**FIRST VIEWPORT:** A centered content frame opens with a quiet status bar, a wide destination scene when a trip exists, today's route underneath, and one generous composer. The three-tab dock is a small floating island centered below the content.

**FORM:** Native mobile editor with a photographic stage, ordered timeline, and floating controls. The form uses progressive disclosure for rare actions and preserves familiar Material semantics for touch, focus, sheets, and dialogs.

## Goal

Replace the previous conservative chrome polish with a visible, coherent redesign of the active Iter shell while preserving the existing mock data, controller seams, and user-confirmed flows.

## Scope

- `Oggi`: active-trip, planning, and empty states receive a new hierarchy.
- Shell: content is capped on wide windows and the bottom navigation becomes a compact floating island instead of a full-width bar.
- Composer: the Home composer becomes the primary object of the empty state and a floating edit surface for an active trip.
- `Viaggi`, thread, Piano, and `Tu`: reuse the same frame, spacing, surface, and divider language without changing routes or controller behavior.
- Documentation and tests record the visual contract and verify the most important stable surfaces.

## Non-goals

- No real AI, payments, maps, social scraping, or provider integration.
- No new navigation architecture and no reintroduction of `IterStore` or the removed legacy app.
- No deletion of compatibility parsing in `plan_models.dart` while current fixtures and tests consume it.

## Visual contract

### Layout

- Content frame: `maxWidth 760` on wide windows, full width with `16–24 dp` side padding on phones.
- Page rhythm: `20–28 dp` outer inset, `12–16 dp` tight groups, `32–48 dp` between sections.
- Hero stage: `minHeight 236 dp`, radius `28 dp`, destination image as the first visual anchor for active trips.
- Floating dock: width `min(360 dp, viewport - 32 dp)`, height `64 dp`, centered, safe-area aware.
- Narrative lists use dividers and a route line. Cards are reserved for content that can be opened or acted on.

### Material and type

- Canvas remains `#F9F7EF` in light mode and `#0B1028` in dark mode.
- Ink and display font remain Iter's Bricolage Grotesque/Figtree pair.
- Floating chrome uses a translucent surface with blur where supported, a hairline border, and a short soft shadow; it must remain legible in reduced-transparency environments.
- Accent blue marks action and selection only. Signal red and possibility lime remain semantic states, not decoration.
- Large titles use tight tracking and short leading; body copy remains generous and scrollable.

### Behavior

- Pressed feedback is immediate; state transitions use `150–250 ms` motion.
- Dock and section transitions are reduced to an immediate state or crossfade when `disableAnimations` is active.
- Composer, hero, timeline, and dock remain usable at 320/360/390 dp and text scale 1.5.
- The plan remains editable without opening Chat. Existing preview → confirm → revision behavior is unchanged.

## File boundaries

- `lib/app/iter_theme.dart`: semantic tokens, typography, shape and material defaults.
- `lib/features/chat_first_prototype/iter_ui_primitives.dart`: centered page frame, material surface and section primitives.
- `lib/features/chat_first_prototype/chat_first_shell.dart`: frame and compact dock only.
- `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`: Home composition and active-trip visual stage.
- Existing thread, plan, list, profile, and data files: adopt primitives without changing controller contracts.

## Acceptance

The redesign is accepted only when:

1. A clean release build on a new local origin visibly differs from the previous full-width dock / sparse canvas composition.
2. Home shows a destination stage for an active trip, a readable route, and a large composer without the old blue block.
3. Chat, Piano, Viaggi, and Tu share the same frame and floating material language.
4. `flutter analyze`, `flutter test`, `flutter build web --release`, and `git diff --check` pass.
5. Browser QA covers Home → Chat → Piano → Tu at the required narrow widths and light/dark/reduced-motion states.
