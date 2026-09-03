import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/engine/session_registry.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/providers/supabase_organization_gateway.dart';

void main() {
  group('Supabase Organization Gateway Truthful Fallback Tests', () {
    late SupabaseOrganizationGateway gateway;

    setUp(() {
      // Inizializzato senza client reale per testare il fallback trasparente
      gateway = SupabaseOrganizationGateway(client: null);
    });

    test(
      'Falls back gracefully to local heuristic when Supabase is not initialized',
      () async {
        final context = OrganizationAiContext(
          intent: TripIntent(
            tripId: 'trip-fallback-test',
            rawDesire: 'Vorrei andare a Lisbona',
            candidateDestinations: const ['Lisbona'],
          ),
          questionBudget: const QuestionBudget(essential: 1, adaptive: 2),
        );

        final response = await gateway.decideNextStep(context);

        expect(response.nextQuestion, isNotNull);
        expect(response.nextQuestion?.prompt, contains('date'));
        expect(response.explanation, contains('periodo'));
      },
    );

    test(
      'Adapts question to food desires when dates are already specified',
      () async {
        final context = OrganizationAiContext(
          intent: TripIntent(
            tripId: 'trip-food-test',
            rawDesire: 'Tour gastronomico e cibo tipico a Porto',
            candidateDestinations: const ['Porto'],
            dateConstraint: ExactDates(
              departure: DateTime(2026, 10, 1),
              returnDate: DateTime(2026, 10, 5),
            ),
          ),
          questionBudget: const QuestionBudget(essential: 0, adaptive: 2),
        );

        final response = await gateway.decideNextStep(context);

        expect(response.nextQuestion, isNotNull);
        expect(response.nextQuestion?.key, 'q-food-pref');
        expect(response.explanation, contains('gastronomico'));
      },
    );

    test(
      'Adapts question to travel pace when dates and general desires are set',
      () async {
        final context = OrganizationAiContext(
          intent: TripIntent(
            tripId: 'trip-pace-test',
            rawDesire: 'Relax e passeggiate',
            candidateDestinations: const ['Lisbona'],
            dateConstraint: ExactDates(
              departure: DateTime(2026, 11, 1),
              returnDate: DateTime(2026, 11, 4),
            ),
          ),
          questionBudget: const QuestionBudget(essential: 0, adaptive: 2),
        );

        final response = await gateway.decideNextStep(context);

        expect(response.nextQuestion, isNotNull);
        expect(response.nextQuestion?.key, 'q-pace');
        expect(response.explanation, contains('euristica'));
      },
    );

    test(
      'SessionRegistry.standard initializes properly without client crashes',
      () {
        final registry = SessionRegistry.standard();
        final session = registry.getOrCreate('trip-registry-test');

        expect(session, isNotNull);
        expect(session.tripId, 'trip-registry-test');
        expect(session.state.phase, OrganizationPhase.collectingIntent);

        registry.disposeAll();
      },
    );
  });
}
