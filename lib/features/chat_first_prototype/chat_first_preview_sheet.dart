import 'package:flutter/material.dart';

import '../../models/trip_models.dart' show JourneyRoute;
import '../../widgets/journey_media.dart';
import 'chat_first_data.dart' show journeyCity;
import 'chat_first_models.dart' show DestinationPoint;

/// Editorial city sheet on Iter's warm surface: small media up top, the facts
/// and the AI why on the plain background, and one clear call to organise the
/// trip with Iter instead of just talking about it.
class ChatPreviewSheet extends StatelessWidget {
  const ChatPreviewSheet({
    super.key,
    required this.journey,
    required this.onStartChat,
    this.pois,
  });

  final JourneyRoute journey;
  final VoidCallback onStartChat;

  /// The must-see points for the destination. When null (or empty) the sheet
  /// shows no "Da non perdere" section at all.
  final Future<List<DestinationPoint>>? pois;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final city = journeyCity(journey);
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.86,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                children: <Widget>[
                  _MediaStrip(destinationId: journey.destinationIds.first),
                  const SizedBox(height: 18),
                  Container(
                    width: 30,
                    height: 3,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    city,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${journey.stops.join(' · ')} · ${journey.durationLabel}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    journey.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.route_outlined,
                            size: 20, color: colors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Perché sceglierla',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                journey.whyItFits,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetaChip(
                        emoji: '🕒',
                        label: journey.durationLabel,
                      ),
                      _MetaChip(
                        emoji: _modeEmoji(journey.travelMode),
                        label: journey.travelMode,
                      ),
                      _MetaChip(
                        emoji: _seasonEmoji(journey.season),
                        label: journey.season,
                      ),
                    ],
                  ),
                  if (pois != null) ...<Widget>[
                    const SizedBox(height: 24),
                    _PoisSection(pois: pois!),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onStartChat,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Organizza un viaggio'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                    child: const Text('Solo ispirazione, per ora'),
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

String _modeEmoji(String mode) {
  final text = mode.toLowerCase();
  if (text.contains('treno')) return '🚆';
  if (text.contains('aereo') || text.contains('volo')) return '✈️';
  if (text.contains('a piedi')) return '🚶';
  if (text.contains('bici')) return '🚲';
  if (text.contains('metro')) return '🚇';
  if (text.contains('auto') || text.contains('macchina')) return '🚗';
  if (text.contains('traghetto') || text.contains('mare')) return '⛴️';
  return '🧭';
}

String _seasonEmoji(String season) {
  final text = season.toLowerCase();
  if (text.contains('primavera')) return '🌸';
  if (text.contains('estate') || text.contains('giugno')) return '☀️';
  if (text.contains('autunno') ||
      text.contains('settembre') ||
      text.contains('novembre') ||
      text.contains('ottobre')) {
    return '🍂';
  }
  if (text.contains('inverno')) return '❄️';
  return '✨';
}

/// Small media tiles on top: the city clip followed by its posters, so the
/// destination is felt without covering the facts below.
class _MediaStrip extends StatelessWidget {
  const _MediaStrip({required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context) {
    final videos = DemoMedia.forDestination(destinationId);
    final posters = DemoMedia.postersForDestination(destinationId);
    final media = <Widget>[
      for (final asset in videos)
        _MediaTile(child: JourneyVideoSequence(
          assets: <String>[asset],
          showControl: true,
          showProgress: false,
          borderRadius: BorderRadius.circular(16),
        )),
      for (final poster in posters.take(2))
        _MediaTile(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(poster, fit: BoxFit.cover),
          ),
        ),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => media[index],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 168, height: 118, child: child);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Da non perdere" block: the destination's points resolved through the
/// data source. Renders nothing while loading or when the list is empty, so a
/// sparse catalogue never breaks the sheet.
class _PoisSection extends StatelessWidget {
  const _PoisSection({required this.pois});

  final Future<List<DestinationPoint>> pois;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DestinationPoint>>(
      future: pois,
      builder: (context, snapshot) {
        final points = snapshot.data ?? const <DestinationPoint>[];
        if (points.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Da non perdere',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final point in points) _PoiRow(point: point),
          ],
        );
      },
    );
  }
}

class _PoiRow extends StatelessWidget {
  const _PoiRow({required this.point});

  final DestinationPoint point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(point.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  point.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (point.category.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    point.category,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (point.whyFits.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    point.whyFits,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
