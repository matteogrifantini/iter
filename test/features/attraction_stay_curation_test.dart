import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/chat/widgets/attraction_curation_card.dart';
import 'package:iter/features/chat/widgets/stay_selector_card.dart';
import 'package:iter/features/stays/stay_models.dart';
import 'package:iter/features/trips/trip_details_screen.dart';
import 'package:iter/features/trips/trip_entity.dart';

void main() {
  testWidgets('AttractionCurationCard visualizza attrazioni e permette selezione e conferma', (tester) async {
    final attractions = [
      const AttractionItem(
        id: 'attr-1',
        name: 'Duomo e terrazze',
        category: 'Monumento',
        why: 'Vista incredibile sulle guglie',
        imageUrl: 'https://example.com/duomo.jpg',
      ),
      const AttractionItem(
        id: 'attr-2',
        name: 'Castello Sforzesco',
        category: 'Storia',
        why: 'Cortili ducali e musei rinascimentali',
        imageUrl: 'https://example.com/castello.jpg',
      ),
      const AttractionItem(
        id: 'attr-3',
        name: 'Pinacoteca di Brera',
        category: 'Arte',
        why: 'I capolavori di Caravaggio e Hayez',
        imageUrl: 'https://example.com/brera.jpg',
      ),
    ];

    List<AttractionItem>? confirmedList;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AttractionCurationCard(
              destination: 'Milano',
              attractions: attractions,
              onConfirmed: (selected) {
                confirmedList = selected;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cosa vorresti vedere a Milano?'), findsOneWidget);
    expect(find.text('Duomo e terrazze'), findsOneWidget);
    expect(find.text('Castello Sforzesco'), findsOneWidget);
    expect(find.text('Pinacoteca di Brera'), findsOneWidget);

    // Tocca Conferma e trova alloggi
    final confirmBtn = find.text('Conferma e trova alloggi');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(confirmedList, isNotNull);
    expect(confirmedList!.length, greaterThanOrEqualTo(1));
    expect(find.textContaining('attrazioni scelte per Milano'), findsOneWidget);
  });

  testWidgets('StaySelectorCard visualizza hotel reali e salva alloggio nel viaggio', (tester) async {
    final stays = [
      const StayOffer(
        id: 'stay-1',
        name: 'Stories Boutique Hotel',
        type: StayType.boutiqueHotel,
        neighborhood: 'Distretto VI · Terézváros',
        ratingScore: 9.3,
        ratingCount: 1200,
        ratingLabel: 'Eccellente',
        pricePerNightEur: 89.0,
        amenities: ['WiFi', 'Colazione'],
        imageUrl: 'https://example.com/hotel.jpg',
        bookingUrl: 'https://google.com/travel/hotels',
        badgeLabel: 'Scelta Iter',
        walkingMinutesToCenter: 5,
      ),
    ];

    StayOffer? savedStay;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaySelectorCard(
              destination: 'Budapest',
              stays: stays,
              onSelectStay: (stay) {
                savedStay = stay;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alloggi ideali a Budapest'), findsOneWidget);
    expect(find.text('Stories Boutique Hotel'), findsOneWidget);
    expect(find.text('89€'), findsOneWidget);

    // Salva questo alloggio
    final saveBtn = find.text('Salva questo alloggio');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(savedStay, isNotNull);
    expect(savedStay!.name, 'Stories Boutique Hotel');
    expect(find.text('✓ Alloggio salvato nel viaggio'), findsOneWidget);
  });

  testWidgets('TripDetailsScreen visualizza attrazioni scelte e hotel salvato', (tester) async {
    final trip = TripEntity(
      id: 'trip-1',
      destination: 'Milano',
      durationDays: 3,
      status: TripStatus.planning,
      coverImageUrl: 'https://example.com/cover.jpg',
      createdAt: DateTime.now(),
      latestPlan: const GeminiTripPlanDraft(
        message: 'Itinerario pronto',
        destination: 'Milano',
        durationDays: 3,
        attractions: [
          AttractionItem(
            id: 'a1',
            name: 'Duomo di Milano',
            category: 'Monumento',
            why: 'Iconico',
            imageUrl: 'https://example.com/duomo.jpg',
          ),
        ],
        selectedStay: StayOffer(
          id: 's1',
          name: 'Hotel Milano Scala',
          type: StayType.boutiqueHotel,
          neighborhood: 'Brera',
          ratingScore: 9.1,
          ratingCount: 850,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 140.0,
          amenities: ['WiFi', 'Rooftop'],
          imageUrl: 'https://example.com/scala.jpg',
          bookingUrl: 'https://google.com',
          badgeLabel: 'Scelta Iter',
          walkingMinutesToCenter: 4,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(trip: trip),
      ),
    );

    expect(find.text('Milano'), findsWidgets);
    expect(find.text('Monumenti & Tappe scelte'), findsOneWidget);
    expect(find.text('Duomo di Milano'), findsOneWidget);
    expect(find.text('Dove alloggiare'), findsOneWidget);
    expect(find.text('Hotel Milano Scala'), findsOneWidget);
    expect(find.textContaining('140€/notte'), findsOneWidget);
  });
}
