import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/map/trip_map_models.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('RealMapService', () {
    test('geocodes place via OpenStreetMap Nominatim', () async {
      final mockJson = '''
      [
        {
          "place_id": 12345,
          "lat": "47.5072",
          "lon": "19.0458",
          "display_name": "Hungarian Parliament Building, Budapest, Hungary"
        }
      ]
      ''';

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealMapService(httpClient: mockClient);
      final coords = await service.geocodePlace('Parlamento', 'Budapest');

      expect(coords, isNotNull);
      expect(coords!.latitude, 47.5072);
      expect(coords.longitude, 19.0458);
    });

    test('fetches walking route from OSRM', () async {
      final mockJson = '''
      {
        "code": "Ok",
        "routes": [
          {
            "geometry": {
              "coordinates": [
                [19.0458, 47.5072],
                [19.0437, 47.4990]
              ],
              "type": "LineString"
            }
          }
        ]
      }
      ''';

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'router.project-osrm.org');
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealMapService(httpClient: mockClient);
      final waypoints = [
        const LatLng(47.5072, 19.0458),
        const LatLng(47.4990, 19.0437),
      ];

      final route = await service.fetchWalkingRoute(waypoints);
      expect(route.length, 2);
      expect(route.first.latitude, 47.5072);
      expect(route.last.latitude, 47.4990);
    });
  });
}
