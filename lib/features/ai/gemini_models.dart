import 'package:flutter/foundation.dart';

@immutable
class FlightRealOffer {
  const FlightRealOffer({
    required this.id,
    required this.airline,
    required this.price,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.isDirect,
    required this.stops,
    required this.bookingUrl,
    this.badge,
  });

  final String id;
  final String airline;
  final int price;
  final String departureTime;
  final String arrivalTime;
  final int durationMinutes;
  final bool isDirect;
  final int stops;
  final String bookingUrl;
  final String? badge;

  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  factory FlightRealOffer.fromJson(Map<String, dynamic> json) {
    return FlightRealOffer(
      id: json['id']?.toString() ?? '',
      airline: json['airline']?.toString() ?? 'Compagnia aerea',
      price: (json['price'] as num?)?.toInt() ?? 0,
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      isDirect: json['isDirect'] == true,
      stops: (json['stops'] as num?)?.toInt() ?? 0,
      bookingUrl: json['bookingUrl']?.toString() ?? '',
      badge: json['badge']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'airline': airline,
    'price': price,
    'departureTime': departureTime,
    'arrivalTime': arrivalTime,
    'durationMinutes': durationMinutes,
    'isDirect': isDirect,
    'stops': stops,
    'bookingUrl': bookingUrl,
    if (badge != null) 'badge': badge,
  };
}

@immutable
class FlightAdvice {
  const FlightAdvice({
    required this.outbound,
    required this.priceEstimate,
    required this.searchUrl,
    this.offers = const [],
    this.outboundOffers = const [],
    this.returnOffers = const [],
    this.departureDateStr,
    this.returnDateStr,
    this.formattedDates,
    this.priceEvaluation,
    this.priceAdvice,
  });

  final String outbound;
  final String priceEstimate;
  final String searchUrl;
  final List<FlightRealOffer> offers;
  final List<FlightRealOffer> outboundOffers;
  final List<FlightRealOffer> returnOffers;
  final String? departureDateStr;
  final String? returnDateStr;
  final String? formattedDates;
  final String? priceEvaluation; // 'economico' | 'nella media' | 'alto'
  final String? priceAdvice;

  factory FlightAdvice.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['offers'];
    final parsedOffers = rawOffers is List
        ? rawOffers
            .whereType<Map<String, dynamic>>()
            .map(FlightRealOffer.fromJson)
            .toList()
        : const <FlightRealOffer>[];

    final rawOut = json['outboundOffers'];
    final parsedOut = rawOut is List
        ? rawOut
            .whereType<Map<String, dynamic>>()
            .map(FlightRealOffer.fromJson)
            .toList()
        : const <FlightRealOffer>[];

    final rawRet = json['returnOffers'];
    final parsedRet = rawRet is List
        ? rawRet
            .whereType<Map<String, dynamic>>()
            .map(FlightRealOffer.fromJson)
            .toList()
        : const <FlightRealOffer>[];

    return FlightAdvice(
      outbound: json['outbound']?.toString() ?? '',
      priceEstimate: json['priceEstimate']?.toString() ?? '',
      searchUrl: json['searchUrl']?.toString() ?? '',
      offers: parsedOffers,
      outboundOffers: parsedOut,
      returnOffers: parsedRet,
      departureDateStr: json['departureDateStr']?.toString() ?? json['departureDate']?.toString(),
      returnDateStr: json['returnDateStr']?.toString() ?? json['returnDate']?.toString(),
      formattedDates: json['formattedDates']?.toString(),
      priceEvaluation: json['priceEvaluation']?.toString(),
      priceAdvice: json['priceAdvice']?.toString(),
    );
  }

  FlightAdvice copyWith({
    String? outbound,
    String? priceEstimate,
    String? searchUrl,
    List<FlightRealOffer>? offers,
    List<FlightRealOffer>? outboundOffers,
    List<FlightRealOffer>? returnOffers,
    String? departureDateStr,
    String? returnDateStr,
    String? formattedDates,
    String? priceEvaluation,
    String? priceAdvice,
  }) {
    return FlightAdvice(
      outbound: outbound ?? this.outbound,
      priceEstimate: priceEstimate ?? this.priceEstimate,
      searchUrl: searchUrl ?? this.searchUrl,
      offers: offers ?? this.offers,
      outboundOffers: outboundOffers ?? this.outboundOffers,
      returnOffers: returnOffers ?? this.returnOffers,
      departureDateStr: departureDateStr ?? this.departureDateStr,
      returnDateStr: returnDateStr ?? this.returnDateStr,
      formattedDates: formattedDates ?? this.formattedDates,
      priceEvaluation: priceEvaluation ?? this.priceEvaluation,
      priceAdvice: priceAdvice ?? this.priceAdvice,
    );
  }

  Map<String, dynamic> toJson() => {
    'outbound': outbound,
    'priceEstimate': priceEstimate,
    'searchUrl': searchUrl,
    'offers': offers.map((o) => o.toJson()).toList(),
    'outboundOffers': outboundOffers.map((o) => o.toJson()).toList(),
    'returnOffers': returnOffers.map((o) => o.toJson()).toList(),
    if (departureDateStr != null) 'departureDateStr': departureDateStr,
    if (returnDateStr != null) 'returnDateStr': returnDateStr,
    if (formattedDates != null) 'formattedDates': formattedDates,
    if (priceEvaluation != null) 'priceEvaluation': priceEvaluation,
    if (priceAdvice != null) 'priceAdvice': priceAdvice,
  };
}





@immutable
class NeighborhoodAdvice {
  const NeighborhoodAdvice({
    required this.name,
    required this.why,
    this.searchUrl = '',
  });

  final String name;
  final String why;
  final String searchUrl;

  factory NeighborhoodAdvice.fromJson(Map<String, dynamic> json) {
    return NeighborhoodAdvice(
      name: json['name']?.toString() ?? '',
      why: json['why']?.toString() ?? '',
      searchUrl: json['searchUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'why': why,
    'searchUrl': searchUrl,
  };
}

@immutable
class DailyPlanDraft {
  const DailyPlanDraft({
    required this.dayNumber,
    required this.theme,
    required this.stops,
    this.diningRecommendation,
  });

  final int dayNumber;
  final String theme;
  final List<String> stops;
  final String? diningRecommendation;

  factory DailyPlanDraft.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    final stopsList = rawStops is List
        ? rawStops.map((s) => s.toString()).toList()
        : <String>[];

    return DailyPlanDraft(
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      theme: json['theme']?.toString() ?? '',
      stops: stopsList,
      diningRecommendation: json['diningRecommendation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'theme': theme,
    'stops': stops,
    'diningRecommendation': diningRecommendation,
  };
}

enum TripPlanningStage {
  flight,
  stay,
  itinerary,
}

@immutable
class GeminiTripPlanDraft {
  const GeminiTripPlanDraft({
    required this.message,
    required this.destination,
    required this.durationDays,
    this.stage = TripPlanningStage.flight,
    this.flight,
    this.neighborhoods = const [],
    this.days = const [],
    this.suggestedReplies = const [],
    this.shouldSearchFlights = false,
  });

  final String message;
  final String destination;
  final int durationDays;
  final TripPlanningStage stage;
  final FlightAdvice? flight;
  final List<NeighborhoodAdvice> neighborhoods;
  final List<DailyPlanDraft> days;
  final List<String> suggestedReplies;
  final bool shouldSearchFlights;

  factory GeminiTripPlanDraft.fromJson(Map<String, dynamic> json, {TripPlanningStage? stage}) {
    final flightJson = json['flight'];
    final rawNeighborhoods = json['neighborhoods'];
    final rawDays = json['days'];
    final rawSuggestions = json['suggestedReplies'];

    final parsedStage = stage ??
        (rawDays is List && rawDays.isNotEmpty
            ? TripPlanningStage.itinerary
            : (rawNeighborhoods is List && rawNeighborhoods.isNotEmpty
                ? TripPlanningStage.stay
                : TripPlanningStage.flight));

    final parsedSuggestions = rawSuggestions is List
        ? rawSuggestions.map((e) => e.toString()).toList()
        : const <String>[];

    final shouldSearch = json['shouldSearchFlights'] == true ||
        (flightJson is Map<String, dynamic> && flightJson.isNotEmpty);

    return GeminiTripPlanDraft(
      message: json['message']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 3,
      stage: parsedStage,
      flight: flightJson is Map<String, dynamic> ? FlightAdvice.fromJson(flightJson) : null,
      neighborhoods: rawNeighborhoods is List
          ? rawNeighborhoods
              .whereType<Map<String, dynamic>>()
              .map(NeighborhoodAdvice.fromJson)
              .toList()
          : const [],
      days: rawDays is List
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(DailyPlanDraft.fromJson)
              .toList()
          : const [],
      suggestedReplies: parsedSuggestions,
      shouldSearchFlights: shouldSearch,
    );
  }

  GeminiTripPlanDraft copyWith({
    String? message,
    String? destination,
    int? durationDays,
    TripPlanningStage? stage,
    FlightAdvice? flight,
    List<NeighborhoodAdvice>? neighborhoods,
    List<DailyPlanDraft>? days,
    List<String>? suggestedReplies,
    bool? shouldSearchFlights,
  }) {
    return GeminiTripPlanDraft(
      message: message ?? this.message,
      destination: destination ?? this.destination,
      durationDays: durationDays ?? this.durationDays,
      stage: stage ?? this.stage,
      flight: flight ?? this.flight,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      days: days ?? this.days,
      suggestedReplies: suggestedReplies ?? this.suggestedReplies,
      shouldSearchFlights: shouldSearchFlights ?? this.shouldSearchFlights,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'destination': destination,
    'durationDays': durationDays,
    'stage': stage.name,
    if (flight != null) 'flight': flight!.toJson(),
    'neighborhoods': neighborhoods.map((n) => n.toJson()).toList(),
    'days': days.map((d) => d.toJson()).toList(),
    'suggestedReplies': suggestedReplies,
    'shouldSearchFlights': shouldSearchFlights,
  };
}
