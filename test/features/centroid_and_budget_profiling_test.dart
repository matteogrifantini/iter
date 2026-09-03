import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/chat/widgets/cost_breakdown_card.dart';
import 'package:iter/features/chat/widgets/trip_profiling_card.dart';
import 'package:iter/features/stays/centroid_solver.dart';
import 'package:iter/features/stays/stay_models.dart';

void main() {
  test('CentroidSolver calcola baricentro per Lisbona tra Belem e Alfama', () {
    const solver = CentroidSolver();
    final attractions = [
      const AttractionItem(
        id: '1',
        name: 'Torre de Belém',
        category: 'Monumento',
        why: 'Icona',
        imageUrl: '',
      ),
      const AttractionItem(
        id: '2',
        name: 'Alfama & Miradouro',
        category: 'Panorami',
        why: 'Vista',
        imageUrl: '',
      ),
    ];

    final result = solver.solveOptimalArea(
      destination: 'Lisbona',
      chosenAttractions: attractions,
    );

    expect(result.optimalNeighborhood, contains('Baixa / Chiado'));
    expect(result.walkingScore, greaterThan(90));
    expect(result.averageMinutesToSpots, lessThanOrEqualTo(12));
  });

  testWidgets('TripProfilingCard permette scelta chi, vibe, ritmo e invia prompt', (tester) async {
    String? confirmedPrompt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TripProfilingCard(
              destination: 'Lisbona',
              onProfileConfirmed: (prompt) {
                confirmedPrompt = prompt;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Che tipo di viaggio desideri?'), findsOneWidget);
    expect(find.text('In coppia 💑'), findsOneWidget);
    expect(find.text('Cultura & Scorci 🏛️'), findsOneWidget);

    final btn = find.text('Personalizza viaggio a Lisbona');
    expect(btn, findsOneWidget);
    await tester.tap(btn);

    expect(confirmedPrompt, isNotNull);
    expect(confirmedPrompt, contains('In coppia'));
    expect(confirmedPrompt, contains('Cultura & Scorci'));
  });

  testWidgets('CostBreakdownCard visualizza preventivo trasparente aggregato', (tester) async {
    const plan = GeminiTripPlanDraft(
      message: 'Ecco il piano',
      destination: 'Lisbona',
      durationDays: 3,
      flight: FlightAdvice(
        outbound: 'Roma - Lisbona',
        priceEstimate: '75€ a/r',
        searchUrl: 'https://google.com',
      ),
      selectedStay: StayOffer(
        id: '1',
        name: 'AlmaLusa Baixa',
        type: StayType.boutiqueHotel,
        neighborhood: 'Baixa',
        ratingScore: 9.4,
        ratingCount: 500,
        ratingLabel: 'Top',
        pricePerNightEur: 98.0,
        amenities: [],
        imageUrl: '',
        bookingUrl: '',
        badgeLabel: 'Consigliato',
        walkingMinutesToCenter: 3,
      ),
      attractions: [
        AttractionItem(id: 'a1', name: 'Belem', category: '', why: '', imageUrl: ''),
        AttractionItem(id: 'a2', name: 'Alfama', category: '', why: '', imageUrl: ''),
      ],
    );

    bool openedSnapshot = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CostBreakdownCard(
              destination: 'Lisbona',
              durationDays: 3,
              plan: plan,
              onOpenSnapshot: () {
                openedSnapshot = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Preventivo Trasparente · Lisbona'), findsOneWidget);
    expect(find.text('Volo a/r da Roma'), findsOneWidget);
    expect(find.text('Soggiorno (2 notti)'), findsOneWidget);
    expect(find.text('TOTALE STIMATO VIAGGIO'), findsOneWidget);

    final saveBtn = find.text('Salva viaggio & vedi itinerario completo');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    expect(openedSnapshot, isTrue);
  });
}
