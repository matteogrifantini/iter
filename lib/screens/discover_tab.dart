import 'package:flutter/material.dart';

import '../app/iter_theme.dart';
import '../models/trip_models.dart';
import '../widgets/journey_media.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({
    super.key,
    required this.journeys,
    required this.onStartDiscovery,
    required this.onStartJourney,
  });

  final List<JourneyRoute> journeys;
  final VoidCallback onStartDiscovery;
  final ValueChanged<JourneyRoute> onStartJourney;

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  var _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viaggi che stanno prendendo forma',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Percorsi da usare come scintilla, mai come pacchetti chiusi.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Crea un viaggio su misura',
                onPressed: widget.onStartDiscovery,
                icon: const Icon(Icons.auto_awesome),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            key: const PageStorageKey('journey-reel'),
            controller: PageController(viewportFraction: .91),
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: widget.journeys.length,
            itemBuilder: (context, index) {
              final journey = widget.journeys[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 12, 16),
                child: _TrendJourney(
                  journey: journey,
                  active: index == _currentPage,
                  onStart: () => widget.onStartJourney(journey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendJourney extends StatelessWidget {
  const _TrendJourney({
    required this.journey,
    required this.active,
    required this.onStart,
  });

  final JourneyRoute journey;
  final bool active;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                JourneyVideo(
                  asset: journey.videoAsset,
                  autoplay: active,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.iterColors.videoScrim,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        journey.season,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${journey.durationLabel} · ${journey.travelMode}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    journey.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    journey.stops.join('  →  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: onStart,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Usalo come punto di partenza'),
                    ),
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
