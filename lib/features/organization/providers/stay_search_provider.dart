import 'package:flutter/foundation.dart';
import '../models/organization_models.dart';
import 'travel_search_provider.dart';

@immutable
class StaySearchQuery {
  StaySearchQuery({
    required this.tripId,
    required this.confirmedFlight,
    required this.zoneId,
    required this.zoneLabel,
    required this.zoneLatitude,
    required this.zoneLongitude,
    required this.travelers,
    List<ProfileSignal> profileSignals = const <ProfileSignal>[],
    List<String> relevantPlaceIds = const <String>[],
    this.localTransportTolerance = 'walk_or_transit',
  }) : profileSignals = List<ProfileSignal>.unmodifiable(profileSignals),
       relevantPlaceIds = List<String>.unmodifiable(relevantPlaceIds);

  final String tripId;
  final ProviderOffer confirmedFlight;
  final String zoneId;
  final String zoneLabel;
  final double zoneLatitude;
  final double zoneLongitude;
  final TravelerGroup travelers;
  final List<ProfileSignal> profileSignals;
  final List<String> relevantPlaceIds;
  final String localTransportTolerance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaySearchQuery &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          confirmedFlight == other.confirmedFlight &&
          zoneId == other.zoneId &&
          zoneLabel == other.zoneLabel &&
          zoneLatitude == other.zoneLatitude &&
          zoneLongitude == other.zoneLongitude &&
          travelers == other.travelers &&
          listEquals(profileSignals, other.profileSignals) &&
          listEquals(relevantPlaceIds, other.relevantPlaceIds) &&
          localTransportTolerance == other.localTransportTolerance;

  @override
  int get hashCode => Object.hash(
    tripId,
    confirmedFlight,
    zoneId,
    zoneLabel,
    zoneLatitude,
    zoneLongitude,
    travelers,
    Object.hashAll(profileSignals),
    Object.hashAll(relevantPlaceIds),
    localTransportTolerance,
  );
}

@immutable
class StaySearchUpdate {
  StaySearchUpdate({
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
      other is StaySearchUpdate &&
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

abstract interface class StaySearchProvider {
  Stream<StaySearchUpdate> search(StaySearchQuery query);
}
