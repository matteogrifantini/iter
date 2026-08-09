# Iter Design System

## Scene

Someone is planning from a phone between everyday commitments: a free evening, a train ride, a pause at work. The interface must make a trip feel possible without asking them to become a travel agent.

## Platform Strategy

Iter ships as a Flutter app for Android. Its interaction model follows Material 3: navigation, top app bars, system back, tonal elevation and expanded layouts that graduate to a navigation rail on larger screens. The app respects safe areas, light/dark appearance, device text scale and reduced motion.

Do not recreate a website inside a phone. Brand is carried through content, a restrained accent, map/route context and the way a plan changes — not through bespoke navigation or ornamental chrome.

## Visual Direction

The direction is **Neutro System Blue**: a quiet native travel planner that refuses the travel-brand rut of warm creams and editorial terracotta. The product is a tool on the phone, not a magazine inside it.

The default light theme uses iOS-style neutral grey surfaces: a grouped light background, white raised surfaces and hairline separators. Text uses two greys — near-black ink and a muted secondary — and System Blue is the single decision colour: primary actions, active selection and the route marker. Vernal red marks a committed decision, current signal or destructive action; green is used sparingly for positive status. The dark theme is a first-class pure-black surface ramp, not an inversion of light. There are no gradients, glass panels, neon glows or oversized decorative radii.

In Flutter, define these through `ColorScheme` semantic roles rather than scattering raw colours through widgets:

- `primary` / `onPrimary`: the one decisive action or active selection.
- `surface`, `surfaceContainer`, `onSurface`, `outline`: itinerary structure, lists and route context.
- `secondaryContainer`: non-blocking suggestions and personal-fit explanations.
- `tertiary` or `error`: warnings, conflicts and irreversible actions only.

The theme owns the light and dark schemes. No screen invents an ad-hoc colour, shadow or typography scale.

## Content Architecture

### Home

Open with a personal greeting, a single proposition — **Partiamo da come vuoi sentirti** — and one unambiguous action: **Inizia un viaggio**. Show at most one current journey and one quiet availability entry point. The archive, trends and profile each have their own bottom-navigation destination; the home must never become a dashboard wall.

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

## Typography

Use the Android system family and Flutter `TextTheme` styles. Body copy, labels and controls stay within the native type scale and respect font-size settings. Headings are clear and slightly tracked; they do not compete with a second display face. Italian labels use sentence case.

## Motion

Motion communicates a planning result:

- A chosen place settles into the collection.
- An accepted AI patch updates the relevant day and preserves the surrounding context.
- Navigation uses platform transitions; temporary tasks use native sheets.

Most transitions are 150–250 ms with a calm ease-out. Never make a traveller wait for choreography, bounce an itinerary, or hide content behind a loader. When reduced motion is enabled, crossfade or update immediately.

## Appearance setting

Light is the default on first launch. The profile contains an explicit two-way **Chiaro / Scuro** control and stores the choice locally. All screen colors come from Material `ColorScheme` roles or the small `IterColorRoles` theme extension; no feature screen owns a parallel palette. Light and dark are both first-class.

## Accessibility Checklist

- Minimum 48 dp targets, with labelled alternatives to gestures.
- Semantic labels for personal-fit scores, route changes, locked stops and outbound booking links.
- Text and state never rely on colour alone; maintain contrast in both themes.
- Screen-reader order follows the visible decision order.
- Spatial diagrams are supplemental; the textual day timeline remains complete.