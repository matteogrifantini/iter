import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          eyebrow: 'I tuoi viaggi',
          title: resumableTrips.isEmpty
              ? 'Il prossimo comincia da qui.'
              : 'I viaggi che stanno prendendo forma.',
          subtitle:
              'Ogni piano conserva le tue scelte, non solo una lista di posti.',
          trailing: IconButton.filledTonal(
            tooltip: 'Nuovo viaggio',
            onPressed: onNewTrip,
            icon: const Icon(Icons.add),
          ),
        ),
        if (resumableTrips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.luggage_outlined),
                  const SizedBox(height: 12),
                  Text(
                    'Nessun viaggio in corso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Un’idea libera è tutto quello che serve per iniziare.',
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: onNewTrip,
                    child: const Text('Nuovo viaggio'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          const SectionTitle(title: 'Da continuare'),
          ...resumableTrips.map(
            (trip) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TripCard(trip: trip, onTap: () => onOpenTrip(trip)),
            ),
          ),
        ],
        if (completedTrips.isNotEmpty) ...[
          const SectionTitle(title: 'Viaggi passati'),
          ...completedTrips.map(
            (trip) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TripCard(trip: trip, onTap: () => onOpenTrip(trip)),
            ),
          ),
        ],
      ],
    );
  }
}
