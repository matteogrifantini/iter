import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/organization_session.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/models/organization_state.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';
import 'package:iter/features/organization/ui/cards/flight_comparison_card_view.dart';
import 'package:iter/features/organization/ui/dialogs/external_purchase_dialog.dart';

class _FakeAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse();
  }
}

void main() {
  group('Flight Purchase Flow & Explicit Confirmation Tests', () {
    late OrganizationSession session;

    setUp(() {
      session = OrganizationSession(
        tripId: 'trip-flight-test',
        aiGateway: _FakeAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      session.dispose();
    });

    testWidgets(
      'ExternalPurchaseDialog renders with 3 distinct settlement actions',
      (tester) async {
        PurchaseDialogResult? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await ExternalPurchaseDialog.show(
                        context,
                        providerName: 'TAP Air Portugal',
                        itemTitle: 'FCO → LIS (TAP Air Portugal TP831)',
                      );
                    },
                    child: const Text('Apri Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Apri Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Hai confermato questo volo?'), findsOneWidget);
        expect(find.textContaining('TAP Air Portugal'), findsWidgets);
        expect(find.text('Sì, confermato'), findsOneWidget);
        expect(find.text('Non ancora'), findsOneWidget);
        expect(find.text('Annulla selezione'), findsOneWidget);

        // Confirm settlement
        await tester.tap(find.text('Sì, confermato'));
        await tester.pumpAndSettle();
        expect(result, PurchaseDialogResult.confirmed);
      },
    );

    testWidgets(
      'Opening external purchase NEVER confirms purchase automatically',
      (tester) async {
        // 1. Start travel search
        await session.startTravelSearch();

        expect(session.state.phase, OrganizationPhase.awaitingFlightPurchase);
        final offer = session.state.flightOffers.first;

        // 2. Select flight
        session.selectFlight(offer.id);
        expect(session.state.selectedFlightId, offer.id);
        expect(session.state.confirmedFlight, isNull);

        // 3. Open external purchase
        await session.openExternalPurchase(
          offer.id,
          purchaseUrl: offer.deepLinkUrl,
        );

        // INVARIANT CHECK: External purchase opened must transition to awaitingFlightConfirmation
        // but confirmedFlight MUST REMAIN NULL.
        expect(
          session.state.phase,
          OrganizationPhase.awaitingFlightConfirmation,
        );
        expect(session.state.confirmedFlight, isNull);

        // 4. Confirm purchase explicitly
        await session.confirmFlightPurchase(
          offer.id,
          bookingReference: 'CONF-XYZ-123',
        );

        expect(session.state.phase, OrganizationPhase.collectingExperience);
        expect(session.state.confirmedFlight, isNotNull);
        expect(session.state.confirmedFlight!.id, offer.id);
        expect(
          session.state.confirmedFlightDecision!.status,
          DecisionStatus.confirmed,
        );
      },
    );

    testWidgets(
      'FlightComparisonCardView transitions from Seleziona to Continua sul sito del provider',
      (tester) async {
        await session.startTravelSearch();
        final card = session.state.cards.last;

        ProviderOffer? selectedOffer;
        ProviderOffer? providerOffer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FlightComparisonCardView(
                  card: card,
                  onOfferSelected: (o) => selectedOffer = o,
                  onContinueToProvider: (o) => providerOffer = o,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Seleziona'), findsWidgets);

        // Tap first Seleziona button
        await tester.tap(find.text('Seleziona').first);
        await tester.pumpAndSettle();

        expect(selectedOffer, isNotNull);
        expect(find.text('Continua sul sito del provider'), findsOneWidget);

        // Tap Continua sul sito del provider
        await tester.tap(find.text('Continua sul sito del provider'));
        await tester.pumpAndSettle();

        expect(providerOffer, isNotNull);
        expect(providerOffer!.id, selectedOffer!.id);
      },
    );
  });
}
