import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/trip_card.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({
    super.key,
    required this.resumableTrips,
    required this.completedTrips,
    required this.onOpenTrip,
    required this.onNewTrip,
  });

  final List<Trip> resumableTrips;
  final List<Trip> completedTrips;
  final ValueChanged<Trip> onOpenTrip;
  final VoidCallback onNewTrip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viaggi',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resumableTrips.length} in corso · ${completedTrips.length} passati',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Nuovo viaggio',
                onPressed: onNewTrip,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        if (resumableTrips.isEmpty && completedTrips.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(Icons.route, size: 46, color: colors.primary),
                const SizedBox(height: 18),
                Text(
                  'Qui prenderanno forma i tuoi viaggi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onNewTrip, child: const Text('Inizia')),
              ],
            ),
          )
        else ...[
          if (resumableTrips.isNotEmpty) ...[
            _Label(title: 'In corso'),
            ...resumableTrips.map(
              (trip) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: TripCard(trip: trip, onTap: () => onOpenTrip(trip)),
              ),
            ),
          ],
          if (completedTrips.isNotEmpty) ...[
            _Label(title: 'Ricordi'),
            ...completedTrips.map(
              (trip) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: TripCard(trip: trip, onTap: () => onOpenTrip(trip)),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
