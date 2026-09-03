import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';

void main() {
  group('ChatFirstHomeScreen Fixed Interaction Points', () {
    testWidgets('Renders fixed hero title, subtitle and quick chips', (
      tester,
    ) async {
      String? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatFirstHomeScreen(
              model: const AdaptiveHomeModel.empty(),
              unread: 0,
              onSubmitIntent: (intent) => submitted = intent,
              onVoiceIntent: () {},
              onPhotoIntent: (_) {},
              onOpenThread: (_) {},
              onOpenTrips: () {},
            ),
          ),
        ),
      );

      // Verify fixed hero title and subtitle (empty-state copy is
      // 'Dove vorresti andare?' — see chat_first_home_screen.dart; the
      // 'Che viaggio...' string predates 9007e49 and no longer exists).
      expect(find.text('Dove vorresti andare?'), findsOneWidget);
      expect(
        find.text(
          'Scrivi una città, un’idea o descrivi il tipo di esperienza che cerchi.',
        ),
        findsOneWidget,
      );


      // Verify seeds (5-destination set @9007e49 — see rottaVivaSeeds in
      // rotta_viva_home_sections.dart; Task 4 preserved it as-is).
      expect(find.textContaining('Mare e pause'), findsOneWidget);
      expect(find.textContaining('Lisbona a novembre'), findsOneWidget);
      expect(find.textContaining('Weekend a Porto'), findsOneWidget);

      // Tap seed to populate composer
      await tester.tap(find.textContaining('Mare e pause'));
      await tester.pumpAndSettle();

      // Submit via composer action
      await tester.tap(find.byTooltip('Invia il desiderio'));
      await tester.pumpAndSettle();

      expect(submitted, contains('Mare e pause'));
    });


    testWidgets('Responsive stress test down to 320dp width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatFirstHomeScreen(
              model: const AdaptiveHomeModel.empty(),
              unread: 0,
              onSubmitIntent: (_) {},
              onVoiceIntent: () {},
              onPhotoIntent: (_) {},
              onOpenThread: (_) {},
              onOpenTrips: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
