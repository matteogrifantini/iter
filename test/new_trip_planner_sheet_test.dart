import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/new_trip_planner_sheet.dart';

void main() {
  group('NewTripPlannerSheet', () {
    testWidgets('allows selecting destination and submitting trip plan', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? plannedPrompt;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewTripPlannerSheet(
              onPlanTrip: (prompt) => plannedPrompt = prompt,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organizza un Nuovo Viaggio'), findsOneWidget);
      expect(find.text('Budapest'), findsOneWidget);

      // Tap Budapest chip
      await tester.tap(find.text('Budapest'));
      await tester.pump();

      // Scroll and tap submit button
      await tester.scrollUntilVisible(
        find.text('Genera Itinerario con l\'IA'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Genera Itinerario con l\'IA'));
      await tester.pump();

      expect(plannedPrompt, isNotNull);
      expect(plannedPrompt, contains('Budapest'));
      expect(plannedPrompt, contains('giorni'));
    });
  });
}
