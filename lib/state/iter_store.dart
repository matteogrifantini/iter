import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/trip_models.dart';

/// App state for Iter's guided, editable trip flow.
///
/// It deliberately has no networking concerns: a Supabase-backed repository can
/// hydrate and persist the same models later, while this store remains usable
/// offline and in widget tests.
class IterStore extends ChangeNotifier {
  IterStore({
    List<Trip>? initialTrips,
    List<Destination>? destinations,
    List<Place>? places,
    List<StayZone>? stayZones,
    List<TravelTrend>? trends,
    List<JourneyRoute>? journeys,
    DateTime Function()? clock,
    String? initialActiveTripId,
  }) : _clock = clock ?? DateTime.now,
       _trips = List<Trip>.from(initialTrips ?? const <Trip>[]),
       _destinations = List<Destination>.from(
         destinations ?? MockData.destinations,
       ),
       _places = List<Place>.from(places ?? MockData.places),
       _stayZones = List<StayZone>.from(stayZones ?? MockData.stayZones),
       _trends = List<TravelTrend>.from(trends ?? MockData.trends),
       _journeys = List<JourneyRoute>.from(journeys ?? MockData.journeys),
       _activeTripId = initialActiveTripId {
    _activeTripId ??= _firstResumableTripId();
  }

  factory IterStore.seeded({DateTime Function()? clock}) {
    final effectiveClock = clock ?? DateTime.now;
    return IterStore(
      initialTrips: MockData.initialTrips(effectiveClock()),
      clock: effectiveClock,
    );
  }

  static const int placesTarget = 4;

  final DateTime Function() _clock;
  final List<Trip> _trips;
  final List<Destination> _destinations;
  final List<Place> _places;
  final List<StayZone> _stayZones;
  final List<TravelTrend> _trends;
  final List<JourneyRoute> _journeys;
  final Map<String, List<Trip>> _aiUndoSnapshots = <String, List<Trip>>{};
  String? _activeTripId;
  int _idCounter = 0;

  List<Trip> get trips => List<Trip>.unmodifiable(_trips);

  List<Trip> get resumableTrips =>
      List<Trip>.unmodifiable(_trips.where((trip) => trip.isResumable));

  List<Trip> get completedTrips => List<Trip>.unmodifiable(
    _trips.where((trip) => trip.status == TripStatus.completed),
  );

  /// Current editable plan. It can be in destination discovery, not just the
  /// final itinerary stage.
  Trip? get currentDraft => _tripById(_activeTripId);

  Trip? get activeTrip => currentDraft;

  List<Destination> get availableDestinations =>
      List<Destination>.unmodifiable(_destinations);

  List<TravelTrend> get trends => List<TravelTrend>.unmodifiable(_trends);

  List<JourneyRoute> get journeys => List<JourneyRoute>.unmodifiable(_journeys);

  List<JourneyRoute> get recommendedJourneys {
    final answers = currentDraft?.discoveryAnswers.values
        .join(' ')
        .toLowerCase();
    final ranked = <JourneyRoute>[..._journeys];
    if (answers != null && answers.contains('treno')) {
      ranked.sort((left, right) {
        final leftRail = left.travelMode.toLowerCase().contains('treno');
        final rightRail = right.travelMode.toLowerCase().contains('treno');
        if (leftRail != rightRail) return leftRail ? -1 : 1;
        return right.matchScore.compareTo(left.matchScore);
      });
    } else {
      ranked.sort((left, right) => right.matchScore.compareTo(left.matchScore));
    }
    return List<JourneyRoute>.unmodifiable(ranked);
  }

  List<Place> get selectedPlaces {
    final trip = currentDraft;
    if (trip?.destination == null) {
      return const <Place>[];
    }

    final selectedIds = trip!.selectedPlaceIds.toSet();
    final places = _places
        .where(
          (place) =>
              (trip.journey?.destinationIds.contains(place.destinationId) ??
                  place.destinationId == trip.destination!.id) &&
              selectedIds.contains(place.id),
        )
        .toList();
    places.sort((left, right) {
      final leftReaction = trip.reactions[left.id];
      final rightReaction = trip.reactions[right.id];
      final leftWeight = leftReaction == PlaceReaction.mustSee ? 1 : 0;
      final rightWeight = rightReaction == PlaceReaction.mustSee ? 1 : 0;
      if (leftWeight != rightWeight) {
        return rightWeight.compareTo(leftWeight);
      }
      return right.matchScore.compareTo(left.matchScore);
    });
    return List<Place>.unmodifiable(places);
  }

  int get selectedPlacesCount => currentDraft?.selectedPlaceCount ?? 0;

  bool get canUndoAiChange {
    final tripId = currentDraft?.id;
    return tripId != null && (_aiUndoSnapshots[tripId]?.isNotEmpty ?? false);
  }

  /// Next undecided place in the deck, ordered by personal fit.
  Place? get currentPlace {
    final trip = currentDraft;
    final destination = trip?.destination;
    if (destination == null) {
      return null;
    }

    final candidates =
        _places
            .where(
              (place) =>
                  place.destinationId == destination.id &&
                  !trip!.reactions.containsKey(place.id),
            )
            .toList()
          ..sort((left, right) => right.matchScore.compareTo(left.matchScore));
    return candidates.isEmpty ? null : candidates.first;
  }

  List<Place> get activeDestinationPlaces {
    final destination = currentDraft?.destination;
    if (destination == null) {
      return const <Place>[];
    }
    final destinationIds =
        currentDraft?.journey?.destinationIds ?? <String>[destination.id];
    return List<Place>.unmodifiable(
      _places.where((place) => destinationIds.contains(place.destinationId)),
    );
  }

  List<StayZone> get suggestedStayZones {
    final destination = currentDraft?.destination;
    if (destination == null) {
      return const <StayZone>[];
    }
    final destinationIds =
        currentDraft?.journey?.destinationIds ?? <String>[destination.id];
    final zones =
        _stayZones
            .where((zone) => destinationIds.contains(zone.destinationId))
            .toList()
          ..sort((left, right) {
            final byDestination = destinationIds
                .indexOf(left.destinationId)
                .compareTo(destinationIds.indexOf(right.destinationId));
            if (byDestination != 0) return byDestination;
            return left.averageWalkMinutes.compareTo(right.averageWalkMinutes);
          });
    return List<StayZone>.unmodifiable(zones);
  }

  List<TransportOption> get suggestedTransportOptions {
    final trip = currentDraft;
    final target = trip?.journey?.stops.first ?? trip?.destination?.name;
    if (target == null) return const <TransportOption>[];
    return List<TransportOption>.unmodifiable(
      MockData.transportOptionsFor(target),
    );
  }

  /// Starts a new, separate destination-discovery conversation.
  Trip beginNewTrip({String note = ''}) {
    final now = _clock();
    final trip = Trip(
      id: _newId('trip'),
      title: 'Nuova idea di viaggio',
      stage: TripStage.destinationDiscovery,
      status: TripStatus.draft,
      createdAt: now,
      updatedAt: now,
      discoveryNote: note.trim(),
      discoveryAnswers: const <String, String>{},
      messages: <AiMessage>[
        AiMessage(
          id: _newId('assistant'),
          role: AiMessageRole.assistant,
          text:
              'Raccontami come vuoi sentirti quando parti. Troviamo la meta insieme.',
          createdAt: now,
        ),
      ],
    );
    _trips.insert(0, trip);
    _activeTripId = trip.id;
    notifyListeners();
    return trip;
  }

  Trip beginDestinationDiscovery({String note = ''}) =>
      beginNewTrip(note: note);

  bool resumeTrip(String tripId) {
    final trip = _tripById(tripId);
    if (trip == null) {
      return false;
    }
    _activeTripId = trip.id;
    notifyListeners();
    return true;
  }

  bool updateDiscoveryNote(String note) {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    _discardAiUndo(trip.id);
    _replaceTrip(
      trip.copyWith(discoveryNote: note.trim(), updatedAt: _clock()),
    );
    return true;
  }

  bool answerDiscovery(String key, String value) {
    final trip = currentDraft;
    final cleanValue = value.trim();
    if (trip == null || cleanValue.isEmpty) return false;
    final answers = <String, String>{...trip.discoveryAnswers, key: cleanValue};
    _replaceTrip(
      trip.copyWith(
        discoveryAnswers: answers,
        discoveryNote: answers.values.join(' · '),
        updatedAt: _clock(),
      ),
    );
    return true;
  }

  void sendDiscoveryMessage(String key, String text) {
    final cleanText = text.trim();
    final trip = currentDraft;
    if (trip == null || cleanText.isEmpty) return;
    final now = _clock();
    final answers = <String, String>{...trip.discoveryAnswers, key: cleanText};
    _replaceTrip(
      trip.copyWith(
        discoveryAnswers: answers,
        discoveryNote: answers.values.join(' · '),
        messages: <AiMessage>[
          ...trip.messages,
          AiMessage(
            id: _newId('traveler'),
            role: AiMessageRole.traveler,
            text: cleanText,
            createdAt: now,
          ),
          AiMessage(
            id: _newId('assistant'),
            role: AiMessageRole.assistant,
            text: 'Ricevuto. Lo tengo dentro al viaggio mentre continuiamo.',
            createdAt: now,
            planChange: 'Preferenza aggiornata',
          ),
        ],
        updatedAt: now,
      ),
    );
  }

  bool chooseJourney(JourneyRoute journey) {
    final trip = currentDraft;
    if (trip == null || journey.destinationIds.isEmpty) return false;
    final destination = _destinations.firstWhere(
      (item) => item.id == journey.destinationIds.first,
    );
    _discardAiUndo(trip.id);
    final now = _clock();
    _replaceTrip(
      trip.copyWith(
        title: journey.title,
        journey: journey,
        destination: destination,
        stage: TripStage.placeCuration,
        status: TripStatus.active,
        reactions: const <String, PlaceReaction>{},
        days: const <ItineraryDay>[],
        clearStayZone: true,
        clearTransportOption: true,
        messages: <AiMessage>[
          ...trip.messages,
          AiMessage(
            id: _newId('assistant'),
            role: AiMessageRole.assistant,
            text:
                '${journey.title} tiene insieme quello che mi hai raccontato. Ora scegliamo cosa merita spazio lungo il percorso.',
            createdAt: now,
            planChange: 'Viaggio scelto: ${journey.title}',
          ),
        ],
        updatedAt: now,
      ),
    );
    return true;
  }

  bool chooseDestination(Destination destination) {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    _discardAiUndo(trip.id);

    final now = _clock();
    final assistant = AiMessage(
      id: _newId('assistant'),
      role: AiMessageRole.assistant,
      text:
          '${destination.name} ha il ritmo giusto. Ora scegliamo cosa merita davvero il tuo tempo.',
      createdAt: now,
      planChange: 'Meta scelta: ${destination.name}',
    );
    _replaceTrip(
      trip.copyWith(
        title: '${destination.name} da immaginare',
        destination: destination,
        clearJourney: true,
        stage: TripStage.placeCuration,
        status: TripStatus.active,
        reactions: const <String, PlaceReaction>{},
        days: const <ItineraryDay>[],
        clearStayZone: true,
        clearTransportOption: true,
        messages: <AiMessage>[...trip.messages, assistant],
        updatedAt: now,
      ),
    );
    return true;
  }

  /// Reacts to the current card by default. [placeId] lets a manual list use
  /// the same intent without faking a swipe.
  bool reactToPlace(PlaceReaction reaction, {String? placeId}) {
    final trip = currentDraft;
    final destination = trip?.destination;
    final targetId = placeId ?? currentPlace?.id;
    if (trip == null || destination == null || targetId == null) {
      return false;
    }
    _discardAiUndo(trip.id);

    final destinationIds =
        trip.journey?.destinationIds ?? <String>[destination.id];
    final placeExists = _places.any(
      (place) =>
          place.id == targetId && destinationIds.contains(place.destinationId),
    );
    if (!placeExists) {
      return false;
    }

    final reactions = Map<String, PlaceReaction>.from(trip.reactions)
      ..[targetId] = reaction;
    var stage = trip.stage;
    final selectedCount = reactions.values
        .where((value) => value != PlaceReaction.skip)
        .length;
    if (stage == TripStage.placeCuration && selectedCount >= placesTarget) {
      stage = TripStage.transportSelection;
    }
    _replaceTrip(
      trip.copyWith(reactions: reactions, stage: stage, updatedAt: _clock()),
    );
    return true;
  }

  bool beginTransportSelection() {
    final trip = currentDraft;
    if (trip == null ||
        trip.destination == null ||
        trip.selectedPlaceCount == 0) {
      return false;
    }
    _discardAiUndo(trip.id);
    _replaceTrip(
      trip.copyWith(stage: TripStage.transportSelection, updatedAt: _clock()),
    );
    return true;
  }

  bool selectTransportOption(TransportOption option) {
    final trip = currentDraft;
    if (trip == null || trip.destination == null) return false;
    final allowed = suggestedTransportOptions.any(
      (candidate) => candidate.id == option.id,
    );
    if (!allowed) return false;
    _discardAiUndo(trip.id);
    final now = _clock();
    final kindLabel = switch (option.kind) {
      TransportKind.flight => 'Volo',
      TransportKind.train => 'Treno',
      TransportKind.bus => 'Bus',
      TransportKind.car => 'Auto',
    };
    _replaceTrip(
      trip.copyWith(
        transportOption: option,
        stage: TripStage.staySelection,
        messages: <AiMessage>[
          ...trip.messages,
          AiMessage(
            id: _newId('assistant'),
            role: AiMessageRole.assistant,
            text:
                '${option.title} diventa il riferimento per l’inizio del viaggio. Nessun biglietto è stato acquistato.',
            createdAt: now,
            planChange: '$kindLabel scelto: ${option.title}',
          ),
        ],
        updatedAt: now,
      ),
    );
    return true;
  }

  bool beginStaySelection() {
    final trip = currentDraft;
    if (trip == null ||
        trip.destination == null ||
        trip.selectedPlaceCount == 0) {
      return false;
    }
    _discardAiUndo(trip.id);
    _replaceTrip(
      trip.copyWith(stage: TripStage.staySelection, updatedAt: _clock()),
    );
    return true;
  }

  bool selectStayZone(StayZone zone) {
    final trip = currentDraft;
    final destinationId = trip?.destination?.id;
    final allowedDestinations =
        trip?.journey?.destinationIds ??
        (destinationId == null ? const <String>[] : <String>[destinationId]);
    if (trip == null || !allowedDestinations.contains(zone.destinationId)) {
      return false;
    }
    _discardAiUndo(trip.id);

    final now = _clock();
    final days = trip.days.isEmpty ? _buildInitialDays(trip) : trip.days;
    final assistant = AiMessage(
      id: _newId('assistant'),
      role: AiMessageRole.assistant,
      text:
          '${zone.name} tiene insieme le tue tappe senza rubare tempo al viaggio.',
      createdAt: now,
      planChange: 'Zona dove dormire: ${zone.name}',
    );
    _replaceTrip(
      trip.copyWith(
        title: trip.journey?.title ?? '${trip.destination!.name} con calma',
        stayZone: zone,
        stage: TripStage.itinerary,
        status: TripStatus.active,
        days: days,
        messages: <AiMessage>[...trip.messages, assistant],
        updatedAt: now,
      ),
    );
    return true;
  }

  bool chooseStayZone(StayZone zone) => selectStayZone(zone);

  bool toggleAvailability(DateTime date) {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    _discardAiUndo(trip.id);
    final normalized = _dateOnly(date);
    final available = <DateTime>[...trip.availableDates];
    final existing = available.indexWhere(
      (value) => _sameDate(value, normalized),
    );
    if (existing >= 0) {
      available.removeAt(existing);
    } else {
      available.add(normalized);
      available.sort();
    }
    _replaceTrip(trip.copyWith(availableDates: available, updatedAt: _clock()));
    return true;
  }

  /// Adds the traveler's message, then applies one visible, deterministic
  /// itinerary edit. The reply summarizes the edit instead of exposing model
  /// reasoning.
  void sendAiMessage(String text) {
    final cleanText = text.trim();
    final trip = currentDraft;
    if (trip == null || cleanText.isEmpty) {
      return;
    }

    final now = _clock();
    final traveler = AiMessage(
      id: _newId('traveler'),
      role: AiMessageRole.traveler,
      text: cleanText,
      createdAt: now,
    );
    final result = _planForMessage(trip, cleanText);
    final assistant = AiMessage(
      id: _newId('assistant'),
      role: AiMessageRole.assistant,
      text: result.reply,
      createdAt: now,
      planChange: result.planChange,
    );
    if (result.planChange != null) {
      _rememberAiUndo(trip);
    }
    _replaceTrip(
      trip.copyWith(
        stage: result.days.isNotEmpty ? TripStage.itinerary : trip.stage,
        status: trip.status == TripStatus.draft
            ? TripStatus.active
            : trip.status,
        days: result.days.isEmpty ? trip.days : result.days,
        messages: <AiMessage>[...trip.messages, traveler, assistant],
        updatedAt: now,
      ),
    );
  }

  /// Reverts the last local AI patch. This never tries to undo an accepted
  /// itinerary version on the server; it only restores the in-memory draft.
  bool undoLastAiChange() {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    final snapshots = _aiUndoSnapshots[trip.id];
    if (snapshots == null || snapshots.isEmpty) {
      return false;
    }
    final previous = snapshots.removeLast();
    _replaceTrip(previous.copyWith(updatedAt: _clock()));
    return true;
  }

  bool toggleItineraryLock(String itemId) {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    _discardAiUndo(trip.id);
    var changed = false;
    final days = trip.days.map((day) {
      final items = day.items.map((item) {
        if (item.id != itemId) {
          return item;
        }
        changed = true;
        return item.copyWith(isLocked: !item.isLocked);
      }).toList();
      return day.copyWith(items: items);
    }).toList();
    if (!changed) {
      return false;
    }
    _replaceTrip(trip.copyWith(days: days, updatedAt: _clock()));
    return true;
  }

  bool removeItineraryItem(String itemId) {
    final trip = currentDraft;
    if (trip == null) {
      return false;
    }
    _discardAiUndo(trip.id);
    var changed = false;
    final days = trip.days.map((day) {
      final items = day.items.where((item) {
        final canRemove = item.id == itemId && !item.isLocked;
        changed = changed || canRemove;
        return !canRemove;
      }).toList();
      return day.copyWith(items: items);
    }).toList();
    if (!changed) {
      return false;
    }
    _replaceTrip(trip.copyWith(days: days, updatedAt: _clock()));
    return true;
  }

  bool completeDraft() {
    final trip = currentDraft;
    if (trip == null || trip.destination == null || trip.days.isEmpty) {
      return false;
    }
    _discardAiUndo(trip.id);
    _replaceTrip(
      trip.copyWith(
        stage: TripStage.ready,
        status: TripStatus.completed,
        updatedAt: _clock(),
      ),
    );
    return true;
  }

  bool completeActiveTrip() => completeDraft();

  void _replaceTrip(Trip nextTrip) {
    final index = _trips.indexWhere((trip) => trip.id == nextTrip.id);
    if (index < 0) {
      return;
    }
    _trips[index] = nextTrip;
    _activeTripId = nextTrip.id;
    notifyListeners();
  }

  void _rememberAiUndo(Trip trip) {
    final snapshots = _aiUndoSnapshots.putIfAbsent(trip.id, () => <Trip>[]);
    snapshots.add(trip);
  }

  void _discardAiUndo(String tripId) {
    _aiUndoSnapshots.remove(tripId);
  }

  Trip? _tripById(String? id) {
    if (id == null) {
      return null;
    }
    for (final trip in _trips) {
      if (trip.id == id) {
        return trip;
      }
    }
    return null;
  }

  String? _firstResumableTripId() {
    for (final trip in _trips) {
      if (trip.isResumable) {
        return trip.id;
      }
    }
    return null;
  }

  String _newId(String prefix) {
    _idCounter += 1;
    return '$prefix-${_clock().microsecondsSinceEpoch}-$_idCounter';
  }

  List<ItineraryDay> _buildInitialDays(Trip trip) {
    final destination = trip.destination;
    if (destination == null) {
      return const <ItineraryDay>[];
    }
    final picked = _selectedPlacesFor(trip);
    if (picked.isEmpty) {
      return const <ItineraryDay>[];
    }
    final firstDay = <ItineraryItem>[];
    final secondDay = <ItineraryItem>[];
    final slots = <String>['10:00', '13:00', '17:30', '20:30'];
    for (var index = 0; index < picked.length && index < 8; index += 1) {
      final place = picked[index];
      final item = ItineraryItem(
        id: _newId('stop'),
        placeId: place.id,
        title: place.name,
        category: place.category,
        startTime: slots[(index ~/ 2) % slots.length],
        durationMinutes: place.durationMinutes,
        note: place.bestMoment,
        isLocked: trip.reactions[place.id] == PlaceReaction.mustSee,
      );
      if (index.isEven) {
        firstDay.add(item);
      } else {
        secondDay.add(item);
      }
    }
    return <ItineraryDay>[
      ItineraryDay(
        id: _newId('day'),
        label: 'Giorno 1',
        theme:
            trip.journey?.stops.take(2).join(' → ') ??
            '${destination.name} senza fretta',
        items: firstDay,
      ),
      if (secondDay.isNotEmpty)
        ItineraryDay(
          id: _newId('day'),
          label: 'Giorno 2',
          theme: 'Spazio per quello che scopri strada facendo',
          items: secondDay,
        ),
    ];
  }

  List<Place> _selectedPlacesFor(Trip trip) {
    final selectedIds = trip.selectedPlaceIds.toSet();
    final picked = _places
        .where(
          (place) =>
              (trip.journey?.destinationIds.contains(place.destinationId) ??
                  place.destinationId == trip.destination?.id) &&
              selectedIds.contains(place.id),
        )
        .toList();
    picked.sort((left, right) {
      final leftReaction = trip.reactions[left.id];
      final rightReaction = trip.reactions[right.id];
      final leftWeight = leftReaction == PlaceReaction.mustSee ? 1 : 0;
      final rightWeight = rightReaction == PlaceReaction.mustSee ? 1 : 0;
      if (leftWeight != rightWeight) {
        return rightWeight.compareTo(leftWeight);
      }
      return right.matchScore.compareTo(left.matchScore);
    });
    return picked;
  }

  _AiPlanResult _planForMessage(Trip trip, String text) {
    if (trip.destination == null) {
      return const _AiPlanResult(
        days: <ItineraryDay>[],
        reply:
            'Partiamo da una sensazione: weekend lento, mare, amici, musei o altro?',
      );
    }

    var days = trip.days;
    if (days.isEmpty && trip.selectedPlaceCount > 0) {
      days = _buildInitialDays(trip);
    }
    if (days.isEmpty) {
      return const _AiPlanResult(
        days: <ItineraryDay>[],
        reply:
            'Prima salva qualche luogo che ti attira: poi posso dargli un ritmo.',
      );
    }

    final normalized = text.toLowerCase();
    if (_containsAny(normalized, const <String>[
      'cena',
      'mang',
      'ristorante',
    ])) {
      return _addDinner(days, trip);
    }
    if (_containsAny(normalized, const <String>[
      'lento',
      'calma',
      'rilass',
      'pausa',
    ])) {
      return _slowDown(days);
    }
    if (_containsAny(normalized, const <String>['museo', 'arte', 'cultura'])) {
      return _addCulturalStop(days, trip);
    }
    if (_containsAny(normalized, const <String>['togli', 'rimuovi', 'meno'])) {
      return _removeFlexibleStop(days);
    }
    return _addFreeTime(days, trip);
  }

  _AiPlanResult _addDinner(List<ItineraryDay> days, Trip trip) {
    final first = days.first;
    final dinner = ItineraryItem(
      id: _newId('dinner'),
      title: 'Cena libera in ${trip.stayZone?.name ?? trip.destination!.name}',
      category: 'Serata',
      startTime: '20:30',
      durationMinutes: 105,
      note: 'Zona scelta perché vicina al tuo ritmo, non a un tavolo imposto.',
    );
    final updatedFirst = first.copyWith(
      items: <ItineraryItem>[...first.items, dinner],
    );
    return _AiPlanResult(
      days: <ItineraryDay>[updatedFirst, ...days.skip(1)],
      reply:
          'Ho tenuto una cena libera: puoi decidere il posto quando senti davvero la zona.',
      planChange: 'Aggiunta cena libera al ${first.label}',
    );
  }

  _AiPlanResult _slowDown(List<ItineraryDay> days) {
    for (var dayIndex = 0; dayIndex < days.length; dayIndex += 1) {
      final day = days[dayIndex];
      final itemIndex = day.items.indexWhere((item) => !item.isLocked);
      if (itemIndex < 0) {
        continue;
      }
      final item = day.items[itemIndex];
      final items = <ItineraryItem>[...day.items]
        ..[itemIndex] = item.copyWith(
          durationMinutes: item.durationMinutes + 30,
          note: '${item.note} Ho aggiunto una pausa qui.',
        );
      final updated = <ItineraryDay>[...days]
        ..[dayIndex] = day.copyWith(items: items);
      return _AiPlanResult(
        days: updated,
        reply:
            'Ho allargato una tappa e lasciato un cuscinetto: il giorno ora respira di più.',
        planChange: 'Allungata ${item.title} di 30 minuti',
      );
    }
    return const _AiPlanResult(
      days: <ItineraryDay>[],
      reply:
          'Le tappe che vedo sono tutte bloccate. Sblocca quella che vuoi rendere più lenta.',
    );
  }

  _AiPlanResult _addCulturalStop(List<ItineraryDay> days, Trip trip) {
    final scheduledIds = days
        .expand((day) => day.items)
        .map((item) => item.placeId)
        .whereType<String>()
        .toSet();
    Place? culturalPlace;
    for (final place in _selectedPlacesFor(trip)) {
      final isCultural = const <String>[
        'Arte',
        'Cultura',
        'Architettura',
      ].contains(place.category);
      if (isCultural && !scheduledIds.contains(place.id)) {
        culturalPlace = place;
        break;
      }
    }
    if (culturalPlace == null) {
      return _addFreeTime(
        days,
        trip,
        reply:
            'Ho lasciato una finestra per arte o cultura, così puoi scegliere sul momento.',
      );
    }
    final first = days.first;
    final stop = ItineraryItem(
      id: _newId('culture'),
      placeId: culturalPlace.id,
      title: culturalPlace.name,
      category: culturalPlace.category,
      startTime: '15:30',
      durationMinutes: culturalPlace.durationMinutes,
      note: culturalPlace.bestMoment,
    );
    final updatedFirst = first.copyWith(
      items: <ItineraryItem>[...first.items, stop],
    );
    return _AiPlanResult(
      days: <ItineraryDay>[updatedFirst, ...days.skip(1)],
      reply:
          'Ho aggiunto ${culturalPlace.name}, senza spostare le cose che hai bloccato.',
      planChange: 'Aggiunta ${culturalPlace.name}',
    );
  }

  _AiPlanResult _removeFlexibleStop(List<ItineraryDay> days) {
    for (var dayIndex = days.length - 1; dayIndex >= 0; dayIndex -= 1) {
      final day = days[dayIndex];
      final itemIndex = day.items.lastIndexWhere((item) => !item.isLocked);
      if (itemIndex < 0) {
        continue;
      }
      final removed = day.items[itemIndex];
      final items = <ItineraryItem>[...day.items]..removeAt(itemIndex);
      final updated = <ItineraryDay>[...days]
        ..[dayIndex] = day.copyWith(items: items);
      return _AiPlanResult(
        days: updated,
        reply:
            'Ho tolto ${removed.title}. Le tappe bloccate sono rimaste al loro posto.',
        planChange: 'Rimossa ${removed.title}',
      );
    }
    return const _AiPlanResult(
      days: <ItineraryDay>[],
      reply: 'Non ho tolto nulla: le tappe attuali sono tutte bloccate da te.',
    );
  }

  _AiPlanResult _addFreeTime(
    List<ItineraryDay> days,
    Trip trip, {
    String? reply,
  }) {
    final first = days.first;
    final stop = ItineraryItem(
      id: _newId('free-time'),
      title: 'Tempo libero in ${trip.stayZone?.name ?? trip.destination!.name}',
      category: 'Spazio libero',
      startTime: '16:00',
      durationMinutes: 60,
      note: 'Una finestra per un bar, una deviazione o una scoperta sul posto.',
    );
    final updatedFirst = first.copyWith(
      items: <ItineraryItem>[...first.items, stop],
    );
    return _AiPlanResult(
      days: <ItineraryDay>[updatedFirst, ...days.skip(1)],
      reply:
          reply ??
          'Ho inserito un’ora libera: il piano resta utile senza diventare una gabbia.',
      planChange: 'Aggiunto spazio libero al ${first.label}',
    );
  }

  bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _AiPlanResult {
  const _AiPlanResult({
    required this.days,
    required this.reply,
    this.planChange,
  });

  final List<ItineraryDay> days;
  final String reply;
  final String? planChange;
}
