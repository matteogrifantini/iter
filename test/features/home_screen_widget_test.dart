import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/home/home_screen.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen NON contiene TextField chat ed espone banner e sezioni', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var openedChat = false;
    String? selectedDestination;


    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onOpenNewTripChat: ({destination}) {
              openedChat = true;
              selectedDestination = destination;
            },
            onOpenTripDetails: (_) {},
            onOpenProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificare che NON ci sia nessun campo di testo o composer chat nella Home!
    expect(find.byType(TextField), findsNothing);

    // Verificare il banner primario e il pulsante
    expect(find.text('Organizza un nuovo viaggio'), findsOneWidget);
    await tester.tap(find.text('Organizza un nuovo viaggio'));
    expect(openedChat, isTrue);
    expect(selectedDestination, isNull);

    // Verificare la presenza delle sezioni
    expect(find.text('Le tue pianificazioni'), findsOneWidget);
    expect(find.text('Consigli & Offerte per te'), findsOneWidget);
    expect(find.text('Scopri nuovi posti'), findsOneWidget);
  });

  testWidgets('HomeScreen mostra le card dei viaggi se presenti nel repository', (tester) async {
    final repo = TripRepository();
    await repo.saveTrip(
      TripEntity(
        id: 'trip-99',
        destination: 'Siviglia',
        durationDays: 4,
        status: TripStatus.planning,
        coverImageUrl: '',
        createdAt: DateTime(2026, 9, 2),
      ),
    );

    String? openedTripId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            tripRepository: repo,
            onOpenNewTripChat: ({destination}) {},
            onOpenTripDetails: (trip) {
              openedTripId = trip.id;
            },
            onOpenProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siviglia'), findsOneWidget);
    expect(find.text('4 giorni'), findsOneWidget);

    await tester.tap(find.text('Siviglia'));
    expect(openedTripId, 'trip-99');
  });
}
