import 'package:flutter/material.dart';
import 'trip_entity.dart';
import 'trip_repository.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({
    super.key,
    this.tripRepository,
    required this.onOpenTripChat,
    required this.onOpenTripSnapshot,
    required this.onStartNewTrip,
  });

  final TripRepository? tripRepository;
  final ValueChanged<TripEntity> onOpenTripChat;
  final ValueChanged<TripEntity> onOpenTripSnapshot;
  final VoidCallback onStartNewTrip;

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  late final TripRepository _repo;
  List<TripEntity> _trips = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.tripRepository ?? TripRepository();
    _loadTrips();
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

  Future<void> _deleteTrip(TripEntity trip) async {
    await _repo.deleteTrip(trip.id);
    await _loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'I tuoi viaggi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onStartNewTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuovo viaggio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _trips.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.luggage_outlined,
                          size: 64,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun viaggio pianificato',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tutte le tue conversazioni e i tuoi piani completi compariranno qui.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: widget.onStartNewTrip,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Inizia a organizzare'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: _trips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return _TripListItem(
                        trip: trip,
                        onOpenChat: () => widget.onOpenTripChat(trip),
                        onOpenSnapshot: () => widget.onOpenTripSnapshot(trip),
                        onDelete: () => _deleteTrip(trip),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TripListItem extends StatelessWidget {
  const _TripListItem({
    required this.trip,
    required this.onOpenChat,
    required this.onOpenSnapshot,
    required this.onDelete,
  });

  final TripEntity trip;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSnapshot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReady = trip.status == TripStatus.ready;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.shade50
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReady ? Colors.green.shade200 : colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isReady ? 'Pronto' : 'In pianificazione',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isReady ? Colors.green.shade800 : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${trip.durationDays} giorni',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Elimina viaggio', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trip.destination,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onOpenChat,
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('Chat'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onOpenSnapshot,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Itinerario'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
