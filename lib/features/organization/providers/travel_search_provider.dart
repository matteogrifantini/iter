import 'package:flutter/foundation.dart';
import '../models/organization_models.dart';

enum ProviderUpdateKind {
  started,
  progressed,
  partial,
  completed,
  degraded,
  failed,
}

@immutable
class TravelSearchQuery {
  TravelSearchQuery({
    required this.tripId,
    List<String> originCandidates = const <String>[],
    List<String> destinationCandidates = const <String>[],
    required this.dateConstraint,
    required this.duration,
    required this.travelers,
    Set<TravelMode> acceptedModes = const <TravelMode>{TravelMode.flight},
    this.maxStops,
    this.budgetCentsPerPerson,
  }) : originCandidates = List<String>.unmodifiable(originCandidates),
       destinationCandidates = List<String>.unmodifiable(destinationCandidates),
       acceptedModes = Set<TravelMode>.unmodifiable(acceptedModes);

  final String tripId;
  final List<String> originCandidates;
  final List<String> destinationCandidates;
  final DateConstraint dateConstraint;
  final DurationRange duration;
  final TravelerGroup travelers;
  final Set<TravelMode> acceptedModes;
  final int? maxStops;
  final int? budgetCentsPerPerson;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelSearchQuery &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          listEquals(originCandidates, other.originCandidates) &&
          listEquals(destinationCandidates, other.destinationCandidates) &&
          dateConstraint == other.dateConstraint &&
          duration == other.duration &&
          travelers == other.travelers &&
          setEquals(acceptedModes, other.acceptedModes) &&
          maxStops == other.maxStops &&
          budgetCentsPerPerson == other.budgetCentsPerPerson;

  @override
  int get hashCode => Object.hash(
    tripId,
    Object.hashAll(originCandidates),
    Object.hashAll(destinationCandidates),
    dateConstraint,
    duration,
    travelers,
    Object.hashAll(acceptedModes),
    maxStops,
    budgetCentsPerPerson,
  );
}

@immutable
class TravelSearchUpdate {
  TravelSearchUpdate({
    required this.tripId,
    required this.providerId,
    required this.kind,
    required this.occurredAt,
    List<ProviderOffer> offers = const <ProviderOffer>[],
    this.message,
  }) : offers = List<ProviderOffer>.unmodifiable(offers);

  final String tripId;
  final String providerId;
  final ProviderUpdateKind kind;
  final DateTime occurredAt;
  final List<ProviderOffer> offers;
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelSearchUpdate &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          providerId == other.providerId &&
          kind == other.kind &&
          occurredAt == other.occurredAt &&
          listEquals(offers, other.offers) &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
    tripId,
    providerId,
    kind,
    occurredAt,
    Object.hashAll(offers),
    message,
  );
}

abstract interface class TravelSearchProvider {
  Stream<TravelSearchUpdate> search(TravelSearchQuery query);
}
