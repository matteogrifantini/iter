import 'package:flutter/material.dart';

import '../app/iter_theme.dart';
import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';
import '../widgets/journey_media.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({
    super.key,
    required this.trip,
    required this.onSendAiMessage,
    required this.canUndoAiChange,
    required this.onUndoAiChange,
    required this.onToggleLock,
    required this.onRemoveItem,
    required this.onFinish,
  });

  final Trip trip;
  final ValueChanged<String> onSendAiMessage;
  final bool canUndoAiChange;
  final bool Function() onUndoAiChange;
  final bool Function(String itemId) onToggleLock;
  final bool Function(String itemId) onRemoveItem;
  final VoidCallback onFinish;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _composer = TextEditingController();
  var _dayIndex = 0;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    widget.onSendAiMessage(text);
    _composer.clear();
  }

  void _remove(String itemId, String title) {
    final removed = widget.onRemoveItem(itemId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed ? '$title rimosso.' : 'Sblocca $title prima di rimuoverlo.',
        ),
      ),
    );
  }

  void _undo() {
    if (!widget.onUndoAiChange()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Modifica annullata.')));
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final destination = trip.destination;
    if (destination == null) {
      return const Scaffold(
        body: Center(child: Text('Scegli prima una meta.')),
      );
    }
    final days = trip.days;
    if (_dayIndex >= days.length) _dayIndex = 0;
    final day = days.isEmpty ? null : days[_dayIndex];
    final lastChange = trip.messages.lastPlanChange;
    final posters = DemoMedia.postersForDestination(destination.id);
    final videos =
        trip.journey?.videoAssets ?? DemoMedia.forDestination(destination.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Piano'),
        actions: [
          IconButton(
            tooltip: 'Salva il viaggio',
            onPressed: days.isEmpty ? null : widget.onFinish,
            icon: const Icon(Icons.check_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(
              currentStep: 3,
              padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    sliver: SliverToBoxAdapter(
                      child: _TripHero(trip: trip, videos: videos),
                    ),
                  ),
                  if (lastChange != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _PlanChangeNotice(
                          message: lastChange,
                          onUndo: widget.canUndoAiChange ? _undo : null,
                        ),
                      ),
                    ),
                  if (days.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: days.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ChoiceChip(
                            label: Text(days[index].label),
                            selected: index == _dayIndex,
                            onSelected: (_) =>
                                setState(() => _dayIndex = index),
                          ),
                        ),
                      ),
                    ),
                  if (day != null) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 5),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          day.theme,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      sliver: SliverList.builder(
                        itemCount: day.items.length,
                        itemBuilder: (context, index) {
                          final item = day.items[index];
                          return _VisualTimelineItem(
                            key: ValueKey(item.id),
                            item: item,
                            imageAsset: posters[index % posters.length],
                            isLast: index == day.items.length - 1,
                            onToggleLock: () => widget.onToggleLock(item.id),
                            onRemove: () => _remove(item.id, item.title),
                          );
                        },
                      ),
                    ),
                  ] else
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Il piano apparirà qui.')),
                    ),
                ],
              ),
            ),
            _PlanComposer(controller: _composer, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _TripHero extends StatelessWidget {
  const _TripHero({required this.trip, required this.videos});

  final Trip trip;
  final List<String> videos;

  @override
  Widget build(BuildContext context) {
    final destination = trip.destination!;
    return SizedBox(
      height: 236,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            JourneyVideoSequence(
              assets: videos,
              borderRadius: BorderRadius.zero,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColoredBox(
                color: context.iterColors.videoScrim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.journey?.stops.join('  →  ') ?? destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _HeroFact(
                            icon: _transportIcon(trip.transportOption?.kind),
                            label:
                                trip.transportOption?.company ??
                                'Arrivo libero',
                          ),
                          _HeroFact(
                            icon: Icons.bed_outlined,
                            label: trip.stayZone?.name ?? 'Base libera',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _PlanChangeNotice extends StatelessWidget {
  const _PlanChangeNotice({required this.message, this.onUndo});

  final AiMessage message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.auto_awesome, color: colors.onSecondaryContainer),
        title: Text(
          message.planChange!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onUndo == null
            ? null
            : IconButton(
                tooltip: 'Annulla modifica',
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
              ),
      ),
    );
  }
}

class _VisualTimelineItem extends StatelessWidget {
  const _VisualTimelineItem({
    super.key,
    required this.item,
    required this.imageAsset,
    required this.isLast,
    required this.onToggleLock,
    required this.onRemove,
  });

  final ItineraryItem item;
  final String imageAsset;
  final bool isLast;
  final VoidCallback onToggleLock;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 30,
                    bottom: 0,
                    child: Container(width: 2, color: colors.outlineVariant),
                  ),
                Positioned(
                  top: 14,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.isLocked ? colors.secondary : colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 34,
                  child: Text(
                    item.startTime,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imageAsset,
                      width: 92,
                      height: 104,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (item.isLocked)
                              Icon(
                                Icons.lock,
                                size: 16,
                                color: colors.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.category} · ${item.durationMinutes} min',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_ItemAction>(
                    tooltip: 'Azioni per ${item.title}',
                    onSelected: (action) => switch (action) {
                      _ItemAction.lock => onToggleLock(),
                      _ItemAction.remove => onRemove(),
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ItemAction.lock,
                        child: Text(item.isLocked ? 'Sblocca' : 'Blocca'),
                      ),
                      const PopupMenuItem(
                        value: _ItemAction.remove,
                        child: Text('Rimuovi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ItemAction { lock, remove }

class _PlanComposer extends StatelessWidget {
  const _PlanComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.auto_awesome),
                    hintText: 'Cambia il piano…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Applica al piano',
                onPressed: onSend,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _transportIcon(TransportKind? kind) => switch (kind) {
  TransportKind.flight => Icons.flight_takeoff,
  TransportKind.train => Icons.train,
  TransportKind.bus => Icons.directions_bus,
  TransportKind.car => Icons.directions_car,
  null => Icons.route,
};

extension on Iterable<AiMessage> {
  AiMessage? get lastPlanChange {
    for (final message in toList().reversed) {
      if (message.planChange != null) return message;
    }
    return null;
  }
}
