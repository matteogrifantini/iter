import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/profile_models.dart';

void main() {
  test('availability entry normalizes the date and round-trips', () {
    final entry = AvailabilityEntry(
      id: 'free-1',
      date: DateTime(2026, 10, 24, 18),
      kind: AvailabilityKind.free,
      timeRange: 'Dopo le 18:00',
      note: 'Fine turno',
    );

    final rebuilt = AvailabilityEntry.fromJson(entry.toJson());

    expect(rebuilt.date, DateTime(2026, 10, 24));
    expect(rebuilt.kind, AvailabilityKind.free);
    expect(rebuilt.timeRange, 'Dopo le 18:00');
    expect(rebuilt.note, 'Fine turno');
  });

  test('travel stats expose stable mock values', () {
    const stats = TravelStats(
      completedTrips: 3,
      visitedPlaces: 18,
      estimatedKilometers: 1240,
    );

    expect(stats.completedTrips, 3);
    expect(stats.visitedPlaces, 18);
    expect(stats.estimatedKilometers, 1240);
  });
}
