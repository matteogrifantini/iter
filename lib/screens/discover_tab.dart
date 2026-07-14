import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scopri',
                      style: Theme.of(context).textTheme.headlineLarge,
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
            controller: PageController(viewportFraction: .88),
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: widget.journeys.length,
            itemBuilder: (context, index) {
              final journey = widget.journeys[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
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
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          JourneyVideoSequence(
            assets: journey.videoAssets,
            active: active,
            borderRadius: BorderRadius.zero,
          ),
          Positioned(
            right: 10,
            top: 74,
            child: IconButton.filledTonal(
              tooltip: 'Informazioni su ${journey.title}',
              onPressed: () => _showInfo(context),
              icon: const Icon(Icons.info_outline),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: const Color(0xB8000000),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${journey.durationLabel} · ${journey.stops.join(' → ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onStart,
                        child: const Text('Scegli'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.title,
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(journey.summary),
              const SizedBox(height: 12),
              Text(
                journey.stops.join('  →  '),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(journey.whyItFits),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onStart();
                  },
                  child: const Text('Inizia da qui'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
