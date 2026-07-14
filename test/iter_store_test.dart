import 'package:flutter_test/flutter_test.dart';
import 'package:iter/data/mock_data.dart';
import 'package:iter/models/trip_models.dart';
import 'package:iter/state/iter_store.dart';

void main() {
  test('every launch city has enough local places and stay zones to plan', () {
    expect(MockData.destinations, hasLength(8));

    for (final destination in MockData.destinations) {
      final places = MockData.places
          .where((place) => place.destinationId == destination.id)
          .length;
      final zones = MockData.stayZones
          .where((zone) => zone.destinationId == destination.id)
          .length;
      expect(places, greaterThanOrEqualTo(6), reason: destination.name);
      expect(zones, greaterThanOrEqualTo(3), reason: destination.name);
    }
  });

  test('the demo mixes city ideas and routes with every arrival mode', () {
    final singleCities = MockData.journeys
        .where((journey) => journey.stops.length == 1)
        .map((journey) => journey.stops.single)
        .toSet();
    expect(singleCities, containsAll(<String>{'Roma', 'Parigi', 'Barcellona'}));
    expect(
      MockData.journeys.every(
        (journey) => journey.videoAssets.single.endsWith('_sequence.mp4'),
      ),
      isTrue,
    );

    final options = MockData.transportOptionsFor('Parigi');
    expect(
      options.map((option) => option.kind).toSet(),
      equals(TransportKind.values.toSet()),
    );
    expect(options.every((option) => option.logoAsset.isNotEmpty), isTrue);
  });

  test(
    'a destination can become a visible itinerary through explicit choices',
    () {
      final store = IterStore.seeded(clock: () => DateTime(2026, 7, 12, 10));
      store.beginNewTrip(note: 'Vorrei camminare e mangiare bene');

      expect(store.currentDraft!.stage, TripStage.destinationDiscovery);
      expect(
        store.chooseDestination(MockData.destinationById('porto')),
        isTrue,
      );

      final places = store.activeDestinationPlaces
          .take(IterStore.placesTarget)
          .toList();
      for (final place in places) {
        expect(
          store.reactToPlace(PlaceReaction.save, placeId: place.id),
          isTrue,
        );
      }

      expect(store.currentDraft!.selectedPlaceCount, IterStore.placesTarget);
      expect(store.currentDraft!.stage, TripStage.transportSelection);
      final transport = store.suggestedTransportOptions.first;
      expect(store.selectTransportOption(transport), isTrue);
      expect(store.currentDraft!.transportOption?.id, transport.id);
      expect(store.currentDraft!.stage, TripStage.staySelection);
      expect(
        store.selectStayZone(MockData.stayZoneById('porto-cedofeita')),
        isTrue,
      );
      expect(store.currentDraft!.stage, TripStage.itinerary);
      expect(store.currentDraft!.days, isNotEmpty);
    },
  );

  test('a journey can curate places and stays across more than one city', () {
    final store = IterStore.seeded(clock: () => DateTime(2026, 7, 12, 10));
    store.beginNewTrip();
    store.answerDiscovery('return_feeling', 'Rigenerato');
    store.answerDiscovery('rhythm', 'Spostarmi in treno');

    final journey = MockData.journeyById('atlantic-rail');
    expect(store.chooseJourney(journey), isTrue);
    expect(store.currentDraft!.journey, journey);
    expect(
      store.activeDestinationPlaces.map((place) => place.destinationId).toSet(),
      containsAll(<String>{'lisbona', 'porto'}),
    );

    final selected = <Place>[
      ...store.activeDestinationPlaces
          .where((place) => place.destinationId == 'lisbona')
          .take(2),
      ...store.activeDestinationPlaces
          .where((place) => place.destinationId == 'porto')
          .take(2),
    ];
    for (final place in selected) {
      expect(store.reactToPlace(PlaceReaction.save, placeId: place.id), isTrue);
    }

    expect(store.currentDraft!.selectedPlaceCount, IterStore.placesTarget);
    expect(store.currentDraft!.stage, TripStage.transportSelection);
    final train = store.suggestedTransportOptions.firstWhere(
      (option) => option.kind == TransportKind.train,
    );
    expect(store.selectTransportOption(train), isTrue);
    expect(store.currentDraft!.transportOption?.kind, TransportKind.train);
    expect(
      store.selectStayZone(MockData.stayZoneById('porto-cedofeita')),
      isTrue,
    );
    expect(store.currentDraft!.days, isNotEmpty);
  });

  test(
    'locked stops cannot be removed and AI reports a visible local change',
    () {
      final store = IterStore.seeded(clock: () => DateTime(2026, 7, 12, 10));
      final trip = store.resumableTrips.first;
      expect(store.resumeTrip(trip.id), isTrue);
      final item = store.currentDraft!.days.first.items.first;

      expect(store.toggleItineraryLock(item.id), isTrue);
      expect(store.removeItineraryItem(item.id), isFalse);

      final countBefore = store.currentDraft!.days.first.items.length;
      store.sendAiMessage('Aggiungi una cena speciale');
      final updated = store.currentDraft!;

      expect(updated.days.first.items.length, greaterThan(countBefore));
      expect(updated.messages.last.planChange, contains('cena libera'));
      expect(store.canUndoAiChange, isTrue);
      expect(store.undoLastAiChange(), isTrue);
      expect(store.currentDraft!.days.first.items.length, countBefore);
      expect(store.canUndoAiChange, isFalse);
    },
  );
}
