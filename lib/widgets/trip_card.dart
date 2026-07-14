import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import 'iter_ui.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destination = trip.destination;
    final colors = Theme.of(context).colorScheme;
    final days = trip.days.length;
    final stage = switch (trip.stage) {
      TripStage.destinationDiscovery => 'Stiamo scegliendo la meta',
      TripStage.placeCuration => '${trip.selectedPlaceCount} idee salvate',
      TripStage.transportSelection => 'Scegli volo o treno',
      TripStage.staySelection => 'Scegli dove dormire',
      TripStage.itinerary =>
        '$days ${days == 1 ? 'giorno pronto' : 'giorni pronti'}',
      TripStage.ready => 'Viaggio archiviato',
    };

    return SurfacePanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Semantics(
        label: '${trip.title}, $stage',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 18,
                    top: 16,
                    child: Icon(
                      Icons.route_outlined,
                      color: colors.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 58,
                    bottom: 14,
                    child: Text(
                      trip.journey?.stops.join(' → ') ??
                          destination?.name ??
                          'Nuova idea',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          stage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
