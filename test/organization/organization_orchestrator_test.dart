import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/engine/organization_orchestrator.dart';
import 'package:iter/features/organization/events/organization_events.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';

void main() {
  group('OrganizationOrchestrator Lifecycle Tests', () {
    test('startWithDesire parses desire and poses origin question', () async {
      final orchestrator = OrganizationOrchestrator(tripId: 'trip-test-1');

      await orchestrator.startWithDesire(
        'Vorrei fare un viaggio a Budapest con circa 250 € a novembre',
      );

      expect(orchestrator.intent, isNotNull);
      expect(orchestrator.intent!.candidateDestinations, contains('Budapest'));
      expect(orchestrator.intent!.budgetEurPerPerson, 250.0);
      expect(orchestrator.cards, isNotEmpty);
      expect(orchestrator.cards.first.kind, OrganizationCardKind.intentSummary);

      // Question card for origin should be added
      expect(
        orchestrator.cards.any((c) => c.kind == OrganizationCardKind.question),
        isTrue,
      );
      expect(orchestrator.events.any((e) => e is IntentCreatedEvent), isTrue);
      expect(
        orchestrator.events.any((e) => e is QuestionRequestedEvent),
        isTrue,
      );
    });

    test(
      'answering questions leads to flight search and comparison card',
      () async {
        final orchestrator = OrganizationOrchestrator(tripId: 'trip-test-2');

        await orchestrator.startWithDesire('Voglio andare a Porto');
        expect(orchestrator.intent!.origin, isNull);

        // Answer origin
        await orchestrator.answerQuestion(
          OrganizationQuestions.origin,
          'Milano',
        );
        expect(orchestrator.intent!.origin, 'Milano');

        // Check that flight search was executed and flight comparison card was emitted
        expect(orchestrator.flightOffers, isNotEmpty);
        final comparisonCard = orchestrator.cards.firstWhere(
          (c) => c.kind == OrganizationCardKind.flightComparison,
        );
        expect(comparisonCard.state, OrganizationCardState.ready);
        expect(
          orchestrator.events.any((e) => e is SearchCompletedEvent),
          isTrue,
        );

        // Select flight
        final chosenOffer = orchestrator.flightOffers.first;
        orchestrator.selectFlightOffer(chosenOffer);

        expect(orchestrator.flightDecision, isNotNull);
        expect(orchestrator.flightDecision!.targetId, chosenOffer.id);
        expect(orchestrator.flightDecision!.status, DecisionStatus.provisional);
        expect(
          orchestrator.events.any((e) => e is FlightSelectedEvent),
          isTrue,
        );
      },
    );
  });
}
