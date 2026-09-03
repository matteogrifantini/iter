import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/events/organization_events.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse(
      nextQuestion: OrganizationQuestion(
        id: 'q-origin',
        prompt: 'Da dove preferisci partire?',
        options: const ['Milano (Tutti gli aeroporti)', 'Roma Fiumicino'],
      ),
    );
  }
}

void main() {
  group('OrganizationSession Tests', () {
    late OrganizationSession session;
    late _FakeAiGateway aiGateway;
    late MockTravelSearchProvider travelProvider;
    late UnavailableStaySearchProvider stayProvider;

    setUp(() {
      aiGateway = _FakeAiGateway();
      travelProvider = MockTravelSearchProvider(delay: Duration.zero);
      stayProvider = const UnavailableStaySearchProvider(delay: Duration.zero);

      session = OrganizationSession(
        tripId: 'trip-sess-1',
        aiGateway: aiGateway,
        travelProvider: travelProvider,
        stayProvider: stayProvider,
      );
    });

    tearDown(() {
      session.dispose();
    });

    test('submitDesire with empty string yields error event', () async {
      final events = <OrganizationEvent>[];
      final sub = session.events.listen(events.add);

      await session.submitDesire('   ');
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.kind, OrganizationEventKind.error);
      expect(events.first.payload['code'], 'empty_desire');

      await sub.cancel();
    });

    test(
      'submitDesire with valid desire calls AI gateway and requests question',
      () async {
        final events = <OrganizationEvent>[];
        final states = <OrganizationState>[];
        final eventSub = session.events.listen(events.add);
        final stateSub = session.states.listen(states.add);

        await session.submitDesire('Un weekend rilassante a Lisbona');
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 2);
        expect(events[0].kind, OrganizationEventKind.intentCreated);
        expect(events[1].kind, OrganizationEventKind.questionRequested);
        expect(session.state.cards.length, 2);

        await eventSub.cancel();
        await stateSub.cancel();
      },
    );

    test('Full lifecycle from travel search to confirmed flight', () async {
      await session.submitDesire('Weekend a Porto');
      await session.answerQuestion(questionKey: 'q-origin', answer: 'Milano');

      // Start travel search
      await session.startTravelSearch();

      expect(session.state.phase, OrganizationPhase.awaitingFlightPurchase);

      // Select flight
      await session.selectFlight('mock-flight-1');
      expect(session.state.decisions.length, 1);
      expect(session.state.decisions.first.status, DecisionStatus.selected);

      // Open external purchase
      await session.openExternalPurchase('mock-flight-1');
      expect(session.state.phase, OrganizationPhase.awaitingFlightConfirmation);

      // Confirm flight purchase explicitly
      await session.confirmFlightPurchase('mock-flight-1');
      expect(session.state.phase, OrganizationPhase.collectingExperience);
      expect(session.state.confirmedFlight, isNotNull);
    });
  });
}
