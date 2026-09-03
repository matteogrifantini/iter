import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';

void main() {
  group('TripIntent Domain Model', () {
    test('TripIntent default creation and immutability', () {
      final intent = TripIntent(
        id: 'trip-123',
        text: 'Vorrei un weekend a Lisbona a novembre con buon cibo',
      );

      expect(intent.id, 'trip-123');
      expect(intent.tripId, 'trip-123');
      expect(intent.text, contains('Lisbona'));
      expect(intent.origin, isNull);
      expect(intent.acceptedModes, contains(TravelMode.flight));
      expect(intent.companyType, TravelerKind.solo);
      expect(intent.travelersCount, 1);
      expect(intent.budgetToleranceEur, 50.0);
      expect(intent.pace, OrganizationPace.balanced);
      expect(intent.isComplete, isFalse);
    });

    test('TripIntent copies lists and maps defensively', () {
      final mutableOrigins = <String>['Firenze'];
      final mutableInterests = <String>['arte', 'cibo'];
      final mutableSignals = <String, String>{'diet': 'vegetarian'};

      final intent = TripIntent(
        tripId: 'trip-imm',
        rawDesire: 'Viaggio culturale',
        originCandidates: mutableOrigins,
        priorities: mutableInterests,
        profileSignalsUsed: mutableSignals,
      );

      // Attempt external mutation
      mutableOrigins.add('Bologna');
      mutableInterests.add('musica');
      mutableSignals['pace'] = 'slow';

      expect(intent.originCandidates, <String>['Firenze']);
      expect(intent.priorities, <String>['arte', 'cibo']);
      expect(intent.profileSignalsUsed, <String, String>{'diet': 'vegetarian'});

      // Attempt mutation on intent collections directly
      expect(
        () => (intent.originCandidates as List).add('Pisa'),
        throwsUnsupportedError,
      );
      expect(
        () => (intent.priorities as List).add('relax'),
        throwsUnsupportedError,
      );
      expect(
        () => (intent.profileSignalsUsed as Map)['k'] = 'v',
        throwsUnsupportedError,
      );
    });

    test(
      'TripIntent copyWith updates correctly and allows nullable clearing',
      () {
        final now = DateTime(2026, 11, 15);
        final initial = TripIntent(
          id: 'trip-123',
          text: 'Weekend a Porto',
          budgetCentsPerPerson: 35000,
          duration: const DurationRange(minimumDays: 2, maximumDays: 4),
        );

        final updated = initial.copyWith(
          origin: 'Firenze',
          originAlternatives: const <String>['Pisa', 'Bologna'],
          candidateDestinations: const <String>['Porto'],
          budgetEurPerPerson: 400.0,
          exactStartDate: now,
          exactEndDate: now.add(const Duration(days: 3)),
          dateMode: OrganizationDateMode.exact,
          isComplete: true,
        );

        expect(updated.id, 'trip-123');
        expect(updated.origin, 'Firenze');
        expect(updated.originAlternatives, <String>['Pisa', 'Bologna']);
        expect(updated.candidateDestinations, <String>['Porto']);
        expect(updated.budgetEurPerPerson, 400.0);
        expect(updated.budgetCentsPerPerson, 40000);
        expect(updated.dateMode, OrganizationDateMode.exact);
        expect(updated.exactStartDate, now);
        expect(updated.isComplete, isTrue);
        expect(updated, isNot(equals(initial)));

        // Clear budget using functional clearing
        final clearedBudget = updated.copyWith(
          budgetCentsPerPerson: () => null,
        );
        expect(clearedBudget.budgetCentsPerPerson, isNull);
        expect(clearedBudget.budgetEurPerPerson, isNull);
      },
    );

    test('TripIntent equality and hash code agree', () {
      final intent1 = TripIntent(
        tripId: 'trip-1',
        rawDesire: 'Test',
        priorities: const <String>['cibo', 'arte'],
        profileSignalsUsed: const <String, String>{'fav': 'train'},
      );
      final intent2 = TripIntent(
        tripId: 'trip-1',
        rawDesire: 'Test',
        priorities: const <String>['cibo', 'arte'],
        profileSignalsUsed: const <String, String>{'fav': 'train'},
      );

      expect(intent1, equals(intent2));
      expect(intent1.hashCode, equals(intent2.hashCode));
    });
  });

  group('DateConstraint Domain Models', () {
    test('ExactDates rejects return before or on departure', () {
      final departure = DateTime(2026, 11, 20);
      final earlier = DateTime(2026, 11, 19);
      final same = DateTime(2026, 11, 20);
      final validReturn = DateTime(2026, 11, 24);

      expect(
        () => ExactDates(departure: departure, returnDate: earlier),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExactDates(departure: departure, returnDate: same),
        throwsA(isA<ArgumentError>()),
      );

      final valid = ExactDates(departure: departure, returnDate: validReturn);
      expect(valid.departure, departure);
      expect(valid.returnDate, validReturn);
    });

    test('FlexibleDates preserves disjoint departures defensively', () {
      final departures = <DateTime>[
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 20),
      ];

      final flex = FlexibleDates(
        departures: departures,
        duration: const DurationRange(minimumDays: 3, maximumDays: 5),
        horizonEnd: DateTime(2026, 11, 30),
      );

      departures.add(DateTime(2026, 11, 27));
      expect(flex.departures.length, 3);
      expect(
        () => (flex.departures as List).add(DateTime.now()),
        throwsUnsupportedError,
      );
    });

    test('DurationRange validates range bounds', () {
      expect(
        () => DurationRange(minimumDays: 0, maximumDays: 5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DurationRange(minimumDays: 5, maximumDays: 3),
        throwsA(isA<AssertionError>()),
      );

      const valid = DurationRange(minimumDays: 2, maximumDays: 6);
      expect(valid.minimumDays, 2);
      expect(valid.maximumDays, 6);
    });
  });

  group('SearchSession Domain Model', () {
    test('SearchSession expiration check and copyWith', () {
      final started = DateTime(2026, 9, 1, 10, 0);
      final expiredTime = DateTime(2026, 9, 1, 10, 5);

      final session = SearchSession(
        id: 'session-1',
        tripId: 'trip-123',
        query: 'FCO -> OPO',
        providers: const <String>['mock-flights'],
        startedAt: started,
        updatedAt: started,
        expiresAt: expiredTime,
        status: SearchSessionStatus.searching,
      );

      expect(session.isExpiredAt(DateTime(2026, 9, 1, 10, 6)), isTrue);
      expect(session.isExpiredAt(DateTime(2026, 9, 1, 10, 4)), isFalse);
      expect(session.partialResultsCount, 0);

      final updated = session.copyWith(
        status: SearchSessionStatus.completed,
        partialResultsCount: 8,
      );

      expect(updated.status, SearchSessionStatus.completed);
      expect(updated.partialResultsCount, 8);
    });
  });

  group('ProviderOffer Domain Model', () {
    test('ProviderOffer validates inputs strictly', () {
      final dep = DateTime(2026, 11, 20);

      // Negative price rejected
      expect(
        () => ProviderOffer(
          id: 'off-1',
          providerId: 'mock-flights',
          origin: 'FCO',
          destination: 'OPO',
          departureDate: dep,
          priceCents: -100,
          externalBookingUrl: 'https://example.com',
          fetchedAt: DateTime.now(),
          tradeoffSummary: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Empty providerId rejected
      expect(
        () => ProviderOffer(
          id: 'off-1',
          providerId: '   ',
          origin: 'FCO',
          destination: 'OPO',
          departureDate: dep,
          priceCents: 5000,
          externalBookingUrl: 'https://example.com',
          fetchedAt: DateTime.now(),
          tradeoffSummary: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Non-HTTPS URL rejected
      expect(
        () => ProviderOffer(
          id: 'off-1',
          providerId: 'mock-flights',
          origin: 'FCO',
          destination: 'OPO',
          departureDate: dep,
          priceCents: 5000,
          externalBookingUrl: 'http://insecure.com',
          fetchedAt: DateTime.now(),
          tradeoffSummary: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ProviderOffer truth state and money normalization', () {
      final departure = DateTime(2026, 11, 20, 9, 30);
      final fetched = DateTime(2026, 9, 1, 12, 0);
      final futureExpiry = DateTime(2026, 9, 1, 12, 30);

      final offer = ProviderOffer(
        id: 'offer-flight-1',
        providerId: 'mock-flights',
        kind: OfferKind.flight,
        origin: 'FCO',
        destination: 'OPO',
        departureDate: departure,
        priceCents: 4999,
        externalBookingUrl: 'https://ryanair.com/booking/123',
        fetchedAt: fetched,
        expiresAt: futureExpiry,
        truthState: OfferTruthState.demo,
        tradeoffSummary: 'Diretto, ottimo orario, bagaglio a mano escluso',
        badgeLabel: 'Miglior equilibrio',
      );

      expect(offer.priceCents, 4999);
      expect(offer.priceEur, 49.99);
      expect(offer.truthState, OfferTruthState.demo);
      expect(offer.status, OfferTruthState.demo);
      expect(offer.tradeoffSummary, contains('bagaglio a mano escluso'));
      expect(offer.isExpiredAt(DateTime(2026, 9, 1, 12, 31)), isTrue);
      expect(offer.isExpiredAt(DateTime(2026, 9, 1, 12, 29)), isFalse);
    });

    test('ProviderOffer equality and hashCode agree', () {
      final dep = DateTime(2026, 11, 20);
      final fetched = DateTime(2026, 9, 1);

      final offer1 = ProviderOffer(
        id: 'off-1',
        providerId: 'mock-flights',
        origin: 'FCO',
        destination: 'OPO',
        departureDate: dep,
        priceCents: 5000,
        externalBookingUrl: 'https://example.com',
        fetchedAt: fetched,
        tradeoffSummary: 'Summary',
      );

      final offer2 = ProviderOffer(
        id: 'off-1',
        providerId: 'mock-flights',
        origin: 'FCO',
        destination: 'OPO',
        departureDate: dep,
        priceCents: 5000,
        externalBookingUrl: 'https://example.com',
        fetchedAt: fetched,
        tradeoffSummary: 'Summary',
      );

      expect(offer1, equals(offer2));
      expect(offer1.hashCode, equals(offer2.hashCode));
    });
  });

  group('UserDecision Domain Model', () {
    test('UserDecision tracks confirmation state strictly', () {
      final selectedAt = DateTime(2026, 9, 1, 14, 0);
      final decision = UserDecision(
        id: 'dec-1',
        tripId: 'trip-123',
        target: DecisionTarget.flight,
        targetId: 'offer-flight-1',
        createdAt: selectedAt,
        status: DecisionStatus.selected,
      );

      expect(decision.isConfirmed, isFalse);
      expect(decision.status, DecisionStatus.selected);
      expect(decision.confirmedAt, isNull);

      // Open partner URL moves to awaitingConfirmation, not confirmed
      final awaiting = decision.copyWith(
        status: DecisionStatus.awaitingConfirmation,
      );
      expect(awaiting.isConfirmed, isFalse);
      expect(awaiting.status, DecisionStatus.awaitingConfirmation);

      // Explicit confirmation
      final confirmedTime = DateTime(2026, 9, 1, 14, 15);
      final confirmedDecision = decision.copyWith(
        status: DecisionStatus.confirmed,
        confirmedAt: confirmedTime,
        source: 'user_explicit_dialog',
      );

      expect(confirmedDecision.isConfirmed, isTrue);
      expect(confirmedDecision.status, DecisionStatus.confirmed);
      expect(confirmedDecision.confirmedAt, confirmedTime);
      expect(confirmedDecision.source, 'user_explicit_dialog');
    });

    test('UserDecision equality and hashCode agree', () {
      final dec1 = UserDecision(
        id: 'dec-1',
        tripId: 'trip-1',
        targetId: 'target-1',
        createdAt: DateTime(2026, 9, 1),
      );
      final dec2 = UserDecision(
        id: 'dec-1',
        tripId: 'trip-1',
        targetId: 'target-1',
        createdAt: DateTime(2026, 9, 1),
      );

      expect(dec1, equals(dec2));
      expect(dec1.hashCode, equals(dec2.hashCode));
    });
  });

  group('OrganizationState and Invariants', () {
    test('OrganizationState exposes unmodifiable collections', () {
      final state = OrganizationState(
        tripId: 'trip-1',
        phase: OrganizationPhase.collectingIntent,
        intent: TripIntent(tripId: 'trip-1', rawDesire: 'Viaggio'),
        cards: <OrganizationCard>[],
        decisions: <UserDecision>[],
        searchSessions: <SearchSession>[],
      );

      expect(
        () => (state.cards as List).add(
          const OrganizationCard(
            id: 'c-1',
            tripId: 'trip-1',
            kind: OrganizationCardKind.intentSummary,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (state.decisions as List).add(
          const UserDecision(id: 'd-1', tripId: 'trip-1', targetId: 't-1'),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (state.searchSessions as List).add(
          SearchSession(
            id: 's-1',
            tripId: 'trip-1',
            query: 'q',
            startedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('QuestionBudget counts and consumes correctly', () {
      const budget = QuestionBudget(essential: 3, adaptive: 2);
      expect(budget.canAskEssential, isTrue);
      expect(budget.canAskAdaptive, isTrue);
      expect(budget.hasRemaining, isTrue);

      final consumed = budget.consumeEssential().consumeAdaptive();
      expect(consumed.essential, 2);
      expect(consumed.adaptive, 1);

      final exhausted = QuestionBudget(essential: 0, adaptive: 0);
      expect(exhausted.canAskEssential, isFalse);
      expect(exhausted.canAskAdaptive, isFalse);
      expect(exhausted.hasRemaining, isFalse);
    });
  });
}
