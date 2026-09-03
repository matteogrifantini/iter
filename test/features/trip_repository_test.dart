import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TripRepository salva, recupera ed elimina viaggi in SharedPreferences', () async {
    final repo = TripRepository();

    final trip = TripEntity(
      id: 'trip-1',
      destination: 'Siviglia',
      durationDays: 4,
      status: TripStatus.planning,
      coverImageUrl: 'https://images.unsplash.com/photo-siviglia',
      createdAt: DateTime(2026, 9, 2),
      messages: [
        const ChatMessage(role: 'user', text: 'Vorrei andare a Siviglia'),
        const ChatMessage(role: 'assistant', text: 'Ecco una proposta splendida!'),
      ],
    );

    await repo.saveTrip(trip);
    var all = await repo.getAllTrips();
    expect(all.length, 1);
    expect(all.first.destination, 'Siviglia');
    expect(all.first.durationDays, 4);
    expect(all.first.messages.length, 2);

    final retrieved = await repo.getTripById('trip-1');
    expect(retrieved, isNotNull);
    expect(retrieved!.id, 'trip-1');

    await repo.deleteTrip('trip-1');
    all = await repo.getAllTrips();
    expect(all, isEmpty);
  });

  test('TripRepository aggiorna un viaggio esistente mantenendo l id', () async {
    final repo = TripRepository();

    final trip1 = TripEntity(
      id: 'trip-2',
      destination: 'Tokyo',
      durationDays: 7,
      status: TripStatus.planning,
      coverImageUrl: '',
      createdAt: DateTime(2026, 9, 2),
    );
    await repo.saveTrip(trip1);

    final updated = trip1.copyWith(
      status: TripStatus.ready,
      durationDays: 10,
    );
    await repo.saveTrip(updated);

    final all = await repo.getAllTrips();
    expect(all.length, 1);
    expect(all.first.durationDays, 10);
    expect(all.first.status, TripStatus.ready);
  });
}
