import 'package:flutter/material.dart';
import 'flight_models.dart';
import 'flight_search_service.dart';

/// Modal bottom sheet allowing travelers to explore and compare flight options.
class FlightSearchSheet extends StatefulWidget {
  const FlightSearchSheet({
    super.key,
    required this.destination,
    this.initialOriginCity = 'Milano',
    this.initialOriginIata = 'MXP',
    this.onFlightSelected,
  });

  final String destination;
  final String initialOriginCity;
  final String initialOriginIata;
  final ValueChanged<FlightOffer>? onFlightSelected;

  @override
  State<FlightSearchSheet> createState() => _FlightSearchSheetState();
}

class _FlightSearchSheetState extends State<FlightSearchSheet> {
  final _service = const FlightSearchService();
  late String _originCity;
  late String _originIata;
  FlightSortBy _sortBy = FlightSortBy.best;
  List<FlightOffer> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _originCity = widget.initialOriginCity;
    _originIata = widget.initialOriginIata;
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() => _loading = true);
    final results = await _service.searchFlights(
      destination: widget.destination,
      originCity: _originCity,
      originIata: _originIata,
      sortBy: _sortBy,
    );
    if (mounted) {
      setState(() {
        _offers = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flight_takeoff_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voli per ${widget.destination}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Partenza da $_originCity ($_originIata) · Comparatore live',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Origin selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _hubChip('Milano (MXP/BGY)', 'Milano', 'MXP'),
                _hubChip('Roma (FCO)', 'Roma', 'FCO'),
                _hubChip('Napoli (NAP)', 'Napoli', 'NAP'),
                _hubChip('Venezia (VCE)', 'Venezia', 'VCE'),
                _hubChip('Bologna (BLQ)', 'Bologna', 'BLQ'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Sort segmented button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<FlightSortBy>(
              segments: const [
                ButtonSegment(
                  value: FlightSortBy.best,
                  label: Text('Consigliati'),
                ),
                ButtonSegment(
                  value: FlightSortBy.cheapest,
                  label: Text('Economici'),
                ),
                ButtonSegment(
                  value: FlightSortBy.fastest,
                  label: Text('Diretti'),
                ),
              ],
              selected: {_sortBy},
              onSelectionChanged: (newSet) {
                setState(() => _sortBy = newSet.first);
                _loadFlights();
              },
            ),
          ),
          const SizedBox(height: 12),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _offers.isEmpty
                ? Center(
                    child: Text(
                      'Nessun volo trovato per questa rotta.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final f = _offers[index];
                      return _buildFlightCard(context, f, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hubChip(String label, String city, String iata) {
    final isSelected = _originCity == city;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _originCity = city;
            _originIata = iata;
          });
          _loadFlights();
        },
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context, FlightOffer f, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Airline & Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: f.airlineColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  f.airlineName,
                  style: TextStyle(
                    color: f.airlineColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                f.flightNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  f.badgeLabel,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Flight times & Route visualizer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Departure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.departureTime,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    f.originIata,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Flight path graphic
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        f.durationLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.grey),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: Colors.grey.withAlpha(120),
                            ),
                          ),
                          Icon(
                            Icons.flight,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: Colors.grey.withAlpha(120),
                            ),
                          ),
                          const Icon(Icons.circle, size: 6, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.isDirect
                            ? 'Diretto'
                            : f.stopoverDuration ?? '1 scalo',
                        style: TextStyle(
                          fontSize: 11,
                          color: f.isDirect
                              ? Colors.green[700]
                              : Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrival
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    f.arrivalTime,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    f.destinationIata,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Price & Select Action
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'da €${f.priceEur.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'a persona, tasse incluse',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Seleziona'),
                onPressed: () {
                  widget.onFlightSelected?.call(f);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
