import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/chat/widgets/destination_hero_card.dart';
import 'package:iter/features/chat/widgets/monument_swipe_deck.dart';
import 'package:iter/features/chat/widgets/animated_route_map_card.dart';
import 'package:iter/features/places/visual_media_service.dart';

void main() {
  test('VisualMediaService restituisce dati curati per mete note', () async {
    final service = VisualMediaService();
    final lisbon = await service.getVisualData('Lisbona');
    expect(lisbon.destination, 'Lisbona');
    expect(lisbon.images.length, greaterThanOrEqualTo(2));
    expect(lisbon.climatePill, contains('Autunno'));
  });

  testWidgets('DestinationHeroCard visualizza carosello foto e pillole informative', (tester) async {
    const visualData = DestinationVisualData(
      destination: 'Lisbona',
      tagline: 'Luce dorata sull\'Atlantico',
      images: [
        'https://example.com/lisbon1.jpg',
        'https://example.com/lisbon2.jpg',
      ],
      climatePill: '20°C Ideale',
      transportPill: 'Tram 28',
      flightAdvicePill: 'Voli diretti da 65€',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DestinationHeroCard(
              visualData: visualData,
            ),
          ),
        ),
      ),
    );


    expect(find.text('Lisbona'), findsOneWidget);
    expect(find.text('Luce dorata sull\'Atlantico'), findsOneWidget);
    expect(find.text('20°C Ideale'), findsOneWidget);
    expect(find.text('Tram 28'), findsOneWidget);

    final btn = find.text('Scopri Lisbona · Info, periodo & costi');
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(find.text('Quando andare'), findsOneWidget);
  });


  testWidgets('MonumentSwipeDeck permette swipe/like e visualizza stima ore', (tester) async {
    final attractions = [
      const AttractionItem(
        id: '1',
        name: 'Torre de Belém',
        category: 'Monumento',
        why: 'Icona sul fiume Tago',
        imageUrl: 'https://example.com/belem.jpg',
        estimatedTimeMinutes: 60,
      ),
      const AttractionItem(
        id: '2',
        name: 'Mosteiro dos Jerónimos',
        category: 'Architettura Manuelina',
        why: 'Chiostro maestoso',
        imageUrl: 'https://example.com/jeronimos.jpg',
        estimatedTimeMinutes: 90,
      ),
    ];

    List<AttractionItem>? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonumentSwipeDeck(
              destination: 'Lisbona',
              attractions: attractions,
              durationDays: 2,
              onConfirmed: (chosen) {
                confirmed = chosen;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Scegli cosa vedere a Lisbona'), findsOneWidget);
    expect(find.text('Torre de Belém'), findsOneWidget);

    // Tocca "Mi piace"
    final likeBtn = find.text('Mi piace');
    expect(likeBtn, findsOneWidget);
    await tester.tap(likeBtn);
    await tester.pumpAndSettle();

    // Ora mostra la seconda attrazione
    expect(find.text('Mosteiro dos Jerónimos'), findsOneWidget);

    // Tocca "Salta"
    final skipBtn = find.text('Salta');
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    // Ora ha finito e mostra il riassunto
    expect(find.text('✓ 1 attrazioni scelte per Lisbona'), findsOneWidget);
    expect(find.text('Torre de Belém'), findsOneWidget);

    final confirmAll = find.text('Conferma scelte e trova alloggi nella zona ideale');
    expect(confirmAll, findsOneWidget);
    await tester.tap(confirmAll);

    expect(confirmed, isNotNull);
    expect(confirmed!.length, 1);
    expect(confirmed!.first.name, 'Torre de Belém');
  });

  testWidgets('AnimatedRouteMapCard visualizza canvas rotta e tappe della giornata', (tester) async {
    const day = DailyPlanDraft(
      dayNumber: 1,
      theme: 'Esplorazione Storica',
      stops: [
        'Belém & Pastéis de Belém',
        'Mosteiro dos Jerónimos',
        'Tramonto a Miradouro de Santa Luzia',
      ],
      diningRecommendation: 'Tasca tipica per bacalhau à brás',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnimatedRouteMapCard(
              destination: 'Lisbona',
              day: day,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rotta Viva · Giorno 1'), findsOneWidget);
    expect(find.text('Esplorazione Storica'), findsOneWidget);
    expect(find.text('Belém & Pastéis de Belém'), findsOneWidget);
    expect(find.text('Mosteiro dos Jerónimos'), findsOneWidget);
    expect(find.text('Tramonto a Miradouro de Santa Luzia'), findsOneWidget);
    expect(find.text('Pausa Gastronomica tipica'), findsOneWidget);
    expect(find.textContaining('km a piedi complessivi'), findsOneWidget);
  });
}
