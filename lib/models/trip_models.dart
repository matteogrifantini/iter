import 'dart:collection';

/// Where a trip is in Iter's guided planning flow.
enum TripStage {
  destinationDiscovery,
  placeCuration,
  transportSelection,
  staySelection,
  itinerary,
  ready,
}

/// A trip can stay editable after it is complete; `completed` only changes
/// where it is presented in the user's library.
enum TripStatus { draft, active, completed }

/// Intent captured by the places deck. A `mustSee` item carries more weight
/// when the first itinerary is assembled.
enum PlaceReaction { skip, save, mustSee }

enum TransportKind { flight, train }

enum AiMessageRole { traveler, assistant }

/// A discoverable journey can cross several places. A city is a stop inside
/// the journey, never the first question shown to the traveller.
class JourneyRoute {
  const JourneyRoute({
    required this.id,
    required this.title,
    required this.summary,
    required this.durationLabel,
    required this.stops,
    required this.destinationIds,
    required this.whyItFits,
    required this.season,
    required this.travelMode,
    required this.videoAsset,
    required this.matchScore,
  });

  final String id;
  final String title;
  final String summary;
  final String durationLabel;
  final List<String> stops;
  final List<String> destinationIds;
  final String whyItFits;
  final String season;
  final String travelMode;
  final String videoAsset;
  final int matchScore;
}

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.tagline,
    required this.whyItFits,
    required this.matchScore,
    required this.bestFor,
  });

  final String id;
  final String name;
  final String country;
  final String tagline;
  final String whyItFits;
  final int matchScore;
  final String bestFor;
}

class Place {
  const Place({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.durationMinutes,
    required this.matchScore,
    required this.whyItFits,
    required this.bestMoment,
  });

  final String id;
  final String destinationId;
  final String name;
  final String category;
  final String neighborhood;
  final int durationMinutes;
  final int matchScore;
  final String whyItFits;
  final String bestMoment;
}

class StayZone {
  const StayZone({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.summary,
    required this.whyItFits,
    required this.averageWalkMinutes,
    required this.hotelSearchUrl,
  });

  final String id;
  final String destinationId;
  final String name;
  final String summary;
  final String whyItFits;
  final int averageWalkMinutes;
  final Uri hotelSearchUrl;
}

/// A planning preference for reaching the first stop. Values are deliberately
/// indicative in the mock backend: choosing one shapes the plan, it does not
/// book a ticket or promise live availability.
class TransportOption {
  const TransportOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.origin,
    required this.destination,
    required this.timingLabel,
    required this.durationLabel,
    required this.priceLabel,
    required this.changesLabel,
    required this.whyItFits,
    required this.searchUrl,
    this.isRecommended = false,
  });

  final String id;
  final TransportKind kind;
  final String title;
  final String origin;
  final String destination;
  final String timingLabel;
  final String durationLabel;
  final String priceLabel;
  final String changesLabel;
  final String whyItFits;
  final Uri searchUrl;
  final bool isRecommended;
}

class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.durationMinutes,
    required this.note,
    this.placeId,
    this.isLocked = false,
  });

  final String id;
  final String? placeId;
  final String title;
  final String category;
  final String startTime;
  final int durationMinutes;
  final String note;
  final bool isLocked;

  ItineraryItem copyWith({
    String? id,
    String? placeId,
    bool clearPlaceId = false,
    String? title,
    String? category,
    String? startTime,
    int? durationMinutes,
    String? note,
    bool? isLocked,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      placeId: clearPlaceId ? null : placeId ?? this.placeId,
      title: title ?? this.title,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class ItineraryDay {
  ItineraryDay({
    required this.id,
    required this.label,
    required this.theme,
    required List<ItineraryItem> items,
  }) : items = List.unmodifiable(items);

  final String id;
  final String label;
  final String theme;
  final List<ItineraryItem> items;

  ItineraryDay copyWith({
    String? id,
    String? label,
    String? theme,
    List<ItineraryItem>? items,
  }) {
    return ItineraryDay(
      id: id ?? this.id,
      label: label ?? this.label,
      theme: theme ?? this.theme,
      items: items ?? this.items,
    );
  }
}

class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.planChange,
  });

  final String id;
  final AiMessageRole role;
  final String text;
  final DateTime createdAt;

  /// A concise user-facing summary of the concrete itinerary change. It is
  /// intentionally not model reasoning or a chain of thought.
  final String? planChange;
}

class TravelTrend {
  const TravelTrend({
    required this.id,
    required this.title,
    required this.detail,
    required this.signal,
  });

  final String id;
  final String title;
  final String detail;
  final String signal;
}

class Trip {
  Trip({
    required this.id,
    required this.title,
    required this.stage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.destination,
    this.journey,
    this.transportOption,
    this.stayZone,
    Map<String, PlaceReaction> reactions = const <String, PlaceReaction>{},
    List<ItineraryDay> days = const <ItineraryDay>[],
    List<AiMessage> messages = const <AiMessage>[],
    List<DateTime> availableDates = const <DateTime>[],
    this.discoveryNote = '',
    Map<String, String> discoveryAnswers = const <String, String>{},
  }) : reactions = UnmodifiableMapView(
         Map<String, PlaceReaction>.from(reactions),
       ),
       days = List.unmodifiable(days),
       messages = List.unmodifiable(messages),
       availableDates = List.unmodifiable(availableDates),
       discoveryAnswers = UnmodifiableMapView(
         Map<String, String>.from(discoveryAnswers),
       );

  final String id;
  final String title;
  final Destination? destination;
  final JourneyRoute? journey;
  final TransportOption? transportOption;
  final TripStage stage;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StayZone? stayZone;
  final Map<String, PlaceReaction> reactions;
  final List<ItineraryDay> days;
  final List<AiMessage> messages;
  final List<DateTime> availableDates;
  final String discoveryNote;
  final Map<String, String> discoveryAnswers;

  Iterable<String> get selectedPlaceIds => reactions.entries
      .where((entry) => entry.value != PlaceReaction.skip)
      .map((entry) => entry.key);

  int get selectedPlaceCount => selectedPlaceIds.length;

  int get mustSeeCount => reactions.values
      .where((reaction) => reaction == PlaceReaction.mustSee)
      .length;

  bool get isResumable => status != TripStatus.completed;

  Trip copyWith({
    String? id,
    String? title,
    Destination? destination,
    bool clearDestination = false,
    JourneyRoute? journey,
    bool clearJourney = false,
    TransportOption? transportOption,
    bool clearTransportOption = false,
    TripStage? stage,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    StayZone? stayZone,
    bool clearStayZone = false,
    Map<String, PlaceReaction>? reactions,
    List<ItineraryDay>? days,
    List<AiMessage>? messages,
    List<DateTime>? availableDates,
    String? discoveryNote,
    Map<String, String>? discoveryAnswers,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: clearDestination ? null : destination ?? this.destination,
      journey: clearJourney ? null : journey ?? this.journey,
      transportOption: clearTransportOption
          ? null
          : transportOption ?? this.transportOption,
      stage: stage ?? this.stage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stayZone: clearStayZone ? null : stayZone ?? this.stayZone,
      reactions: reactions ?? this.reactions,
      days: days ?? this.days,
      messages: messages ?? this.messages,
      availableDates: availableDates ?? this.availableDates,
      discoveryNote: discoveryNote ?? this.discoveryNote,
      discoveryAnswers: discoveryAnswers ?? this.discoveryAnswers,
    );
  }
}
