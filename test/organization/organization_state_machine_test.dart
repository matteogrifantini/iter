import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/engine/organization_reducer.dart';
import 'package:iter/features/organization/events/organization_events.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';

void main() {
  group('Organization State Machine & Reducer Tests', () {
    final now = DateTime(2026, 9, 1, 10, 0);

    test('Canonical phase transition flow from intent to readyForPlan', () {
      var state = OrganizationState(
        tripId: 'trip-sm-1',
        phase: OrganizationPhase.collectingIntent,
        intent: TripIntent(
          tripId: 'trip-sm-1',
          rawDesire: 'Lisbona a novembre',
        ),
      );

      // 1. Intent created
      state = reduceOrganizationState(
        state,
        IntentCreatedEvent(
          sequence: 1,
          tripId: 'trip-sm-1',
          intent: state.intent,
        ),
      );
      expect(state.phase, OrganizationPhase.collectingIntent);
      expect(state.cards.length, 1);
      expect(state.cards.first.kind, OrganizationCardKind.intentSummary);

      // 2. Question requested
      state = reduceOrganizationState(
        state,
        QuestionRequestedEvent(
          sequence: 2,
          tripId: 'trip-sm-1',
          questionKey: 'origin',
          questionText: 'Da dove parti?',
          options: const ['Roma', 'Milano'],
        ),
      );
      expect(state.phase, OrganizationPhase.collectingIntent);
      expect(state.cards.length, 2);

      // 3. Answer confirmed
      state = reduceOrganizationState(
        state,
        UserAnswerConfirmedEvent(
          sequence: 3,
          tripId: 'trip-sm-1',
          questionKey: 'origin',
          answer: 'Roma',
        ),
      );
      expect(state.cards.last.state, OrganizationCardState.confirmed);

      // 4. Flight search started -> searchingTransport
      state = reduceOrganizationState(
        state,
        SearchStartedEvent(
          sequence: 4,
          tripId: 'trip-sm-1',
          sessionId: 'sess-1',
          targetType: OfferKind.flight,
        ),
      );
      expect(state.phase, OrganizationPhase.searchingTransport);

      // 5. Search completed -> awaitingFlightPurchase
      state = reduceOrganizationState(
        state,
        SearchCompletedEvent(
          sequence: 5,
          tripId: 'trip-sm-1',
          sessionId: 'sess-1',
          totalOffersFound: 3,
        ),
      );
      expect(state.phase, OrganizationPhase.awaitingFlightPurchase);

      // 6. Flight selected
      state = reduceOrganizationState(
        state,
        FlightSelectedEvent(
          sequence: 6,
          tripId: 'trip-sm-1',
          flightOfferId: 'mock-flight-1',
          decision: const UserDecision(
            id: 'dec-1',
            tripId: 'trip-sm-1',
            target: DecisionTarget.flight,
            targetId: 'mock-flight-1',
          ),
        ),
      );
      expect(state.phase, OrganizationPhase.awaitingFlightPurchase);
      expect(state.decisions.length, 1);

      // 7. External purchase link opened -> awaitingFlightConfirmation (NOT confirmed)
      state = reduceOrganizationState(
        state,
        ExternalPurchaseOpenedEvent(
          sequence: 7,
          tripId: 'trip-sm-1',
          targetOfferId: 'mock-flight-1',
          url: 'https://ryanair.com/buy',
        ),
      );
      expect(state.phase, OrganizationPhase.awaitingFlightConfirmation);
      expect(state.confirmedFlight, isNull);

      // 8. Flight confirmed explicitly by user -> collectingExperience
      state = reduceOrganizationState(
        state,
        FlightConfirmedEvent(
          sequence: 8,
          tripId: 'trip-sm-1',
          flightOfferId: 'mock-flight-1',
          decision: const UserDecision(
            id: 'dec-1',
            tripId: 'trip-sm-1',
            target: DecisionTarget.flight,
            targetId: 'mock-flight-1',
            status: DecisionStatus.confirmed,
          ),
        ),
      );
      expect(state.phase, OrganizationPhase.collectingExperience);
      expect(state.confirmedFlight, isNotNull);

      // 9. Zone proposed -> proposingZones
      state = reduceOrganizationState(
        state,
        ZoneProposedEvent(
          sequence: 9,
          tripId: 'trip-sm-1',
          zoneNames: const ['Alfama', 'Baixa'],
          motivationSummary: 'Zone storiche ideali',
        ),
      );
      expect(state.phase, OrganizationPhase.proposingZones);

      // 10. Stay search started -> searchingStay
      state = reduceOrganizationState(
        state,
        StaySearchStartedEvent(
          sequence: 10,
          tripId: 'trip-sm-1',
          sessionId: 'sess-stay-1',
          zone: 'Alfama',
        ),
      );
      expect(state.phase, OrganizationPhase.searchingStay);

      // 11. Search completed -> awaitingStayPurchase
      state = reduceOrganizationState(
        state,
        SearchCompletedEvent(
          sequence: 11,
          tripId: 'trip-sm-1',
          sessionId: 'sess-stay-1',
          totalOffersFound: 2,
        ),
      );
      expect(state.phase, OrganizationPhase.awaitingStayPurchase);

      // 12. Stay confirmed explicitly -> readyForPlan
      state = reduceOrganizationState(
        state,
        StayConfirmedEvent(
          sequence: 12,
          tripId: 'trip-sm-1',
          stayOfferId: 'stay-1',
          decision: const UserDecision(
            id: 'dec-stay-1',
            tripId: 'trip-sm-1',
            target: DecisionTarget.stay,
            targetId: 'stay-1',
            status: DecisionStatus.confirmed,
          ),
        ),
      );
      expect(state.phase, OrganizationPhase.readyForPlan);
      expect(state.confirmedStay, isNotNull);

      // 13. Plan proposed
      state = reduceOrganizationState(
        state,
        PlanProposedEvent(
          sequence: 13,
          tripId: 'trip-sm-1',
          planCard: const OrganizationCard(
            id: 'plan-1',
            tripId: 'trip-sm-1',
            kind: OrganizationCardKind.planProposal,
          ),
        ),
      );
      expect(state.phase, OrganizationPhase.readyForPlan);
      expect(
        state.cards.any((c) => c.kind == OrganizationCardKind.planProposal),
        isTrue,
      );
    });

    test('Invariants: Stay search is blocked if flight is not confirmed', () {
      final unconfirmedFlightState = OrganizationState(
        tripId: 'trip-inv-1',
        phase: OrganizationPhase.awaitingFlightPurchase,
        intent: TripIntent(tripId: 'trip-inv-1', rawDesire: 'Lisbona'),
        confirmedFlight: null, // Flight NOT confirmed
      );

      final result = reduceOrganizationState(
        unconfirmedFlightState,
        StaySearchStartedEvent(
          sequence: 1,
          tripId: 'trip-inv-1',
          sessionId: 'sess-stay-inv',
          zone: 'Alfama',
        ),
      );

      // Must remain in previous phase and not mutate
      expect(result.phase, OrganizationPhase.awaitingFlightPurchase);
      expect(result.cards, isEmpty);
    });

    test('Invariants: Plan proposed is blocked if stay is not confirmed', () {
      final flightOnlyState = OrganizationState(
        tripId: 'trip-inv-2',
        phase: OrganizationPhase.awaitingStayPurchase,
        intent: TripIntent(tripId: 'trip-inv-2', rawDesire: 'Lisbona'),
        confirmedFlight: ProviderOffer(
          id: 'f-1',
          providerId: 'mock-flights',
          kind: OfferKind.flight,
          origin: 'FCO',
          destination: 'LIS',
          departureDate: now,
          priceCents: 5000,
          externalBookingUrl: 'https://example.com',
          fetchedAt: now,
          tradeoffSummary: 'Summary',
        ),
        confirmedStay: null, // Stay NOT confirmed
      );

      final result = reduceOrganizationState(
        flightOnlyState,
        PlanProposedEvent(
          sequence: 1,
          tripId: 'trip-inv-2',
          planCard: const OrganizationCard(
            id: 'plan-card-inv',
            tripId: 'trip-inv-2',
            kind: OrganizationCardKind.planProposal,
          ),
        ),
      );

      // Must remain in awaitingStayPurchase and not add plan card
      expect(result.phase, OrganizationPhase.awaitingStayPurchase);
      expect(result.cards, isEmpty);
    });

    test('Invariants: Error event does not mutate protected state', () {
      final initial = OrganizationState(
        tripId: 'trip-err-1',
        phase: OrganizationPhase.collectingIntent,
        intent: TripIntent(tripId: 'trip-err-1', rawDesire: 'Porto'),
      );

      final result = reduceOrganizationState(
        initial,
        OrganizationEvent(
          sequence: 1,
          tripId: 'trip-err-1',
          kind: OrganizationEventKind.error,
          payload: const {'code': 'offer_stale'},
        ),
      );

      expect(result, equals(initial));
    });
  });
}
