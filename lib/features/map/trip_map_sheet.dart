import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip_map_models.dart';

/// Interactive modal sheet displaying a REAL OpenStreetMap with interactive POI pins and routes.
class TripMapSheet extends StatefulWidget {
  const TripMapSheet({
    super.key,
    required this.destination,
    required this.dayTitle,
    required this.places,
  });

  final String destination;
  final String dayTitle;
  final List<MapPoiLocation> places;

  static const Map<String, (double, double)> _knownCoordinates = {
    // Budapest
    'parlamento': (47.5072, 19.0458),
    'castello': (47.4962, 19.0396),
    'széchenyi': (47.5186, 19.0825),
    'szechenyi': (47.5186, 19.0825),
    'terme': (47.5186, 19.0825),
    'basilica': (47.5009, 19.0540),
    'mercato': (47.4870, 19.0583),
    'bastione': (47.5022, 19.0348),
    'ponte': (47.4990, 19.0437),

    // Porto
    'ribeira': (41.1408, -8.6133),
    'clérigos': (41.1458, -8.6143),
    'clerigos': (41.1458, -8.6143),
    'lello': (41.1468, -8.6149),
    'douro': (41.1396, -8.6094),
    'gaia': (41.1350, -8.6140),

    // Roma
    'colosseo': (41.8902, 12.4922),
    'borghese': (41.9142, 12.4922),
    'trastevere': (41.8883, 12.4704),
    'navona': (41.8986, 12.4731),
    'vaticano': (41.9029, 12.4534),

    // Lisbona
    'belém': (38.6916, -9.2160),
    'belem': (38.6916, -9.2160),
    'alfama': (38.7121, -9.1306),
    'tram': (38.7110, -9.1340),
    'miradouro': (38.7196, -9.1325),
  };

  static List<MapPoiLocation> resolveLocations(
    String destination,
    List<String> placeTitles,
  ) {
    final list = <MapPoiLocation>[];
    for (var i = 0; i < placeTitles.length; i++) {
      final title = placeTitles[i];
      final titleLower = title.toLowerCase();
      var coord = const (47.4979, 19.0402);

      for (final entry in _knownCoordinates.entries) {
        if (titleLower.contains(entry.key)) {
          coord = entry.value;
          break;
        }
      }

      list.add(
        MapPoiLocation(
          id: 'poi-map-$i',
          title: title,
          category: 'Tappa ${i + 1}',
          latitude: coord.$1 + (i * 0.003),
          longitude: coord.$2 + (i * 0.002),
        ),
      );
    }
    return list;
  }

  @override
  State<TripMapSheet> createState() => _TripMapSheetState();
}

class _TripMapSheetState extends State<TripMapSheet> {
  final _mapController = MapController();
  final _mapService = RealMapService();
  List<LatLng> _routeGeometry = [];
  MapPoiLocation? _selectedPoi;

  @override
  void initState() {
    super.initState();
    _loadRealRoute();
  }

  Future<void> _loadRealRoute() async {
    if (widget.places.length < 2) return;
    final waypoints = widget.places.map((p) => p.latLng).toList();
    final route = await _mapService.fetchWalkingRoute(waypoints);
    if (mounted) {
      setState(() => _routeGeometry = route);
    }
  }

  LatLng get _initialCenter {
    if (widget.places.isNotEmpty) {
      return widget.places.first.latLng;
    }
    return const LatLng(47.4979, 19.0402);
  }

  Future<void> _openNavigation(MapPoiLocation poi) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${poi.latitude},${poi.longitude}&travelmode=walking',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mappa Live OpenStreetMap',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.dayTitle} · ${widget.destination} · Percorsi a piedi reali',
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
          // REAL OPENSTREETMAP CONTAINER
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 14.0,
                      maxZoom: 18.0,
                      minZoom: 4.0,
                    ),
                    children: [
                      // OpenStreetMap live tile layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'app.itertravel',
                      ),
                      // Walking route polyline
                      if (_routeGeometry.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routeGeometry,
                              strokeWidth: 4.0,
                              color: const Color(0xFF0284C7),
                            ),
                          ],
                        ),
                      // POI Markers
                      MarkerLayer(
                        markers: widget.places.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final poi = entry.value;
                          final isSelected = _selectedPoi?.id == poi.id;

                          return Marker(
                            point: poi.latLng,
                            width: isSelected ? 48 : 36,
                            height: isSelected ? 48 : 36,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedPoi = poi);
                                _mapController.move(poi.latLng, 15.5);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Layer badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black87
                          : Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.places.length} tappe connesse via OSRM',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Selected POI or Stops List
          Expanded(
            flex: 2,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: widget.places.length,
                itemBuilder: (context, index) {
                  final place = widget.places[index];
                  final hasNext = index + 1 < widget.places.length;
                  final nextPlace = hasNext ? widget.places[index + 1] : null;
                  final walkMin = nextPlace != null
                      ? place.walkingMinutesTo(nextPlace)
                      : 0;
                  final distM = nextPlace != null
                      ? place.distanceTo(nextPlace).round()
                      : 0;
                  final isSelected = _selectedPoi?.id == place.id;

                  return Column(
                    children: [
                      Card(
                        elevation: isSelected ? 2 : 0,
                        color: isSelected
                            ? theme.colorScheme.primary.withAlpha(20)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                      ? Colors.white12
                                      : Colors.black.withAlpha(15)),
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() => _selectedPoi = place);
                            _mapController.move(place.latLng, 15.5);
                          },
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.deepOrange
                                : theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            place.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton.filledTonal(
                            icon: const Icon(
                              Icons.navigation_rounded,
                              size: 18,
                            ),
                            tooltip: 'Apri navigatore Google Maps',
                            onPressed: () => _openNavigation(place),
                          ),
                        ),
                      ),
                      if (hasNext)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const SizedBox(width: 32),
                              Container(
                                width: 2,
                                height: 20,
                                color: theme.colorScheme.primary.withAlpha(80),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.directions_walk,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$walkMin min a piedi (${distM > 1000 ? "${(distM / 1000).toStringAsFixed(1)} km" : "$distM m"})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
