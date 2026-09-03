import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/flights/google_flights_url_builder.dart';

void main() {
  group('GoogleFlightsUrlBuilder', () {
    test('risolve IATA per citta principali', () {
      expect(GoogleFlightsUrlBuilder.resolveIata('Budapest'), 'BUD');
      expect(GoogleFlightsUrlBuilder.resolveIata('Milano'), 'MIL');
      expect(GoogleFlightsUrlBuilder.resolveIata('Malpensa'), 'MXP');
      expect(GoogleFlightsUrlBuilder.resolveIata('Roma'), 'ROM');
      expect(GoogleFlightsUrlBuilder.resolveIata('Fiumicino'), 'FCO');
      expect(GoogleFlightsUrlBuilder.resolveIata('LIS'), 'LIS');
    });

    test('estrae date in formato italiano "dal 5 al 10 dicembre"', () {
      final (dep, ret) = GoogleFlightsUrlBuilder.extractDatesFromText(
        'Vorrei andare a Budapest dal 5 al 10 dicembre',
        referenceYear: 2026,
      );
      expect(dep, DateTime(2026, 12, 5));
      expect(ret, DateTime(2026, 12, 10));
    });

    test('costruisce URL Google Flights con date e IATA', () {
      final url = GoogleFlightsUrlBuilder.build(
        destination: 'Budapest',
        originCity: 'Milano',
        textWithDates: 'Viaggio dal 5 al 10 dicembre',
      );
      expect(url, contains('google.com/travel/flights'));
      expect(url, contains('Flights%20to%20BUD%20from%20MIL%20on%202026-12-05%20through%202026-12-10'));
      expect(url, contains('hl=it'));
      expect(url, contains('curr=EUR'));
    });


    test('sostituisce Skyscanner con Google Flights URL canonico', () {
      final url = GoogleFlightsUrlBuilder.build(
        destination: 'Budapest',
        originCity: 'Milano',
        rawUrl: 'https://www.skyscanner.it/trasporti/voli/mil/bud/',
        textWithDates: '5-10 dicembre',
      );
      expect(url, contains('google.com/travel/flights'));
      expect(url, isNot(contains('skyscanner')));
    });
  });
}
