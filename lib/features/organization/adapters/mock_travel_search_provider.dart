import 'dart:async';
import '../models/organization_models.dart';
import '../providers/provider_capabilities.dart';
import '../providers/travel_search_provider.dart';

/// Provider di ricerca viaggi basato su fixture deterministiche e dati demo.
class MockTravelSearchProvider implements TravelSearchProvider {
  MockTravelSearchProvider({this.delay = const Duration(milliseconds: 10)});

  final Duration delay;

  static const String providerIdentifier = 'mock-flights';

  static const ProviderCapabilities capabilities = ProviderCapabilities(
    providerId: providerIdentifier,
    displayName: 'Mock Travel Provider',
    state: ProviderCapabilityState.mockOnly,
    supportedModes: <TravelMode>{TravelMode.flight, TravelMode.train},
    message: 'Provider con offerte dimostrative controllate localmente.',
  );

  @override
  Stream<TravelSearchUpdate> search(TravelSearchQuery query) async* {
    final now = DateTime.now();

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.started,
      occurredAt: now,
      message: 'Avvio scansione combinazioni di viaggio...',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.progressed,
      occurredAt: DateTime.now(),
      message: 'Confronto tariffe e tempi di percorrenza...',
    );

    final departureDate = switch (query.dateConstraint) {
      ExactDates(:final departure) => departure,
      FlexibleDates(:final departures) when departures.isNotEmpty =>
        departures.first,
      _ => DateTime(2026, 11, 20, 9, 30),
    };

    final destination = query.destinationCandidates.isNotEmpty
        ? query.destinationCandidates.first
        : 'LIS';
    final origin = query.originCandidates.isNotEmpty
        ? query.originCandidates.first
        : 'FCO';

    final offers = <ProviderOffer>[
      ProviderOffer(
        id: 'mock-flight-1',
        providerId: providerIdentifier,
        kind: OfferKind.flight,
        origin: origin,
        destination: destination,
        departureDate: departureDate,
        returnDate: departureDate.add(const Duration(days: 3)),
        priceCents: 4900,
        externalBookingUrl: 'https://ryanair.com/booking/mock1',
        fetchedAt: DateTime.now(),
        truthState: OfferTruthState.demo,
        tradeoffSummary: 'Diretto, ottimo orario, bagaglio escluso',
        badgeLabel: 'Dati demo',
      ),
      ProviderOffer(
        id: 'mock-flight-2',
        providerId: providerIdentifier,
        kind: OfferKind.flight,
        origin: origin,
        destination: destination,
        departureDate: departureDate.add(const Duration(hours: 4)),
        returnDate: departureDate.add(const Duration(days: 3, hours: 2)),
        priceCents: 7500,
        externalBookingUrl: 'https://tap.pt/booking/mock2',
        fetchedAt: DateTime.now(),
        truthState: OfferTruthState.demo,
        tradeoffSummary: 'Compagnia di linea, bagaglio a mano incluso',
        badgeLabel: 'Dati demo',
      ),
    ];

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.partial,
      occurredAt: DateTime.now(),
      offers: offers.take(1).toList(),
      message: 'Trovata 1 prima combinazione.',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: providerIdentifier,
      kind: ProviderUpdateKind.completed,
      occurredAt: DateTime.now(),
      offers: offers,
      message: 'Ricerca completata: 2 opzioni disponibili.',
    );
  }
}
