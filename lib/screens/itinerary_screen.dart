import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';

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

  void _send([String? preset]) {
    final text = (preset ?? _composer.text).trim();
    if (text.isEmpty) return;
    widget.onSendAiMessage(text);
    _composer.clear();
  }

  void _remove(String itemId, String title) {
    final removed = widget.onRemoveItem(itemId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? '$title rimosso dal piano.'
              : '$title è bloccato: sbloccalo prima di rimuoverlo.',
        ),
      ),
    );
  }

  void _undo() {
    if (!widget.onUndoAiChange()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ultima modifica annullata.')));
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Il tuo viaggio'),
        actions: [
          TextButton.icon(
            onPressed: days.isEmpty ? null : widget.onFinish,
            icon: const Icon(Icons.check),
            label: const Text('Salva'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(currentStep: 3),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          trip.title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trip.journey?.stops.join('  →  ') ??
                              '${destination.name}, ${destination.country}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        _TripFoundation(trip: trip),
                        if (lastChange != null) ...[
                          const SizedBox(height: 14),
                          _PlanChangeNotice(
                            message: lastChange,
                            onUndo: widget.canUndoAiChange ? _undo : null,
                          ),
                        ],
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Giorno per giorno',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Text(
                              '${days.length} ${days.length == 1 ? 'giorno' : 'giorni'}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  if (days.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          day.theme,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList.builder(
                        itemCount: day.items.length,
                        itemBuilder: (context, index) {
                          final item = day.items[index];
                          return AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: _TimelineItem(
                              key: ValueKey(item.id),
                              item: item,
                              isLast: index == day.items.length - 1,
                              onToggleLock: () => widget.onToggleLock(item.id),
                              onRemove: () => _remove(item.id, item.title),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Il primo giorno apparirà qui appena scegli una base.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
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

class _TripFoundation extends StatelessWidget {
  const _TripFoundation({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final transport = trip.transportOption;
    final stay = trip.stayZone;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            minTileHeight: 74,
            leading: Icon(
              transport?.kind == TransportKind.train
                  ? Icons.train_outlined
                  : Icons.flight_outlined,
              color: colors.primary,
            ),
            title: Text(transport?.title ?? 'Arrivo da definire'),
            subtitle: Text(
              transport == null
                  ? 'Aggiungi un volo o un treno.'
                  : '${transport.durationLabel} · ${transport.changesLabel}',
            ),
          ),
          Divider(height: 1, indent: 56, color: colors.outlineVariant),
          ListTile(
            minTileHeight: 74,
            leading: Icon(Icons.bed_outlined, color: colors.primary),
            title: Text(stay?.name ?? 'Base da definire'),
            subtitle: Text(
              stay == null
                  ? 'Scegli dove svegliarti.'
                  : '~${stay.averageWalkMinutes} min a piedi dalle tappe',
            ),
          ),
        ],
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: colors.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.planChange!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (onUndo != null)
              IconButton(
                tooltip: 'Annulla ultima modifica',
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                color: colors.onSecondaryContainer,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    super.key,
    required this.item,
    required this.isLast,
    required this.onToggleLock,
    required this.onRemove,
  });

  final ItineraryItem item;
  final bool isLast;
  final VoidCallback onToggleLock;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 51,
              top: 39,
              bottom: 0,
              child: Container(width: 2, color: colors.outlineVariant),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 43,
                        child: Text(
                          item.startTime,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: item.isLocked
                              ? colors.secondary
                              : colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                  decoration: isLast
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colors.outlineVariant),
                          ),
                        ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (item.isLocked)
                                  Icon(
                                    Icons.lock,
                                    size: 17,
                                    color: colors.secondary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.category} · ${item.durationMinutes} min',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colors.primary),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              item.note,
                              style: Theme.of(context).textTheme.bodyMedium
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
                            child: Text(
                              item.isLocked ? 'Sblocca tappa' : 'Blocca tappa',
                            ),
                          ),
                          const PopupMenuItem(
                            value: _ItemAction.remove,
                            child: Text('Togli dal giorno'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
  final void Function([String? preset]) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ActionChip(
                      label: const Text('Rallenta il pomeriggio'),
                      onPressed: () => onSend('Rallenta il pomeriggio'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Aggiungi una cena'),
                      onPressed: () => onSend('Aggiungi una cena speciale'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Più arte'),
                      onPressed: () => onSend('Vorrei più arte'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
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
                        hintText: 'Chiedi a Iter di cambiare il piano',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Applica al piano',
                    onPressed: () => onSend(),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Iterable<AiMessage> {
  AiMessage? get lastPlanChange {
    for (final message in toList().reversed) {
      if (message.planChange != null) return message;
    }
    return null;
  }
}
