import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/stays/stay_search_service.dart';

void main() {
  group('StaySearchService', () {
    const service = StaySearchService();

    test(
      'searches stays for Budapest with realistic ratings and prices',
      () async {
        final stays = await service.searchStays(destination: 'Budapest');

        expect(stays, isNotEmpty);
        expect(stays.first.ratingScore, greaterThan(8.0));
        expect(stays.first.pricePerNightEur, greaterThan(30.0));
        expect(stays.first.amenities, isNotEmpty);
      },
    );

    test('sorts stays by price correctly', () async {
      final stays = await service.searchStays(
        destination: 'Budapest',
        sortBy: StaySortBy.priceLow,
      );

      expect(stays.length, greaterThanOrEqualTo(2));
      expect(
        stays[0].pricePerNightEur,
        lessThanOrEqualTo(stays[1].pricePerNightEur),
      );
    });

    test('sorts stays by rating correctly', () async {
      final stays = await service.searchStays(
        destination: 'Porto',
        sortBy: StaySortBy.ratingHigh,
      );

      expect(
        stays.first.ratingScore,
        greaterThanOrEqualTo(stays.last.ratingScore),
      );
    });
  });
}
