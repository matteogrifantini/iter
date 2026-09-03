import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';
import 'package:iter/features/trips/trips_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TripsListScreen mostra lista viaggi e permette di aprire chat o itinerario', (tester) async {
    final repo = TripRepository();
    await repo.saveTrip(
      TripEntity(
        id: 'trip-101',
        destination: 'Amsterdam',
        durationDays: 3,
        status: TripStatus.ready,
        coverImageUrl: '',
        createdAt: DateTime(2026, 9, 2),
      ),
    );

    String? openedChatTripId;
    String? openedSnapshotTripId;
    var startedNewTrip = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TripsListScreen(
          tripRepository: repo,
          onOpenTripChat: (trip) {
            openedChatTripId = trip.id;
          },
          onOpenTripSnapshot: (trip) {
            openedSnapshotTripId = trip.id;
          },
          onStartNewTrip: () {
            startedNewTrip = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I tuoi viaggi'), findsOneWidget);
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text('3 giorni'), findsOneWidget);

    // Tocca azione Chat
    expect(find.text('Chat'), findsOneWidget);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(openedChatTripId, 'trip-101');

    // Tocca azione Itinerario
    expect(find.text('Itinerario'), findsOneWidget);
    await tester.tap(find.text('Itinerario'));
    await tester.pumpAndSettle();
    expect(openedSnapshotTripId, 'trip-101');

    // Tocca Nuovo viaggio
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(startedNewTrip, isTrue);
  });
}
