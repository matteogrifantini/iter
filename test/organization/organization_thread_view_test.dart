import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/views/organization_thread_view.dart';

class _TestAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse(
      nextQuestion: OrganizationQuestion(
        id: 'q-origin',
        prompt: 'Da dove parti?',
        options: const ['Roma', 'Milano'],
      ),
    );
  }
}

void main() {
  group('OrganizationThreadView Tests', () {
    late OrganizationSession session;

    setUp(() {
      session = OrganizationSession(
        tripId: 'trip-view-1',
        aiGateway: _TestAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      session.dispose();
    });

    testWidgets('Renders empty prompt when session has no cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: OrganizationThreadView(session: session)),
      );

      expect(
        find.textContaining('Descrivi il tuo prossimo viaggio ideale'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Submitting desire renders IntentSummaryCard and QuestionCard',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: OrganizationThreadView(session: session)),
        );

        final input = find.byType(TextField);
        expect(input, findsOneWidget);

        await tester.enterText(input, 'Weekend a Lisbona');
        await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Desiderio di viaggio'), findsOneWidget);
        expect(find.textContaining('Da dove parti?'), findsOneWidget);
        expect(find.text('Roma'), findsWidgets);
        expect(find.text('Milano'), findsWidgets);
      },
    );

    testWidgets('Tapping answer option on QuestionCard confirms selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: OrganizationThreadView(session: session)),
      );

      await tester.enterText(find.byType(TextField), 'Weekend a Lisbona');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      final romaOption = find.text('Roma').first;
      await tester.tap(romaOption);
      await tester.pumpAndSettle();

      expect(find.textContaining('Risposta: Roma'), findsOneWidget);
    });
  });
}
