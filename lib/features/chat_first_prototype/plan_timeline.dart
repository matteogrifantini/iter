import 'package:flutter/material.dart';

import 'chat_first_models.dart';
import 'plan_patch_sheet.dart';

enum PlanTimelineAction { move, changeTime, toggleLock, remove }

class PlanTimeline extends StatelessWidget {
  const PlanTimeline({
    super.key,
    required this.day,
    required this.mediaForItem,
    required this.onOpenPlace,
    this.canOpenPlace,
    this.onDragStarted,
    this.onDragEnded,
    this.onAction,
  });

  final TripDaySnapshot day;
  final PlanMedia? Function(TripItemSnapshot item) mediaForItem;
  final void Function(TripItemSnapshot item, int index) onOpenPlace;
  final bool Function(TripItemSnapshot item)? canOpenPlace;
  final ValueChanged<String>? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(TripItemSnapshot item, PlanTimelineAction action)?
  onAction;

  @override
  Widget build(BuildContext context) {
    final items = day.items;
    return Semantics(
      container: true,
      label: '${day.label}, ${day.theme}',
      child: Column(
        key: const Key('plan-timeline'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(day.theme, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _TimelineEmptyState()
          else
            for (var index = 0; index < items.length; index++)
              _TimelineStop(
                item: items[index],
                index: index,
                isLast: index == items.length - 1,
                imageAsset: mediaForItem(items[index])?.imageUrl,
                onTap:
                    !(canOpenPlace?.call(items[index]) ??
                        items[index].place != null)
                    ? null
                    : () => onOpenPlace(items[index], index),
                onDragStarted: onDragStarted,
                onDragEnded: onDragEnded,
                onAction: onAction,
              ),
        ],
      ),
    );
  }
}

class PlanDragDestinations extends StatelessWidget {
  const PlanDragDestinations({
    super.key,
    required this.snapshot,
    required this.itemId,
    required this.onAccept,
  });

  final TripSnapshot snapshot;
  final String itemId;
  final ValueChanged<PlanMoveTarget> onAccept;

  @override
  Widget build(BuildContext context) {
    final targets = buildPlanMoveTargets(
      snapshot: snapshot,
      movingItemId: itemId,
    );
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('plan-drag-destinations'),
      elevation: 6,
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 288),
        child: Semantics(
          container: true,
          label: 'Destinazioni disponibili per lo spostamento',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Dove vuoi spostarla?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  key: const Key('plan-drag-targets-scroll'),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    return DragTarget<String>(
                      key: Key('plan-drag-target-${target.keyId}'),
                      onWillAcceptWithDetails: (details) =>
                          details.data == itemId,
                      onAcceptWithDetails: (_) => onAccept(target),
                      builder: (context, candidates, _) => Material(
                        color: candidates.isEmpty
                            ? colors.surfaceContainerHigh
                            : colors.primaryContainer,
                        child: ListTile(
                          minTileHeight: 48,
                          leading: const Icon(Icons.subdirectory_arrow_right),
                          title: Text(target.label),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanUnplacedItems extends StatelessWidget {
  const PlanUnplacedItems({
    super.key,
    required this.items,
    required this.canMove,
    required this.onAction,
  });

  final List<TripItemSnapshot> items;
  final bool canMove;
  final void Function(TripItemSnapshot item, PlanTimelineAction action)
  onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('plan-unplaced-section'),
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                header: true,
                child: Text(
                  'Da sistemare',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final item in items)
              ListTile(
                key: Key('plan-unplaced-${item.id}'),
                contentPadding: const EdgeInsets.only(left: 4),
                minTileHeight: 56,
                title: Text(item.title),
                subtitle: Text(item.category),
                trailing: PopupMenuButton<PlanTimelineAction>(
                  key: Key('plan-unplaced-menu-${item.id}'),
                  tooltip: 'Azioni per ${item.title}',
                  onSelected: (action) => onAction(item, action),
                  itemBuilder: (_) => <PopupMenuEntry<PlanTimelineAction>>[
                    if (canMove)
                      const PopupMenuItem(
                        value: PlanTimelineAction.move,
                        child: Text('Sposta'),
                      ),
                    const PopupMenuItem(
                      value: PlanTimelineAction.remove,
                      child: Text('Rimuovi'),
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

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Giornata vuota',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Le tappe da collocare compariranno qui.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TimelineStop extends StatelessWidget {
  const _TimelineStop({
    required this.item,
    required this.index,
    required this.isLast,
    required this.imageAsset,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAction,
  });

  final TripItemSnapshot item;
  final int index;
  final bool isLast;
  final String? imageAsset;
  final VoidCallback? onTap;
  final ValueChanged<String>? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(TripItemSnapshot item, PlanTimelineAction action)?
  onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = _durationLabel(item.durationMinutes);
    final locked = item.locked ? ', tappa bloccata' : '';
    return Semantics(
      button: onTap != null,
      label:
          '${item.startTime}, ${item.title}, ${item.category}, $duration$locked',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 34,
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  if (!isLast)
                    Positioned(
                      top: 18,
                      bottom: 0,
                      child: Container(width: 2, color: colors.primary),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.locked
                          ? colors.secondaryContainer
                          : colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.locked
                            ? colors.onSecondaryContainer
                            : colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                color: colors.surface,
                child: InkWell(
                  key: Key('plan-item-${item.id.isEmpty ? index : item.id}'),
                  onTap: onTap,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 104),
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _StopImage(
                          imageAsset: imageAsset,
                          semanticsLabel: 'Foto di ${item.title}',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 0,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      item.startTime,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (item.locked)
                                      Icon(
                                        Icons.lock_outline,
                                        size: 17,
                                        color: colors.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.category} · $duration',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (onAction != null || onDragStarted != null)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (onDragStarted != null)
                                Semantics(
                                  label: 'Trascina ${item.title} per spostarla',
                                  button: true,
                                  child: LongPressDraggable<String>(
                                    data: item.id,
                                    onDragStarted: () =>
                                        onDragStarted?.call(item.id),
                                    onDragEnd: (_) => onDragEnded?.call(),
                                    feedback: Material(
                                      key: Key('plan-drag-feedback-${item.id}'),
                                      color: colors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Text(item.title),
                                      ),
                                    ),
                                    child: IconButton(
                                      key: Key('plan-drag-${item.id}'),
                                      onPressed: () => onAction?.call(
                                        item,
                                        PlanTimelineAction.move,
                                      ),
                                      icon: const Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ),
                              if (onAction != null)
                                PopupMenuButton<PlanTimelineAction>(
                                  key: Key('plan-menu-${item.id}'),
                                  tooltip: 'Altre azioni per ${item.title}',
                                  onSelected: (action) =>
                                      onAction?.call(item, action),
                                  itemBuilder: (_) =>
                                      <PopupMenuEntry<PlanTimelineAction>>[
                                        const PopupMenuItem(
                                          value: PlanTimelineAction.move,
                                          child: Text('Sposta'),
                                        ),
                                        const PopupMenuItem(
                                          value: PlanTimelineAction.changeTime,
                                          child: Text('Cambia orario'),
                                        ),
                                        PopupMenuItem(
                                          value: PlanTimelineAction.toggleLock,
                                          child: Text(
                                            item.locked ? 'Sblocca' : 'Blocca',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: PlanTimelineAction.remove,
                                          child: Text('Rimuovi'),
                                        ),
                                      ],
                                ),
                            ],
                          )
                        else if (onTap != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Icon(
                              Icons.chevron_right,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
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

class _StopImage extends StatelessWidget {
  const _StopImage({required this.imageAsset, required this.semanticsLabel});

  final String? imageAsset;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = imageAsset;
    final hasImage = asset != null && asset.isNotEmpty;
    return Semantics(
      image: true,
      label: hasImage
          ? semanticsLabel
          : semanticsLabel.replaceFirst(
              'Foto di',
              'Immagine non disponibile per',
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          height: 84,
          child: !hasImage
              ? ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.place_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                )
              : ExcludeSemantics(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.place_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

String _durationLabel(int minutes) {
  if (minutes <= 0) return 'durata da definire';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$remaining min';
  if (remaining == 0) return '$hours h';
  return '$hours h $remaining min';
}
