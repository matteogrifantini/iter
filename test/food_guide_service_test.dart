import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/food/food_guide_service.dart';

void main() {
  group('FoodGuideService', () {
    const service = FoodGuideService();

    test('delivers traditional dishes and venues for Budapest', () async {
      final guide = await service.getFoodGuide('Budapest');

      expect(guide.destination, 'Budapest');
      expect(
        guide.dishes.any(
          (d) => d.name.contains('Gulasch') || d.name.contains('Lángos'),
        ),
        isTrue,
      );
      expect(
        guide.venues.any((v) => v.name.contains('Mercato Centrale')),
        isTrue,
      );
      expect(guide.orderingPhrases, isNotEmpty);
    });

    test('delivers traditional dishes and venues for Porto', () async {
      final guide = await service.getFoodGuide('Porto');

      expect(guide.destination, 'Porto');
      expect(guide.dishes.any((d) => d.name.contains('Francesinha')), isTrue);
      expect(guide.venues.any((v) => v.name.contains('Bolhão')), isTrue);
    });
  });
}
