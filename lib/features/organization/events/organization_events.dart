import 'package:flutter/foundation.dart';
import '../models/organization_card.dart';
import '../models/organization_models.dart';

/// Tipologia canonica di evento di organizzazione.
enum OrganizationEventKind {
  intentCreated,
  questionRequested,
  answerConfirmed,
  searchStarted,
  searchProgressed,
  searchPartialResults,
  searchCompleted,
  providerDegraded,
  offerExpired,
  flightSelected,
  externalPurchaseOpened,
  flightConfirmationRequested,
  flightConfirmed,
  experienceContextRequested,
  zoneProposed,
  staySearchStarted,
  stayPartialResults,
  staySelected,
  stayConfirmationRequested,
  stayConfirmed,
  planProposed,
  error,
}

/// Envelope canonico per tutti gli eventi del motore di organizzazione.
@immutable
class OrganizationEvent {
  OrganizationEvent({
    int? sequence,
    String? id,
    required this.tripId,
    OrganizationEventKind? kind,
    String? type,
    DateTime? occurredAt,
    DateTime? timestamp,
    Map<String, Object?> payload = const <String, Object?>{},
  }) : sequence = sequence ?? 0,
       id = id ?? 'evt-$tripId-${sequence ?? 0}',
       kind = kind ?? _kindFromType(type),
       occurredAt = occurredAt ?? timestamp ?? DateTime.now(),
       payload = Map<String, Object?>.unmodifiable(payload);

  final String id;
  final int sequence;
  final String tripId;
  final OrganizationEventKind kind;
  final DateTime occurredAt;
  final Map<String, Object?> payload;

  String get type {
    switch (kind) {
      case OrganizationEventKind.intentCreated:
        return 'intent.created';
      case OrganizationEventKind.questionRequested:
        return 'question.requested';
      case OrganizationEventKind.answerConfirmed:
        return 'user.answer.confirmed';
      case OrganizationEventKind.searchStarted:
        return 'search.started';
      case OrganizationEventKind.searchProgressed:
        return 'search.progressed';
      case OrganizationEventKind.searchPartialResults:
        return 'search.partialResults';
      case OrganizationEventKind.searchCompleted:
        return 'search.completed';
      case OrganizationEventKind.providerDegraded:
        return 'provider.degraded';
      case OrganizationEventKind.offerExpired:
        return 'offer.expired';
      case OrganizationEventKind.flightSelected:
        return 'flight.selected';
      case OrganizationEventKind.externalPurchaseOpened:
        return 'external.purchaseOpened';
      case OrganizationEventKind.flightConfirmationRequested:
        return 'flight.confirmationRequested';
      case OrganizationEventKind.flightConfirmed:
        return 'flight.confirmed';
      case OrganizationEventKind.experienceContextRequested:
        return 'experience.contextRequested';
      case OrganizationEventKind.zoneProposed:
        return 'zone.proposed';
      case OrganizationEventKind.staySearchStarted:
        return 'stay.searchStarted';
      case OrganizationEventKind.stayPartialResults:
        return 'stay.partialResults';
      case OrganizationEventKind.staySelected:
        return 'stay.selected';
      case OrganizationEventKind.stayConfirmationRequested:
        return 'stay.confirmationRequested';
      case OrganizationEventKind.stayConfirmed:
        return 'stay.confirmed';
      case OrganizationEventKind.planProposed:
        return 'plan.proposed';
      case OrganizationEventKind.error:
        return 'error';
    }
  }

  DateTime get timestamp => occurredAt;

  static OrganizationEventKind _kindFromType(String? type) {
    if (type == null) return OrganizationEventKind.error;
    switch (type) {
      case 'intent.created':
      case 'intentCreated':
        return OrganizationEventKind.intentCreated;
      case 'question.requested':
      case 'questionRequested':
        return OrganizationEventKind.questionRequested;
      case 'user.answer.confirmed':
      case 'answerConfirmed':
        return OrganizationEventKind.answerConfirmed;
      case 'search.started':
      case 'searchStarted':
        return OrganizationEventKind.searchStarted;
      case 'search.progressed':
      case 'searchProgressed':
        return OrganizationEventKind.searchProgressed;
      case 'search.partialResults':
      case 'searchPartialResults':
        return OrganizationEventKind.searchPartialResults;
      case 'search.completed':
      case 'searchCompleted':
        return OrganizationEventKind.searchCompleted;
      case 'provider.degraded':
      case 'providerDegraded':
        return OrganizationEventKind.providerDegraded;
      case 'offer.expired':
      case 'offerExpired':
        return OrganizationEventKind.offerExpired;
      case 'flight.selected':
      case 'flightSelected':
        return OrganizationEventKind.flightSelected;
      case 'external.purchaseOpened':
      case 'externalPurchaseOpened':
        return OrganizationEventKind.externalPurchaseOpened;
      case 'flight.confirmationRequested':
      case 'flightConfirmationRequested':
        return OrganizationEventKind.flightConfirmationRequested;
      case 'flight.confirmed':
      case 'flightConfirmed':
        return OrganizationEventKind.flightConfirmed;
      case 'experience.contextRequested':
      case 'experienceContextRequested':
        return OrganizationEventKind.experienceContextRequested;
      case 'zone.proposed':
      case 'zoneProposed':
        return OrganizationEventKind.zoneProposed;
      case 'stay.searchStarted':
      case 'staySearchStarted':
        return OrganizationEventKind.staySearchStarted;
      case 'stay.partialResults':
      case 'stayPartialResults':
        return OrganizationEventKind.stayPartialResults;
      case 'stay.selected':
      case 'staySelected':
        return OrganizationEventKind.staySelected;
      case 'stay.confirmationRequested':
      case 'stayConfirmationRequested':
        return OrganizationEventKind.stayConfirmationRequested;
      case 'stay.confirmed':
      case 'stayConfirmed':
        return OrganizationEventKind.stayConfirmed;
      case 'plan.proposed':
      case 'planProposed':
        return OrganizationEventKind.planProposed;
      case 'error':
      default:
        return OrganizationEventKind.error;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationEvent &&
          runtimeType == other.runtimeType &&
          sequence == other.sequence &&
          tripId == other.tripId &&
          kind == other.kind &&
          occurredAt == other.occurredAt &&
          mapEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(
    sequence,
    tripId,
    kind,
    occurredAt,
    Object.hashAll(payload.keys),
    Object.hashAll(payload.values),
  );
}

/// Evento generato alla creazione di un nuovo intento di viaggio.
class IntentCreatedEvent extends OrganizationEvent {
  IntentCreatedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.intent,
  }) : super(
         kind: OrganizationEventKind.intentCreated,
         payload: <String, Object?>{
           'rawDesire': intent.rawDesire,
           'originCandidates': intent.originCandidates,
           'destinationCandidates': intent.destinationCandidates,
         },
       );

  final TripIntent intent;
}

/// Evento generato quando l'orchestratore richiede una domanda mirata.
class QuestionRequestedEvent extends OrganizationEvent {
  QuestionRequestedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.questionKey,
    required this.questionText,
    this.options = const <String>[],
    this.isAdaptive = false,
  }) : super(
         kind: OrganizationEventKind.questionRequested,
         payload: <String, Object?>{
           'questionKey': questionKey,
           'questionText': questionText,
           'options': options,
           'isAdaptive': isAdaptive,
         },
       );

  final String questionKey;
  final String questionText;
  final List<String> options;
  final bool isAdaptive;
}

/// Evento generato quando l'utente conferma una risposta esplicita.
class UserAnswerConfirmedEvent extends OrganizationEvent {
  UserAnswerConfirmedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.questionKey,
    required this.answer,
  }) : super(
         kind: OrganizationEventKind.answerConfirmed,
         payload: <String, Object?>{
           'questionKey': questionKey,
           'answer': answer?.toString(),
         },
       );

  final String questionKey;
  final dynamic answer;
}

/// Evento generato all'avvio di una ricerca trasporti o alloggi.
class SearchStartedEvent extends OrganizationEvent {
  SearchStartedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.targetType,
    this.providers = const <String>[],
  }) : super(
         kind: OrganizationEventKind.searchStarted,
         payload: <String, Object?>{
           'sessionId': sessionId,
           'targetType': targetType.name,
           'providers': providers,
         },
       );

  final String sessionId;
  final OfferKind targetType;
  final List<String> providers;
}

/// Evento generato durante il progresso della ricerca reale.
class SearchProgressedEvent extends OrganizationEvent {
  SearchProgressedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.stageMessage,
  }) : super(
         kind: OrganizationEventKind.searchProgressed,
         payload: <String, Object?>{
           'sessionId': sessionId,
           'stageMessage': stageMessage,
         },
       );

  final String sessionId;
  final String stageMessage;
}

/// Evento generato all'arrivo di risultati parziali dai provider.
class SearchPartialResultsEvent extends OrganizationEvent {
  SearchPartialResultsEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.offers,
  }) : super(
         kind: OrganizationEventKind.searchPartialResults,
         payload: <String, Object?>{
           'sessionId': sessionId,
           'offersCount': offers.length,
         },
       );

  final String sessionId;
  final List<ProviderOffer> offers;
}

/// Evento generato al completamento della ricerca.
class SearchCompletedEvent extends OrganizationEvent {
  SearchCompletedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.totalOffersFound,
  }) : super(
         kind: OrganizationEventKind.searchCompleted,
         payload: <String, Object?>{
           'sessionId': sessionId,
           'totalOffersFound': totalOffersFound,
         },
       );

  final String sessionId;
  final int totalOffersFound;
}

/// Evento generato alla selezione di un'offerta volo.
class FlightSelectedEvent extends OrganizationEvent {
  FlightSelectedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.flightOfferId,
    required this.decision,
  }) : super(
         kind: OrganizationEventKind.flightSelected,
         payload: <String, Object?>{
           'flightOfferId': flightOfferId,
           'decisionId': decision.id,
           'status': decision.status.name,
         },
       );

  final String flightOfferId;
  final UserDecision decision;
}

/// Evento generato quando l'utente apre il link del partner esterno.
class ExternalPurchaseOpenedEvent extends OrganizationEvent {
  ExternalPurchaseOpenedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    OfferKind? targetType,
    OfferKind? type,
    required this.targetOfferId,
    required this.url,
  }) : targetType = targetType ?? type ?? OfferKind.flight,
       super(
         kind: OrganizationEventKind.externalPurchaseOpened,
         payload: <String, Object?>{
           'targetType': (targetType ?? type ?? OfferKind.flight).name,
           'targetOfferId': targetOfferId,
           'url': url,
         },
       );

  final OfferKind targetType;
  final String targetOfferId;
  final String url;
}

/// Evento generato per richiedere la conferma esplicita dell'acquisto volo.
class FlightConfirmationRequestedEvent extends OrganizationEvent {
  FlightConfirmationRequestedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.flightOfferId,
  }) : super(
         kind: OrganizationEventKind.flightConfirmationRequested,
         payload: <String, Object?>{'flightOfferId': flightOfferId},
       );

  final String flightOfferId;
}

/// Evento generato alla conferma esplicita del volo acquistato.
class FlightConfirmedEvent extends OrganizationEvent {
  FlightConfirmedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.flightOfferId,
    required this.decision,
    this.bookingReference,
  }) : super(
         kind: OrganizationEventKind.flightConfirmed,
         payload: <String, Object?>{
           'flightOfferId': flightOfferId,
           'decisionId': decision.id,
           'status': decision.status.name,
           'bookingReference': ?bookingReference,
         },
       );

  final String flightOfferId;
  final UserDecision decision;
  final String? bookingReference;
}

/// Evento generato per raccogliere preferenze contestuali di destinazione.
class ExperienceContextRequestedEvent extends OrganizationEvent {
  ExperienceContextRequestedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.destination,
  }) : super(
         kind: OrganizationEventKind.experienceContextRequested,
         payload: <String, Object?>{'destination': destination},
       );

  final String destination;
}

/// Evento generato con proposte di zona motivate per l'alloggio.
class ZoneProposedEvent extends OrganizationEvent {
  ZoneProposedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.zoneNames,
    this.motivationSummary = 'Zone consigliate in base alle tue preferenze',
  }) : super(
         kind: OrganizationEventKind.zoneProposed,
         payload: <String, Object?>{
           'zoneNames': zoneNames,
           'motivationSummary': motivationSummary,
         },
       );

  final List<String> zoneNames;
  final String motivationSummary;
}

/// Evento generato all'avvio della ricerca alloggi/hotel.
class StaySearchStartedEvent extends OrganizationEvent {
  StaySearchStartedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.zone,
  }) : super(
         kind: OrganizationEventKind.staySearchStarted,
         payload: <String, Object?>{'sessionId': sessionId, 'zone': zone},
       );

  final String sessionId;
  final String zone;
}

/// Evento generato all'arrivo di risultati parziali hotel.
class StayPartialResultsEvent extends OrganizationEvent {
  StayPartialResultsEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.sessionId,
    required this.stays,
  }) : super(
         kind: OrganizationEventKind.stayPartialResults,
         payload: <String, Object?>{
           'sessionId': sessionId,
           'staysCount': stays.length,
         },
       );

  final String sessionId;
  final List<ProviderOffer> stays;
}

/// Evento generato alla selezione di un soggiorno.
class StaySelectedEvent extends OrganizationEvent {
  StaySelectedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.stayOfferId,
    required this.decision,
  }) : super(
         kind: OrganizationEventKind.staySelected,
         payload: <String, Object?>{
           'stayOfferId': stayOfferId,
           'decisionId': decision.id,
           'status': decision.status.name,
         },
       );

  final String stayOfferId;
  final UserDecision decision;
}

/// Evento generato alla conferma esplicita del soggiorno.
class StayConfirmedEvent extends OrganizationEvent {
  StayConfirmedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.stayOfferId,
    required this.decision,
  }) : super(
         kind: OrganizationEventKind.stayConfirmed,
         payload: <String, Object?>{
           'stayOfferId': stayOfferId,
           'decisionId': decision.id,
           'status': decision.status.name,
         },
       );

  final String stayOfferId;
  final UserDecision decision;
}

/// Evento generato quando viene formulata la prima bozza di piano completa.
class PlanProposedEvent extends OrganizationEvent {
  PlanProposedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.planCard,
  }) : super(
         kind: OrganizationEventKind.planProposed,
         payload: <String, Object?>{
           'cardId': planCard.id,
           'title': planCard.title,
         },
       );

  final OrganizationCard planCard;
}

/// Evento generato quando un provider esterno segnala degrado o errore.
class ProviderDegradedEvent extends OrganizationEvent {
  ProviderDegradedEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.providerId,
    required this.reason,
  }) : super(
         kind: OrganizationEventKind.providerDegraded,
         payload: <String, Object?>{'providerId': providerId, 'reason': reason},
       );

  final String providerId;
  final String reason;
}

/// Evento generato quando un'offerta precedentemente visualizzata scade.
class OfferExpiredEvent extends OrganizationEvent {
  OfferExpiredEvent({
    super.id,
    super.sequence,
    required super.tripId,
    super.timestamp,
    super.occurredAt,
    required this.offerId,
  }) : super(
         kind: OrganizationEventKind.offerExpired,
         payload: <String, Object?>{'offerId': offerId},
       );

  final String offerId;
}
