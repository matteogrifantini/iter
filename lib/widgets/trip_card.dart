import 'package:flutter/material.dart';

import '../app/iter_theme.dart';
import '../models/trip_models.dart';
import 'journey_media.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destination = trip.destination;
    final colors = Theme.of(context).colorScheme;
    final posters = DemoMedia.postersForDestination(destination?.id ?? '');
    final image = posters[trip.id.hashCode.abs() % posters.length];
    final stage = switch (trip.stage) {
      TripStage.destinationDiscovery => 'Trova la direzione',
      TripStage.placeCuration => '${trip.selectedPlaceCount} luoghi scelti',
      TripStage.transportSelection => 'Scegli come arrivare',
      TripStage.staySelection => 'Scegli la zona',
      TripStage.itinerary => '${trip.days.length} giorni pronti',
      TripStage.ready => 'Viaggio completo',
    };
    final route =
        trip.journey?.stops.join('  →  ') ?? destination?.name ?? 'Nuova idea';

    return Semantics(
      button: true,
      label: '${trip.title}, $stage',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 154,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(image, fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: context.iterColors.videoScrim,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                route,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: trip.status == TripStatus.completed
                            ? colors.tertiary
                            : colors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
