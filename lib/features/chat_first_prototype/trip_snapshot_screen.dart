import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chat_first_models.dart';

/// Read-only editorial trip view bound to a conversation. The prototype never
/// edits a snapshot directly: every change goes through the chat, and this
/// screen only mirrors the state shared in the conversation.
class TripSnapshotScreen extends StatelessWidget {
  const TripSnapshotScreen({super.key, required this.snapshot});

  final TripSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mapPlaces = snapshot.placeLabels.isNotEmpty
        ? snapshot.placeLabels
        : snapshot.days
              .expand((d) => d.items)
              .map((i) => i.title)
              .take(4)
              .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Viaggio')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StatusPill(label: snapshot.statusLabel),
              const SizedBox(height: 12),
              Text(
                snapshot.destinationTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${snapshot.country} · ${snapshot.durationLabel}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (mapPlaces.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            _RouteMap(places: mapPlaces),
          ],
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: <Widget>[
                _FactRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: snapshot.dates,
                ),
                const SizedBox(height: 14),
                _FactRow(
                  icon: Icons.directions_outlined,
                  label: 'Come arrivi',
                  value: snapshot.transport,
                ),
                const SizedBox(height: 14),
                _FactRow(
                  icon: Icons.home_outlined,
                  label: 'Dove dormi',
                  value: snapshot.stay,
                ),
              ],
            ),
          ),
          if (snapshot.placeLabels.isNotEmpty) ...<Widget>[
            const SizedBox(height: 26),
            _SectionTitle(title: 'Luoghi salvati'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final label in snapshot.placeLabels)
                  Chip(
                    avatar: Text(
                      placeEmoji(label),
                      style: const TextStyle(fontSize: 16),
                    ),
                    label: Text(label),
                    side: BorderSide(color: colors.outlineVariant),
                    backgroundColor: colors.surface,
                  ),
              ],
            ),
          ],
          if (snapshot.days.isNotEmpty) ...<Widget>[
            const SizedBox(height: 26),
            _SectionTitle(title: 'Giorni'),
            const SizedBox(height: 12),
            for (final day in snapshot.days) _DayCard(day: day),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.chat_outlined,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Modifiche solo tramite chat: apri la conversazione e chiedi a Iter.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Schematic route of the saved places: a dashed line with a node per place,
/// drawn from the demo data only. It reads as a map without any live service.
class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.places});

  final List<String> places;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 176,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _RouteMapPainter(
          places: places,
          line: colors.primary.withValues(alpha: 0.55),
          node: colors.primary,
          label: colors.onSurfaceVariant,
          textScaler: MediaQuery.textScalerOf(context),
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({
    required this.places,
    required this.line,
    required this.node,
    required this.label,
    required this.textScaler,
  });

  final List<String> places;
  final Color line;
  final Color node;
  final Color label;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (places.isEmpty) return;
    final n = places.length;
    const padX = 30.0;
    final midY = size.height * 0.42;

    Offset pos(int i) {
      final x = n == 1
          ? size.width / 2
          : padX + (size.width - padX * 2) * i / (n - 1);
      final y = midY + math.sin(i * 1.05) * (size.height * 0.16);
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = pos(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    const dash = 6.0;
    const gap = 5.0;
    final metric = path.computeMetrics().first;
    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var distance = 0.0;
    while (distance < metric.length) {
      final from = metric.getTangentForOffset(distance)!.position;
      final to = metric
          .getTangentForOffset(math.min(distance + dash, metric.length))!
          .position;
      canvas.drawLine(from, to, linePaint);
      distance += dash + gap;
    }

    for (var i = 0; i < n; i++) {
      final p = pos(i);
      canvas.drawCircle(p, 15, Paint()..color = node.withValues(alpha: 0.16));
      canvas.drawCircle(p, 4.5, Paint()..color = node);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: places[i],
          style: TextStyle(
            fontSize: 13,
            color: label,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        textAlign: TextAlign.center,
      )..layout(maxWidth: (size.width / n) - 8);
      labelPainter.paint(
        canvas,
        Offset(p.dx - labelPainter.width / 2, p.dy + 21),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter old) {
    return old.places != places ||
        old.line != line ||
        old.node != node ||
        old.label != label ||
        old.textScaler != textScaler;
  }
}

/// Small deterministic map from a place label to a travel emoji.
String placeEmoji(String label) {
  final text = label.toLowerCase();
  const keywords = <String, String>{
    'foro': '🏛️',
    'palatino': '🏛️',
    'colosseo': '🏛️',
    'archeolog': '🏛️',
    'fontana': '⛲',
    'piazza': '⛲',
    'navona': '⛲',
    'borghese': '🌳',
    'giardini': '🌳',
    'jardins': '🌳',
    'parco': '🌳',
    'orto': '🌳',
    'tavola': '🍝',
    'mercado': '🍝',
    'bolhão': '🍝',
    'trattoria': '🍝',
    'cucina': '🍝',
    'miradouro': '🌅',
    'panorama': '🌅',
    'belvedere': '🌅',
    'tramonto': '🌅',
    'ribeira': '🏘️',
    'quartiere': '🏘️',
    'borgo': '🏘️',
    'foz': '🌊',
    'mare': '🌊',
    'spiaggia': '🌊',
    'oceano': '🌊',
    'cammino': '🚶',
    'passeggiata': '🚶',
    'museo': '🖼️',
    'galleria': '🖼️',
    'fiume': '🚣',
    'canale': '🚣',
  };
  for (final entry in keywords.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return '📍';
}

/// Small deterministic map from a day-item category to a travel emoji.
String categoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'archeologia':
      return '🏛️';
    case 'cibo':
    case 'tavola':
      return '🍝';
    case 'verde':
    case 'orto':
      return '🌳';
    case 'passeggiata':
    case 'cammino':
      return '🚶';
    case 'panorama':
      return '🌅';
    case 'quartiere':
      return '🏘️';
    case 'mare':
      return '🌊';
    case 'museo':
    case 'galleria':
      return '🖼️';
    default:
      return '✨';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.circle, size: 8, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final TripDaySnapshot day;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: <Widget>[
                Text(
                  day.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      day.theme,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in day.items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      categoryEmoji(item.category),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.time,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: item.locked
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.locked) ...<Widget>[
                    Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: colors.primary,
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