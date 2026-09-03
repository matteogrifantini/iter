import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/events/organization_events.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';

void main() {
  group('Organization Events Specification Conformance', () {
    final now = DateTime(2026, 9, 1, 10, 0);

    test('Canonical envelope fields and unmodifiable payload', () {
      final event = OrganizationEvent(
        sequence: 1,
        tripId: 'trip-env',
        kind: OrganizationEventKind.intentCreated,
        occurredAt: now,
        payload: <String, Object?>{
          'rawDesire': 'Voglio andare a Lisbona',
          'budget': 400,
        },
      );

      expect(event.sequence, 1);
      expect(event.tripId, 'trip-env');
      expect(event.kind, OrganizationEventKind.intentCreated);
      expect(event.occurredAt, now);
      expect(event.payload['rawDesire'], 'Voglio andare a Lisbona');
      expect(event.payload['budget'], 400);

      // Payload is defensively unmodifiable
      expect(
        () => (event.payload as Map)['extra'] = 'val',
        throwsUnsupportedError,
      );
    });

    test('OrganizationEvent equality and hashCode agree', () {
      final ev1 = OrganizationEvent(
        sequence: 2,
        tripId: 'trip-1',
        kind: OrganizationEventKind.searchStarted,
        occurredAt: now,
        payload: const <String, Object?>{'mode': 'flight'},
      );

      final ev2 = OrganizationEvent(
        sequence: 2,
        tripId: 'trip-1',
        kind: OrganizationEventKind.searchStarted,
        occurredAt: now,
        payload: const <String, Object?>{'mode': 'flight'},
      );

      expect(ev1, equals(ev2));
      expect(ev1.hashCode, equals(ev2.hashCode));
    });

    test('Intent and Question events adhere to specs', () {
      final intent = TripIntent(
        id: 'trip-1',
        text: 'Qualche giorno a novembre con buon cibo',
      );

      final intentEvent = IntentCreatedEvent(
        id: 'evt-1',
        tripId: 'trip-1',
        timestamp: now,
        intent: intent,
      );
      expect(intentEvent.type, 'intent.created');
      expect(intentEvent.kind, OrganizationEventKind.intentCreated);
      expect(intentEvent.intent.text, contains('novembre'));

      final questionEvent = QuestionRequestedEvent(
        id: 'evt-2',
        tripId: 'trip-1',
        timestamp: now,
        questionKey: 'origin',
        questionText: 'Da dove ti è più comodo partire?',
        options: const <String>['Firenze', 'Pisa', 'Bologna', 'Roma'],
      );
      expect(questionEvent.type, 'question.requested');
      expect(questionEvent.kind, OrganizationEventKind.questionRequested);
      expect(questionEvent.options.length, 4);

      final answerEvent = UserAnswerConfirmedEvent(
        id: 'evt-3',
        tripId: 'trip-1',
        timestamp: now,
        questionKey: 'origin',
        answer: 'Firenze',
      );
      expect(answerEvent.type, 'user.answer.confirmed');
      expect(answerEvent.kind, OrganizationEventKind.answerConfirmed);
      expect(answerEvent.answer, 'Firenze');
    });

    test('Search lifecycle events adhere to specs', () {
      final searchStart = SearchStartedEvent(
        id: 'evt-4',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-1',
        targetType: OfferKind.flight,
        providers: const <String>['mock-flights'],
      );
      expect(searchStart.type, 'search.started');
      expect(searchStart.kind, OrganizationEventKind.searchStarted);
      expect(searchStart.targetType, OfferKind.flight);

      final searchProgress = SearchProgressedEvent(
        id: 'evt-5',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-1',
        stageMessage: 'Confronto rotte da FCO e PSA verso Lisbona e Porto...',
      );
      expect(searchProgress.type, 'search.progressed');
      expect(searchProgress.kind, OrganizationEventKind.searchProgressed);

      final partialResults = SearchPartialResultsEvent(
        id: 'evt-6',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-1',
        offers: <ProviderOffer>[
          ProviderOffer(
            id: 'off-1',
            providerId: 'mock-flights',
            type: OfferKind.flight,
            origin: 'FCO',
            destination: 'LIS',
            departureDate: DateTime(2026, 11, 10),
            priceEur: 54.0,
            externalBookingUrl: 'https://partner.com/buy',
            fetchedAt: now,
            tradeoffSummary: 'Volo diretto',
          ),
        ],
      );
      expect(partialResults.type, 'search.partialResults');
      expect(partialResults.kind, OrganizationEventKind.searchPartialResults);
      expect(partialResults.offers.length, 1);

      final completed = SearchCompletedEvent(
        id: 'evt-7',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-1',
        totalOffersFound: 6,
      );
      expect(completed.type, 'search.completed');
      expect(completed.kind, OrganizationEventKind.searchCompleted);
      expect(completed.totalOffersFound, 6);
    });

    test('Flight and stay confirmation events adhere to specs', () {
      const decision = UserDecision(
        id: 'dec-flight-1',
        tripId: 'trip-1',
        target: DecisionTarget.flight,
        targetId: 'off-1',
      );

      final flightSelected = FlightSelectedEvent(
        id: 'evt-8',
        tripId: 'trip-1',
        timestamp: now,
        flightOfferId: 'off-1',
        decision: decision,
      );
      expect(flightSelected.type, 'flight.selected');
      expect(flightSelected.kind, OrganizationEventKind.flightSelected);

      final externalOpen = ExternalPurchaseOpenedEvent(
        id: 'evt-9',
        tripId: 'trip-1',
        timestamp: now,
        targetType: OfferKind.flight,
        targetOfferId: 'off-1',
        url: 'https://partner.com/buy',
      );
      expect(externalOpen.type, 'external.purchaseOpened');
      expect(externalOpen.kind, OrganizationEventKind.externalPurchaseOpened);

      final confirmRequested = FlightConfirmationRequestedEvent(
        id: 'evt-10',
        tripId: 'trip-1',
        timestamp: now,
        flightOfferId: 'off-1',
      );
      expect(confirmRequested.type, 'flight.confirmationRequested');
      expect(
        confirmRequested.kind,
        OrganizationEventKind.flightConfirmationRequested,
      );

      final flightConfirmed = FlightConfirmedEvent(
        id: 'evt-11',
        tripId: 'trip-1',
        timestamp: now,
        flightOfferId: 'off-1',
        decision: decision.copyWith(
          status: DecisionStatus.confirmed,
          confirmedAt: now,
        ),
      );
      expect(flightConfirmed.type, 'flight.confirmed');
      expect(flightConfirmed.kind, OrganizationEventKind.flightConfirmed);
      expect(flightConfirmed.decision.isConfirmed, isTrue);

      final expContext = ExperienceContextRequestedEvent(
        id: 'evt-12',
        tripId: 'trip-1',
        timestamp: now,
        destination: 'Lisbona',
      );
      expect(expContext.type, 'experience.contextRequested');
      expect(expContext.kind, OrganizationEventKind.experienceContextRequested);

      final zoneProposed = ZoneProposedEvent(
        id: 'evt-13',
        tripId: 'trip-1',
        timestamp: now,
        zoneNames: const <String>['Alfama', 'Baixa-Chiado', 'Príncipe Real'],
        motivationSummary: 'Zone centrali vicine ai ristoranti autentici.',
      );
      expect(zoneProposed.type, 'zone.proposed');
      expect(zoneProposed.kind, OrganizationEventKind.zoneProposed);

      final staySearch = StaySearchStartedEvent(
        id: 'evt-14',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-stay-1',
        zone: 'Alfama',
      );
      expect(staySearch.type, 'stay.searchStarted');
      expect(staySearch.kind, OrganizationEventKind.staySearchStarted);

      final stayPartial = StayPartialResultsEvent(
        id: 'evt-15',
        tripId: 'trip-1',
        timestamp: now,
        sessionId: 'sess-stay-1',
        stays: const <ProviderOffer>[],
      );
      expect(stayPartial.type, 'stay.partialResults');
      expect(stayPartial.kind, OrganizationEventKind.stayPartialResults);

      final staySelected = StaySelectedEvent(
        id: 'evt-16',
        tripId: 'trip-1',
        timestamp: now,
        stayOfferId: 'stay-1',
        decision: decision.copyWith(target: DecisionTarget.stay),
      );
      expect(staySelected.type, 'stay.selected');
      expect(staySelected.kind, OrganizationEventKind.staySelected);

      final stayConfirmed = StayConfirmedEvent(
        id: 'evt-17',
        tripId: 'trip-1',
        timestamp: now,
        stayOfferId: 'stay-1',
        decision: decision.copyWith(
          target: DecisionTarget.stay,
          status: DecisionStatus.confirmed,
          confirmedAt: now,
        ),
      );
      expect(stayConfirmed.type, 'stay.confirmed');
      expect(stayConfirmed.kind, OrganizationEventKind.stayConfirmed);
    });

    test('Plan, degradation and expiration events adhere to specs', () {
      final planProposed = PlanProposedEvent(
        id: 'evt-18',
        tripId: 'trip-1',
        timestamp: now,
        planCard: const OrganizationCard(
          id: 'plan-card-1',
          tripId: 'trip-1',
          kind: OrganizationCardKind.planProposal,
          title: 'Il tuo piano per Lisbona',
        ),
      );
      expect(planProposed.type, 'plan.proposed');
      expect(planProposed.kind, OrganizationEventKind.planProposed);

      final degraded = ProviderDegradedEvent(
        id: 'evt-19',
        tripId: 'trip-1',
        timestamp: now,
        providerId: 'mock-flights',
        reason: 'Rate limit temporaneo del provider',
      );
      expect(degraded.type, 'provider.degraded');
      expect(degraded.kind, OrganizationEventKind.providerDegraded);

      final expired = OfferExpiredEvent(
        id: 'evt-20',
        tripId: 'trip-1',
        timestamp: now,
        offerId: 'off-1',
      );
      expect(expired.type, 'offer.expired');
      expect(expired.kind, OrganizationEventKind.offerExpired);
    });
  });
}
