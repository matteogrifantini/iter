import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/flight_search_adapter.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/providers/stay_search_provider.dart';
import 'package:iter/features/organization/providers/travel_search_provider.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse(
      explanation: 'Analisi completata con successo.',
      rankings: const <String>['mock-flight-1'],
    );
  }
}

void main() {
  group('OrganizationAiGateway Port Tests', () {
    test('OrganizationAiContext and AiOrganizationResponse contract', () async {
      final gateway = _FakeAiGateway();
      final context = OrganizationAiContext(
        intent: TripIntent(
          tripId: 'trip-ai-1',
          rawDesire: 'Volo per Lisbona a novembre',
        ),
        profileSignals: const <ProfileSignal>[],
        recentEvents: const [],
        questionBudget: const QuestionBudget(essential: 3, adaptive: 2),
      );

      final response = await gateway.decideNextStep(context);

      expect(response.explanation, isNotNull);
      expect(response.rankings, contains('mock-flight-1'));
      expect(response.nextQuestion, isNull);
    });
  });

  group('MockTravelSearchProvider Tests', () {
    test(
      'MockTravelSearchProvider emits full lifecycle with demo truth state',
      () async {
        final provider = MockTravelSearchProvider(delay: Duration.zero);
        final query = TravelSearchQuery(
          tripId: 'trip-travel-1',
          originCandidates: const <String>['FCO', 'PSA'],
          destinationCandidates: const <String>['LIS'],
          dateConstraint: ExactDates(
            departure: DateTime(2026, 11, 20),
            returnDate: DateTime(2026, 11, 24),
          ),
          duration: const DurationRange(minimumDays: 3, maximumDays: 5),
          travelers: const TravelerGroup(kind: TravelerKind.solo, adults: 1),
          acceptedModes: const <TravelMode>{TravelMode.flight},
          budgetCentsPerPerson: 25000,
        );

        final updates = await provider.search(query).toList();

        expect(updates.length, 4);
        expect(updates[0].kind, ProviderUpdateKind.started);
        expect(updates[1].kind, ProviderUpdateKind.progressed);
        expect(updates[2].kind, ProviderUpdateKind.partial);
        expect(updates[2].offers.length, 1);
        expect(updates[3].kind, ProviderUpdateKind.completed);
        expect(updates[3].offers.length, 2);

        for (final offer in updates[3].offers) {
          expect(offer.providerId, 'mock-flights');
          expect(offer.truthState, OfferTruthState.demo);
          expect(offer.badgeLabel, 'Dati demo');
          expect(offer.priceCents, greaterThan(0));
          expect(offer.externalBookingUrl.startsWith('https://'), isTrue);
        }
      },
    );

    test('MockTravelSearchProvider capabilities match contract', () {
      const caps = MockTravelSearchProvider.capabilities;
      expect(caps.providerId, 'mock-flights');
      expect(caps.isMockOnly, isTrue);
      expect(caps.isVerified, isFalse);
      expect(caps.supportedModes, contains(TravelMode.flight));
    });
  });

  group('UnavailableStaySearchProvider Tests', () {
    test(
      'UnavailableStaySearchProvider emits honest degradation and empty results',
      () async {
        const provider = UnavailableStaySearchProvider(delay: Duration.zero);
        final query = StaySearchQuery(
          tripId: 'trip-stay-1',
          confirmedFlight: ProviderOffer(
            id: 'flight-conf-1',
            providerId: 'mock-flights',
            kind: OfferKind.flight,
            origin: 'FCO',
            destination: 'LIS',
            departureDate: DateTime(2026, 11, 20),
            priceCents: 5000,
            externalBookingUrl: 'https://example.com',
            fetchedAt: DateTime.now(),
            tradeoffSummary: 'Volo confermato',
          ),
          zoneId: 'zone-alfama',
          zoneLabel: 'Alfama',
          zoneLatitude: 38.7107,
          zoneLongitude: -9.1303,
          travelers: const TravelerGroup(kind: TravelerKind.solo, adults: 1),
        );

        final updates = await provider.search(query).toList();

        expect(updates.length, 3);
        expect(updates[0].kind, ProviderUpdateKind.started);
        expect(updates[1].kind, ProviderUpdateKind.degraded);
        expect(
          updates[1].message,
          contains('Nessun provider alloggi approvato'),
        );
        expect(updates[2].kind, ProviderUpdateKind.completed);
        expect(updates[2].offers, isEmpty);
      },
    );

    test(
      'UnavailableStaySearchProvider capabilities declare unconfigured state',
      () {
        const caps = UnavailableStaySearchProvider.capabilities;
        expect(caps.providerId, 'unavailable-stays');
        expect(caps.isUnavailable, isTrue);
        expect(caps.isVerified, isFalse);
        expect(caps.supportedModes, isEmpty);
      },
    );
  });

  group('FlightSearchAdapter Streaming Search', () {
    test(
      'FlightSearchAdapter implements TravelSearchProvider stream interface',
      () async {
        const adapter = FlightSearchAdapter();
        final query = TravelSearchQuery(
          tripId: 'trip-stream-1',
          originCandidates: const <String>['Milano'],
          destinationCandidates: const <String>['Budapest'],
          dateConstraint: OpenDates(horizonEnd: DateTime(2027, 3, 1)),
          duration: const DurationRange(minimumDays: 2, maximumDays: 4),
          travelers: const TravelerGroup(kind: TravelerKind.solo, adults: 1),
        );

        final updates = await adapter.search(query).toList();

        expect(updates.length, 3);
        expect(updates[0].kind, ProviderUpdateKind.started);
        expect(updates[1].kind, ProviderUpdateKind.progressed);
        expect(updates[2].kind, ProviderUpdateKind.completed);
        expect(updates[2].offers, isNotEmpty);
        expect(updates[2].offers.first.truthState, OfferTruthState.demo);
      },
    );
  });
}
