import 'package:flutter/material.dart';
import '../../places/visual_media_service.dart';
import '../../trips/trip_entity.dart';

class HomeTripsSection extends StatelessWidget {
  const HomeTripsSection({
    super.key,
    required this.trips,
    required this.onOpenTripDetails,
    required this.onOpenNewTripChat,
  });

  final List<TripEntity> trips;
  final ValueChanged<TripEntity> onOpenTripDetails;
  final VoidCallback onOpenNewTripChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Le tue pianificazioni',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (trips.isNotEmpty)
              Text(
                '${trips.length} attive',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),
        if (trips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nessun viaggio pianificato',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inizia a raccontare a Iter dove vorresti andare.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onOpenNewTripChat,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Pianifica ora'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _TripCard(
                  trip: trip,
                  onTap: () => onOpenTripDetails(trip),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final TripEntity trip;
  final VoidCallback onTap;

  String _resolvePhotoUrl() {
    if (trip.coverImageUrl.isNotEmpty) {
      return trip.coverImageUrl;
    }
    return VisualMediaService.getPhotoForDestination(trip.destination);
  }


  @override
  Widget build(BuildContext context) {
    final photoUrl = _resolvePhotoUrl();
    final isReady = trip.status == TripStatus.ready;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 210,
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto di sfondo della destinazione
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF2D63FF),
                child: const Center(
                  child: Icon(Icons.flight_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),

            // Gradient per leggibilità
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Contenuto
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${trip.durationDays} giorni',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    trip.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isReady ? const Color(0xFFE7FF67) : Colors.amberAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isReady ? 'Itinerario pronto' : 'In pianificazione',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isReady ? const Color(0xFFE7FF67) : Colors.amberAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
