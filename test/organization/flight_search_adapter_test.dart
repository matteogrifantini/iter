import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/flight_search_adapter.dart';
import 'package:iter/features/organization/models/organization_models.dart';

void main() {
  group('FlightSearchAdapter Tests', () {
    const adapter = FlightSearchAdapter();

    test(
      'searchFlights returns normalized ProviderOffer list with tradeoffs',
      () async {
        final offers = await adapter.searchFlights(
          destination: 'Budapest',
          originCity: 'Milano',
          originIata: 'MXP',
          budgetPerPerson: 50.0,
        );

        expect(offers, isNotEmpty);
        final first = offers.first;
        expect(first.type, OfferType.flight);
        expect(first.providerId, 'fast-flights');
        expect(first.priceEur, greaterThan(0));
        expect(first.tradeoffSummary, isNotEmpty);
        expect(first.conditions, contains('airlineName'));
        expect(first.conditions, contains('durationLabel'));
      },
    );

    test('searchFlights sorting criteria (cheapest and fastest)', () async {
      final cheapestOffers = await adapter.searchFlights(
        destination: 'Porto',
        originCity: 'Milano',
        sortBy: FlightSortCriterion.cheapest,
      );

      for (int i = 0; i < cheapestOffers.length - 1; i++) {
        expect(
          cheapestOffers[i].priceEur <= cheapestOffers[i + 1].priceEur,
          isTrue,
        );
      }

      final fastestOffers = await adapter.searchFlights(
        destination: 'Porto',
        originCity: 'Milano',
        sortBy: FlightSortCriterion.fastest,
      );
      expect(fastestOffers, isNotEmpty);
      expect(fastestOffers.first.conditions['isDirect'], isTrue);
    });
  });
}
