import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/flights/flight_search_service.dart';

void main() {
  group('FlightSearchService', () {
    const service = FlightSearchService();

    test(
      'searches flights for Budapest with realistic airlines and prices',
      () async {
        final flights = await service.searchFlights(
          destination: 'Budapest',
          originCity: 'Milano',
          originIata: 'MXP',
        );

        expect(flights, isNotEmpty);
        expect(flights.any((f) => f.airlineCode == 'W6'), isTrue);
        expect(flights.first.destinationIata, 'BUD');
        expect(flights.first.priceEur, greaterThan(10));
        expect(flights.first.bookingUrl, contains('google.com/travel/flights'));
      },
    );

    test('sorts flights correctly by cheapest', () async {
      final flights = await service.searchFlights(
        destination: 'Porto',
        sortBy: FlightSortBy.cheapest,
      );

      expect(flights.length, greaterThanOrEqualTo(2));
      expect(flights[0].priceEur, lessThanOrEqualTo(flights[1].priceEur));
    });

    test('sorts flights correctly by fastest / direct first', () async {
      final flights = await service.searchFlights(
        destination: 'Budapest',
        sortBy: FlightSortBy.fastest,
      );

      expect(flights.first.isDirect, isTrue);
    });
  });
}
