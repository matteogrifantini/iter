# Iter Organization Vertical Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Work in the current thread only; do not delegate to workers or subagents.

**Goal:** Build the first real organization vertical of Iter from an open travel desire to a confirmed flight, a profile-led zone and stay choice, and a first editable plan, while keeping the Home predictable and the live-trip mode separate.

**Architecture:** Keep `ChatFirstPrototypeApp` and `ChatFirstPrototypeController` as the application entrypoint, but give each organization conversation a dedicated `OrganizationSession` keyed by the same `tripId` used by the chat. The session owns a typed state machine and consumes AI, travel, and stay ports; the Flutter client renders its events as inline chat cards. Provider data, user decisions, profile signals, and the eventual `TripSnapshot` remain separate objects, and no card can skip a required confirmation.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Material 3, existing Iter theme/primitives, `flutter_test`, existing `supabase_flutter`/Supabase Edge Functions, existing `http` and `url_launcher` seams, deterministic mock providers for tests, and the first flight-provider feasibility check against [`AWeirdDev/flights`](https://github.com/AWeirdDev/flights).

**Spec:** `docs/superpowers/specs/2026-09-01-iter-organization-vertical.md`

## Global Constraints

- Preserve `main.dart` → `buildIterApp()` → `ChatFirstPrototypeApp` and the current `Oggi / Viaggi / Tu` shell.
- Treat `feat/real-iter-app` as dirty and user-owned. Inspect `git status` before every task; do not reset, checkout, clean, delete untracked files, commit, push, merge, or deploy.
- Do not delete or connect `NewTripPlannerSheet` / the Nuovo viaggio Lab to this vertical. The Lab remains deterministic and isolated from `IterStore` and real providers.
- The Home has one stable CTA, a manually browsable trip carousel, an optional relevant-opportunity slot, and fixed bottom navigation. It does not ask the user to choose among `Organizza`, `Scegli` or `Sono in viaggio`.
- The organization conversation is AI-led, not a fixed wizard: 3–4 essential questions and at most 2 adaptive questions. Questions must be tied to a concrete search or decision and may use chips, calendar, counter, inline text, or voice.
- Iter may propose origin, departure mode, destination, dates, and flexible combinations. The user may browse cards or correct Iter in chat; no technical airport/station form is required.
- The sequence is transport → external purchase → explicit flight confirmation → contextual experience questions → zones → stay search → explicit stay confirmation → plan proposal.
- Opening a partner URL is never treated as a purchase. A confirmed flight or stay requires an explicit user action or a future verifiable booking source that is not part of this plan.
- Real prices, availability, media, and conditions must carry source, verification time, and freshness state. A deterministic adapter is allowed in mock/test mode only and must be labeled `Dati demo`; a missing provider is an honest unavailable/degraded state.
- No provider secret, service-role key, or Gemini key enters Flutter. Supabase requests use the current authenticated user access token; the backend validates the user before quota consumption and generation.
- Do not claim that `fast-flights`, Vio, Trivago, or any other provider is commercially or operationally available until its current access, terms, rate limits, and no-fixed-cost model are verified. If a provider is not verified, keep its adapter disabled outside mock mode.
- The AI interprets intent, chooses the next question, ranks and explains real provider results, and proposes zones. Deterministic code enforces hard constraints, state transitions, ownership, expiry, and confirmation rules. The AI never invents an offer.
- Search progress may animate only facts represented by real events: provider contacted, combinations evaluated, partial results, verification, degraded provider, or expired offer. Never animate simulated reasoning, fake percentages, or an indefinite spinner without an action.
- Use Iter semantic theme tokens, 48 dp targets, text scale 1.5, light/dark themes, reduced motion, and layouts at 320/360/390 dp. Cards are inline actionable content, not a replacement dashboard.
- Every task ends with focused tests, `git diff --check`, and a written note of what remains mock, unavailable, or unverified. Full verification is required before any completion claim.

## Execution order and ownership boundaries

The current untracked `lib/features/organization/` and `test/organization/` tree is an unaccepted implementation from another AI. It must be reviewed and either adapted or left untouched; no task below assumes it is correct. The current committed UI baseline at `9007e49` remains the visual starting point, while the new specification is the product source of truth.

The tasks are intentionally sequential because each later surface depends on the same `tripId`, state machine, and confirmation history. A task is complete only when its own focused tests pass and its boundary is usable by the next task.

---

### Task 1: Establish a truthful baseline and isolate the Lab

**Files:**

- Modify: `.env.example`
- Modify: `HANDOFF.md`
- Test/verify: `git diff --check`, repository status, existing documentation references

**Interfaces:**

- Consumes: current branch state, `PRODUCT.md`, `DESIGN.md`, `NEW_TRIP_MASTER_PLAN.md`, and the organization specification.
- Produces: a truthful environment example and handoff that distinguish implemented mock behavior, target behavior, unavailable providers, and future live/radar work.

- [ ] **Step 1: Record the baseline without mutating it.**

  Run:

  ```bash
  git status --short --branch
  git diff --stat
  git log --oneline --decorate -5
  ```

  Expected: the existing dirty files and untracked organization files are listed; no reset or cleanup is performed.

- [ ] **Step 2: Write a documentation regression checklist.**

  Confirm that the handoff does not call fixture flights/hotels “live”, does not promise €0 provider access without verification, does not report an outdated test count, and points to the organization specification as a target rather than an implemented feature.

- [ ] **Step 3: Restore safe example configuration.**

  Keep `ITER_BACKEND=mock` as the default, leave `SUPABASE_URL` and `SUPABASE_ANON_KEY` empty or placeholder-only, and document that Gemini/provider secrets belong to the backend. A model name may be present as a non-secret override, but no live project URL or token belongs in `.env.example`.

- [ ] **Step 4: Rewrite the handoff around evidence.**

  Keep the current entrypoint and UI baseline, list the actual verification commands, label each existing feature folder according to its observed mock/demo or verified state, link the organization specification and this plan, and state explicitly that the organization vertical is not yet integrated.

- [ ] **Step 5: Verify the documentation-only slice.**

  Run:

  ```bash
  git diff --check
  rg -n -i 'complete|live|real|free|279|organization|mock|unavailable' HANDOFF.md .env.example
  ```

  Expected: no secret-looking value is present; every “live/real/free” claim has an evidence-backed qualification.

---

### Task 2: Replace loose organization data with a typed state contract

**Files:**

- Modify: `lib/features/organization/models/organization_models.dart`
- Modify: `lib/features/organization/models/organization_card.dart`
- Modify: `lib/features/organization/events/organization_events.dart`
- Create: `lib/features/organization/models/organization_state.dart`
- Test: `test/organization/organization_models_test.dart`
- Test: `test/organization/organization_events_test.dart`

**Interfaces:**

- Consumes: existing organization model names only where they match the specification; existing `TripSnapshot` remains a downstream plan representation.
- Produces: immutable, serializable-enough values for `TripIntent`, `SearchSession`, `ProviderOffer`, `UserDecision`, `ProfileSignal`, `OrganizationCard`, `OrganizationState`, and `OrganizationEvent`.

  Required public contract:

  ```dart
  enum OrganizationPhase {
    collectingIntent,
    searchingTransport,
    awaitingFlightPurchase,
    awaitingFlightConfirmation,
    collectingExperience,
    proposingZones,
    searchingStay,
    awaitingStayPurchase,
    awaitingStayConfirmation,
    readyForPlan,
  }

  class OrganizationState {
    const OrganizationState({
      required this.tripId,
      required this.phase,
      required this.intent,
      required this.cards,
      required this.decisions,
      required this.searchSessions,
      this.confirmedFlight,
      this.confirmedStay,
      this.plan,
    });

    final String tripId;
    final OrganizationPhase phase;
    final TripIntent intent;
    final List<OrganizationCard> cards;
    final List<UserDecision> decisions;
    final List<SearchSession> searchSessions;
    final ProviderOffer? confirmedFlight;
    final ProviderOffer? confirmedStay;
    final TripPlan? plan;
  }

  class OrganizationAnswer {
    const OrganizationAnswer({required this.key, required this.value});

    final String key;
    final Object? value;
  }

  class IntentPatch {
    const IntentPatch({required this.field, required this.value});

    final String field;
    final Object? value;
  }

  class ExperienceContext {
    const ExperienceContext({
      required this.priorities,
      required this.pace,
      required this.walkingTolerance,
      required this.singleBase,
    });

    final List<String> priorities;
    final String pace;
    final String walkingTolerance;
    final bool singleBase;
  }

  class QuestionBudget {
    const QuestionBudget({required this.essential, required this.adaptive});

    final int essential;
    final int adaptive;
  }

  class OrganizationQuestion {
    const OrganizationQuestion({
      required this.key,
      required this.prompt,
      required this.essential,
      required this.options,
    });

    final String key;
    final String prompt;
    final bool essential;
    final List<String> options;
  }

  sealed class DateConstraint {
    const DateConstraint();
  }

  class ExactDates extends DateConstraint {
    const ExactDates({required this.departure, required this.returnDate});

    final DateTime departure;
    final DateTime returnDate;
  }

  class FlexibleDates extends DateConstraint {
    const FlexibleDates({required this.departures, required this.duration});

    final List<DateTime> departures;
    final DurationRange duration;
  }

  class DurationRange {
    const DurationRange({required this.minimumDays, required this.maximumDays});

    final int minimumDays;
    final int maximumDays;
  }

  class TravelerGroup {
    const TravelerGroup({required this.kind, required this.count});

    final String kind;
    final int count;
  }

  enum TravelMode { flight, train, bus, car }
  ```

- [ ] **Step 1: Add failing model tests for immutability and equality.**

  Cover defensive copies for lists/maps, stable equality and hash codes for equal values, date/freshness fields, and explicit distinction between `openedExternally`, `awaitingConfirmation`, `confirmed`, `stale`, and `unavailable`.

- [ ] **Step 2: Add failing transition invariant tests.**

  Assert that a stay cannot be selected before a confirmed flight, a plan cannot exist before a confirmed stay, a link-open event does not create a confirmed decision, and a changed confirmed flight makes dependent stay searches stale.

- [ ] **Step 3: Implement immutable value objects.**

  Copy incoming collections into unmodifiable values, use a sentinel or dedicated nullable-update type in `copyWith` so a caller can explicitly clear a field, and make `==`/`hashCode` use the same structural fields. Normalize money as integer cents plus currency rather than floating-point display values.

- [ ] **Step 4: Make card payloads typed at the boundary.**

  Define decoders/constructors for offer, question, zone, confirmation, and plan payloads. Accept integer or double JSON numbers for monetary values, reject malformed provider payloads with a typed decode error, and never rely on `payload['offers']` already containing Dart objects after persistence.

- [ ] **Step 5: Define event metadata.**

  Every event carries `tripId`, a monotonic sequence, timestamp, and a stable event kind. Include the event types from the specification, including partial results, provider degradation, expired offers, external purchase opened, flight/stay confirmation requested, and plan proposed.

- [ ] **Step 6: Run the focused model/event tests.**

  ```bash
  dart format lib/features/organization/models lib/features/organization/events test/organization
  flutter test test/organization/organization_models_test.dart test/organization/organization_events_test.dart
  git diff --check
  ```

  Expected: tests pass without relying on mutable payload identity or untyped provider objects.

---

### Task 3: Introduce honest AI, travel, and stay ports

**Files:**

- Create: `lib/features/organization/providers/organization_ai_gateway.dart`
- Create: `lib/features/organization/providers/travel_search_provider.dart`
- Create: `lib/features/organization/providers/stay_search_provider.dart`
- Create: `lib/features/organization/providers/provider_capabilities.dart`
- Create: `lib/features/organization/adapters/mock_travel_search_provider.dart`
- Create: `lib/features/organization/adapters/unavailable_stay_search_provider.dart`
- Modify: `lib/features/organization/adapters/flight_search_adapter.dart`
- Test: `test/organization/provider_contract_test.dart`
- Test: `test/organization/flight_search_adapter_test.dart`

**Interfaces:**

- Consumes: the typed models/events from Task 2.
- Produces: replaceable ports with these signatures:

  ```dart
  abstract interface class OrganizationAiGateway {
    Future<AiOrganizationResponse> decideNextStep(
      OrganizationAiContext context,
    );
  }

  abstract interface class TravelSearchProvider {
    Stream<TravelSearchUpdate> search(TravelSearchQuery query);
  }

  abstract interface class StaySearchProvider {
    Stream<StaySearchUpdate> search(StaySearchQuery query);
  }
  ```

  The public data types used by those ports are:

  ```dart
  class OrganizationAiContext {
    const OrganizationAiContext({
      required this.intent,
      required this.profileSignals,
      required this.recentEvents,
      required this.questionBudget,
    });

    final TripIntent intent;
    final List<ProfileSignal> profileSignals;
    final List<OrganizationEvent> recentEvents;
    final QuestionBudget questionBudget;
  }

  class AiOrganizationResponse {
    const AiOrganizationResponse({
      this.nextQuestion,
      this.explanation,
      this.rankings = const <String>[],
      this.zoneProposalIds = const <String>[],
    });

    final OrganizationQuestion? nextQuestion;
    final String? explanation;
    final List<String> rankings;
    final List<String> zoneProposalIds;
  }

  class TravelSearchQuery {
    const TravelSearchQuery({
      required this.tripId,
      required this.originCandidates,
      required this.destinationCandidates,
      required this.dateConstraint,
      required this.duration,
      required this.travelers,
      required this.acceptedModes,
      required this.maxStops,
      required this.budgetCentsPerPerson,
    });

    final String tripId;
    final List<String> originCandidates;
    final List<String> destinationCandidates;
    final DateConstraint dateConstraint;
    final DurationRange duration;
    final TravelerGroup travelers;
    final Set<TravelMode> acceptedModes;
    final int? maxStops;
    final int? budgetCentsPerPerson;
  }

  class StaySearchQuery {
    const StaySearchQuery({
      required this.tripId,
      required this.confirmedFlight,
      required this.zoneId,
      required this.zoneLabel,
      required this.zoneLatitude,
      required this.zoneLongitude,
      required this.travelers,
      required this.profileSignals,
      required this.relevantPlaceIds,
      required this.localTransportTolerance,
    });

    final String tripId;
    final ProviderOffer confirmedFlight;
    final String zoneId;
    final String zoneLabel;
    final double zoneLatitude;
    final double zoneLongitude;
    final TravelerGroup travelers;
    final List<ProfileSignal> profileSignals;
    final List<String> relevantPlaceIds;
    final String localTransportTolerance;
  }

  sealed class TravelSearchUpdate {
    const TravelSearchUpdate({
      required this.tripId,
      required this.providerId,
      required this.kind,
      required this.occurredAt,
      this.offers = const <ProviderOffer>[],
      this.message,
    });

    final String tripId;
    final String providerId;
    final ProviderUpdateKind kind;
    final DateTime occurredAt;
    final List<ProviderOffer> offers;
    final String? message;
  }

  sealed class StaySearchUpdate {
    const StaySearchUpdate({
      required this.tripId,
      required this.providerId,
      required this.kind,
      required this.occurredAt,
      this.offers = const <ProviderOffer>[],
      this.message,
    });

    final String tripId;
    final String providerId;
    final ProviderUpdateKind kind;
    final DateTime occurredAt;
    final List<ProviderOffer> offers;
    final String? message;
  }

  enum ProviderUpdateKind { started, progressed, partial, completed, degraded, failed }

  enum ProviderCapabilityState { verified, mockOnly, unavailable }

  class ProviderCapabilities {
    const ProviderCapabilities({
      required this.providerId,
      required this.displayName,
      required this.state,
      required this.supportedModes,
      required this.message,
    });

    final String providerId;
    final String displayName;
    final ProviderCapabilityState state;
    final Set<TravelMode> supportedModes;
    final String message;
  }
  ```

  `TravelSearchQuery` represents origin alternatives, destination candidates, exact or flexible dates, duration, travelers, accepted modes, stops, budget, and the current `tripId`. `StaySearchQuery` requires a confirmed flight, a selected zone ID/coordinate, fixed dates from that flight, travelers, profile signals, relevant places/events, and local transport constraints. `QuestionBudget`, `OrganizationQuestion`, `DateConstraint`, `DurationRange`, `TravelerGroup`, `TravelMode`, and `ProviderUpdateKind` are domain values defined in Task 2; they are not untyped maps.

- [ ] **Step 1: Write provider contract tests before adapters.**

  Verify that every update includes `tripId`, provider ID, status, timestamp, and an honest source state; partial results can be emitted before completion; errors become typed degraded/failed updates; and an unavailable provider never returns fabricated offers marked live.

- [ ] **Step 2: Record the flight-provider feasibility boundary.**

  Inspect the current [`AWeirdDev/flights`](https://github.com/AWeirdDev/flights) interface, runtime requirements, scraping limitations, terms, rate behavior, and a backend execution option. Record the outcome in the provider capability model. The client adapter may consume normalized backend results, but it must not import or execute a scraper or hold provider secrets in Flutter.

- [ ] **Step 3: Normalize the existing fixture adapter.**

  Keep deterministic offers only under a mock provider ID such as `mock-flights`, mark them `demo`, give them fixed verification metadata, and remove the misleading `fast-flights`/`live` labeling unless the feasibility gate has actually produced a verified backend result.

- [ ] **Step 4: Add explicit unavailable behavior for stays.**

  `UnavailableStaySearchProvider` emits `started`, one `provider.degraded` update explaining that no approved hotel provider is configured, and a completed empty result. It does not invent hotel names, prices, images, availability, or booking URLs.

- [ ] **Step 5: Add capability tests.**

  Test that mock mode is selectable without network access, production mode refuses an unverified provider, source/freshness fields survive normalization, and provider errors preserve the current state instead of leaving a permanent searching flag.

- [ ] **Step 6: Run focused provider tests.**

  ```bash
  flutter test test/organization/provider_contract_test.dart test/organization/flight_search_adapter_test.dart
  git diff --check
  ```

  Expected: demo data is visibly demo, unavailable data is visibly unavailable, and no test calls a real external provider.

---

### Task 4: Build the organization state machine and event stream

**Files:**

- Modify: `lib/features/organization/engine/organization_orchestrator.dart`
- Create: `lib/features/organization/engine/organization_session.dart`
- Create: `lib/features/organization/engine/organization_session_registry.dart`
- Modify: `test/organization/organization_orchestrator_test.dart`
- Create: `test/organization/organization_state_machine_test.dart`

**Interfaces:**

- Consumes: `OrganizationAiGateway`, `TravelSearchProvider`, `StaySearchProvider`, typed state and events.
- Produces:

  ```dart
  class OrganizationSession {
    OrganizationSession({
      required String tripId,
      required OrganizationAiGateway ai,
      required TravelSearchProvider travel,
      required StaySearchProvider stays,
    });

    String get tripId;
    OrganizationState get state;
    Stream<OrganizationEvent> get events;

    Future<void> startWithDesire(String text);
    Future<void> answer(OrganizationAnswer answer);
    Future<void> reviseIntent(IntentPatch patch);
    Future<void> startFlightSearch();
    Future<void> selectFlight(String offerId);
    Future<void> openFlightPurchase();
    Future<void> confirmFlight({String? bookingReference});
    Future<void> submitExperience(ExperienceContext context);
    Future<void> selectZone(String zoneId);
    Future<void> startStaySearch();
    Future<void> selectStay(String offerId);
    Future<void> openStayPurchase();
    Future<void> confirmStay({String? bookingReference});
    Future<void> proposePlan();
  }

  class OrganizationSessionRegistry {
    OrganizationSession getOrCreate(String tripId);
    OrganizationSession? find(String tripId);
    bool contains(String tripId);
  }
  ```

  `OrganizationSessionRegistry` maps one `conversationId` to one session and uses that same value as `tripId`; it must not create a second session when the user reopens a draft.

- [ ] **Step 1: Write failing lifecycle tests.**

  Cover open desire → summary/question, answer → updated intent, enough context → transport search, partial updates → comparison card, selection → external purchase state, external URL open → awaiting confirmation, explicit confirmation → experience context, zone → stay search, stay confirmation → plan proposal.

- [ ] **Step 2: Write failing invalid-transition tests.**

  Assert that `startStaySearch`, `selectStay`, and `proposePlan` fail with an observable typed error before their prerequisites; repeated confirmation is idempotent; a new flight selection invalidates dependent stay/plan state; and stale async results from an older query cannot overwrite a newer query.

- [ ] **Step 3: Implement serialized event emission.**

  Replace the current append-only event list with a broadcast or single-subscription-safe stream backed by a state reducer. Assign a request ID to every search, cancel or ignore obsolete requests, emit `search.started`, `search.progressed`, partial results, completion, degradation, and error events, and always return to a non-searching state.

- [ ] **Step 4: Implement question budgeting.**

  Track essential and adaptive question counts in the session. The AI may select the next question, but deterministic code rejects a sixth explicit question after 3–4 essential answers plus 2 adaptive answers unless the user directly asks to continue. `Non lo so` and `Decidi tu` are explicit values, not hidden defaults.

- [ ] **Step 5: Implement hard gates.**

  Require a flight decision with `confirmed` status before experience/zone/stay actions. Require a stay decision with `confirmed` status before creating `TripPlan`. Do not set the live-trip status anywhere in this session.

- [ ] **Step 6: Run the lifecycle suite.**

  ```bash
  flutter test test/organization/organization_orchestrator_test.dart test/organization/organization_state_machine_test.dart
  git diff --check
  ```

  Expected: all illegal transitions are rejected with user-visible event/error data, and all legal transitions preserve one `tripId`.

---

### Task 5: Connect one organization session to the existing chat surface

**Files:**

- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_app.dart`
- Create: `lib/features/organization/ui/organization_thread_renderer.dart`
- Test: `test/chat_first_prototype_widget_test.dart`
- Create: `test/organization/organization_thread_integration_test.dart`

**Interfaces:**

- Consumes: `OrganizationSessionRegistry` and the event stream from Task 4.
- Produces: the existing app can create/open an organization conversation from the Home CTA, render organization events inline in the thread, and reopen the same session from `Viaggi` without a duplicate `tripId`.

- [ ] **Step 1: Add failing app-level tests.**

  Start `ChatFirstPrototypeApp` with injected mock dependencies, tap the single Home CTA, submit a free-text desire, and assert that the thread shows an intent summary and a contextual question. Assert that no `NewTripPlannerSheet` and no three-mode chooser appears.

- [ ] **Step 2: Add the session registry to the controller.**

  Create a session when `startFreeTalk` is used for a new organization conversation, keep it keyed by conversation ID, and expose read-only lookup to the shell/thread. Existing fixture conversations continue using their current behavior until they are explicitly migrated.

- [ ] **Step 3: Render events as inline cards.**

  Map event kinds to card views in the thread renderer. Ordinary messages remain ordinary chat bubbles; an actionable organization card appears in the same chronological thread and retains `tripId`, card ID, state, source, and freshness metadata.

- [ ] **Step 4: Route all card actions back to the session.**

  A card action must call the session command and append the resulting event; it must not mutate a separate widget-local copy. Reopening the thread must render from session state rather than from stale card instances.

- [ ] **Step 5: Keep the Lab isolated.**

  Leave `NewTripPlannerSheet` and its existing tests on their current path. The Home organization CTA opens a conversation directly; it does not route through the Lab wizard.

- [ ] **Step 6: Run focused integration tests.**

  ```bash
  flutter test test/organization/organization_thread_integration_test.dart test/chat_first_prototype_widget_test.dart
  git diff --check
  ```

  Expected: the real application path, not only isolated organization widgets, displays the first organization card and preserves the same session after reopening.

---

### Task 6: Rebuild the Home around fixed interaction points

**Files:**

- Modify: `lib/features/chat_first_prototype/chat_first_home_screen.dart`
- Modify: `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart`
- Modify: `lib/features/chat_first_prototype/adaptive_home_model.dart`
- Test: `test/chat_first_prototype_widget_test.dart`
- Test: `test/adaptive_home_model_test.dart`

**Interfaces:**

- Consumes: controller conversations, draft progress, confirmed/upcoming trip summaries, and the fixed shell callbacks.
- Produces: a predictable Home with stable section positions:

  ```text
  Oggi
  [Organizza un viaggio]
  I tuoi viaggi  [in costruzione / in arrivo / live]  →
  Opportunità per te  →  (hidden when no relevant opportunity)
  Oggi · Viaggi · Tu
  ```

- [ ] **Step 1: Add failing layout and behavior tests.**

  Assert one primary CTA, a manually scrollable trip carousel, no automatic carousel advance, no three-mode selection, no generic destination grid when there is no relevant opportunity, and stable navigation semantics.

- [ ] **Step 2: Remove the catalogue composition.**

  Replace hardcoded “Mete del momento”, vibe grids, tool showcases, and manifesto blocks with fixed sections whose contents are data-driven. An empty opportunity slot is absent rather than filled with Budapest/Porto/Lisbona/Roma placeholders.

- [ ] **Step 3: Make draft progress actionable.**

  Each trip tile shows the next real action, such as `Continua: scegli il volo` or `Conferma il soggiorno`, and opens the existing conversation/session. It never asks the user to choose the active trip.

- [ ] **Step 4: Keep live activation out of this slice.**

  Do not add date/GPS activation in this task. Preserve a future resolver boundary so a later live task can enforce one active trip and contextual `Sei in viaggio?` confirmation without changing Home navigation.

- [ ] **Step 5: Run responsive Home tests.**

  ```bash
  flutter test test/adaptive_home_model_test.dart test/chat_first_prototype_widget_test.dart
  git diff --check
  ```

  Expected: the Home remains understandable at 320/360/390 dp and only the fixed sections change content.

---

### Task 7: Implement the flight comparison and explicit external purchase flow

**Files:**

- Create: `lib/features/organization/ui/cards/external_purchase_card_view.dart`
- Create: `lib/features/organization/ui/cards/flight_confirmation_card_view.dart`
- Modify: `lib/features/organization/ui/cards/flight_comparison_card_view.dart`
- Create: `lib/features/organization/ui/organization_external_link_policy.dart`
- Modify: `lib/features/organization/engine/organization_session.dart`
- Test: `test/organization/organization_flight_flow_test.dart`
- Test: `test/organization/organization_cards_widget_test.dart`

**Interfaces:**

- Consumes: normalized `ProviderOffer` values and `TravelSearchUpdate` events.
- Produces: a browseable flight list with filters, sorting, freshness/source labels, and these explicit commands: `selectFlight`, `openFlightPurchase`, `confirmFlight`.

- [ ] **Step 1: Add failing flight-flow tests.**

  Cover exact dates, flexible date alternatives, origin/airport alternatives, cheapest/fastest/fewest-changes/profile-fit sorting, source/fetched/expiry display, partial results, expired offers, partner-link failure, and explicit `Ho acquistato questo volo` confirmation.

- [ ] **Step 2: Make sorting real and local.**

  Sort the normalized offer list by a declared criterion and rebuild the visible list; do not only emit a callback. “Migliore” must be explained as a compromise among the actual query criteria and available provider results.

- [ ] **Step 3: Add link validation.**

  Allow only HTTPS URLs with a provider host declared by the normalized offer. Reject empty, non-HTTPS, malformed, or unapproved hosts with an actionable error card. Reuse the existing launcher seam where possible instead of opening URLs directly from a widget.

- [ ] **Step 4: Separate open from confirmation.**

  Opening the partner moves the card to `awaitingConfirmation` and emits `external.purchaseOpened`; it never marks the offer purchased. The return action records `UserDecision.confirmed` only after the user explicitly confirms.

- [ ] **Step 5: Invalidate dependent searches.**

  If the user changes the selected flight or confirms a different one, mark prior stay queries and zone proposals stale. Do not show hotel actions while the flight is only selected or the purchase is awaiting confirmation.

- [ ] **Step 6: Run focused UI/flow tests.**

  ```bash
  flutter test test/organization/organization_flight_flow_test.dart test/organization/organization_cards_widget_test.dart
  git diff --check
  ```

  Expected: every flight card shows what is known, what is estimated, and what the user must still confirm.

---

### Task 8: Add contextual experience questions, zones, and profile-led stays

**Files:**

- Create: `lib/features/organization/models/zone_proposal.dart`
- Create: `lib/features/organization/ui/cards/experience_card_view.dart`
- Create: `lib/features/organization/ui/cards/zone_proposal_card_view.dart`
- Create: `lib/features/organization/ui/cards/stay_comparison_card_view.dart`
- Create: `lib/features/organization/ui/cards/stay_confirmation_card_view.dart`
- Modify: `lib/features/organization/providers/stay_search_provider.dart`
- Modify: `lib/features/organization/engine/organization_session.dart`
- Test: `test/organization/organization_stay_flow_test.dart`
- Test: `test/organization/organization_cards_widget_test.dart`

**Interfaces:**

- Consumes: confirmed flight, remaining adaptive-question budget, profile signals, selected places/events, and `StaySearchProvider` updates.
- Produces: two or three editable zone proposals with reasons, a stay search scoped by zone/coordinates/connectivity, and explicit stay purchase/confirmation states.

- [ ] **Step 1: Add failing sequencing tests.**

  Assert that experience context is requested only after confirmed flight, zones appear before stays, a zone change causes a new stay query, and no complete plan is emitted before confirmed stay.

- [ ] **Step 2: Implement contextual questions.**

  Use at most the remaining adaptive budget for pace, food/culture/nature/night, walking/transit tolerance, one base versus multiple moves, and relevant places/events. Each question must explain the decision it changes; no second questionnaire is allowed.

- [ ] **Step 3: Implement zone proposals.**

  Show 2–3 hypotheses with reachable places/events, airport connection, atmosphere, movement burden, availability/price band, and one principal compromise. Do not collapse the explanation into an unexplained numeric score.

- [ ] **Step 4: Implement stay query normalization.**

  Require zone ID/coordinates, fixed flight dates, traveler data, relevant profile signals, and transport constraints. Preserve source, verified time, total price, cancellation, meal plan, media, booking URL, distance/travel time to relevant places, and compatibility explanation.

- [ ] **Step 5: Implement honest provider absence.**

  If no approved Vio/Trivago/other partner adapter is configured, render the unavailable/degraded state and allow the user to change the zone or retry. Never fill the card with named hotels or prices copied from fixtures while calling the result live.

- [ ] **Step 6: Implement explicit stay confirmation.**

  Reuse the flight purchase state machine: external link, awaiting confirmation, explicit user confirmation, and stale handling. Only a confirmed stay unlocks `proposePlan`.

- [ ] **Step 7: Run focused stay tests.**

  ```bash
  flutter test test/organization/organization_stay_flow_test.dart test/organization/organization_cards_widget_test.dart
  git diff --check
  ```

  Expected: the hotel query visibly depends on the confirmed flight, zone, and profile instead of only city/date strings.

---

### Task 9: Map confirmed decisions into the existing editable plan

**Files:**

- Create: `lib/features/organization/plan/organization_plan_mapper.dart`
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_controller.dart`
- Modify: `lib/features/chat_first_prototype/data_source.dart`
- Modify: `lib/features/chat_first_prototype/mock_data_source.dart`
- Modify: `lib/features/chat_first_prototype/supabase_data_source.dart`
- Test: `test/organization/organization_plan_mapper_test.dart`
- Test: `test/chat_first_prototype_controller_test.dart`

**Interfaces:**

- Consumes: `OrganizationState` with confirmed flight/stay, selected experiences, zones, and alternatives.
- Produces: an immutable `TripSnapshot`/`TripPlan` proposal that uses the existing preview → confirm → revision path and persists through `IterDataSource.saveTripVersion` only after user confirmation.

- [ ] **Step 1: Add failing mapper tests.**

  Verify arrival/departure, confirmed transport, confirmed stay, realistic transfer buffers, free time, selected experiences, alternative proposals, costs, and source/freshness metadata map consistently into the existing plan model.

- [ ] **Step 2: Add the precondition test.**

  Assert that an organization state without confirmed flight or without confirmed stay cannot produce a complete plan. The UI shows the next missing decision instead of a disabled generic plan button.

- [ ] **Step 3: Implement a pure mapper.**

  Keep provider and organization objects out of `TripSnapshot`; map only confirmed facts and clearly labeled proposals. Preserve existing plan revision IDs and never mutate an accepted revision in place.

- [ ] **Step 4: Connect persistence through the existing seam.**

  Save a new plan revision using the controller/data-source boundary. Mock mode remains local and deterministic. Supabase mode requires authenticated ownership/RLS and reports a visible failure instead of silently losing the revision.

- [ ] **Step 5: Keep Piano useful without chat.**

  The existing plan screen can display and edit the resulting plan without reopening the organization conversation; any important edit still follows preview → confirmation → revision.

- [ ] **Step 6: Run focused plan tests.**

  ```bash
  flutter test test/organization/organization_plan_mapper_test.dart test/chat_first_prototype_controller_test.dart
  git diff --check
  ```

  Expected: the plan is impossible before both confirmations and remains compatible with existing controller revision behavior.

---

### Task 10: Make AI/backend authentication and multimodal progress truthful

**Files:**

- Create: `lib/features/organization/providers/mock_organization_ai_gateway.dart`
- Create: `lib/features/organization/providers/supabase_organization_ai_gateway.dart`
- Modify: `lib/features/chat_first_prototype/gemini_ai_service.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_app.dart`
- Create: `supabase/functions/organize/index.ts`
- Create: `supabase/functions/organize/README.md`
- Modify: `supabase/config.toml` only if current JWT configuration does not match the endpoint
- Test: `test/organization/organization_ai_gateway_test.dart`
- Test: `test/gemini_ai_service_test.dart`

**Interfaces:**

- Consumes: `OrganizationAiContext`, provider results, profile signals explicitly allowed for this trip, and the current Supabase session.
- Produces: a structured AI response containing the next question or action, rationale tied to input data, ranking/explanation metadata, and no fabricated offer fields.

- [ ] **Step 1: Add failing auth contract tests.**

  Assert that a Supabase request uses the current access token, not the anon key as the user bearer; an absent/expired session is observable; a backend 401 is not converted into a destination or offer; and mock mode never requires Supabase.

- [ ] **Step 2: Define the organization Edge Function contract.**

  Accept `tripId`, operation, structured intent, permitted profile signals, and normalized provider results. Validate body size/types, verify the caller with the forwarded JWT, enforce ownership and `consume_ai_credit` before generation, and return typed SSE events for question, explanation, proposal, warning, and error.

- [ ] **Step 3: Remove silent production fallback.**

  In Supabase mode, provider/AI failure emits a visible degraded/error event and preserves the current state. The deterministic gateway is selected only by explicit mock configuration or injected tests; it is never silently substituted after a live call fails.

- [ ] **Step 4: Keep keys and CORS controlled.**

  Read Gemini/provider keys only from Edge Function secrets. Do not use a wildcard production CORS policy; allow the configured local development origin and declared application origins. Never send a service-role key to Flutter.

- [ ] **Step 5: Implement real progress states.**

  The session and cards show provider stages, partial results, verification time, degraded providers, stale offers, and retry/change actions. The text equivalent remains visible with reduced motion; no fake percent or endless loading animation is permitted.

- [ ] **Step 6: Define voice and media behavior.**

  Voice recording produces editable transcript text in the composer and requires send confirmation. Photos/video are attached to the current organization message and are used only when a real analyzer/source can explain their relevance; missing permissions or media sources produce an actionable text state.

- [ ] **Step 7: Run backend/client contract tests.**

  ```bash
  flutter test test/organization/organization_ai_gateway_test.dart test/gemini_ai_service_test.dart
  git diff --check
  ```

  For the Edge Function, run the repository’s available Deno/Supabase checks after discovering the installed CLI commands with `supabase --help`; do not invent a deployment command. Expected: invalid JWT, quota exhaustion, provider failure, and missing media are all visible and non-fabricated.

---

### Task 11: End-to-end, responsive, and handoff verification

**Files:**

- Modify: `HANDOFF.md`
- Modify: `PRODUCT.md` or `DESIGN.md` only when an implemented behavior changes an approved contract
- Test: `test/organization/organization_vertical_e2e_test.dart`

**Interfaces:**

- Consumes: the complete app path from Tasks 1–10.
- Produces: evidence that the user can complete the organization vertical in mock mode, with real/unavailable states accurately labeled, without activating live-trip or radar behavior.

- [ ] **Step 1: Add the end-to-end state-machine test.**

  With deterministic injected providers and AI:

  ```text
  Home CTA
  → free-text desire
  → 3–4 essential questions
  → optional adaptive question
  → departure/mode/destination/date combinations
  → flight comparison
  → external purchase-open state
  → explicit flight confirmation
  → contextual experience question
  → zone proposal
  → stay comparison
  → explicit stay confirmation
  → plan proposal
  → plan confirmation/revision
  ```

  Assert the same `tripId` in every event/card, no duplicate session on reopen, no hotel before flight confirmation, no plan before stay confirmation, and no silent mutation after a confirmed decision.

- [ ] **Step 2: Run the required static and test gates.**

  ```bash
  dart format --output=none --set-exit-if-changed lib test
  git diff --check
  flutter analyze
  flutter test
  flutter build web --release
  ```

  Expected: all commands pass. Report the actual test count; never copy the previous handoff count.

- [ ] **Step 3: Perform Browser QA on the release build.**

  Serve `build/web` on a fresh local port and inspect Home → new organization conversation → flight cards → confirmation → zones/stays → plan, plus reopening the same trip. Check 320/360/390 dp, text scale 1.5, dark mode, reduced motion, keyboard/back behavior, and semantic labels. Confirm the DDC blank-page issue is not being mistaken for release behavior.

- [ ] **Step 4: Verify degraded and unavailable paths manually.**

  Exercise provider failure, empty results, expired offer, invalid partner URL, denied voice permission, missing media, unauthenticated AI, and quota exhaustion. Each state must explain what happened and offer retry, edit, or continue-without-that-source where valid.

- [ ] **Step 5: Update the handoff with evidence.**

  Record exact files, current branch/status, tests/build/browser checks, provider capability state, remaining mock surfaces, and the next approved task. Keep live automatic activation, one-active-trip enforcement, radar/batch monitoring, import flows, and automatic confirmations listed as future work unless a later plan explicitly implements them.

- [ ] **Step 6: Stop at review.**

  Leave the worktree uncommitted. Present changed files, verification output, known limitations, and any provider/commercial blocker to the user before requesting authorization for commit, push, deployment, or the separate live-trip plan.

## Explicitly deferred follow-up plans

These are not hidden tasks in the organization vertical:

1. automatic live activation by date and location, with one active trip and contextual `Sei in viaggio?` confirmation;
2. duplicate-trip detection and merging for future/in-building trips;
3. personal radar with explicit consent, pause, expiry, deduplication, and low-frequency meaningful-change checks;
4. automatic booking confirmation from a verifiable partner source;
5. push notifications and batch infrastructure for the radar;
6. social/import flows and any payment or checkout inside Iter.

The next implementation session must start by reading `AGENTS.md`, `HANDOFF.md`, `PRODUCT.md`, `DESIGN.md`, the organization specification, and this plan, then verifying the dirty worktree. It must not treat the current other-AI modules as approved or the existing handoff’s “real/live/complete” claims as evidence.

## Appendice tecnica operativa

Questa appendice rende il piano eseguibile anche da un agente che non ha seguito
la conversazione. Le regole qui sotto sono vincolanti quanto i task precedenti.
Quando una scelta tecnica sembra in conflitto con la specifica di prodotto, vince
la specifica; quando una scorciatoia sembra utile ma nasconde un dato mock come
live, la scorciatoia non è ammessa.

### A. Invarianti di prodotto da verificare in ogni task

| Invariante | Comportamento obbligatorio | Test minimo |
| --- | --- | --- |
| Home prevedibile | CTA fissa, carosello manuale e opportunità solo se pertinenti | `home_has_fixed_interaction_points` |
| Conversazione unica | Chat, schede, filtri e piano usano lo stesso `tripId` | `reopening_draft_reuses_session` |
| AI regista | AI sceglie prossima domanda, strumenti e spiegazione; non inventa dati | `ai_context_contains_only_allowed_signals` |
| Poche domande | 3–4 essenziali, massimo 2 adattive | `question_budget_rejects_overflow` |
| Partenza flessibile | Iter può proporre origine, aeroporto/stazione, mezzo e destinazione | `search_query_contains_alternatives` |
| Volo prima | Nessuna ricerca hotel prima della conferma del volo | `stay_is_blocked_before_flight_confirmation` |
| Zona prima dell’hotel | Le zone sono proposte e modificabili prima della ricerca soggiorno | `zone_change_creates_new_stay_query` |
| Conferma esplicita | Link aperto non significa acquistato/prenotato | `open_does_not_confirm` |
| Piano dopo conferme | Il piano completo richiede volo e soggiorno confermati | `plan_requires_two_confirmations` |
| Dato onesto | Mock, live, stimato, scaduto e non disponibile sono stati distinti | `demo_never_renders_as_live` |
| Profilo correggibile | Solo segnali confermati entrano nel profilo stabile | `inferred_signal_is_not_persisted` |
| Live separato | L’organizzazione non attiva né sceglie il viaggio live | `organization_never_sets_live_state` |

Prima di chiudere un task, l’implementatore deve indicare nella nota di verifica
quali invarianti sono coperte e quali appartengono a task successivi.

### B. Contratto dati canonico

Il codice attuale contiene modelli preliminari con mappe e liste mutabili. I
modelli finali devono seguire questo contratto. I nomi possono cambiare solo se
la modifica viene applicata in tutto il piano e nei test; non creare un secondo
modello semanticamente equivalente.

#### B.1 `TripIntent`

`TripIntent` è il desiderio corrente, non il profilo permanente e non una
ricerca già confermata.

```dart
enum IntentCompleteness { sparse, usable, searchReady }

class TripIntent {
  const TripIntent({
    required this.tripId,
    required this.rawDesire,
    required this.originCandidates,
    required this.destinationCandidates,
    required this.acceptedModes,
    required this.dateConstraint,
    required this.duration,
    required this.travelers,
    required this.budgetCentsPerPerson,
    required this.budgetTolerancePercent,
    required this.priorities,
    required this.avoidances,
    required this.profileSignalsUsed,
    required this.completeness,
  });

  final String tripId;
  final String rawDesire;
  final List<String> originCandidates;
  final List<String> destinationCandidates;
  final Set<TravelMode> acceptedModes;
  final DateConstraint? dateConstraint;
  final DurationRange? duration;
  final TravelerGroup travelers;
  final int? budgetCentsPerPerson;
  final int budgetTolerancePercent;
  final List<String> priorities;
  final List<String> avoidances;
  final Map<String, String> profileSignalsUsed;
  final IntentCompleteness completeness;
}
```

Rules:

- An empty candidate list means “not known yet”, not an implicit destination.
- `Milano`, `Roma` or `Budapest` may appear only when parsed from user input,
  supplied by a confirmed profile signal, or returned by the AI as a proposal
  backed by provider/search context.
- A default used by a deterministic test fixture must be marked `mock` and must
  never be copied into production UI text as if it were user intent.
- `profileSignalsUsed` contains references/explanations, not the complete
  private profile. It is visible and correctable through the conversation.

#### B.2 Date and traveler values

```dart
sealed class DateConstraint {
  const DateConstraint();
}

class ExactDates extends DateConstraint {
  const ExactDates({required this.departure, required this.returnDate});

  final DateTime departure;
  final DateTime returnDate;
}

class FlexibleDates extends DateConstraint {
  const FlexibleDates({
    required this.departures,
    required this.duration,
    required this.horizonEnd,
  });

  final List<DateTime> departures;
  final DurationRange duration;
  final DateTime horizonEnd;
}

class OpenDates extends DateConstraint {
  const OpenDates({required this.horizonEnd, this.duration});

  final DateTime horizonEnd;
  final DurationRange? duration;
}

class DurationRange {
  const DurationRange({required this.minimumDays, required this.maximumDays});

  final int minimumDays;
  final int maximumDays;
}

class TravelerGroup {
  const TravelerGroup({
    required this.kind,
    required this.adults,
    required this.children,
  });

  final TravelerKind kind;
  final int adults;
  final int children;
}

enum TravelerKind { solo, couple, friends, family }
```

Validation rules:

- All dates are local dates in the destination/search timezone when sent to a
  provider, and are serialized as ISO calendar dates without an accidental
  timezone shift.
- Return date must be later than departure date; the first vertical requires at
  least one night.
- Flexible departures may be disjoint dates. Never collapse them into one
  consecutive range unless the source is the saved “giorni liberi” snapshot.
- `adults >= 1`, `children >= 0`, and total travelers must be positive.
- A missing duration with open dates triggers a bounded multi-duration search,
  not a hardcoded three-day result.

#### B.3 `ProviderOffer`

```dart
enum OfferKind { flight, stay }
enum OfferTruthState { demo, live, estimated, stale, unavailable }

class ProviderOffer {
  const ProviderOffer({
    required this.id,
    required this.providerId,
    required this.kind,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.priceCents,
    required this.currency,
    required this.conditions,
    required this.mediaUrls,
    required this.externalBookingUrl,
    required this.fetchedAt,
    required this.expiresAt,
    required this.truthState,
    required this.tradeoffSummary,
  });

  final String id;
  final String providerId;
  final OfferKind kind;
  final String origin;
  final String destination;
  final DateTime departureDate;
  final DateTime returnDate;
  final int priceCents;
  final String currency;
  final Map<String, Object?> conditions;
  final List<String> mediaUrls;
  final Uri? externalBookingUrl;
  final DateTime fetchedAt;
  final DateTime? expiresAt;
  final OfferTruthState truthState;
  final String tradeoffSummary;
}
```

The normalizer must reject an offer with a negative price, invalid dates,
missing provider ID, a non-HTTPS booking URL, or a truth state that does not
match its source. `conditions` is read-only at the domain boundary and must
contain typed keys for the relevant offer kind:

- flight: airline, flight number, departure/arrival local times, duration,
  stops, airports, baggage, and fare conditions;
- stay: property name/type, zone ID, nights, cancellation, meal plan, total,
  distance/time to selected places, and room conditions.

No UI may infer `live` from the presence of a URL or from the provider ID.

#### B.4 `UserDecision`

```dart
enum DecisionTarget { flight, zone, stay, experience, plan }
enum DecisionStatus { selected, openedExternally, awaitingConfirmation, confirmed, superseded }

class UserDecision {
  const UserDecision({
    required this.id,
    required this.tripId,
    required this.target,
    required this.targetId,
    required this.status,
    required this.createdAt,
    required this.confirmedAt,
    required this.source,
  });

  final String id;
  final String tripId;
  final DecisionTarget target;
  final String targetId;
  final DecisionStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String source;
}
```

Rules:

- `selected` means “the user is considering this”, not “purchased”.
- `openedExternally` means Iter launched a partner link and is waiting for the
  user; it is not evidence of completion.
- A confirmed decision is append-only. A replacement creates a new decision and
  marks the old one `superseded`; it never edits the old object in place.
- A booking reference is optional, opaque, and never required to reach the
  explicit confirmation action in the first vertical.

### C. Event envelope and reducer rules

All organization events use one envelope so the thread, persistence, tests and
future remote transport can consume the same shape.

```dart
enum OrganizationEventKind {
  intentCreated,
  questionRequested,
  answerConfirmed,
  searchStarted,
  searchProgressed,
  searchPartialResults,
  searchCompleted,
  providerDegraded,
  offerExpired,
  flightSelected,
  externalPurchaseOpened,
  flightConfirmationRequested,
  flightConfirmed,
  experienceContextRequested,
  zoneProposed,
  staySearchStarted,
  stayPartialResults,
  staySelected,
  stayConfirmationRequested,
  stayConfirmed,
  planProposed,
  error,
}

class OrganizationEvent {
  const OrganizationEvent({
    required this.sequence,
    required this.tripId,
    required this.kind,
    required this.occurredAt,
    required this.payload,
  });

  final int sequence;
  final String tripId;
  final OrganizationEventKind kind;
  final DateTime occurredAt;
  final Map<String, Object?> payload;
}
```

Reducer rules:

1. The reducer is the only code allowed to mutate `OrganizationState`.
2. Events are emitted after the state transition has succeeded, except an
   error event, which describes the rejected command without changing the
   protected state.
3. Every async search carries a request ID. Results with an old request ID are
   ignored and do not alter cards, offers or phase.
4. Sequence numbers increase by exactly one per emitted event for one `tripId`.
5. The stream is closed when the session is disposed; no widget may own or
   manually close the session stream.
6. Serializing and restoring events must preserve decisions and freshness but
   must not restore an in-progress network request as if it completed.

### D. Allowed state-transition matrix

| Current phase | Command | Preconditions | Next phase | Required event/card |
| --- | --- | --- | --- | --- |
| `collectingIntent` | `startWithDesire` | non-empty user text | `collectingIntent` or `searchingTransport` | `intent.created`, summary, next question |
| `collectingIntent` | `answer` | matching open question and budget available | `collectingIntent` or `searchingTransport` | `answer.confirmed`, updated summary/question |
| `collectingIntent` | `startFlightSearch` | intent is `searchReady` | `searchingTransport` | `search.started`, status card |
| `searchingTransport` | provider update | matching request ID | `searchingTransport` or `awaitingFlightPurchase` | progress/partial/completed card update |
| `awaitingFlightPurchase` | `selectFlight` | offer is present and not stale | `awaitingFlightPurchase` | `flight.selected`, selected state |
| `awaitingFlightPurchase` | `openFlightPurchase` | selected offer has approved HTTPS URL | `awaitingFlightConfirmation` | `external.purchaseOpened` |
| `awaitingFlightConfirmation` | `confirmFlight` | selected offer and explicit user action | `collectingExperience` | `flight.confirmed`, experience request |
| `collectingExperience` | `submitExperience` | flight is confirmed | `proposingZones` | context accepted, zone request |
| `proposingZones` | `selectZone` | zone belongs to current proposal | `searchingStay` | `zone.proposed`, stay status |
| `searchingStay` | provider update | matching request ID and confirmed flight | `searchingStay` or `awaitingStayPurchase` | stay progress/partial/completed |
| `awaitingStayPurchase` | `selectStay` | offer belongs to selected zone and is fresh | `awaitingStayPurchase` | `stay.selected` |
| `awaitingStayPurchase` | `openStayPurchase` | selected offer has approved HTTPS URL | `awaitingStayConfirmation` | `external.purchaseOpened` |
| `awaitingStayConfirmation` | `confirmStay` | explicit user action | `readyForPlan` | `stay.confirmed`, plan action |
| `readyForPlan` | `proposePlan` | flight and stay confirmed | `readyForPlan` | `plan.proposed` |

Rejected commands emit `error` with a stable code and keep the previous phase.
The initial stable error codes are:

```text
empty_desire
question_not_open
question_budget_exceeded
intent_not_search_ready
search_already_running
offer_not_found
offer_stale
offer_not_selected
external_url_not_allowed
flight_not_confirmed
zone_not_found
stay_not_available
stay_not_confirmed
plan_prerequisites_missing
obsolete_request
session_disposed
```

The UI copy may be localized, but tests assert the stable error code and the
presence of an actionable next step.

### E. Event-to-card mapping

The thread renderer must use this table. A new event must not silently become a
plain text bubble if it represents an actionable decision.

| Event | Card | Primary action | Secondary action | Data that must remain visible |
| --- | --- | --- | --- | --- |
| `intent.created` | `IntentSummaryCard` | Modifica | — | raw desire, interpreted constraints, profile signals used |
| `question.requested` | `QuestionCard` | Select/submit answer | `Non lo so` / `Decidi tu` where valid | question reason, progress budget, options |
| `search.started/progressed` | `SearchStatusCard` | Cambia criteri / Annulla | — | actual stage, provider, request time |
| `search.partialResults/completed` | `FlightComparisonCard` | Seleziona | Filtri/ordinamento/Correggi | airports, times, stops, price, source, freshness, tradeoff |
| `external.purchaseOpened` | `ExternalPurchaseCard` | Ho acquistato questo volo/hotel | Non ancora | partner, selected offer, state awaiting confirmation |
| `flight.confirmationRequested` | `FlightConfirmationCard` | Conferma volo | Cambia scelta | frozen dates/airports/conditions |
| `experienceContextRequested` | `ExperienceCard` | Conferma priorità | Modifica risposta | pace, interests, walking/transit tolerance |
| `zone.proposed` | `ZoneProposalCard` | Usa questa zona | Confronta/Modifica | rationale, places/events, airport connection, compromise |
| `stay.partialResults/completed` | `StayComparisonCard` | Seleziona | Filtri/Correggi | zone, hotel facts, price, source, freshness, transport |
| `stay.confirmationRequested` | `StayConfirmationCard` | Conferma soggiorno | Cambia scelta | dates, zone, property, conditions |
| `plan.proposed` | `PlanProposalCard` | Vedi/Conferma piano | Modifica | confirmed facts vs proposed activities |
| `provider.degraded/error` | DegradedStateCard | Riprova / Modifica | Continua senza fonte where valid | provider, reason, last verified time |
| `offer.expired` | StaleOfferCard | Aggiorna ricerca | Mantieni alternativa | old price, expiry, replacement action |

Each card receives a read-only `OrganizationCardContext`:

```dart
class OrganizationCardContext {
  const OrganizationCardContext({
    required this.tripId,
    required this.cardId,
    required this.state,
    required this.source,
    required this.verifiedAt,
    required this.expiresAt,
  });

  final String tripId;
  final String cardId;
  final OrganizationCardState state;
  final String? source;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
}
```

The renderer does not call a provider, parse free-form JSON, change the phase,
or write to the controller directly. It emits a typed card action that the
session validates.

### F. Exact integration map for the existing Flutter app

The following is the only intended path through the current app:

```text
lib/main.dart
  → lib/app/app_entry.dart
  → lib/features/chat_first_prototype/chat_first_app.dart
  → lib/features/chat_first_prototype/chat_first_shell.dart
  → lib/features/chat_first_prototype/chat_first_home_screen.dart
  → ChatFirstPrototypeController.startFreeTalk()
  → OrganizationSessionRegistry.getOrCreate(conversationId)
  → lib/features/chat_first_prototype/chat_first_thread_screen.dart
  → OrganizationThreadRenderer
  → OrganizationSession command
  → OrganizationEvent stream
  → controller/thread rebuild
```

File responsibilities:

- `chat_first_app.dart`: construct injected dependencies; select mock mode by
  default; select real backend ports only from explicit configuration; do not
  decide organization phases.
- `chat_first_controller.dart`: own conversation/session lookup, bridge thread
  lifecycle and persistence, expose read-only session state; do not duplicate
  the state reducer.
- `chat_first_shell.dart`: provide callbacks and route to the thread; do not
  present a mode chooser or instantiate provider clients in a widget.
- `chat_first_home_screen.dart`: render fixed Home sections and invoke the CTA;
  do not parse a destination or start a wizard locally.
- `chat_first_thread_screen.dart`: render ordinary messages and organization
  cards in chronological order; forward typed actions; preserve composer text.
- `organization_session.dart`: own one `tripId`, reducer, request IDs and event
  stream; do not know about Flutter widgets or Navigator.
- `organization_session_registry.dart`: guarantee one session per conversation
  ID and dispose sessions only when their owning conversation is removed.
- `organization_thread_renderer.dart`: map state/events to card widgets; no
  business rules or provider calls.
- `trip_snapshot_screen.dart`: remain the editable plan surface; receive a
  confirmed plan proposal and keep existing preview → confirm → revision.

The following paths are explicitly forbidden:

- Home CTA → `NewTripPlannerSheet` for the organization vertical;
- Home CTA → three choices `Organizza/Scegli/Sono in viaggio`;
- thread card → direct database write without a session command;
- widget → direct call to `fast-flights`, Vio, Trivago, Gemini, or a scraper;
- selected flight → hotel search before external confirmation;
- link opened → `purchased`/`confirmed` state;
- organization session → live-trip resolver or GPS listener.

### G. Question decision table

The AI may reorder these questions, but the deterministic gate decides whether a
question is still needed. A question is allowed only when its answer can change
the search query or a meaningful tradeoff.

| Area | Essential when | Input control | Stored field | Example reason shown to user |
| --- | --- | --- | --- | --- |
| Origin | no reliable origin candidate | text/chips/location while in use | `originCandidates` | “Cambia molto il prezzo: posso confrontare più partenze.” |
| Dates | no exact/flexible/open constraint | calendar/date options | `dateConstraint` | “Con più finestre posso cercare combinazioni meno costose.” |
| Duration | dates are open or duration missing | chips/range | `duration` | “Serve per non confrontare weekend e settimane come se fossero uguali.” |
| Travelers | group is unknown | chips/counter | `travelers` | “Il numero di persone cambia prezzo e camere disponibili.” |
| Transport | no accepted mode or all modes are allowed but unclear | multi-select | `acceptedModes` | “Posso includere treno o bus se migliorano il rapporto tempo/prezzo.” |
| Budget | no usable limit and price is a hard constraint | amount/tolerance | budget fields | “Mi serve un limite per evitare proposte fuori scala.” |
| Travel form | profile and desire do not distinguish pace/interests | chips/text | priorities/avoidances | “Questa risposta cambia zona e attività, non è un questionario generale.” |

Adaptive questions after flight confirmation are limited to:

- pace and density of activities;
- food/culture/nature/night/relax priorities;
- walking and public-transport tolerance;
- one base versus multiple moves;
- specific places/events that alter zone ranking.

The session must refuse a question if:

- the same semantic field is already confirmed for the current trip;
- the answer would not change a query, ranking, zone or plan;
- the question budget is exhausted;
- the question is only intended to make the conversation feel intelligent.

### H. Provider execution and no-cost gate

Provider implementation is split into capability, normalization and execution.
The existence of a repository or public URL is not evidence that a production
provider is available.

#### H.1 Capability record

Every provider has a checked record:

```dart
class ProviderCapabilityRecord {
  const ProviderCapabilityRecord({
    required this.providerId,
    required this.kind,
    required this.state,
    required this.checkedAt,
    required this.executionLocation,
    required this.costModel,
    required this.limitations,
  });

  final String providerId;
  final OfferKind kind;
  final ProviderCapabilityState state;
  final DateTime checkedAt;
  final String executionLocation;
  final String costModel;
  final List<String> limitations;
}
```

Allowed capability states:

- `verified`: current request path was executed successfully, response was
  normalized, and cost/terms are documented;
- `mockOnly`: deterministic fixture is available only in mock/test mode;
- `unavailable`: no approved provider path is configured or the last request
  failed in a way that must remain visible.

#### H.2 Flight provider checklist

Before enabling a `fast-flights` adapter:

1. Run a disposable backend-side request with a known test route.
2. Record the exact input/output shape and all fields needed by `ProviderOffer`.
3. Verify that flexible dates and multiple origin/destination combinations can
   be represented without inventing alternatives.
4. Record scraper blocking, rate, caching and terms limitations.
5. Decide where the process runs without adding a secret or scraper to Flutter.
6. Add a contract fixture containing source, fetched time, expiry behavior and a
   provider error response.
7. Keep the capability `mockOnly` until all seven checks are evidenced.

If the provider cannot pass the gate, the production result is a visible
`provider.degraded` state; the UI must not silently switch to the current
hardcoded `FlightSearchService` fixtures.

#### H.3 Hotel provider checklist

For Vio, Trivago or another partner, verify before adding an adapter:

- legal/partner access for a free or no-fixed-cost Iter integration;
- search by coordinates/zone and fixed dates;
- total price, taxes/conditions, cancellation, images and availability;
- deep link behavior and allowed redirect hosts;
- rate limits, attribution and caching rules;
- whether the partner permits the intended comparison experience.

Until verified, use `UnavailableStaySearchProvider` outside explicit mock mode.
Do not fill unavailable hotel cards with the existing named fixture properties.

### I. Mock fixture contract

Mock mode is useful for completing the UX and test path, but every fixture must
be visibly distinguishable from live data.

The fixture set must include:

- at least three flight alternatives with different price, duration and stop
  tradeoffs;
- at least two flexible departure dates and one exact-date query;
- two origin/airport alternatives where the query asks for them;
- one expired flight offer and one provider-degraded result;
- two zone proposals with different atmosphere/connection compromises;
- at least three stay alternatives per zone in mock mode, with total price,
  cancellation, distance and source labels;
- one unavailable stay provider path;
- one profile signal marked confirmed and one inferred signal that is not saved;
- one media-rich place/event card and one card with no media;
- one partial-result sequence followed by a completion event.

Every mock fixture uses:

```text
truthState = demo
providerId = mock-<kind>
sourceLabel = Dati demo
fetchedAt = fixed test clock
expiresAt = fixed test clock + declared duration
```

Tests must assert both the useful content and the truth label. A fixture test
that checks only “Ryanair” or “€54” is insufficient.

### J. Persistence and restoration rules

The first vertical may run completely in memory in mock mode, but its boundary
must make future persistence possible without changing the state machine.

Persistable records are:

```text
organization_sessions(trip_id, owner_id, phase, updated_at, version)
organization_events(trip_id, sequence, kind, payload, occurred_at)
organization_decisions(trip_id, target, target_id, status, confirmed_at)
organization_searches(trip_id, request_id, kind, query, provider_state, expires_at)
```

Rules for any future Supabase migration:

- `owner_id` is checked against `auth.uid()` in both read and write policies;
- exposed tables have RLS enabled and explicit grants;
- `UPDATE` policies include both ownership `USING` and `WITH CHECK` where needed;
- no user-editable metadata claim is used for authorization;
- a service-role key is never used by Flutter;
- accepted decisions and plan revisions are append-only from the user’s point
  of view;
- restoring a session never replays a stale network result as fresh.

For the first implementation, `ChatFirstPrototypeController` may keep a
registry in memory. The registry API must nevertheless make it possible to
replace the backing store later:

```dart
abstract interface class OrganizationSessionStore {
  Future<OrganizationState?> load(String tripId);
  Future<void> append(OrganizationEvent event);
  Future<void> saveState(OrganizationState state);
}
```

`MockOrganizationSessionStore` is deterministic and local. A future Supabase
store is not part of the first mock acceptance gate and must not be introduced
just to make the demo look persistent.

### K. AI gateway request/response contract

The AI gateway receives facts and constraints; it does not receive authority to
change state directly.

Request shape:

```json
{
  "tripId": "conversation-id",
  "operation": "next_step",
  "intent": {
    "rawDesire": "Vorrei staccare qualche giorno",
    "originCandidates": ["Firenze"],
    "destinationCandidates": [],
    "dateConstraint": {"kind": "flexible", "departures": ["2026-11-12"]},
    "acceptedModes": ["flight", "train"],
    "budgetCentsPerPerson": 400
  },
  "profileSignals": [
    {"key": "prefers_local_food", "value": "confirmed", "source": "trip-12"}
  ],
  "providerResults": [],
  "questionBudget": {"essentialRemaining": 3, "adaptiveRemaining": 2}
}
```

Response event shape:

```json
{
  "type": "question",
  "tripId": "conversation-id",
  "question": {
    "key": "transport_modes",
    "prompt": "Posso includere treno e bus se convengono?",
    "essential": true,
    "options": ["Volo", "Treno", "Qualsiasi, se conviene"]
  },
  "reason": "Cambierà le combinazioni che posso confrontare.",
  "clientRequestId": "request-1"
}
```

Backend rules:

- Validate `tripId`, operation, field types, payload size and allowed profile
  signal shape before calling Gemini.
- Verify the forwarded access token and derive the user identity from the
  validated session.
- Check ownership before reading or writing trip-scoped data.
- Consume `public.consume_ai_credit` before a paid/free-tier generation.
- Return a typed quota/provider error; never generate a destination or offer as
  a fallback after an authenticated provider failure.
- Keep the deterministic gateway available only through explicit mock config or
  test injection.
- Log provider status and request ID without logging raw personal messages or
  secrets.

### L. Voice, media and motion acceptance details

#### L.1 Voice

The voice interaction has four observable states:

```text
idle → recording → transcriptReady → userConfirmedSend
```

Required behavior:

- permission denial returns to `idle` with a text explanation;
- stopping recording writes editable transcript text into the same composer;
- transcript is not sent until the user taps send/confirm;
- failed transcription leaves the recording/error action visible;
- a transcript has the same `tripId` and message ordering as typed text;
- tests can inject a fake recorder/transcriber and never require a microphone.

#### L.2 Media

- An image/video attachment belongs to the current organization message.
- The card states why the media is being used or says that it is only attached,
  not analyzed.
- Missing media source, unsupported format or denied permission is an honest
  actionable error, not a blank card.
- Images/videos used for a recommendation carry source/attribution metadata or
  the card remains text-only.

#### L.3 Motion

- Searching animation is driven by `SearchStatusCard` state changes.
- A status line must name the actual operation: `Confronto le partenze`,
  `Verifico le condizioni`, `Cerco hotel nella zona scelta`.
- No “AI is thinking” stream, fake percent, fake provider logo or fixed delay is
  allowed.
- With `MediaQuery.disableAnimations`, the same text/events appear immediately
  or crossfade.
- Partial results stay in the same card and do not jump the user to another
  route.

### M. Test catalog before claiming completion

The following test names are the minimum contract. The implementation may use
different grouping, but each behavior must be covered.

#### M.1 Domain/model tests

```text
TripIntent copies lists and maps defensively
TripIntent allows explicit nullable clearing in copyWith
ExactDates rejects return before departure
FlexibleDates preserves disjoint departures
ProviderOffer rejects invalid price and URL
ProviderOffer truth state survives serialization
UserDecision equality and hashCode agree
OrganizationCard equality and hashCode agree
OrganizationState exposes unmodifiable collections
```

#### M.2 Reducer/session tests

```text
startWithDesire emits intent summary and one justified question
answer updates only the matching question field
question budget caps essential and adaptive questions
search cannot start without search-ready intent
search emits started/progress/partial/completed in sequence
obsolete search results cannot overwrite current state
provider failure returns to actionable non-searching state
selecting flight does not confirm flight
opening flight URL does not confirm flight
confirming flight freezes transport facts
flight change marks zone/stay state stale
experience context is requested after flight confirmation only
zone selection starts stay query with fixed flight facts
stay cannot start without confirmed flight
selecting stay does not confirm stay
confirming stay unlocks plan proposal only
plan cannot be proposed with missing confirmation
repeated confirmations are idempotent
disposed session rejects new commands
```

#### M.3 Integration/widget tests

```text
Home CTA opens organization thread without mode chooser
Home CTA does not open NewTripPlannerSheet
free text renders intent card in the actual thread
voice transcript remains editable before send
organization cards appear in chronological chat order
card actions call session commands rather than widget-local mutations
reopening a conversation reuses its session and tripId
Home hides empty opportunities slot
Home carousel does not auto-advance
flight comparison reorders visible offers
flight card shows source/freshness/truth state
external purchase card has explicit confirmation action
hotel card is absent before flight confirmation
zone card appears before stay card
stay card contains zone/profile rationale
plan card appears only after stay confirmation
all cards remain usable at 320/360/390 dp
all cards remain usable at text scale 1.5
dark mode and disableAnimations retain equivalent text state
```

#### M.4 Backend contract tests

```text
missing bearer token returns 401
expired bearer token returns 401
valid user token resolves auth.uid
foreign tripId is rejected
quota is consumed before generation
quota exhaustion returns typed error event
provider failure is not converted to mock success
malformed AI JSON returns typed provider error
oversized request is rejected
production CORS does not use wildcard
```

### N. Task-by-task stop conditions

An implementer must stop and report rather than continuing when any of these
conditions occurs:

- the current dirty file is not listed in the active task and its ownership is
  unclear;
- a provider requires a key, paid account, scraping bypass or remote deployment
  not explicitly authorized;
- a state transition would need to bypass a confirmation gate;
- an existing test expects the old behavior and the specification does not
  clearly authorize changing it;
- a real provider response cannot supply the freshness/source fields required by
  the card;
- a remote Supabase schema differs from the migration precondition;
- a visual state can only be represented by a fake loading/reasoning animation;
- a fix would connect the Nuovo viaggio Lab to the organization session;
- `flutter analyze`, focused tests or the release build fail twice for the same
  reason without a new diagnosis.

When stopping, record the exact command, error, affected files, and the smallest
safe alternative. Do not “solve” the stop condition by weakening a test,
silently switching to fixture data, or editing unrelated files.

### O. Completion report template

At the end of the vertical, the handoff must use this structure:

```text
Branch/status:
- branch:
- commit base:
- dirty files intentionally changed:
- untracked files intentionally left untouched:

Implemented:
- organization phases:
- Home interactions:
- flight flow:
- zone/stay flow:
- plan mapping:
- AI/voice/media:

Verified:
- focused tests:
- full flutter test count:
- flutter analyze:
- flutter build web --release:
- Browser QA widths/themes/motion:

Truth boundaries:
- verified live providers:
- mock-only providers:
- unavailable providers:
- estimated/editorial content:
- remaining authentication or commercial checks:

Deferred:
- automatic live activation:
- one-active-trip enforcement:
- radar/batch:
- automatic booking confirmation:
- payment/checkout/social import:

Next user decision:
- exact task or provider decision needed:
```

The report must not use “completo”, “reale”, “live”, “gratuito” or “100%”
without the corresponding evidence in the same report.
