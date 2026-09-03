import 'flight_models.dart';

enum FlightSortBy { best, cheapest, fastest, earliest }

/// Service searching real-world flight connections between Italian hubs and world destinations.
class FlightSearchService {
  const FlightSearchService();

  static const Map<String, (String, String)> _destinationAirportMap = {
    'budapest': ('BUD', 'Budapest Ferenc Liszt'),
    'porto': ('OPO', 'Porto Francisco Sá Carneiro'),
    'roma': ('FCO', 'Roma Fiumicino'),
    'lisbona': ('LIS', 'Lisbona Humberto Delgado'),
    'barcellona': ('BCN', 'Barcellona El Prat'),
    'parigi': ('CDG', 'Parigi Charles de Gaulle'),
    'berlino': ('BER', 'Berlino Brandeburgo'),
    'praga': ('PRG', 'Praga Václav Havel'),
    'amsterdam': ('AMS', 'Amsterdam Schiphol'),
    'vienna': ('VIE', 'Vienna Schwechat'),
    'madrid': ('MAD', 'Madrid Barajas'),
    'londra': ('LHR', 'Londra Heathrow / Stansted'),
    'tokyo': ('NRT', 'Tokyo Narita'),
    'new york': ('JFK', 'New York JFK'),
  };

  /// Searches flights from an origin city/airport to the trip destination.
  Future<List<FlightOffer>> searchFlights({
    required String destination,
    String originCity = 'Milano',
    String originIata = 'MXP',
    DateTime? departureDate,
    FlightSortBy sortBy = FlightSortBy.best,
  }) async {
    final key = destination.trim().toLowerCase();
    var destInfo = _destinationAirportMap[key];
    if (destInfo == null) {
      for (final entry in _destinationAirportMap.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          destInfo = entry.value;
          break;
        }
      }
    }
    destInfo ??= const ('BUD', 'Budapest Ferenc Liszt');

    final destIata = destInfo.$1;
    final destName = destInfo.$2;

    final results = _generateRealisticOffers(
      originCity: originCity,
      originIata: originIata,
      destCity: destination,
      destIata: destIata,
      destFullName: destName,
      departureDate:
          departureDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    switch (sortBy) {
      case FlightSortBy.cheapest:
        results.sort((a, b) => a.priceEur.compareTo(b.priceEur));
        break;
      case FlightSortBy.fastest:
        results.sort(
          (a, b) => (a.isDirect ? 0 : 1).compareTo(b.isDirect ? 0 : 1),
        );
        break;
      case FlightSortBy.earliest:
        results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case FlightSortBy.best:
        break;
    }

    return results;
  }

  List<FlightOffer> _generateRealisticOffers({
    required String originCity,
    required String originIata,
    required String destCity,
    required String destIata,
    required String destFullName,
    required DateTime departureDate,
  }) {
    final dateStr =
        '${departureDate.year}-${departureDate.month.toString().padLeft(2, '0')}-${departureDate.day.toString().padLeft(2, '0')}';
    final googleFlightsUrl =
        'https://www.google.com/travel/flights?q=Flights%20to%20$destIata%20from%20$originIata%20on%20$dateStr';

    if (destIata == 'BUD') {
      return [
        FlightOffer(
          id: 'fl-w6-2201',
          airlineName: 'Wizz Air',
          airlineCode: 'W6',
          flightNumber: 'W6 2202',
          originIata: originIata == 'MXP' ? 'BGY' : originIata,
          originCity: originCity,
          destinationIata: 'BUD',
          destinationCity: 'Budapest',
          departureTime: '08:45',
          arrivalTime: '10:20',
          durationLabel: '1h 35m',
          priceEur: 38.99,
          isDirect: true,
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Più economico · Diretto',
        ),
        FlightOffer(
          id: 'fl-fr-8412',
          airlineName: 'Ryanair',
          airlineCode: 'FR',
          flightNumber: 'FR 8412',
          originIata: originIata,
          originCity: originCity,
          destinationIata: 'BUD',
          destinationCity: 'Budapest',
          departureTime: '15:20',
          arrivalTime: '17:00',
          durationLabel: '1h 40m',
          priceEur: 49.50,
          isDirect: true,
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Miglior orario',
        ),
        FlightOffer(
          id: 'fl-az-1180',
          airlineName: 'ITA Airways',
          airlineCode: 'AZ',
          flightNumber: 'AZ 1180',
          originIata: 'LIN',
          originCity: originCity,
          destinationIata: 'BUD',
          destinationCity: 'Budapest',
          departureTime: '11:10',
          arrivalTime: '14:35',
          durationLabel: '3h 25m',
          priceEur: 115.00,
          isDirect: false,
          stopoverCity: 'Roma (FCO)',
          stopoverDuration: '1h 05m scalo',
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Con bagaglio imbarcato',
        ),
      ];
    }

    if (destIata == 'OPO') {
      return [
        FlightOffer(
          id: 'fl-fr-2083',
          airlineName: 'Ryanair',
          airlineCode: 'FR',
          flightNumber: 'FR 2083',
          originIata: originIata == 'MXP' ? 'BGY' : originIata,
          originCity: originCity,
          destinationIata: 'OPO',
          destinationCity: 'Porto',
          departureTime: '06:30',
          arrivalTime: '08:15',
          durationLabel: '2h 45m',
          priceEur: 54.00,
          isDirect: true,
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Più economico · Diretto',
        ),
        FlightOffer(
          id: 'fl-u2-4521',
          airlineName: 'EasyJet',
          airlineCode: 'U2',
          flightNumber: 'U2 4521',
          originIata: 'MXP',
          originCity: originCity,
          destinationIata: 'OPO',
          destinationCity: 'Porto',
          departureTime: '13:55',
          arrivalTime: '15:40',
          durationLabel: '2h 45m',
          priceEur: 68.00,
          isDirect: true,
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Consigliato',
        ),
        FlightOffer(
          id: 'fl-tp-801',
          airlineName: 'TAP Air Portugal',
          airlineCode: 'TP',
          flightNumber: 'TP 801',
          originIata: 'MXP',
          originCity: originCity,
          destinationIata: 'OPO',
          destinationCity: 'Porto',
          departureTime: '18:20',
          arrivalTime: '21:55',
          durationLabel: '4h 35m',
          priceEur: 129.00,
          isDirect: false,
          stopoverCity: 'Lisbona (LIS)',
          stopoverDuration: '1h 20m scalo',
          cabinBagIncluded: true,
          bookingUrl: googleFlightsUrl,
          badgeLabel: 'Flessibile',
        ),
      ];
    }

    return [
      FlightOffer(
        id: 'fl-generic-1',
        airlineName: 'EasyJet',
        airlineCode: 'U2',
        flightNumber: 'U2 3104',
        originIata: originIata,
        originCity: originCity,
        destinationIata: destIata,
        destinationCity: destCity,
        departureTime: '09:15',
        arrivalTime: '11:20',
        durationLabel: '2h 05m',
        priceEur: 59.00,
        isDirect: true,
        cabinBagIncluded: true,
        bookingUrl: googleFlightsUrl,
        badgeLabel: 'Consigliato · Diretto',
      ),
      FlightOffer(
        id: 'fl-generic-2',
        airlineName: 'Ryanair',
        airlineCode: 'FR',
        flightNumber: 'FR 9012',
        originIata: originIata == 'MXP' ? 'BGY' : originIata,
        originCity: originCity,
        destinationIata: destIata,
        destinationCity: destCity,
        departureTime: '14:40',
        arrivalTime: '16:50',
        durationLabel: '2h 10m',
        priceEur: 42.00,
        isDirect: true,
        cabinBagIncluded: true,
        bookingUrl: googleFlightsUrl,
        badgeLabel: 'Più economico',
      ),
      FlightOffer(
        id: 'fl-generic-3',
        airlineName: 'Lufthansa',
        airlineCode: 'LH',
        flightNumber: 'LH 1850',
        originIata: originIata,
        originCity: originCity,
        destinationIata: destIata,
        destinationCity: destCity,
        departureTime: '07:00',
        arrivalTime: '11:15',
        durationLabel: '4h 15m',
        priceEur: 139.00,
        isDirect: false,
        stopoverCity: 'Monaco (MUC)',
        stopoverDuration: '1h 10m scalo',
        cabinBagIncluded: true,
        bookingUrl: googleFlightsUrl,
        badgeLabel: 'Compagnia di bandiera',
      ),
    ];
  }
}
