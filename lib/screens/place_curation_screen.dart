import 'package:flutter/material.dart';

import '../app/iter_theme.dart';
import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';
import '../widgets/journey_media.dart';

class PlaceCurationScreen extends StatelessWidget {
  const PlaceCurationScreen({
    super.key,
    required this.destination,
    this.journeyTitle,
    required this.destinationNames,
    required this.places,
    required this.totalSuggestions,
    required this.reactions,
    required this.onReact,
    required this.onContinue,
  });

  final Destination destination;
  final String? journeyTitle;
  final Map<String, String> destinationNames;
  final List<Place> places;
  final int totalSuggestions;
  final Map<String, PlaceReaction> reactions;
  final void Function(Place place, PlaceReaction reaction) onReact;
  final VoidCallback onContinue;

  int get _savedCount => reactions.values
      .where((reaction) => reaction != PlaceReaction.skip)
      .length;

  @override
  Widget build(BuildContext context) {
    final current = places.firstOrNull;
    final seenCount = totalSuggestions - places.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Scegli i luoghi'),
        actions: [
          Center(
            child: Text(
              '${seenCount.clamp(0, totalSuggestions)} / $totalSuggestions',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(
              currentStep: 0,
              padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: const Cubic(0.16, 1, 0.3, 1),
                child: current == null
                    ? _FinishedCuration(
                        key: const ValueKey('places-finished'),
                        savedCount: _savedCount,
                        onContinue: _savedCount > 0 ? onContinue : null,
                      )
                    : _PlaceDecision(
                        key: ValueKey(current.id),
                        place: current,
                        city:
                            destinationNames[current.destinationId] ??
                            destination.name,
                        onReact: (reaction) => onReact(current, reaction),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceDecision extends StatelessWidget {
  const _PlaceDecision({
    super.key,
    required this.place,
    required this.city,
    required this.onReact,
  });

  final Place place;
  final String city;
  final ValueChanged<PlaceReaction> onReact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() <= 260) return;
        onReact(velocity < 0 ? PlaceReaction.skip : PlaceReaction.save);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              JourneyVideoSequence(
                assets: DemoMedia.forDestination(place.destinationId),
                borderRadius: BorderRadius.zero,
              ),
              Positioned(
                left: 12,
                top: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.iterColors.videoScrim,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    child: Text(
                      '${place.matchScore}% per te',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 84,
                bottom: 150,
                child: Align(
                  alignment: Alignment.center,
                  child: _ActionRail(
                    place: place,
                    city: city,
                    onSkip: () => onReact(PlaceReaction.skip),
                    onSave: () => onReact(PlaceReaction.save),
                    onMustSee: () => onReact(PlaceReaction.mustSee),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: context.iterColors.videoScrim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 76, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$city · ${place.neighborhood}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${place.durationMinutes} min  ·  ${place.bestMoment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
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

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.place,
    required this.city,
    required this.onSkip,
    required this.onSave,
    required this.onMustSee,
  });

  final Place place;
  final String city;
  final VoidCallback onSkip;
  final VoidCallback onSave;
  final VoidCallback onMustSee;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReelAction(
          icon: Icons.info_outline,
          label: 'Info',
          onTap: () => _showPlaceInfo(context),
        ),
        const SizedBox(height: 10),
        _ReelAction(icon: Icons.close, label: 'Passa', onTap: onSkip),
        const SizedBox(height: 10),
        _ReelAction(
          icon: Icons.bookmark_outline,
          label: 'Salva',
          onTap: onSave,
        ),
        const SizedBox(height: 10),
        _ReelAction(
          icon: Icons.favorite_outline,
          label: 'Must',
          onTap: onMustSee,
        ),
      ],
    );
  }

  void _showPlaceInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '$city · ${place.neighborhood}',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Text(place.whyItFits),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(place.category)),
                  Chip(label: Text('${place.durationMinutes} min')),
                  Chip(label: Text(place.bestMoment)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onSave();
                  },
                  icon: const Icon(Icons.bookmark_outline),
                  label: const Text('Salva'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelAction extends StatelessWidget {
  const _ReelAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            tooltip: label,
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: context.iterColors.videoScrim,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(icon),
          ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedCuration extends StatelessWidget {
  const _FinishedCuration({
    super.key,
    required this.savedCount,
    required this.onContinue,
  });

  final int savedCount;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmarks, size: 42, color: colors.primary),
            const SizedBox(height: 18),
            Text(
              '$savedCount luoghi scelti',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Come arrivare'),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
