import 'package:flutter/foundation.dart';

/// Tipologie di schede ammesse nel flusso di organizzazione.
enum OrganizationCardKind {
  intentSummary,
  question,
  searchStatus,
  flightComparison,
  externalPurchase,
  flightConfirmation,
  experience,
  zoneProposal,
  stayComparison,
  stayConfirmation,
  planProposal,
}

/// Stati possibili di una scheda organizzativa.
enum OrganizationCardState {
  collecting,
  searching,
  partial,
  ready,
  selected,
  awaitingConfirmation,
  confirmed,
  stale,
  unavailable,
}

/// Tipo di azione eseguibile su una scheda.
enum CardActionType { select, openExternal, confirm, retry, edit, dismiss }

/// Azione associata a una scheda interattiva.
@immutable
class CardAction {
  const CardAction({
    required this.id,
    required this.label,
    required this.actionType,
    this.isPrimary = false,
    this.isDestructive = false,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final String label;
  final CardActionType actionType;
  final bool isPrimary;
  final bool isDestructive;
  final Map<String, dynamic> payload;

  CardAction copyWith({
    String? id,
    String? label,
    CardActionType? actionType,
    bool? isPrimary,
    bool? isDestructive,
    Map<String, dynamic>? payload,
  }) {
    return CardAction(
      id: id ?? this.id,
      label: label ?? this.label,
      actionType: actionType ?? this.actionType,
      isPrimary: isPrimary ?? this.isPrimary,
      isDestructive: isDestructive ?? this.isDestructive,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          actionType == other.actionType &&
          isPrimary == other.isPrimary &&
          isDestructive == other.isDestructive &&
          mapEquals(payload, other.payload);

  @override
  int get hashCode =>
      Object.hash(id, label, actionType, isPrimary, isDestructive, payload);
}

/// Scheda interattiva della timeline di organizzazione.
@immutable
class OrganizationCard {
  const OrganizationCard({
    required this.id,
    required this.tripId,
    required this.kind,
    this.state = OrganizationCardState.ready,
    this.title,
    this.description,
    this.payload = const <String, dynamic>{},
    this.actions = const <CardAction>[],
    this.source,
    this.verifiedAt,
    this.expiresAt,
  });

  final String id;
  final String tripId;
  final OrganizationCardKind kind;
  final OrganizationCardState state;
  final String? title;
  final String? description;
  final Map<String, dynamic> payload;
  final List<CardAction> actions;
  final String? source;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;

  bool get isConfirmed => state == OrganizationCardState.confirmed;
  bool get isAwaitingConfirmation =>
      state == OrganizationCardState.awaitingConfirmation;
  bool get isStale => state == OrganizationCardState.stale;
  bool get isUnavailable => state == OrganizationCardState.unavailable;

  bool isExpiredAt([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    return expiresAt != null && now.isAfter(expiresAt!);
  }

  bool get isExpired => isExpiredAt();

  OrganizationCard copyWith({
    String? id,
    String? tripId,
    OrganizationCardKind? kind,
    OrganizationCardState? state,
    String? title,
    String? description,
    Map<String, dynamic>? payload,
    List<CardAction>? actions,
    String? source,
    DateTime? verifiedAt,
    DateTime? expiresAt,
  }) {
    return OrganizationCard(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      title: title ?? this.title,
      description: description ?? this.description,
      payload: payload ?? this.payload,
      actions: actions ?? this.actions,
      source: source ?? this.source,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          kind == other.kind &&
          state == other.state &&
          title == other.title &&
          description == other.description &&
          mapEquals(payload, other.payload) &&
          listEquals(actions, other.actions) &&
          source == other.source &&
          verifiedAt == other.verifiedAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    kind,
    state,
    title,
    description,
    payload,
    Object.hashAll(actions),
    source,
    verifiedAt,
    expiresAt,
  );
}

/// Contesto di visualizzazione sicuro e in sola lettura per le schede.
@immutable
class OrganizationCardContext {
  const OrganizationCardContext({
    required this.tripId,
    required this.cardId,
    required this.state,
    this.source,
    this.verifiedAt,
    this.expiresAt,
  });

  final String tripId;
  final String cardId;
  final OrganizationCardState state;
  final String? source;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationCardContext &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          cardId == other.cardId &&
          state == other.state &&
          source == other.source &&
          verifiedAt == other.verifiedAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode =>
      Object.hash(tripId, cardId, state, source, verifiedAt, expiresAt);
}

/// Errore tipizzato nel decoding di payload delle schede.
class CardPayloadDecodeException implements Exception {
  const CardPayloadDecodeException(this.message, {this.details});
  final String message;
  final Object? details;

  @override
  String toString() =>
      'CardPayloadDecodeException: $message (${details ?? ""})';
}
