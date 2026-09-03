import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/chat_first_prototype/local_preferences_service.dart';
import 'package:iter/features/chat_first_prototype/profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalPreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('saves and loads theme mode', () async {
      const service = LocalPreferencesService();

      expect(await service.loadThemeMode(), isNull);

      await service.saveThemeMode(ThemeMode.dark);
      expect(await service.loadThemeMode(), ThemeMode.dark);

      await service.saveThemeMode(ThemeMode.light);
      expect(await service.loadThemeMode(), ThemeMode.light);
    });

    test('saves and loads availability entries', () async {
      const service = LocalPreferencesService();

      expect(await service.loadAvailability(), isNull);

      final entries = <AvailabilityEntry>[
        AvailabilityEntry(
          id: 'test-1',
          date: DateTime(2026, 11, 1),
          kind: AvailabilityKind.free,
          timeRange: 'Tutto il giorno',
          note: 'Ponte festivo',
        ),
      ];

      await service.saveAvailability(entries);
      final loaded = await service.loadAvailability();

      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.id, 'test-1');
      expect(loaded.first.note, 'Ponte festivo');
      expect(loaded.first.kind, AvailabilityKind.free);
    });

    test('saves and loads memory tags', () async {
      const service = LocalPreferencesService();

      expect(await service.loadMemoryTags(), isNull);

      final tags = <String>['Ritmo lento', 'Solo treno'];
      await service.saveMemoryTags(tags);
      final loaded = await service.loadMemoryTags();

      expect(loaded, tags);
    });
  });
}
