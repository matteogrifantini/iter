import 'dart:async';
import '../models/organization_models.dart';
import '../providers/provider_capabilities.dart';
import '../providers/stay_search_provider.dart';
import '../providers/travel_search_provider.dart';

/// Provider onesto per alloggi che segnala esplicitamente l'indisponibilità di provider hotel approvati.
class UnavailableStaySearchProvider implements StaySearchProvider {
  const UnavailableStaySearchProvider({
    this.delay = const Duration(milliseconds: 10),
  });

  final Duration delay;

  static const String providerIdentifier = 'unavailable-stays';

  static const ProviderCapabilities capabilities = ProviderCapabilities(
    providerId: providerIdentifier,
    displayName: 'Stays Provider (Unconfigured)',
    state: ProviderCapabilityState.unavailable,
    supportedModes: <TravelMode>{},
    message:
        'Nessun provider alberghiero ufficiale attualmente configurato a costo zero.',
  );

  @override
  Stream<StaySearchUpdate> search(StaySearchQuery query) async* {
    yield StaySearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.started,
      occurredAt: DateTime.now(),
      message: 'Verifica disponibilità partner alloggi...',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    yield StaySearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.degraded,
      occurredAt: DateTime.now(),
      message:
          'Nessun provider alloggi approvato è attualmente configurato. '
          'La selezione della zona è registrata per esplorare strutture su mappe esterne.',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    yield StaySearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.completed,
      occurredAt: DateTime.now(),
      offers: const <ProviderOffer>[],
      message: 'Ricerca alloggi terminata senza risultati inventati.',
    );
  }
}
