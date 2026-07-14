# Impeccable native audit

Date: 2026-07-14
Platform: Flutter / Android
Scope: current Iter MVP source, 375 × 812 widget flow, Android emulator, light and dark appearance

## Audit Health Score

| # | Dimension | Score | Key finding |
|---|---|---:|---|
| 1 | Accessibility | 4 | TalkBack roles, 48 dp targets and reduced motion are handled in the new flow. |
| 2 | Performance | 3 | Local video keeps discovery immediate but increases the binary and needs release encoding review. |
| 3 | Appearance & Theming | 4 | Semantic Material roles drive distinct light and dark schemes. |
| 4 | Platform Conformance | 4 | Material navigation, back behaviour, insets and controls read as a native Android app. |
| 5 | Adaptivity | 3 | The shell becomes a navigation rail on wide windows; pushed planning tasks still deserve tablet and landscape QA. |
| **Total** |  | **18/20** | **Excellent — minor release polish remains.** |

## Platform Conformance Verdict

**Pass.** Iter now reads as a native Android travel product rather than a ported website. Navigation uses Material 3 destinations and a wide-window rail, temporary tasks use platform routes, the system back stack remains intact, and content respects safe areas. The interface avoids gradient text, glass panels, metric heroes and decorative card grids. Route lines and local video carry the product identity without replacing native controls.

## Executive Summary

- Audit Health Score: **18/20 (Excellent)**
- Findings: **0 P0, 0 P1, 2 P2, 1 P3**
- The new discovery flow is operable with labelled tap controls; swipe is never the only interaction.
- Light and dark appearances were checked on the Android emulator.
- The most important remaining work is release-media optimization and broader window-size regression coverage.

## Detailed Findings

### [P2] Planning routes need wide-window and landscape regression coverage

- **Location:** discovery, curation, stay and itinerary routes opened from `lib/app/iter_app.dart`
- **Category:** Adaptivity
- **Impact:** the main shell constrains content and switches to a navigation rail, but full-screen pushed tasks can still become too wide or visually sparse on tablets and landscape phones.
- **Guideline:** Android large-screen layouts should preserve readable line length and use available space deliberately instead of stretching a phone composition.
- **Recommendation:** add compact/medium/expanded golden tests and cap task content width or introduce a contextual second pane where it improves planning.
- **Suggested command:** `$impeccable adapt`

### [P2] Bundled demo video needs a release-size budget

- **Location:** `assets/videos/`, `lib/widgets/journey_media.dart`
- **Category:** Performance
- **Impact:** the three clips make discovery immediate and offline, but add about 15 MB before native packaging. Unchecked additions could slow store downloads and updates.
- **Guideline:** Android media should be encoded for the target display size and unnecessary density or bitrate should not ship.
- **Recommendation:** keep the three-clip cap for the prototype, measure the release AAB, transcode to a documented resolution/bitrate budget and pause controllers when the app enters the background.
- **Suggested command:** `$impeccable optimize`

### [P3] Media-overlay foreground is an intentional fixed contrast colour

- **Location:** `lib/screens/discover_tab.dart`, `lib/screens/destination_discovery_screen.dart`
- **Category:** Theming
- **Impact:** white overlay text is correct over the shared dark scrim, but it is the only feature-level foreground not represented by a semantic theme role.
- **Guideline:** reusable visual states should come from shared design tokens.
- **Recommendation:** add an `onVideoScrim` semantic role if more video surfaces are introduced; no change is needed for the current two uses.
- **Suggested command:** `$impeccable colorize`

## Patterns & Systemic Issues

No systemic conformance issue remains in the redesigned shell. Colors, typography, radius, navigation and motion are centralized. The only emerging system concern is media governance: new clips should not be added without source attribution and a release-size budget.

## Positive Findings

- One primary Home action and one decision per discovery step keep cognitive load low.
- The chat composer remains attached to the planning product instead of becoming a separate chatbot.
- Answer rows expose button and selected state semantics; all primary targets meet Android's 48 dp minimum.
- Reduced-motion settings remove step choreography and disable video autoplay while preserving explicit playback.
- The route canvas is supplemental to complete textual stops and days.
- Light is the first-launch default; the explicit Chiaro/Scuro preference persists locally.
- Video playback has a labelled pause control and a non-video fallback.

## Recommended Actions

1. **[P2] `$impeccable adapt`:** add tablet, landscape and multi-window regression layouts for pushed planning routes.
2. **[P2] `$impeccable optimize`:** measure the release AAB and enforce a media bitrate and lifecycle budget.
3. **[P3] `$impeccable colorize`:** introduce `onVideoScrim` only if the media component family grows.
4. **[P3] `$impeccable polish`:** re-run emulator and accessibility checks after those release changes.

You can ask to run these one at a time, all at once, or in any order.

Re-run `$impeccable audit` after fixes to see the score improve.
