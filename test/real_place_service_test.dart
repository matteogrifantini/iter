import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/places/real_place_service.dart';

void main() {
  group('RealPlaceService', () {
    test('fetches and parses Wikipedia summary for a place', () async {
      final mockJson = '''
      {
        "type": "standard",
        "title": "Parlamento di Budapest",
        "description": "Edificio storico a Budapest, Ungheria",
        "extract": "Il palazzo del Parlamento di Budapest è un edificio monumentale situato sulla riva orientale del Danubio.",
        "originalimage": {
          "source": "https://upload.wikimedia.org/wikipedia/commons/parliament.jpg"
        },
        "coordinates": {
          "lat": 47.5072,
          "lon": 19.0458
        },
        "content_urls": {
          "desktop": {
            "page": "https://it.wikipedia.org/wiki/Parlamento_di_Budapest"
          }
        }
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealPlaceService(httpClient: mockClient);
      final detail = await service.fetchPlaceDetails('Parlamento di Budapest');

      expect(detail, isNotNull);
      expect(detail!.title, 'Parlamento di Budapest');
      expect(detail.description, contains('Budapest'));
      expect(detail.extract, contains('Danubio'));
      expect(detail.imageUrl, contains('wikimedia.org'));
      expect(detail.latitude, 47.5072);
      expect(detail.longitude, 19.0458);
      expect(detail.wikipediaUrl, contains('wikipedia.org'));
    });

    test('returns null when Wikipedia responds 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = RealPlaceService(httpClient: mockClient);
      final detail = await service.fetchPlaceDetails(
        'Luogo Inesistente XYZ 123',
      );

      expect(detail, isNull);
    });
  });
}
