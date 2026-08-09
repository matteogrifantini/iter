# Iter Design System

## Scene

Someone is planning from a phone between everyday commitments: a free evening, a train ride, a pause at work. The interface must make a trip feel possible without asking them to become a travel agent.

## Platform Strategy

Iter ships as a Flutter app for Android. Its interaction model follows Material 3: navigation, top app bars, system back, tonal elevation and expanded layouts that graduate to a navigation rail on larger screens. The app respects safe areas, light/dark appearance, device text scale and reduced motion.

Do not recreate a website inside a phone. Brand is carried through content,
route context and the way a plan changes — not through bespoke navigation or
ornamental chrome.

## Visual Direction

The direction is **Rotta viva**: cartografia affettiva and orientation systems
for an AI-guided travel planner. The Home is a manifesto operativo — a human
question, a free input and a route made from understood signals — rather than a
photographic catalog or a permanent chat transcript. Its approved composition
is **Manifesto + input**: wordmark and a discreet conversation shortcut,
dominant question **Che viaggio ti farebbe bene adesso?**, promise
**Raccontami il momento. Alla destinazione penso io.**, one dark composer, up
to three quick signals, and a route line leading to subsequent content.

Rotta viva uses this controlled five-role palette. Tokens live in `ColorScheme`
and `IterColorRoles`; widgets do not own raw colors.

| Role | Light | Dark | Use |
| --- | --- | --- | --- |
| Ink | `#18204B` | `#F9F7EF` | primary text; decisive light/dark surfaces |
| Rotta | `#2D63FF` | `#7EA0FF` | primary action, active state, route line |
| Segnale | `#FF5C42` | `#FF7A63` | arrow, attention, decision awaiting confirmation |
| Possibilità | `#E7FF67` | `#E7FF67` | new signal, opportunity, positive progress |
| Canvas | `#F9F7EF` | `#0B1028` | mineral page background |

Dark also uses `#141C3B` for surface. Light contrast is fixed: Ink on Canvas
`14.53:1`, Rotta on Canvas `4.51:1`, white on Rotta `4.84:1`, Ink on Segnale
`5.09:1`, Ink on Possibilità `14.03:1`. Segnale never carries normal white
text; use Ink or treat it as a graphic signal. Color fills a meaningful field
or communicates state, never a scatter of decorative accents. No gradients,
glass panels, neon glows or oversized radii.

## Content Architecture

### Home

The adaptive Home has three product-led states, not a selectable visual mode.
With no trip, the manifesto and composer dominate; cities, affinity percentages
and destination carousels do not appear. With open planning, show exactly one
missing decision, three understood signals and **Continua il viaggio**; a new
trip is quiet. With an active trip, show the current day and a short timeline;
**Apri il piano di oggi** is primary and any operational alternative remains a
proposal. Priority is active trip today, pending planning, recent draft, then a
new trip; only one resumable item is visible.

The bottom navigation is Material and has three destinations: **Oggi** for
Home, **Viaggi** for the archive, and **Tu** for Profile. The route line is
wide enough to be recognizable but never obstructs text or touch targets. It
links actual signals and states: a first waypoint after send, an extended trace
for another signal, and an arrow for the complete proposal.

### Destination discovery

Use one prompt at a time and show honest progress through the eight shared
decisions. **Semplice** is the selected and only Lab presentation. In debug the
Lab defaults on through `kDebugMode`, so Home's **Inizia un viaggio** opens it
directly; `--dart-define=ITER_NEW_TRIP_LAB=false` explicitly disables it and
preserves the product's existing path. Release defaults the Lab off. Phase 1
changes presentation and intake only: the shared controller, typed dates,
deterministic mock proposal source and no-persistence/provider contract stay
unchanged. Single complete answers
advance after brief feedback; multiple choices, calendars and counters use only
contextual confirmation. Do not keep a permanent open-response composer and
never reveal candidate destinations before the editable summary.

Semplice uses a dominant title and less copy. Answer options combine emoji and
text in two columns only above 360 dp at normal text size; use one column at
360 dp or less and with large text. Anchor progress immediately after the
options and state both the current and remaining questions. Its neutral
background comes from Material `ColorScheme` roles — including
`secondaryContainer` — layered above the existing canvas; do not introduce
parallel palettes, raw colours, gradients or cream surfaces.

Phase 1 integrated Browser QA is complete for Home, direct Lab entry and manual
origin editing: two columns at 390 dp, one at 360 dp, progress after the
options, back navigation and light/dark themes. The complete Flutter suite has
49 tests; analyze, Web release and debug APK gates are complete.

The existing results are a vertical comparison surface rather than a portrait reel. A
proposal must keep date/period, duration, estimated all-in cost, breakdown,
travel complexity, fit and compromise visible together. Shortlist state stays
visible, enables comparison from two items and stops at four. The comparison
is grouped vertically by cost, dates, arrival, contents and trade-offs; the
destination is confirmed only after the person has enough information.

The redesign of results, shortlist and comparison, and the app-wide rollout of
the Semplice intake, are subsequent plans rather than Phase 1 work.

### Place curation

The current place owns a portrait video surface. Its name, neighbourhood and useful time stay visible; the personal-fit score remains supporting evidence. A horizontal swipe accelerates the choice while **Info**, **Passa**, **Salva** and **Must** remain 48 dp controls in a right-hand rail. Show progress as context, not as a test.

### Transport choice

Show flight, train, bus and car together. Each compact row uses the real company mark and keeps timing, duration, changes and indicative cost in the same order. Selection is explicit and reversible. Keep the trust line next to the commitment: values are demo estimates and no ticket is purchased.

### Stay choice

Treat a neighbourhood as a base, not a hotel result. The map is the primary surface: accepted places are pins and possible zones are translucent coloured areas. One compact summary shows atmosphere and walking time. **Scegli base** is the commitment, while external accommodation search remains secondary.

### Itinerary workspace

The day plan is a visual travel strip. A short video hero contains arrivals and base, then image-led stops follow a continuous timeline without a card around every item. Locked state is visible in the route marker. The compact conversation composer is anchored to the bottom and applies a visible, undoable patch; it is not a floating chat bot.

## Component Language

- Prefer native list rows, buttons, chips, bottom sheets and system dialogs over decorative containers.
- A card earns its place when it is a trip, destination, place or area the user can act on. Avoid nested cards and repeated icon-heading-copy grids.
- Use one button vocabulary across flows: filled for the next meaningful commitment, tonal/outlined for alternatives, text for low-risk actions.
- Status is written as useful language: “Bozza pronta da rivedere”, “Due tappe bloccate”, “Percorso stimato”. Never use a fake AI loader.
- Every action has default, disabled, loading, error and success feedback. Empty states teach the next action.
- Video is content, not decoration: bundled clips loop silently, have a pause action and fall back to a semantic route illustration when playback is unavailable.
- Corner radii stop at 14 dp for components, 16 dp for cards. Route progress, typography and media provide character; containers do not need to look like bubbles. Hairline separators, not shadows, define structure.
- The proprietary route glyph is only a continuous rounded stroke, waypoint and
  direction arrow. It marks start, progress and passage from signal to proposal;
  it never replaces familiar Android icons.
- Standard actions use Material rounded/outlined icons with an approximately
  `1.8 dp` visual stroke, a minimum `48 dp` target, and a label or tooltip.
  Icons do not sit in decorative tiles or change family by surface.
- Emoji are labeled semantic seeds, not decoration: `🌊 Voglio respirare`,
  `📅 Ho pochi giorni`, `💶 Ho 500 €`, `🐢 Voglio rallentare`. They remain out
  of semantics when adjacent text already says the meaning; never use them for
  bottom navigation, icon-only controls or title ornament.

## Typography

**Bricolage Grotesque** is the local variable-font asset for the lowercase
`iter` wordmark, display, headlines and decisive questions. **Figtree** is the
local variable-font asset for body, labels, controls, chat, results and
itineraries. Map both through `TextTheme`; do not load fonts remotely at
runtime. Bricolage never enters body copy or dense lists; Figtree remains the
operational fallback for large text and long Italian content. Display may use
strong weight, compact line-height and negative tracking only; labels, buttons
and copy use sentence case without decorative all-caps.

## Motion

Motion communicates a planning result:

- A chosen place settles into the collection.
- An accepted AI patch updates the relevant day and preserves the surrounding context.
- Navigation uses platform transitions; temporary tasks use native sheets.

Most transitions are 150–250 ms with a calm ease-out. The Rotta viva trace uses
`180–260 ms`, ease-out and one main transformation: waypoint after first send,
extension for a new signal, arrow for the proposal. Never loop, glow, fake
type, bounce an itinerary or hide content behind an AI loader. With
`disableAnimations` or reduced motion, the trace reaches its final state by
crossfade or immediate update.

## Appearance setting

Light is the default on first launch. The profile contains an explicit two-way **Chiaro / Scuro** control and stores the choice locally. All screen colors come from Material `ColorScheme` roles or the small `IterColorRoles` theme extension; no feature screen owns a parallel palette. Light and dark are both first-class.

## Accessibility Checklist

- Minimum `48×48 dp` targets, with at least `8 dp` spacing and labelled
  alternatives to gestures.
- Semantic order follows context, question, composer, signals, primary action,
  secondary content, then navigation. After an update, screen-reader focus
  moves to the new signal or next question.
- Required responsive gates are `320 dp`, `360 dp`, `390 dp`, the minimum
  compact Android width, and text scale `1.5`. At every gate, headline,
  composer and signals flow vertically; the route line never fixes their
  height. The keyboard never obscures the input, error or send action.
- Semantic labels for personal-fit scores, route changes, locked stops and outbound booking links.
- Text and state never rely on colour alone; maintain contrast in both themes.
- Screen-reader order follows the visible decision order.
- Spatial diagrams are supplemental; the textual day timeline remains complete.
- System Back closes a media sheet or keyboard before leaving the flow and
  preserves composed text. Light and dark themes are both first-class.
