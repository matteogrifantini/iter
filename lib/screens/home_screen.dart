import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/journey_media.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.trips,
    required this.onNewTrip,
    required this.onOpenTrip,
    required this.onAvailability,
    required this.onSeeAllTrips,
    required this.onProfile,
  });

  final List<Trip> trips;
  final VoidCallback onNewTrip;
  final ValueChanged<Trip> onOpenTrip;
  final VoidCallback onAvailability;
  final VoidCallback onSeeAllTrips;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final resumable = trips.where((trip) => trip.isResumable).toList();
    final active = resumable.isEmpty ? null : resumable.first;
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      key: const PageStorageKey('home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Text(
                    'ITER',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Apri il profilo',
                    onPressed: onProfile,
                    icon: const Icon(Icons.person_outline),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              Text(
                'Ciao, Matteo.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Partiamo da come vuoi sentirti.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 46,
                child: JourneyRouteLine(
                  progress: active == null ? .12 : .68,
                  horizontal: true,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('new-trip'),
                onPressed: onNewTrip,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Inizia un viaggio'),
              ),
              if (active != null) ...[
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'In corso',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onSeeAllTrips,
                      child: const Text('Tutti i viaggi'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ActiveJourneyRow(
                  trip: active,
                  onTap: () => onOpenTrip(active),
                ),
              ],
              const SizedBox(height: 34),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 64,
                leading: Icon(
                  Icons.calendar_month_outlined,
                  color: colors.primary,
                ),
                title: const Text('Quando puoi partire?'),
                subtitle: const Text(
                  'Segna i giorni liberi, anche senza una meta.',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: onAvailability,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveJourneyRow extends StatelessWidget {
  const _ActiveJourneyRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stageLabel = switch (trip.stage) {
      TripStage.destinationDiscovery => 'Stiamo capendo che viaggio cerchi',
      TripStage.placeCuration => '${trip.selectedPlaceCount} luoghi tenuti',
      TripStage.transportSelection => 'Scegli come arrivare',
      TripStage.staySelection => 'Scegli la prima base',
      TripStage.itinerary => '${trip.days.length} giorni in costruzione',
      TripStage.ready => 'Pronto da rileggere',
    };
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: const Icon(Icons.route_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stageLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}
