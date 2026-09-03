import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/checklist/trip_checklist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripChecklistService', () {
    const service = TripChecklistService();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'generates tailored checklist for Budapest with thermal baths items',
      () async {
        final items = await service.loadChecklist('trip-bud-1', 'Budapest');

        expect(items, isNotEmpty);
        expect(items.any((i) => i.title.contains('Terme Széchenyi')), isTrue);
        expect(items.any((i) => i.category == 'Documenti'), isTrue);
      },
    );

    test(
      'generates tailored checklist for Porto with calçada antislip shoes',
      () async {
        final items = await service.loadChecklist('trip-opo-1', 'Porto');

        expect(items.any((i) => i.title.contains('calçada')), isTrue);
      },
    );

    test('persists item check state across loads', () async {
      final items = await service.loadChecklist('trip-1', 'Roma');
      items[0].isDone = true;
      await service.saveChecklist('trip-1', items);

      final reloaded = await service.loadChecklist('trip-1', 'Roma');
      expect(reloaded[0].isDone, isTrue);
    });
  });
}
