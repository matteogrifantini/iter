import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/flights/fast_flights_service.dart';

void main() {
  group('FastFlightsService', () {
    test('ritorna offerte reali formattate quando il server risponde 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(
            '''
            {
              "success": true,
              "origin": "MIL",
              "destination": "BUD",
              "searchUrl": "https://www.google.com/travel/flights/search?tfs=123&hl=it&curr=EUR",
              "offers": [
                {
                  "id": "flight-0",
                  "airline": "Wizz Air",
                  "price": 167,
                  "currency": "EUR",
                  "isDirect": true,
                  "stops": 0,
                  "departureTime": "06:10",
                  "arrivalTime": "07:50",
                  "durationMinutes": 100,
                  "bookingUrl": "https://www.google.com/travel/flights"
                },
                {
                  "id": "flight-1",
                  "airline": "Ryanair",
                  "price": 195,
                  "currency": "EUR",
                  "isDirect": true,
                  "stops": 0,
                  "departureTime": "10:30",
                  "arrivalTime": "12:05",
                  "durationMinutes": 95,
                  "bookingUrl": "https://www.google.com/travel/flights"
                }
              ]
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = FastFlightsService(client: mockClient);
      final result = await service.searchRealFlights(
        destination: 'Budapest',
        originCity: 'Milano',
        textWithDates: 'dal 5 al 10 dicembre',
      );

      expect(result.offers.length, 2);
      expect(result.offers.first.airline, 'Wizz Air');
      expect(result.offers.first.price, 167);
      expect(result.offers.first.isDirect, isTrue);
      expect(result.offers.first.durationLabel, '1h 40m');
      expect(result.offers[1].airline, 'Ryanair');
      expect(result.offers[1].price, 195);
    });

    test('ritorna fallback strutturato se il server e offline senza causare crash', () async {
      final failingClient = MockClient((_) async {
        throw Exception('Connection refused');
      });

      final service = FastFlightsService(client: failingClient);
      final result = await service.searchRealFlights(
        destination: 'Budapest',
        originCity: 'Milano',
        textWithDates: '5-10 dicembre',
      );

      expect(result.offers, isNotEmpty);
      expect(result.offers.first.airline, 'Wizz Air');
      expect(result.offers.first.price, 155);
      expect(result.searchUrl, contains('google.com/travel/flights'));

    });
  });
}
