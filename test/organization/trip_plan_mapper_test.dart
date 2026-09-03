import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/plan_models.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/trip_plan_mapper.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse();
  }
}

void main() {
  group('TripPlanMapper and Plan Generation Flow Tests', () {
    late OrganizationSession session;

    setUp(() {
      session = OrganizationSession(
        tripId: 'trip-plan-mapping-test',
        aiGateway: _FakeAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      session.dispose();
    });

    test(
      'Invariant: mapStateToSnapshot throws StateError when flight or stay is unconfirmed',
      () {
        final unconfirmedState = OrganizationState(
          tripId: 'trip-unconfirmed',
          phase: OrganizationPhase.collectingIntent,
          intent: TripIntent(tripId: 'trip-unconfirmed', rawDesire: 'Lisbona'),
        );

        expect(
          () => TripPlanMapper.mapStateToSnapshot(unconfirmedState),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'Invariant: session.generatePlan throws StateError if flight/stay unconfirmed',
      () async {
        expect(() => session.generatePlan(), throwsA(isA<StateError>()));
      },
    );

    test(
      'TripPlanMapper creates complete and truthful TripSnapshot from confirmed state',
      () async {
        // 1. Confirm flight
        await session.startTravelSearch();
        final flightOffer = session.state.flightOffers.first;
        await session.confirmFlightPurchase(flightOffer.id);

        // 2. Propose zone and confirm stay
        await session.proposeZones(const ['Alfama']);
        await session.selectZone('Alfama');
        await session.confirmStayPurchase('stay-alfama-1');

        expect(session.state.confirmedFlight, isNotNull);
        expect(session.state.confirmedStay, isNotNull);

        // 3. Generate plan
        final snapshot = await session.generatePlan();

        expect(snapshot.destinationTitle, 'Lisbona');
        expect(snapshot.statusLabel, 'Confermato');
        expect(
          snapshot.travelSelection?.option.purchaseState,
          PurchaseState.purchased,
        );
        expect(
          snapshot.staySelection?.option.purchaseState,
          PurchaseState.purchased,
        );
        expect(snapshot.costSummary.projectedTotalCents, greaterThan(0));
        expect(snapshot.days, isNotEmpty);
        expect(session.state.phase, OrganizationPhase.readyForPlan);
        expect(
          session.state.cards.any(
            (c) => c.kind == OrganizationCardKind.planProposal,
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'TripSnapshotScreen renders mapped snapshot from organization session',
      (tester) async {
        // 1. Confirm flight and stay
        await session.startTravelSearch();
        final flightOffer = session.state.flightOffers.first;
        await session.confirmFlightPurchase(flightOffer.id);
        await session.selectZone('Alfama');
        await session.confirmStayPurchase('stay-alfama-1');

        final snapshot = await session.generatePlan();
        final controller = ChatFirstPrototypeController();

        await tester.pumpWidget(
          MaterialApp(
            home: TripSnapshotScreen(
              controller: controller,
              conversationId: 'conv-plan-test',
              initialSnapshot: snapshot,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Lisbona'), findsWidgets);
        expect(find.textContaining('Volo'), findsWidgets);
        expect(find.text('Giorno 1'), findsOneWidget);
      },
    );
  });
}
