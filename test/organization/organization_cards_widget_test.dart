import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/flight_search_adapter.dart';
import 'package:iter/features/organization/models/organization_card.dart';
import 'package:iter/features/organization/models/organization_models.dart';
import 'package:iter/features/organization/ui/cards/flight_comparison_card_view.dart';
import 'package:iter/features/organization/ui/cards/intent_summary_card_view.dart';
import 'package:iter/features/organization/ui/cards/question_card_view.dart';
import 'package:iter/features/organization/ui/cards/search_status_card_view.dart';

void main() {
  group('Organization Cards UI & Responsiveness', () {
    testWidgets('IntentSummaryCardView renders desire and metadata', (
      tester,
    ) async {
      const card = OrganizationCard(
        id: 'c1',
        tripId: 't1',
        kind: OrganizationCardKind.intentSummary,
        title: 'Desiderio di viaggio',
        description: 'Voglio andare a Lisbona con buon cibo',
        payload: <String, dynamic>{
          'candidateDestinations': <String>['Lisbona'],
          'budgetEurPerPerson': 250.0,
        },
      );

      bool editTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntentSummaryCardView(
              card: card,
              onEditPressed: () => editTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Desiderio di viaggio'), findsOneWidget);
      expect(
        find.text('“Voglio andare a Lisbona con buon cibo”'),
        findsOneWidget,
      );
      expect(find.text('Lisbona'), findsOneWidget);
      expect(find.text('Target: ~250 € p.p.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editTapped, isTrue);
    });

    testWidgets('QuestionCardView renders options and triggers selection', (
      tester,
    ) async {
      const card = OrganizationCard(
        id: 'q1',
        tripId: 't1',
        kind: OrganizationCardKind.question,
        title: 'Da dove preferisci partire?',
        payload: <String, dynamic>{
          'options': <String>['Milano', 'Roma', 'Non lo so ancora'],
        },
      );

      String? selectedOption;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardView(
              card: card,
              onAnswerSelected: (opt) => selectedOption = opt,
            ),
          ),
        ),
      );

      expect(find.text('Da dove preferisci partire?'), findsOneWidget);
      expect(find.text('Milano'), findsOneWidget);
      expect(find.text('Roma'), findsOneWidget);

      await tester.tap(find.text('Milano'));
      expect(selectedOption, 'Milano');
    });

    testWidgets(
      'SearchStatusCardView renders activity spinner and description',
      (tester) async {
        const card = OrganizationCard(
          id: 's1',
          tripId: 't1',
          kind: OrganizationCardKind.searchStatus,
          title: 'Ricerca voli reali in corso',
          description: 'Confronto rotte da Milano a Porto...',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SearchStatusCardView(card: card)),
          ),
        );

        expect(find.text('Ricerca voli reali in corso'), findsOneWidget);
        expect(
          find.text('Confronto rotte da Milano a Porto...'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'FlightComparisonCardView renders offers and handles selection and sorting',
      (tester) async {
        final now = DateTime.now();
        final sampleOffer = ProviderOffer(
          id: 'fl-1',
          providerId: 'fast-flights',
          type: OfferType.flight,
          origin: 'Milano (MXP)',
          destination: 'Porto (OPO)',
          departureDate: now.add(const Duration(days: 15)),
          priceEur: 54.00,
          conditions: const <String, dynamic>{
            'airlineName': 'Ryanair',
            'flightNumber': 'FR 2083',
            'departureTime': '06:30',
            'arrivalTime': '08:15',
            'durationLabel': '2h 45m',
            'isDirect': true,
          },
          externalBookingUrl: 'https://google.com',
          fetchedAt: now,
          tradeoffSummary: 'Volo diretto (2h 45m) · Bagaglio incluso',
          badgeLabel: 'Più economico',
        );

        final card = OrganizationCard(
          id: 'fc-1',
          tripId: 't1',
          kind: OrganizationCardKind.flightComparison,
          title: 'Confronto Voli per Porto',
          description: 'Offerte disponibili',
          payload: <String, dynamic>{
            'offers': <ProviderOffer>[sampleOffer],
            'sortBy': 'best',
          },
        );

        ProviderOffer? selectedOffer;
        FlightSortCriterion? sortChanged;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FlightComparisonCardView(
                  card: card,
                  onOfferSelected: (o) => selectedOffer = o,
                  onSortCriterionChanged: (s) => sortChanged = s,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Confronto Voli per Porto'), findsOneWidget);
        expect(find.text('Ryanair FR 2083'), findsOneWidget);
        expect(find.text('€ 54.00'), findsOneWidget);
        expect(
          find.text('Volo diretto (2h 45m) · Bagaglio incluso'),
          findsOneWidget,
        );

        // Select offer
        await tester.tap(find.widgetWithText(FilledButton, 'Seleziona'));
        expect(selectedOffer?.id, 'fl-1');

        // Change sort
        await tester.tap(find.text('Economici'));
        expect(sortChanged, FlightSortCriterion.cheapest);
      },
    );

    testWidgets('Responsive stress test at 320, 360, 390 dp without overflow', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 390.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        final card = OrganizationCard(
          id: 'q1',
          tripId: 't1',
          kind: OrganizationCardKind.question,
          title:
              'Qual è il tuo budget indicativo a persona per questo viaggio?',
          payload: const <String, dynamic>{
            'options': <String>[
              'Sotto i 150 €',
              '150–300 €',
              '300–500 €',
              'Libero',
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: QuestionCardView(card: card, onAnswerSelected: (_) {}),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
