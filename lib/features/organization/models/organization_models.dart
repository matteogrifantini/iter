import 'package:flutter/foundation.dart';

/// Modalità di indicazione delle date per il viaggio (legacy compatibilità).
enum OrganizationDateMode { exact, flexible, savedAvailability, open }

/// Modalità di trasporto accettate.
enum TravelMode { flight, train, bus, car, ferry }

/// Alias per compatibilità con codice precedente.
typedef OrganizationTransport = TravelMode;

/// Ritmo desiderato del viaggio.
enum OrganizationPace { relaxed, balanced, intensive }

/// Tipologia di compagnia/viaggiatori.
enum TravelerKind { solo, couple, friends, family }

/// Alias per compatibilità con codice precedente.
typedef OrganizationCompanyType = TravelerKind;

/// Vincolo temporale sulle date.
sealed class DateConstraint {
  const DateConstraint();
}

/// Date precise con partenza e ritorno noti.
@immutable
class ExactDates extends DateConstraint {
  ExactDates({required this.departure, required this.returnDate}) {
    if (!returnDate.isAfter(departure)) {
      throw ArgumentError('returnDate must be strictly after departure date');
    }
  }

  final DateTime departure;
  final DateTime returnDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExactDates &&
          runtimeType == other.runtimeType &&
          departure == other.departure &&
          returnDate == other.returnDate;

  @override
  int get hashCode => Object.hash(departure, returnDate);
}

/// Date flessibili con partenze candidate e durata dichiarata.
@immutable
class FlexibleDates extends DateConstraint {
  FlexibleDates({
    required List<DateTime> departures,
    required this.duration,
    required this.horizonEnd,
  }) : departures = List<DateTime>.unmodifiable(departures);

  final List<DateTime> departures;
  final DurationRange duration;
  final DateTime horizonEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlexibleDates &&
          runtimeType == other.runtimeType &&
          listEquals(departures, other.departures) &&
          duration == other.duration &&
          horizonEnd == other.horizonEnd;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(departures), duration, horizonEnd);
}

/// Finestra aperta fino a un orizzonte dichiarato.
@immutable
class OpenDates extends DateConstraint {
  const OpenDates({required this.horizonEnd, this.duration});

  final DateTime horizonEnd;
  final DurationRange? duration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenDates &&
          runtimeType == other.runtimeType &&
          horizonEnd == other.horizonEnd &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(horizonEnd, duration);
}

/// Intervallo di durata in giorni.
@immutable
class DurationRange {
  const DurationRange({required this.minimumDays, required this.maximumDays})
    : assert(minimumDays > 0, 'minimumDays must be > 0'),
      assert(maximumDays >= minimumDays, 'maximumDays must be >= minimumDays');

  final int minimumDays;
  final int maximumDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DurationRange &&
          runtimeType == other.runtimeType &&
          minimumDays == other.minimumDays &&
          maximumDays == other.maximumDays;

  @override
  int get hashCode => Object.hash(minimumDays, maximumDays);
}

/// Composizione del gruppo di viaggiatori.
@immutable
class TravelerGroup {
  const TravelerGroup({
    required this.kind,
    required this.adults,
    this.children = 0,
  }) : assert(adults >= 1, 'adults must be at least 1'),
       assert(children >= 0, 'children must be non-negative');

  final TravelerKind kind;
  final int adults;
  final int children;

  int get count => adults + children;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelerGroup &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          adults == other.adults &&
          children == other.children;

  @override
  int get hashCode => Object.hash(kind, adults, children);
}

/// Livello di completezza dell'intento.
enum IntentCompleteness { sparse, usable, searchReady }

/// Rappresentazione immutabile dell'intento corrente del viaggio.
@immutable
class TripIntent {
  TripIntent({
    String? tripId,
    String? id,
    String? rawDesire,
    String? text,
    List<String>? originCandidates,
    String? origin,
    List<String>? originAlternatives,
    List<String>? candidateDestinations,
    Set<TravelMode>? acceptedModes,
    List<OrganizationTransport>? acceptedTransports,
    this.dateConstraint,
    OrganizationDateMode? dateMode,
    DateTime? exactStartDate,
    DateTime? exactEndDate,
    List<DateTime>? flexibleStartDates,
    this.duration,
    int? durationDaysMin,
    int? durationDaysMax,
    int? openHorizonMonths,
    TravelerGroup? travelers,
    OrganizationCompanyType? companyType,
    int? travelersCount,
    int? budgetCentsPerPerson,
    double? budgetEurPerPerson,
    this.budgetTolerancePercent = 10,
    double? budgetToleranceEur,
    this.pace = OrganizationPace.balanced,
    List<String> priorities = const <String>[],
    List<String>? interests,
    List<String> avoidances = const <String>[],
    List<String>? hardConstraints,
    Map<String, String> profileSignalsUsed = const <String, String>{},
    IntentCompleteness? completeness,
    bool isComplete = false,
  }) : tripId = tripId ?? id ?? '',
       rawDesire = rawDesire ?? text ?? '',
       originCandidates = List<String>.unmodifiable(
         originCandidates ??
             (origin != null
                 ? <String>[origin, ...?originAlternatives]
                 : (originAlternatives ?? const <String>[])),
       ),
       destinationCandidates = List<String>.unmodifiable(
         candidateDestinations ?? const <String>[],
       ),
       acceptedModes = Set<TravelMode>.unmodifiable(
         acceptedModes ??
             (acceptedTransports != null
                 ? acceptedTransports.toSet()
                 : const <TravelMode>{TravelMode.flight, TravelMode.train}),
       ),
       budgetCentsPerPerson =
           budgetCentsPerPerson ??
           (budgetEurPerPerson != null
               ? (budgetEurPerPerson * 100).round()
               : null),
       travelers =
           travelers ??
           TravelerGroup(
             kind: companyType ?? TravelerKind.solo,
             adults: travelersCount ?? 1,
             children: 0,
           ),
       priorities = List<String>.unmodifiable(
         priorities.isNotEmpty ? priorities : (interests ?? const <String>[]),
       ),
       avoidances = List<String>.unmodifiable(
         avoidances.isNotEmpty
             ? avoidances
             : (hardConstraints ?? const <String>[]),
       ),
       profileSignalsUsed = Map<String, String>.unmodifiable(
         profileSignalsUsed,
       ),
       completeness =
           completeness ??
           (isComplete
               ? IntentCompleteness.searchReady
               : IntentCompleteness.sparse),
       _legacyDateMode = dateMode ?? OrganizationDateMode.flexible,
       _legacyExactStartDate =
           exactStartDate ??
           (dateConstraint is ExactDates ? dateConstraint.departure : null),
       _legacyExactEndDate =
           exactEndDate ??
           (dateConstraint is ExactDates ? dateConstraint.returnDate : null),
       _legacyFlexibleStartDates = List<DateTime>.unmodifiable(
         flexibleStartDates ??
             (dateConstraint is FlexibleDates
                 ? dateConstraint.departures
                 : const <DateTime>[]),
       ),
       _legacyDurationDaysMin = duration?.minimumDays ?? durationDaysMin ?? 2,
       _legacyDurationDaysMax = duration?.maximumDays ?? durationDaysMax ?? 5,
       _legacyOpenHorizonMonths = openHorizonMonths ?? 12,
       _legacyBudgetToleranceEur = budgetToleranceEur ?? 50.0;

  final String tripId;
  final String rawDesire;
  final List<String> originCandidates;
  final List<String> destinationCandidates;
  final Set<TravelMode> acceptedModes;
  final DateConstraint? dateConstraint;
  final DurationRange? duration;
  final TravelerGroup travelers;
  final int? budgetCentsPerPerson;
  final int budgetTolerancePercent;
  final OrganizationPace pace;
  final List<String> priorities;
  final List<String> avoidances;
  final Map<String, String> profileSignalsUsed;
  final IntentCompleteness completeness;

  // Campi di compatibilità
  final OrganizationDateMode _legacyDateMode;
  final DateTime? _legacyExactStartDate;
  final DateTime? _legacyExactEndDate;
  final List<DateTime> _legacyFlexibleStartDates;
  final int _legacyDurationDaysMin;
  final int _legacyDurationDaysMax;
  final int _legacyOpenHorizonMonths;
  final double _legacyBudgetToleranceEur;

  String get id => tripId;
  String get text => rawDesire;
  String? get origin =>
      originCandidates.isNotEmpty ? originCandidates.first : null;
  List<String> get originAlternatives => originCandidates.length > 1
      ? originCandidates.sublist(1)
      : const <String>[];
  List<String> get candidateDestinations => destinationCandidates;
  List<TravelMode> get acceptedTransports => acceptedModes.toList();
  OrganizationDateMode get dateMode => _legacyDateMode;
  DateTime? get exactStartDate => _legacyExactStartDate;
  DateTime? get exactEndDate => _legacyExactEndDate;
  List<DateTime> get flexibleStartDates => _legacyFlexibleStartDates;
  int get durationDaysMin => _legacyDurationDaysMin;
  int get durationDaysMax => _legacyDurationDaysMax;
  int get openHorizonMonths => _legacyOpenHorizonMonths;
  TravelerKind get companyType => travelers.kind;
  int get travelersCount => travelers.count;
  double? get budgetEurPerPerson =>
      budgetCentsPerPerson != null ? budgetCentsPerPerson! / 100.0 : null;
  double get budgetToleranceEur => _legacyBudgetToleranceEur;
  List<String> get interests => priorities;
  List<String> get hardConstraints => avoidances;
  bool get isComplete => completeness == IntentCompleteness.searchReady;

  TripIntent copyWith({
    String? tripId,
    String? id,
    String? rawDesire,
    String? text,
    List<String>? originCandidates,
    String? origin,
    List<String>? originAlternatives,
    List<String>? candidateDestinations,
    Set<TravelMode>? acceptedModes,
    List<OrganizationTransport>? acceptedTransports,
    DateConstraint? Function()? dateConstraint,
    DurationRange? Function()? duration,
    TravelerGroup? travelers,
    int? Function()? budgetCentsPerPerson,
    double? budgetEurPerPerson,
    int? budgetTolerancePercent,
    double? budgetToleranceEur,
    OrganizationPace? pace,
    List<String>? priorities,
    List<String>? interests,
    List<String>? avoidances,
    List<String>? hardConstraints,
    Map<String, String>? profileSignalsUsed,
    IntentCompleteness? completeness,
    bool? isComplete,
    OrganizationDateMode? dateMode,
    DateTime? exactStartDate,
    DateTime? exactEndDate,
    List<DateTime>? flexibleStartDates,
    int? durationDaysMin,
    int? durationDaysMax,
    int? openHorizonMonths,
    OrganizationCompanyType? companyType,
    int? travelersCount,
  }) {
    final effectiveBudgetCents = budgetCentsPerPerson != null
        ? budgetCentsPerPerson()
        : (budgetEurPerPerson != null
              ? (budgetEurPerPerson * 100).round()
              : this.budgetCentsPerPerson);

    return TripIntent(
      tripId: tripId ?? id ?? this.tripId,
      rawDesire: rawDesire ?? text ?? this.rawDesire,
      originCandidates:
          originCandidates ??
          (origin != null
              ? <String>[origin, ...?originAlternatives]
              : this.originCandidates),
      candidateDestinations: candidateDestinations ?? destinationCandidates,
      acceptedModes:
          acceptedModes ??
          (acceptedTransports != null
              ? acceptedTransports.toSet()
              : this.acceptedModes),
      dateConstraint: dateConstraint != null
          ? dateConstraint()
          : this.dateConstraint,
      duration: duration != null ? duration() : this.duration,
      travelers:
          travelers ??
          (companyType != null || travelersCount != null
              ? TravelerGroup(
                  kind: companyType ?? this.travelers.kind,
                  adults: travelersCount ?? this.travelers.adults,
                  children: this.travelers.children,
                )
              : this.travelers),
      budgetCentsPerPerson: effectiveBudgetCents,
      budgetTolerancePercent:
          budgetTolerancePercent ?? this.budgetTolerancePercent,
      budgetToleranceEur: budgetToleranceEur ?? _legacyBudgetToleranceEur,
      pace: pace ?? this.pace,
      priorities: priorities ?? interests ?? this.priorities,
      avoidances: avoidances ?? hardConstraints ?? this.avoidances,
      profileSignalsUsed: profileSignalsUsed ?? this.profileSignalsUsed,
      completeness:
          completeness ??
          (isComplete != null
              ? (isComplete
                    ? IntentCompleteness.searchReady
                    : IntentCompleteness.sparse)
              : this.completeness),
      dateMode: dateMode ?? _legacyDateMode,
      exactStartDate: exactStartDate ?? _legacyExactStartDate,
      exactEndDate: exactEndDate ?? _legacyExactEndDate,
      flexibleStartDates: flexibleStartDates ?? _legacyFlexibleStartDates,
      durationDaysMin: durationDaysMin ?? _legacyDurationDaysMin,
      durationDaysMax: durationDaysMax ?? _legacyDurationDaysMax,
      openHorizonMonths: openHorizonMonths ?? _legacyOpenHorizonMonths,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripIntent &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          rawDesire == other.rawDesire &&
          listEquals(originCandidates, other.originCandidates) &&
          listEquals(destinationCandidates, other.destinationCandidates) &&
          setEquals(acceptedModes, other.acceptedModes) &&
          dateConstraint == other.dateConstraint &&
          duration == other.duration &&
          travelers == other.travelers &&
          budgetCentsPerPerson == other.budgetCentsPerPerson &&
          budgetTolerancePercent == other.budgetTolerancePercent &&
          pace == other.pace &&
          listEquals(priorities, other.priorities) &&
          listEquals(avoidances, other.avoidances) &&
          mapEquals(profileSignalsUsed, other.profileSignalsUsed) &&
          completeness == other.completeness;

  @override
  int get hashCode => Object.hash(
    tripId,
    rawDesire,
    Object.hashAll(originCandidates),
    Object.hashAll(destinationCandidates),
    Object.hashAll(acceptedModes),
    dateConstraint,
    duration,
    travelers,
    budgetCentsPerPerson,
    budgetTolerancePercent,
    pace,
    Object.hashAll(priorities),
    Object.hashAll(avoidances),
    completeness,
  );
}

/// Stato di una sessione di ricerca.
enum SearchSessionStatus {
  pending,
  searching,
  partial,
  completed,
  failed,
  expired,
}

/// Rappresenta una sessione di ricerca con query e provider.
@immutable
class SearchSession {
  SearchSession({
    required this.id,
    required this.tripId,
    required this.query,
    List<String> providers = const <String>[],
    required this.startedAt,
    required this.updatedAt,
    this.expiresAt,
    this.status = SearchSessionStatus.pending,
    this.partialResultsCount = 0,
    List<String> errors = const <String>[],
  }) : providers = List<String>.unmodifiable(providers),
       errors = List<String>.unmodifiable(errors);

  final String id;
  final String tripId;
  final String query;
  final List<String> providers;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final SearchSessionStatus status;
  final int partialResultsCount;
  final List<String> errors;

  bool isExpiredAt([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    return expiresAt != null && now.isAfter(expiresAt!);
  }

  bool get isExpired => isExpiredAt();

  SearchSession copyWith({
    String? id,
    String? tripId,
    String? query,
    List<String>? providers,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    SearchSessionStatus? status,
    int? partialResultsCount,
    List<String>? errors,
  }) {
    return SearchSession(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      query: query ?? this.query,
      providers: providers ?? this.providers,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      partialResultsCount: partialResultsCount ?? this.partialResultsCount,
      errors: errors ?? this.errors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          query == other.query &&
          listEquals(providers, other.providers) &&
          startedAt == other.startedAt &&
          updatedAt == other.updatedAt &&
          expiresAt == other.expiresAt &&
          status == other.status &&
          partialResultsCount == other.partialResultsCount &&
          listEquals(errors, other.errors);

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    query,
    Object.hashAll(providers),
    startedAt,
    updatedAt,
    expiresAt,
    status,
    partialResultsCount,
    Object.hashAll(errors),
  );
}

/// Tipologia di offerta del provider.
enum OfferKind { flight, stay, experience }

/// Alias per compatibilità con codice precedente.
typedef OfferType = OfferKind;

/// Stato di veridicità/freschezza di un'offerta.
enum OfferTruthState { demo, live, estimated, stale, unavailable }

/// Alias per compatibilità con codice precedente.
typedef OfferStatus = OfferTruthState;

/// Offerta normalizzata proveniente da un provider.
@immutable
class ProviderOffer {
  ProviderOffer({
    required this.id,
    required this.providerId,
    OfferKind? kind,
    OfferType? type,
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    int? priceCents,
    double? priceEur,
    this.currency = 'EUR',
    Map<String, dynamic> conditions = const <String, dynamic>{},
    List<String> mediaUrls = const <String>[],
    required this.externalBookingUrl,
    required this.fetchedAt,
    this.expiresAt,
    OfferTruthState? truthState,
    OfferStatus? status,
    required this.tradeoffSummary,
    this.badgeLabel,
  }) : kind = kind ?? type ?? OfferKind.flight,
       priceCents =
           priceCents ?? ((priceEur != null) ? (priceEur * 100).round() : 0),
       truthState = truthState ?? status ?? OfferTruthState.demo,
       conditions = Map<String, dynamic>.unmodifiable(conditions),
       mediaUrls = List<String>.unmodifiable(mediaUrls) {
    if ((priceCents ?? (priceEur != null ? (priceEur * 100).round() : 0)) < 0) {
      throw ArgumentError('priceCents cannot be negative: $priceCents');
    }
    if (providerId.trim().isEmpty) {
      throw ArgumentError('providerId cannot be empty');
    }
    if (externalBookingUrl.isNotEmpty &&
        !externalBookingUrl.startsWith('https://')) {
      throw ArgumentError(
        'externalBookingUrl must be HTTPS: $externalBookingUrl',
      );
    }
    if (returnDate != null && returnDate!.isBefore(departureDate)) {
      throw ArgumentError('returnDate cannot be before departureDate');
    }
  }

  final String id;
  final String providerId;
  final OfferKind kind;
  final String origin;
  final String destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int priceCents;
  final String currency;
  final Map<String, dynamic> conditions;
  final List<String> mediaUrls;
  final String externalBookingUrl;
  final DateTime fetchedAt;
  final DateTime? expiresAt;
  final OfferTruthState truthState;
  final String tradeoffSummary;
  final String? badgeLabel;

  /// URL di approfondimento o checkout esterno.
  String get deepLinkUrl => externalBookingUrl;

  /// Nome visualizzabile del fornitore o compagnia aerea.
  String get providerName =>
      (conditions['airlineName'] as String?) ?? providerId;

  // Compatibilità
  OfferType get type => kind;
  double get priceEur => priceCents / 100.0;
  OfferStatus get status => truthState;

  bool isExpiredAt([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    return expiresAt != null && now.isAfter(expiresAt!);
  }

  bool get isExpired => isExpiredAt();

  ProviderOffer copyWith({
    String? id,
    String? providerId,
    OfferKind? kind,
    OfferType? type,
    String? origin,
    String? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    int? priceCents,
    double? priceEur,
    String? currency,
    Map<String, dynamic>? conditions,
    List<String>? mediaUrls,
    String? externalBookingUrl,
    DateTime? fetchedAt,
    DateTime? expiresAt,
    OfferTruthState? truthState,
    OfferStatus? status,
    String? tradeoffSummary,
    String? badgeLabel,
  }) {
    return ProviderOffer(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      kind: kind ?? type ?? this.kind,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      priceCents:
          priceCents ??
          (priceEur != null ? (priceEur * 100).round() : this.priceCents),
      currency: currency ?? this.currency,
      conditions: conditions ?? this.conditions,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      externalBookingUrl: externalBookingUrl ?? this.externalBookingUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      truthState: truthState ?? status ?? this.truthState,
      tradeoffSummary: tradeoffSummary ?? this.tradeoffSummary,
      badgeLabel: badgeLabel ?? this.badgeLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderOffer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          providerId == other.providerId &&
          kind == other.kind &&
          origin == other.origin &&
          destination == other.destination &&
          departureDate == other.departureDate &&
          returnDate == other.returnDate &&
          priceCents == other.priceCents &&
          currency == other.currency &&
          mapEquals(conditions, other.conditions) &&
          listEquals(mediaUrls, other.mediaUrls) &&
          externalBookingUrl == other.externalBookingUrl &&
          fetchedAt == other.fetchedAt &&
          expiresAt == other.expiresAt &&
          truthState == other.truthState &&
          tradeoffSummary == other.tradeoffSummary &&
          badgeLabel == other.badgeLabel;

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    kind,
    origin,
    destination,
    departureDate,
    returnDate,
    priceCents,
    currency,
    externalBookingUrl,
    fetchedAt,
    expiresAt,
    truthState,
    tradeoffSummary,
    badgeLabel,
  );
}

/// Bersaglio di una decisione dell'utente.
enum DecisionTarget { flight, zone, stay, experience, plan }

/// Alias per compatibilità con codice precedente.
typedef DecisionTargetType = DecisionTarget;

/// Stato di conferma della decisione.
enum DecisionStatus {
  selected,
  provisional,
  openedExternally,
  awaitingConfirmation,
  confirmed,
  superseded,
}

/// Decisione esplicita dell'utente con tracciamento rigoroso della conferma.
@immutable
class UserDecision {
  const UserDecision({
    required this.id,
    required this.tripId,
    DecisionTarget? target,
    DecisionTargetType? targetType,
    required this.targetId,
    this.createdAt,
    DateTime? selectedAt,
    this.status = DecisionStatus.selected,
    this.requiresExplicitConfirmation = true,
    this.confirmedAt,
    String? source,
    String? confirmedSource,
  }) : target = target ?? targetType ?? DecisionTarget.flight,
       _legacySelectedAt = selectedAt,
       source = source ?? confirmedSource ?? 'user_action';

  final String id;
  final String tripId;
  final DecisionTarget target;
  final String targetId;
  final DateTime? createdAt;
  final DateTime? _legacySelectedAt;
  final DecisionStatus status;
  final bool requiresExplicitConfirmation;
  final DateTime? confirmedAt;
  final String source;

  // Compatibilità
  DecisionTargetType get targetType => target;
  DateTime get selectedAt =>
      createdAt ?? _legacySelectedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  String? get confirmedSource => source;
  bool get isConfirmed =>
      status == DecisionStatus.confirmed && confirmedAt != null;

  UserDecision copyWith({
    String? id,
    String? tripId,
    DecisionTarget? target,
    DecisionTargetType? targetType,
    String? targetId,
    DateTime? createdAt,
    DateTime? selectedAt,
    DecisionStatus? status,
    bool? requiresExplicitConfirmation,
    DateTime? confirmedAt,
    String? source,
    String? confirmedSource,
  }) {
    return UserDecision(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      target: target ?? targetType ?? this.target,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? selectedAt ?? this.createdAt,
      status: status ?? this.status,
      requiresExplicitConfirmation:
          requiresExplicitConfirmation ?? this.requiresExplicitConfirmation,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      source: source ?? confirmedSource ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDecision &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          target == other.target &&
          targetId == other.targetId &&
          createdAt == other.createdAt &&
          status == other.status &&
          requiresExplicitConfirmation == other.requiresExplicitConfirmation &&
          confirmedAt == other.confirmedAt &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    target,
    targetId,
    createdAt,
    status,
    requiresExplicitConfirmation,
    confirmedAt,
    source,
  );
}

/// Origine del segnale di profilo.
enum SignalSource { confirmedChoice, userExplicitEdit, inferred }

/// Segnale o preferenza di profilo appresa dall'utente.
@immutable
class ProfileSignal {
  const ProfileSignal({
    required this.key,
    required this.value,
    required this.source,
    this.confidence = 1.0,
    required this.lastUpdatedAt,
    this.isEditable = true,
  });

  final String key;
  final String value;
  final SignalSource source;
  final double confidence;
  final DateTime lastUpdatedAt;
  final bool isEditable;

  ProfileSignal copyWith({
    String? key,
    String? value,
    SignalSource? source,
    double? confidence,
    DateTime? lastUpdatedAt,
    bool? isEditable,
  }) {
    return ProfileSignal(
      key: key ?? this.key,
      value: value ?? this.value,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isEditable: isEditable ?? this.isEditable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSignal &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          source == other.source &&
          confidence == other.confidence &&
          lastUpdatedAt == other.lastUpdatedAt &&
          isEditable == other.isEditable;

  @override
  int get hashCode =>
      Object.hash(key, value, source, confidence, lastUpdatedAt, isEditable);
}
