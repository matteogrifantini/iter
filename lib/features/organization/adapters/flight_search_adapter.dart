import '../../flights/flight_models.dart';
import '../../flights/flight_search_service.dart';
import '../models/organization_models.dart';
import '../providers/provider_capabilities.dart';
import '../providers/travel_search_provider.dart';

/// Criteri di ordinamento supportati per le offerte volo.
enum FlightSortCriterion { best, cheapest, fastest, leastStops, mostAligned }

/// Adapter che normalizza la ricerca voli in contratti [ProviderOffer]
/// e implementa la porta [TravelSearchProvider].
class FlightSearchAdapter implements TravelSearchProvider {
  const FlightSearchAdapter({this.flightService = const FlightSearchService()});

  final FlightSearchService flightService;

  static const ProviderCapabilities capabilities = ProviderCapabilities(
    providerId: 'fast-flights',
    displayName: 'Fast Flights Adapter',
    state: ProviderCapabilityState.mockOnly,
    supportedModes: <TravelMode>{TravelMode.flight},
    message: 'Ricerca voli dimostrativa locale con pricing e orari realistici.',
  );

  @override
  Stream<TravelSearchUpdate> search(TravelSearchQuery query) async* {
    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: 'fast-flights',
      kind: ProviderUpdateKind.started,
      occurredAt: DateTime.now(),
      message: 'Avvio ricerca voli...',
    );

    final destination = query.destinationCandidates.isNotEmpty
        ? query.destinationCandidates.first
        : 'Lisbona';
    final origin = query.originCandidates.isNotEmpty
        ? query.originCandidates.first
        : 'Milano';

    final departureDate = switch (query.dateConstraint) {
      ExactDates(:final departure) => departure,
      FlexibleDates(:final departures) when departures.isNotEmpty =>
        departures.first,
      _ => null,
    };

    final offers = await searchFlights(
      destination: destination,
      originCity: origin,
      departureDate: departureDate,
      budgetPerPerson: query.budgetCentsPerPerson != null
          ? query.budgetCentsPerPerson! / 100.0
          : null,
    );

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: 'fast-flights',
      kind: ProviderUpdateKind.progressed,
      occurredAt: DateTime.now(),
      message: 'Offerte individuate da $origin a $destination',
    );

    yield TravelSearchUpdate(
      tripId: query.tripId,
      providerId: 'fast-flights',
      kind: ProviderUpdateKind.completed,
      occurredAt: DateTime.now(),
      offers: offers,
      message: 'Trovate ${offers.length} offerte di volo',
    );
  }

  /// Esegue la ricerca voli e mappa il risultato in [ProviderOffer].
  Future<List<ProviderOffer>> searchFlights({
    required String destination,
    String originCity = 'Milano',
    String originIata = 'MXP',
    DateTime? departureDate,
    FlightSortCriterion sortBy = FlightSortCriterion.best,
    double? budgetPerPerson,
  }) async {
    final flightSortBy = _mapToSortBy(sortBy);
    final rawOffers = await flightService.searchFlights(
      destination: destination,
      originCity: originCity,
      originIata: originIata,
      departureDate: departureDate,
      sortBy: flightSortBy,
    );

    final now = DateTime.now();
    final defaultExpiry = now.add(const Duration(minutes: 30));

    final normalized = rawOffers.map((raw) {
      final tradeoff = _generateTradeoffSummary(raw, budgetPerPerson);
      return ProviderOffer(
        id: raw.id,
        providerId: 'fast-flights',
        type: OfferType.flight,
        origin: '${raw.originCity} (${raw.originIata})',
        destination: '${raw.destinationCity} (${raw.destinationIata})',
        departureDate: departureDate ?? now.add(const Duration(days: 30)),
        priceEur: raw.priceEur,
        currency: 'EUR',
        conditions: <String, dynamic>{
          'airlineName': raw.airlineName,
          'airlineCode': raw.airlineCode,
          'flightNumber': raw.flightNumber,
          'departureTime': raw.departureTime,
          'arrivalTime': raw.arrivalTime,
          'durationLabel': raw.durationLabel,
          'isDirect': raw.isDirect,
          'stopoverCity': raw.stopoverCity,
          'stopoverDuration': raw.stopoverDuration,
          'cabinBagIncluded': raw.cabinBagIncluded,
        },
        mediaUrls: const <String>[],
        externalBookingUrl: raw.bookingUrl,
        fetchedAt: now,
        expiresAt: defaultExpiry,
        status: OfferStatus.demo,
        tradeoffSummary: tradeoff,
        badgeLabel: raw.badgeLabel.isNotEmpty ? raw.badgeLabel : 'Dati demo',
      );
    }).toList();

    return _applyPostSorting(normalized, sortBy, budgetPerPerson);
  }

  FlightSortBy _mapToSortBy(FlightSortCriterion criterion) {
    switch (criterion) {
      case FlightSortCriterion.cheapest:
        return FlightSortBy.cheapest;
      case FlightSortCriterion.fastest:
        return FlightSortBy.fastest;
      case FlightSortCriterion.best:
      case FlightSortCriterion.leastStops:
      case FlightSortCriterion.mostAligned:
        return FlightSortBy.best;
    }
  }

  List<ProviderOffer> _applyPostSorting(
    List<ProviderOffer> offers,
    FlightSortCriterion sortBy,
    double? budgetPerPerson,
  ) {
    final sorted = List<ProviderOffer>.from(offers);
    switch (sortBy) {
      case FlightSortCriterion.cheapest:
        sorted.sort((a, b) => a.priceEur.compareTo(b.priceEur));
        break;
      case FlightSortCriterion.fastest:
        sorted.sort((a, b) {
          final aDirect = (a.conditions['isDirect'] as bool?) ?? false;
          final bDirect = (b.conditions['isDirect'] as bool?) ?? false;
          if (aDirect != bDirect) return aDirect ? -1 : 1;
          return a.priceEur.compareTo(b.priceEur);
        });
        break;
      case FlightSortCriterion.leastStops:
        sorted.sort((a, b) {
          final aDirect = (a.conditions['isDirect'] as bool?) ?? false;
          final bDirect = (b.conditions['isDirect'] as bool?) ?? false;
          if (aDirect != bDirect) return aDirect ? -1 : 1;
          return a.priceEur.compareTo(b.priceEur);
        });
        break;
      case FlightSortCriterion.mostAligned:
        if (budgetPerPerson != null) {
          sorted.sort((a, b) {
            final aDiff = (a.priceEur - budgetPerPerson).abs();
            final bDiff = (b.priceEur - budgetPerPerson).abs();
            return aDiff.compareTo(bDiff);
          });
        }
        break;
      case FlightSortCriterion.best:
        break;
    }
    return sorted;
  }

  String _generateTradeoffSummary(FlightOffer raw, double? budgetPerPerson) {
    final buffer = StringBuffer();
    if (raw.isDirect) {
      buffer.write('Volo diretto (${raw.durationLabel})');
    } else {
      buffer.write(
        'Con scalo a ${raw.stopoverCity ?? "scalo intermedio"} (${raw.durationLabel})',
      );
    }

    if (raw.cabinBagIncluded) {
      buffer.write(' · Bagaglio a mano incluso');
    }

    if (budgetPerPerson != null && raw.priceEur <= budgetPerPerson) {
      buffer.write(' · Pienamente nel budget');
    } else if (budgetPerPerson != null) {
      final excess = (raw.priceEur - budgetPerPerson).round();
      buffer.write(' · +$excess € rispetto al target');
    }

    return buffer.toString();
  }
}
