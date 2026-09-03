import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/places/destination_detail_sheet.dart';
import 'package:iter/features/places/attraction_detail_sheet.dart';
import 'package:iter/features/places/visual_media_service.dart';

void main() {
  testWidgets('DestinationDetailSheet visualizza periodo migliore, budget e consigli insider', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const visualData = DestinationVisualData(
      destination: 'Barcellona',
      tagline: 'Capolavori di Gaudí',
      images: ['https://example.com/bcn.jpg'],
      climatePill: '22°C Ideale',
      transportPill: 'Metro capillare',
      flightAdvicePill: 'Voli diretti da 45€',
      bestPeriod: 'Maggio - Giugno (evita Agosto)',
      averageDailyCost: '~115€ / giorno',
      insiderTips: ['Prenota la Sagrada Família online', 'Bunkers del Carmel al tramonto'],
      highlights: ['Sagrada Família', 'Park Güell'],
    );

    bool startedPlanning = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  DestinationDetailSheet.show(
                    context,
                    visualData: visualData,
                    onStartPlanning: () {
                      startedPlanning = true;
                    },
                  );
                },
                child: const Text('Apri Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Barcellona'), findsOneWidget);
    expect(find.text('Quando andare'), findsOneWidget);
    expect(find.text('Maggio - Giugno (evita Agosto)'), findsOneWidget);
    expect(find.text('Budget & Costi medi'), findsOneWidget);
    expect(find.text('~115€ / giorno'), findsOneWidget);
    expect(find.textContaining('Sagrada Família online'), findsOneWidget);

    final planBtn = find.text('Pianifica viaggio a Barcellona');
    await tester.ensureVisible(planBtn);
    await tester.pumpAndSettle();
    await tester.tap(planBtn);
    await tester.pumpAndSettle();

    expect(startedPlanning, isTrue);
  });

  testWidgets('AttractionDetailSheet visualizza dettagli monumento e permette like/skip', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const attraction = AttractionItem(
      id: 'sagrada',
      name: 'Sagrada Família',
      category: 'Capolavoro Modernista',
      why: 'La basilica incompiuta di Antoni Gaudí con luce spettacolare dalle vetrate colorate.',
      imageUrl: 'https://example.com/sagrada.jpg',
      estimatedTimeMinutes: 120,
    );

    bool liked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AttractionDetailSheet.show(
                    context,
                    attraction: attraction,
                    onLike: () {
                      liked = true;
                    },
                  );
                },
                child: const Text('Apri Attraction Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri Attraction Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sagrada Família'), findsOneWidget);
    expect(find.text('Capolavoro Modernista'), findsOneWidget);
    expect(find.textContaining('120 min di visita'), findsOneWidget);
    expect(find.text('Perché non perderlo'), findsOneWidget);

    final addBtn = find.text('Aggiungi all\'itinerario');
    await tester.ensureVisible(addBtn);
    await tester.pumpAndSettle();
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(liked, isTrue);
  });
}
