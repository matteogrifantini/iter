import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/map/trip_map_models.dart';

void main() {
  group('MapPoiLocation', () {
    test('computes Haversine distance and walking minutes between POIs', () {
      // Parlamento di Budapest to Bastione dei Pescatori
      const parlamento = MapPoiLocation(
        id: 'p-1',
        title: 'Parlamento',
        category: 'monumento',
        latitude: 47.5072,
        longitude: 19.0458,
      );

      const bastione = MapPoiLocation(
        id: 'p-2',
        title: 'Bastione dei Pescatori',
        category: 'panorama',
        latitude: 47.5022,
        longitude: 19.0348,
      );

      final distanceMeters = parlamento.distanceTo(bastione);
      final walkMinutes = parlamento.walkingMinutesTo(bastione);

      expect(distanceMeters, greaterThan(500));
      expect(distanceMeters, lessThan(2000));
      expect(walkMinutes, greaterThan(5));
      expect(walkMinutes, lessThan(30));
    });
  });
}
