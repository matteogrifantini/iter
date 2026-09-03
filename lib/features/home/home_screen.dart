import 'package:flutter/material.dart';
import '../trips/trip_entity.dart';
import '../trips/trip_repository.dart';
import 'widgets/home_deals_section.dart';
import 'widgets/home_discover_section.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_trips_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenNewTripChat,
    required this.onOpenTripDetails,
    required this.onOpenProfile,
    this.tripRepository,
  });

  final void Function({String? destination}) onOpenNewTripChat;
  final ValueChanged<TripEntity> onOpenTripDetails;
  final VoidCallback onOpenProfile;
  final TripRepository? tripRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TripRepository _repo;
  List<TripEntity> _trips = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.tripRepository ?? TripRepository();
    _loadTrips();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tripRepository != oldWidget.tripRepository) {
      _repo = widget.tripRepository ?? TripRepository();
      _loadTrips();
    }
  }

  Future<void> _loadTrips() async {
    final trips = await _repo.getAllTrips();
    if (mounted) {
      setState(() {
        _trips = trips;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width <= 360 ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadTrips,
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 96),
            children: [
              // Header Superiore
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'iter',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline_rounded),
                    tooltip: 'Il tuo profilo',
                    onPressed: widget.onOpenProfile,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Banner Hero Primario
              HomeHeroBanner(
                onOpenNewTripChat: () => widget.onOpenNewTripChat(),
              ),
              const SizedBox(height: 28),

              // Sezione: Le tue pianificazioni
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                )
              else
                HomeTripsSection(
                  trips: _trips,
                  onOpenTripDetails: widget.onOpenTripDetails,
                  onOpenNewTripChat: () => widget.onOpenNewTripChat(),
                ),
              const SizedBox(height: 28),

              // Sezione: Consigli & Offerte per te
              HomeDealsSection(
                onSelectDestination: (dest) => widget.onOpenNewTripChat(destination: dest),
              ),
              const SizedBox(height: 28),

              // Sezione: Scopri nuovi posti
              HomeDiscoverSection(
                onSelectDestination: (dest) => widget.onOpenNewTripChat(destination: dest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
