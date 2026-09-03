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

      // Verify fixed hero title and subtitle
      expect(find.text('Che viaggio ti farebbe bene adesso?'), findsOneWidget);
      expect(
        find.text(
          'Raccontami il momento. Alla destinazione penso io.',
        ),
        findsOneWidget,
      );


      // Verify seeds
      expect(find.textContaining('Mare e pause'), findsOneWidget);
      expect(find.textContaining('Partire in treno'), findsOneWidget);
      expect(find.textContaining('Mangiare bene'), findsOneWidget);

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
