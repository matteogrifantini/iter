import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/models/organization_state.dart';

import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/views/organization_thread_view.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse(
      explanation: 'Analisi iniziale completata',
      nextQuestion: OrganizationQuestion(
        key: 'q-travel-dates',
        prompt: 'In quali date o mese preferiresti partire?',
        options: const ['Novembre', 'Dicembre', 'Flessibile'],
      ),
    );
  }
}

void main() {
  group('Organization Vertical E2E Tests', () {
    late OrganizationSession session;

    setUp(() {
      session = OrganizationSession(
        tripId: 'trip-vertical-e2e',
        aiGateway: _FakeAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      session.dispose();
    });

    testWidgets('Complete end-to-end trip organization vertical flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Mount OrganizationThreadView
      await tester.pumpWidget(
        MaterialApp(home: OrganizationThreadView(session: session)),
      );
      await tester.pumpAndSettle();

      // Empty prompt initially
      expect(
        find.text('Descrivi il tuo prossimo viaggio ideale per iniziare.'),
        findsOneWidget,
      );

      // 2. Submit raw desire
      await session.submitDesire('Lisbona a novembre per cibo e cultura');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Lisbona a novembre per cibo e cultura'),
        findsOneWidget,
      );

      expect(
        find.text('In quali date o mese preferiresti partire?'),
        findsOneWidget,
      );
      expect(find.text('Novembre'), findsWidgets);

      // 3. User answers the question and starts flight search
      await session.answerQuestion(
        questionKey: 'q-travel-dates',
        answer: 'Novembre',
      );
      await session.startTravelSearch();

      await tester.pumpAndSettle();

      // Flight comparison card is ready
      expect(session.state.phase, OrganizationPhase.awaitingFlightPurchase);
      expect(find.text('Voli individuati'), findsOneWidget);
      expect(find.text('Seleziona'), findsWidgets);

      // 4. Select flight
      final flightOffer = session.state.flightOffers.first;
      session.selectFlight(flightOffer.id);
      await tester.pumpAndSettle();

      expect(find.text('Continua sul sito del provider'), findsOneWidget);

      // 5. User taps "Continua sul sito del provider" -> dialog opens
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continua sul sito del provider'));
      await tester.pumpAndSettle();

      expect(find.text('Hai confermato questo volo?'), findsOneWidget);
      expect(find.text('Sì, confermato'), findsOneWidget);

      // 6. User confirms external purchase
      await tester.tap(find.text('Sì, confermato'));
      await tester.pumpAndSettle();

      expect(session.state.phase, OrganizationPhase.collectingExperience);
      expect(session.state.confirmedFlight, isNotNull);

      // 7. Propose zones and select one
      await session.proposeZones(const [
        'Baixa / Chiado',
        'Alfama',
        'Bairro Alto',
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Zone consigliate'), findsOneWidget);
      expect(find.text('Alfama'), findsOneWidget);

      // 8. Select zone -> triggers stay search with honest degradation
      await session.selectZone('Alfama');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(session.state.phase, OrganizationPhase.awaitingStayPurchase);
      expect(
        find.text(
          'Nessun provider alloggi configurato o collegato. Nessun dato inventato.',
        ),
        findsOneWidget,
      );

      expect(find.text('Conferma alloggio autonomo'), findsOneWidget);

      // 9. Confirm self-booked stay -> triggers readyForPlan
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conferma alloggio autonomo'));
      await tester.pumpAndSettle();

      expect(session.state.confirmedStay, isNotNull);

      // 10. Generate plan proposal
      await session.generatePlan();
      await tester.pumpAndSettle();

      expect(session.state.phase, OrganizationPhase.readyForPlan);
      expect(find.text('Piano di viaggio pronto'), findsOneWidget);
      expect(find.text('Visualizza itinerario'), findsOneWidget);

      // 11. Open plan snapshot screen
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visualizza itinerario'));
      await tester.pumpAndSettle();

      expect(find.text('Lisbona'), findsWidgets);
      expect(find.text('Giorno 1'), findsOneWidget);
    });

    testWidgets('Responsive stress test down to 320dp width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(home: OrganizationThreadView(session: session)),
      );
      await tester.pumpAndSettle();

      await session.submitDesire('Lisbona');
      await session.startTravelSearch();
      final flightOffer = session.state.flightOffers.first;
      await session.confirmFlightPurchase(flightOffer.id);
      await session.proposeZones(const ['Baixa', 'Alfama']);
      await session.selectZone('Alfama');
      await session.confirmStayPurchase('stay-self');
      await session.generatePlan();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
