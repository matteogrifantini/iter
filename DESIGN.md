# Iter Design System

## Scene

Someone is planning from a phone between everyday commitments: a free evening, a train ride, a pause at work. The interface must make a trip feel possible without asking them to become a travel agent.

## Platform Strategy

Iter ships as a Flutter app for Android. Its interaction model follows Material 3: navigation, top app bars, system back, tonal elevation and expanded layouts that graduate to a navigation rail on larger screens. The app respects safe areas, light/dark appearance, device text scale and reduced motion.

Do not recreate a website inside a phone. Brand is carried through content, a restrained tint, map/route context and the way a plan changes — not through bespoke navigation or ornamental chrome.

## Visual Direction

The direction is **Atlante personale**: a quiet editorial travel object made native to Android. A route line is the recurring signature; real travel footage appears only when it helps a person imagine a journey. The interface is sparse enough to make the current decision unmistakable, but never sterile.

The default light theme uses a cool daylight canvas, true white surfaces, graphite text and petrol actions. Vermilion marks a committed decision or the current route signal; mint is used sparingly for positive status. The dark theme has its own near-black petrol surface ramp instead of inverting the light palette. There are no cream backgrounds, gradients, glass panels, neon glows or oversized decorative radii.

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

Use one prompt at a time, a visible five-stop route for progress, grouped plain-language answers and a persistent open response. Never label information as “parameters”, “configuration” or “brief”. Do not reveal candidate destinations early. The result is a horizontal collection of complete routes, possibly multi-city or village-based, with duration, movement and stops visible before commitment.

### Place curation

The current place owns the screen. Its name, neighbourhood, reason and useful time are the hierarchy; the personal-fit score stays supporting evidence, never a hero metric. A horizontal swipe may accelerate the choice, but **Passa**, **Salva** and **Irrinunciabile** remain visible 48 dp controls. Show progress as context, not as a test.

### Transport choice

Use the native segmented control to switch between flight and train. Each option is a comparable entity with origin, first stop, broad timing, duration, changes and indicative cost in the same order. Selection is explicit and reversible. Keep the trust line next to the commitment: values are demo estimates and no ticket is purchased.

### Stay choice

Treat a neighbourhood as a base, not a hotel result. A restrained spatial diagram shows the relationship to accepted places; atmosphere, average walking time and the reason it fits stay textual. **Scegli base** is the commitment, while **Vedi alloggi** opens an external service and remains secondary.

### Itinerary workspace

The day plan is the primary object. Arrival and base form one compact trip foundation, then days and stops read as a continuous timeline without a card around every item. Locked state is visible in the route marker and label. The conversation composer is anchored to the bottom of the current plan and applies a visible, undoable patch; it is not a floating chatbot screen.

## Component Language

- Prefer native list rows, buttons, chips, bottom sheets and system dialogs over decorative containers.
- A card earns its place when it is a trip, destination, place or area the user can act on. Avoid nested cards and repeated icon-heading-copy grids.
- Use one button vocabulary across flows: filled for the next meaningful commitment, tonal/outlined for alternatives, text for low-risk actions.
- Status is written as useful language: “Bozza pronta da rivedere”, “Due tappe bloccate”, “Percorso stimato”. Never use a fake AI loader.
- Every action has default, disabled, loading, error and success feedback. Empty states teach the next action.
- Video is content, not decoration: bundled clips loop silently, have a pause action and fall back to a semantic route illustration when playback is unavailable.
- Corner radii stop at 14 dp for primary surfaces. Route progress, typography and media provide character; containers do not need to look like bubbles.

## Typography

Use the Android system family and Flutter `TextTheme` styles. Body copy, labels and controls stay within the native type scale and respect user font-size settings. Headings can be expressive through weight and spacing, not a second display face. Italian labels use sentence case.

## Motion

Motion communicates a planning result:

- A chosen place settles into the collection.
- An accepted AI patch updates the relevant day and preserves the surrounding context.
- Navigation uses platform transitions; temporary tasks use native sheets.

Most transitions are 150–250 ms with a calm ease-out. Never make a traveller wait for choreography, bounce an itinerary, or hide content behind a loader. When reduced motion is enabled, crossfade or update immediately.

## Appearance setting

Light is the default on first launch. The profile contains an explicit two-way **Chiaro / Scuro** control and stores the choice locally. All screen colors come from Material `ColorScheme` roles or the small `IterColorRoles` theme extension; no feature screen owns a parallel palette.

## Accessibility Checklist

- Minimum 48 dp targets, with labelled alternatives to gestures.
- Semantic labels for personal-fit scores, route changes, locked stops and outbound booking links.
- Text and state never rely on colour alone; maintain contrast in both themes.
- Screen-reader order follows the visible decision order.
- Spatial diagrams are supplemental; the textual day timeline remains complete.
