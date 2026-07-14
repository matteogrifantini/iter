import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';

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
        title: Text(journeyTitle ?? destination.name),
        actions: [
          TextButton(
            onPressed: _savedCount > 0 ? onContinue : null,
            child: const Text('Avanti'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(currentStep: 0),
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
                        savedCount: _savedCount,
                        seenCount: seenCount,
                        totalSuggestions: totalSuggestions,
                        onSwipe: (direction) => onReact(
                          current,
                          direction < 0
                              ? PlaceReaction.skip
                              : PlaceReaction.save,
                        ),
                      ),
              ),
            ),
            if (current != null)
              _DecisionDock(
                onSkip: () => onReact(current, PlaceReaction.skip),
                onSave: () => onReact(current, PlaceReaction.save),
                onMustSee: () => onReact(current, PlaceReaction.mustSee),
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
    required this.savedCount,
    required this.seenCount,
    required this.totalSuggestions,
    required this.onSwipe,
  });

  final Place place;
  final String city;
  final int savedCount;
  final int seenCount;
  final int totalSuggestions;
  final ValueChanged<double> onSwipe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 260) onSwipe(velocity);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Segui il tuo istinto.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Text(
                '$savedCount tenuti',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Proposta ${seenCount + 1} di $totalSuggestions · puoi cambiare tutto più avanti.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  color: colors.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(place.category), color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$city · ${place.neighborhood}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 38),
                      Text(
                        place.name,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: place.matchScore / 100,
                                minHeight: 6,
                                color: colors.secondary,
                                backgroundColor: colors.outlineVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${place.matchScore}% nelle tue corde',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.whyItFits,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _Fact(
                              icon: Icons.schedule_outlined,
                              label: '${place.durationMinutes} min',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _Fact(
                              icon: Icons.light_mode_outlined,
                              label: place.bestMoment,
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
          const SizedBox(height: 14),
          Text(
            'Scorri a sinistra per passare, a destra per salvare.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String category) => switch (category) {
    'Cibo' || 'Mercato' || 'Degustazione' => Icons.restaurant_outlined,
    'Arte' || 'Cultura' => Icons.museum_outlined,
    'Mare' || 'Verde' || 'Panorama' => Icons.landscape_outlined,
    'Musica' || 'Serata' => Icons.music_note_outlined,
    _ => Icons.place_outlined,
  };
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _DecisionDock extends StatelessWidget {
  const _DecisionDock({
    required this.onSkip,
    required this.onSave,
    required this.onMustSee,
  });

  final VoidCallback onSkip;
  final VoidCallback onSave;
  final VoidCallback onMustSee;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: _ReactionAction(
                  icon: Icons.close,
                  label: 'Passa',
                  onTap: onSkip,
                  background: colors.surface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReactionAction(
                  icon: Icons.bookmark_outline,
                  label: 'Salva',
                  onTap: onSave,
                  background: colors.primaryContainer,
                  foreground: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReactionAction(
                  icon: Icons.favorite_outline,
                  label: 'Irrinunciabile',
                  onTap: onMustSee,
                  background: colors.secondaryContainer,
                  foreground: colors.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionAction extends StatelessWidget {
  const _ReactionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final contentColor = foreground ?? colors.onSurface;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 70),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: contentColor),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.bookmarks_outlined, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              '$savedCount luoghi hanno trovato spazio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              savedCount == 0
                  ? 'Torna indietro e tieni almeno una proposta.'
                  : 'Ora scegliamo come far cominciare davvero il viaggio.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Scegli come arrivare'),
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
