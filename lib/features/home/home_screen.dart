import 'package:flutter/material.dart';
import '../trips/trip_entity.dart';
import '../trips/trip_repository.dart';
import 'widgets/destination_details_sheet.dart';
import 'widgets/home_deals_section.dart';
import 'widgets/home_discover_section.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_reels_section.dart';

class HomeScreen extends StatelessWidget {
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

  void _openCityOverview(BuildContext context, String destination) {
    DestinationDetailsSheet.show(
      context,
      destination: destination,
      onStartPlanning: (dest) => onOpenNewTripChat(destination: dest),
    );
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
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 112),
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
                  onPressed: onOpenProfile,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Banner Hero Primario con video
            HomeHeroBanner(
              onOpenNewTripChat: () => onOpenNewTripChat(),
              onSelectDestination: (dest) => _openCityOverview(context, dest),
            ),
            const SizedBox(height: 28),

            // Sezione: Momenti & Atmosfere dal vivo (Reels video)
            HomeReelsSection(
              onSelectDestination: (dest) => _openCityOverview(context, dest),
            ),
            const SizedBox(height: 28),

            // Sezione: Consigli & Offerte per te
            HomeDealsSection(
              onSelectDestination: (dest) => _openCityOverview(context, dest),
            ),
            const SizedBox(height: 28),

            // Sezione: Scopri nuovi posti
            HomeDiscoverSection(
              onSelectDestination: (dest) => _openCityOverview(context, dest),
            ),
          ],
        ),
      ),
    );
  }
}
