import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trip_models.dart';
import '../features/new_trip_lab/new_trip_lab_screen.dart';
import '../screens/availability_screen.dart';
import '../screens/destination_discovery_screen.dart';
import '../screens/discover_tab.dart';
import '../screens/home_screen.dart';
import '../screens/itinerary_screen.dart';
import '../screens/place_curation_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/stay_selection_screen.dart';
import '../screens/trips_screen.dart';
import '../screens/transport_selection_screen.dart';
import '../state/iter_store.dart';
import '../widgets/iter_ui.dart';
import 'app_config.dart';
import 'iter_theme.dart';

class IterApp extends StatefulWidget {
  const IterApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<IterApp> createState() => _IterAppState();
}

class _IterAppState extends State<IterApp> {
  static const _themePreferenceKey = 'appearance:theme-mode:v1';

  late final IterStore _store;
  final _navigatorKey = GlobalKey<NavigatorState>();
  var _tabIndex = 0;
  var _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _store = IterStore.seeded();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final preferences = SharedPreferencesAsync();
      final saved = await preferences.getString(_themePreferenceKey);
      if (!mounted || saved == null) return;
      setState(() {
        _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
      });
    } catch (_) {
      // Widget tests and unsupported hosts keep the explicit light default.
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      final preferences = SharedPreferencesAsync();
      await preferences.setString(
        _themePreferenceKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // The visual preference still applies for the current session.
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Iter',
          debugShowCheckedModeBanner: false,
          theme: IterTheme.light(),
          darkTheme: IterTheme.dark(),
          themeMode: _themeMode,
          locale: const Locale('it'),
          supportedLocales: const <Locale>[Locale('it')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: _AppShell(
            tabIndex: _tabIndex,
            onTabChanged: (index) => setState(() => _tabIndex = index),
            home: HomeScreen(
              trips: _store.trips,
              onNewTrip: () => _startNewTrip(context),
              showNewTripLab: widget.config.newTripLab,
              onNewTripLab: _startNewTripLab,
              onOpenTrip: (trip) => _openTrip(context, trip),
              onAvailability: () => _openAvailability(context),
              onSeeAllTrips: () => setState(() => _tabIndex = 2),
              onProfile: () => setState(() => _tabIndex = 3),
            ),
            discover: DiscoverTab(
              journeys: _store.journeys,
              onStartDiscovery: () => _startNewTrip(context),
              onStartJourney: (journey) => _startFromTrend(context, journey),
            ),
            trips: TripsScreen(
              resumableTrips: _store.resumableTrips,
              completedTrips: _store.completedTrips,
              onOpenTrip: (trip) => _openTrip(context, trip),
              onNewTrip: () => _startNewTrip(context),
            ),
            profile: ProfileScreen(
              themeMode: _themeMode,
              onThemeChanged: _setTheme,
              onAvailability: () => _openAvailability(context),
            ),
          ),
        );
      },
    );
  }

  void _startNewTrip(BuildContext context) {
    _store.beginNewTrip();
    _push(context, _buildDiscovery);
  }

  void _startNewTripLab() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NewTripLabScreen()),
    );
  }

  void _startFromTrend(BuildContext context, JourneyRoute journey) {
    _store.beginNewTrip(note: journey.title);
    if (_store.chooseJourney(journey)) _push(context, _buildCuration);
  }

  void _openTrip(BuildContext context, Trip trip) {
    if (!_store.resumeTrip(trip.id)) return;
    switch (_store.currentDraft?.stage) {
      case TripStage.destinationDiscovery:
        _push(context, _buildDiscovery);
      case TripStage.placeCuration:
        _push(context, _buildCuration);
      case TripStage.transportSelection:
        _push(context, _buildTransportSelection);
      case TripStage.staySelection:
        _push(context, _buildStaySelection);
      case TripStage.itinerary || TripStage.ready:
        _push(context, _buildItinerary);
      case null:
        break;
    }
  }

  void _openAvailability(BuildContext context) {
    if (_store.currentDraft == null) _store.beginNewTrip();
    _push(context, _buildAvailability);
  }

  void _push(BuildContext context, Widget Function(BuildContext) screen) {
    _navigatorKey.currentState?.push(_route(screen));
  }

  void _replace(BuildContext context, Widget Function(BuildContext) screen) {
    _navigatorKey.currentState?.pushReplacement(_route(screen));
  }

  MaterialPageRoute<void> _route(Widget Function(BuildContext) screen) {
    return MaterialPageRoute<void>(
      builder: (routeContext) => AnimatedBuilder(
        animation: _store,
        builder: (_, _) => screen(routeContext),
      ),
    );
  }

  Widget _buildDiscovery(BuildContext context) {
    return DestinationDiscoveryScreen(
      journeys: _store.recommendedJourneys,
      initialAnswers: _store.currentDraft?.discoveryAnswers ?? const {},
      onAnswer: _store.answerDiscovery,
      onChatAnswer: _store.sendDiscoveryMessage,
      onChooseJourney: (journey) {
        if (_store.chooseJourney(journey)) {
          _replace(context, _buildCuration);
        }
      },
    );
  }

  Widget _buildCuration(BuildContext context) {
    final trip = _store.currentDraft;
    final destination = trip?.destination;
    if (trip == null || destination == null) {
      return const Scaffold(
        body: Center(child: Text('Prima costruiamo il viaggio.')),
      );
    }
    final destinationOrder =
        trip.journey?.destinationIds ?? <String>[destination.id];
    final rankedPlaces = _store.activeDestinationPlaces.toList()
      ..sort((left, right) {
        final byDestination = destinationOrder
            .indexOf(left.destinationId)
            .compareTo(destinationOrder.indexOf(right.destinationId));
        if (byDestination != 0) return byDestination;
        return right.matchScore.compareTo(left.matchScore);
      });
    final allPlaces = rankedPlaces.take(4).toList(growable: false);
    final remainingPlaces = allPlaces
        .where((place) => !trip.reactions.containsKey(place.id))
        .toList();
    return PlaceCurationScreen(
      destination: destination,
      journeyTitle: trip.journey?.title,
      destinationNames: <String, String>{
        for (final item in _store.availableDestinations) item.id: item.name,
      },
      places: remainingPlaces,
      totalSuggestions: allPlaces.length,
      reactions: trip.reactions,
      onReact: (place, reaction) =>
          _store.reactToPlace(reaction, placeId: place.id),
      onContinue: () {
        if (_store.beginTransportSelection()) {
          _replace(context, _buildTransportSelection);
        }
      },
    );
  }

  Widget _buildTransportSelection(BuildContext context) {
    final trip = _store.currentDraft;
    if (trip == null || trip.destination == null) {
      return const Scaffold(
        body: Center(child: Text('Prima costruiamo il viaggio.')),
      );
    }
    return TransportSelectionScreen(
      journeyTitle: trip.journey?.title ?? trip.destination!.name,
      options: _store.suggestedTransportOptions,
      initialSelection: trip.transportOption,
      onConfirm: (option) {
        if (_store.selectTransportOption(option)) {
          _replace(context, _buildStaySelection);
        }
      },
      onOpenSearch: (uri) => _openExternal(context, uri),
    );
  }

  Widget _buildStaySelection(BuildContext context) {
    final trip = _store.currentDraft;
    final destination = trip?.destination;
    if (trip == null || destination == null) {
      return const Scaffold(
        body: Center(child: Text('Prima costruiamo il viaggio.')),
      );
    }
    return StaySelectionScreen(
      destination: destination,
      journeyTitle: trip.journey?.title,
      destinationNames: <String, String>{
        for (final item in _store.availableDestinations) item.id: item.name,
      },
      zones: _store.suggestedStayZones,
      savedPlaces: _store.selectedPlaces,
      onSelect: (zone) {
        if (_store.selectStayZone(zone)) _replace(context, _buildItinerary);
      },
      onOpenHotelSearch: (uri) => _openExternal(context, uri),
    );
  }

  Widget _buildItinerary(BuildContext context) {
    final trip = _store.currentDraft;
    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Nessun piano aperto.')));
    }
    return ItineraryScreen(
      trip: trip,
      onSendAiMessage: _store.sendAiMessage,
      canUndoAiChange: _store.canUndoAiChange,
      onUndoAiChange: _store.undoLastAiChange,
      onToggleLock: _store.toggleItineraryLock,
      onRemoveItem: _store.removeItineraryItem,
      onFinish: () {
        if (_store.completeDraft()) {
          setState(() => _tabIndex = 2);
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  Widget _buildAvailability(BuildContext context) {
    final trip = _store.currentDraft;
    return AvailabilityScreen(
      selectedDates: trip?.availableDates ?? const <DateTime>[],
      onToggleDate: _store.toggleAvailability,
    );
  }

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (context.mounted && !opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non riesco ad aprire il sito in questo momento.'),
        ),
      );
    }
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.tabIndex,
    required this.onTabChanged,
    required this.home,
    required this.discover,
    required this.trips,
    required this.profile,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final Widget home;
  final Widget discover;
  final Widget trips;
  final Widget profile;

  @override
  Widget build(BuildContext context) {
    final current = <Widget>[home, discover, trips, profile][tabIndex];
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;
        final content = SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: useRail ? 720 : double.infinity,
              ),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(tabIndex), child: current),
              ),
            ),
          ),
        );
        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: tabIndex,
                    onDestinationSelected: onTabChanged,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        label: Text('Oggi'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.explore_outlined),
                        label: Text('Scopri'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.route_outlined),
                        label: Text('Viaggi'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        label: Text('Profilo'),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          body: content,
          bottomNavigationBar: IterBottomNavigation(
            currentIndex: tabIndex,
            onChanged: onTabChanged,
          ),
        );
      },
    );
  }
}
