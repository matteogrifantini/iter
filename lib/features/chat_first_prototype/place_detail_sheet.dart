import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'chat_first_models.dart';

enum PlaceDetailAction { askIter }

class PlanPlaceSheetData {
  const PlanPlaceSheetData({
    required this.place,
    required this.category,
    required this.neighborhood,
    required this.durationLabel,
    required this.costLabel,
    required this.bestMomentLabel,
    required this.whyIterRecommends,
    required this.positionLabel,
    required this.distanceLabel,
    required this.entranceLabel,
    required this.accessibilityLabel,
    required this.media,
    required this.directionsAvailable,
  });

  final PlanPlaceDetails place;
  final String category;
  final String neighborhood;
  final String durationLabel;
  final String costLabel;
  final String bestMomentLabel;
  final String whyIterRecommends;
  final String positionLabel;
  final String distanceLabel;
  final String entranceLabel;
  final String accessibilityLabel;
  final PlanMedia? media;
  final bool directionsAvailable;
}

Future<PlaceDetailAction?> showPlanPlaceDetailSheet({
  required BuildContext context,
  required PlanPlaceSheetData data,
  required VoidCallback onOpenReel,
  required Future<void> Function() onOpenDirections,
}) {
  final scaledBody = MediaQuery.textScalerOf(context).scale(16);
  final largeText = scaledBody >= 24;
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<PlaceDetailAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: reducedMotion ? AnimationStyle.noAnimation : null,
    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: largeText ? 0.92 : 0.75,
      minChildSize: largeText ? 0.72 : 0.48,
      maxChildSize: 0.96,
      snap: !reducedMotion,
      snapSizes: largeText
          ? const <double>[0.92, 0.96]
          : const <double>[0.75, 0.96],
      builder: (context, scrollController) => _PlaceDetailSheetBody(
        data: data,
        scrollController: scrollController,
        onOpenReel: onOpenReel,
        onOpenDirections: onOpenDirections,
      ),
    ),
  );
}

class _PlaceDetailSheetBody extends StatelessWidget {
  const _PlaceDetailSheetBody({
    required this.data,
    required this.scrollController,
    required this.onOpenReel,
    required this.onOpenDirections,
  });

  final PlanPlaceSheetData data;
  final ScrollController scrollController;
  final VoidCallback onOpenReel;
  final Future<void> Function() onOpenDirections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              key: const Key('place-sheet-scroll'),
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: <Widget>[
                _PlacePhoto(
                  placeTitle: data.place.title,
                  media: data.media,
                  onOpenReel: onOpenReel,
                ),
                const SizedBox(height: 20),
                Focus(
                  key: const Key('place-sheet-title-focus'),
                  autofocus: true,
                  child: Semantics(
                    header: true,
                    sortKey: const OrdinalSortKey(1),
                    child: Text(
                      data.place.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.category} · ${data.neighborhood}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SignalChip(label: '⏱ ${data.durationLabel}'),
                    _SignalChip(label: '💶 ${data.costLabel}'),
                    _SignalChip(label: '☀️ ${data.bestMomentLabel}'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Perché Iter te la consiglia',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.whyIterRecommends,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  data.place.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: data.directionsAvailable
                          ? () => onOpenDirections()
                          : null,
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Indicazioni'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(PlaceDetailAction.askIter),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Chiedi a Iter'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
                if (!data.directionsAvailable) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Coordinate non disponibili per questa tappa.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Informazioni pratiche',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _PracticalRow(icon: '📍', label: data.positionLabel),
                _PracticalRow(icon: '🚶', label: data.distanceLabel),
                _PracticalRow(icon: '🎟', label: data.entranceLabel),
                _PracticalRow(icon: '♿', label: data.accessibilityLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({
    required this.placeTitle,
    required this.media,
    required this.onOpenReel,
  });

  final String placeTitle;
  final PlanMedia? media;
  final VoidCallback onOpenReel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = media?.imageUrl;
    final reel = media?.reelUrl;
    return Semantics(
      image: true,
      label: 'Foto di $placeTitle',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (image == null || image.isEmpty)
                ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.photo_outlined,
                    size: 54,
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                ExcludeSemantics(
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.photo_outlined,
                        size: 54,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              if (reel != null && reel.isNotEmpty)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenReel,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Vedi reel'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _PracticalRow extends StatelessWidget {
  const _PracticalRow({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$icon $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
