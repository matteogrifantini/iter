import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/ui/cards/stay_comparison_card_view.dart';
import 'package:iter/features/organization/ui/cards/zone_proposal_card_view.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse();
  }
}

void main() {
  group('Zone Proposal and Honest Stay Flow Tests', () {
    late OrganizationSession session;

    setUp(() {
      session = OrganizationSession(
        tripId: 'trip-stay-flow',
        aiGateway: _FakeAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      session.dispose();
    });

    test(
      'Invariant: Selecting zone or stay search is blocked if flight is not confirmed',
      () async {
        expect(session.state.confirmedFlight, isNull);

        // Attempt to propose zones without confirmed flight
        await session.proposeZones(const ['Baixa', 'Alfama']);
        expect(session.state.phase, OrganizationPhase.collectingIntent);

        // Attempt to select zone without confirmed flight
        await session.selectZone('Baixa');
        expect(session.state.phase, OrganizationPhase.collectingIntent);
      },
    );

    testWidgets('ZoneProposalCardView renders zones and handles selection', (
      tester,
    ) async {
      String? selectedZone;

      // Start search and confirm flight
      await session.startTravelSearch();
      final offer = session.state.flightOffers.first;
      await session.confirmFlightPurchase(offer.id);

      expect(session.state.confirmedFlight, isNotNull);

      // Propose zones
      await session.proposeZones(const [
        'Baixa / Chiado',
        'Alfama',
        'Bairro Alto',
      ]);
      expect(session.state.phase, OrganizationPhase.proposingZones);

      final zoneCard = session.state.cards.last;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoneProposalCardView(
              card: zoneCard,
              onZoneSelected: (z) => selectedZone = z,
            ),
          ),
        ),
      );

      expect(find.text('Baixa / Chiado'), findsOneWidget);
      expect(find.text('Alfama'), findsOneWidget);
      expect(find.text('Bairro Alto'), findsOneWidget);

      await tester.tap(find.text('Alfama'));
      await tester.pumpAndSettle();

      expect(selectedZone, 'Alfama');
    });

    testWidgets(
      'StayComparisonCardView displays honest degradation when no provider configured',
      (tester) async {
        // 1. Confirm flight
        await session.startTravelSearch();
        final offer = session.state.flightOffers.first;
        await session.confirmFlightPurchase(offer.id);

        // 2. Select zone to trigger stay search on UnavailableStaySearchProvider
        await session.proposeZones(const ['Alfama']);
        await session.selectZone('Alfama');

        expect(session.state.phase, OrganizationPhase.awaitingStayPurchase);
        final stayCard = session.state.cards.last;

        bool selfBooked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StayComparisonCardView(
                  card: stayCard,
                  onOfferSelected: (_) {},
                  onSelfBookConfirmed: () => selfBooked = true,
                ),
              ),
            ),
          ),
        );

        // Verify honest degradation text
        expect(
          find.text(
            'Nessun provider alloggi configurato o collegato. Nessun dato inventato.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Iter non genera hotel fittizi'),
          findsOneWidget,
        );

        // Verify confirmation CTA button
        expect(find.text('Conferma alloggio autonomo'), findsOneWidget);
        await tester.tap(find.text('Conferma alloggio autonomo'));
        await tester.pumpAndSettle();

        expect(selfBooked, isTrue);

        // Confirm stay purchase on session
        await session.confirmStayPurchase('self-booked-stay');
        expect(session.state.phase, OrganizationPhase.readyForPlan);
        expect(session.state.confirmedStay, isNotNull);
      },
    );
  });
}
