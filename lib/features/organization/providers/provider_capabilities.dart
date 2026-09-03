import 'package:flutter/foundation.dart';
import '../models/organization_models.dart';

enum ProviderCapabilityState { verified, mockOnly, unavailable }

@immutable
class ProviderCapabilities {
  const ProviderCapabilities({
    required this.providerId,
    required this.displayName,
    required this.state,
    required this.supportedModes,
    required this.message,
  });

  final String providerId;
  final String displayName;
  final ProviderCapabilityState state;
  final Set<TravelMode> supportedModes;
  final String message;

  bool get isVerified => state == ProviderCapabilityState.verified;
  bool get isMockOnly => state == ProviderCapabilityState.mockOnly;
  bool get isUnavailable => state == ProviderCapabilityState.unavailable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderCapabilities &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId &&
          displayName == other.displayName &&
          state == other.state &&
          setEquals(supportedModes, other.supportedModes) &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
    providerId,
    displayName,
    state,
    Object.hashAll(supportedModes),
    message,
  );
}

@immutable
class ProviderCapabilityRecord {
  const ProviderCapabilityRecord({
    required this.providerId,
    required this.kind,
    required this.state,
    required this.checkedAt,
    required this.executionLocation,
    required this.costModel,
    required this.limitations,
  });

  final String providerId;
  final OfferKind kind;
  final ProviderCapabilityState state;
  final DateTime checkedAt;
  final String executionLocation;
  final String costModel;
  final List<String> limitations;
}
