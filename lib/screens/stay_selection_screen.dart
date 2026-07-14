import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';

class StaySelectionScreen extends StatefulWidget {
  const StaySelectionScreen({
    super.key,
    required this.destination,
    required this.journeyTitle,
    required this.destinationNames,
    required this.zones,
    required this.savedPlaces,
    required this.onSelect,
    required this.onOpenHotelSearch,
  });

  final Destination destination;
  final String? journeyTitle;
  final Map<String, String> destinationNames;
  final List<StayZone> zones;
  final List<Place> savedPlaces;
  final ValueChanged<StayZone> onSelect;
  final ValueChanged<Uri> onOpenHotelSearch;

  @override
  State<StaySelectionScreen> createState() => _StaySelectionScreenState();
}

class _StaySelectionScreenState extends State<StaySelectionScreen> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.journeyTitle ?? widget.destination.name),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PlanningProgress(currentStep: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dove vuoi svegliarti?',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prima scegli la base. La stanza viene dopo.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.zones.isEmpty
                        ? '—'
                        : '${_page + 1} / ${widget.zones.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.zones.isEmpty
                  ? const Center(child: Text('Nessuna zona disponibile.'))
                  : PageView.builder(
                      controller: PageController(viewportFraction: .92),
                      itemCount: widget.zones.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (context, index) {
                        final zone = widget.zones[index];
                        final city =
                            widget.destinationNames[zone.destinationId] ??
                            widget.destination.name;
                        final nearbyPlaces = widget.savedPlaces
                            .where(
                              (place) =>
                                  place.destinationId == zone.destinationId,
                            )
                            .length;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 12, 16),
                          child: _StayZonePage(
                            zone: zone,
                            city: city,
                            nearbyPlaces: nearbyPlaces,
                            active: index == _page,
                            onSelect: () => widget.onSelect(zone),
                            onOpenHotelSearch: () =>
                                widget.onOpenHotelSearch(zone.hotelSearchUrl),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Gli alloggi si aprono fuori da Iter. Prezzi e disponibilità non sono verificati nel prototipo.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StayZonePage extends StatelessWidget {
  const _StayZonePage({
    required this.zone,
    required this.city,
    required this.nearbyPlaces,
    required this.active,
    required this.onSelect,
    required this.onOpenHotelSearch,
  });

  final StayZone zone;
  final String city;
  final int nearbyPlaces;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onOpenHotelSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 500;
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
                flex: compact ? 3 : 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _ZoneMapPainter(
                        route: colors.primary,
                        signal: colors.secondary,
                        background: colors.surfaceContainer,
                        line: colors.outlineVariant,
                        active: active,
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: colors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            zone.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: compact ? 8 : 6,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.summary,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ZoneFact(
                              icon: Icons.directions_walk,
                              value: '~${zone.averageWalkMinutes} min',
                              label: 'spostamento medio',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ZoneFact(
                              icon: Icons.bookmark_outline,
                              value: '$nearbyPlaces luoghi',
                              label: 'già scelti qui',
                            ),
                          ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 14),
                        Text(
                          zone.whyItFits,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onOpenHotelSearch,
                              child: const Text('Vedi alloggi'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: onSelect,
                              child: const Text('Scegli base'),
                            ),
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
      },
    );
  }
}

class _ZoneFact extends StatelessWidget {
  const _ZoneFact({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.labelLarge),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoneMapPainter extends CustomPainter {
  const _ZoneMapPainter({
    required this.route,
    required this.signal,
    required this.background,
    required this.line,
    required this.active,
  });

  final Color route;
  final Color signal;
  final Color background;
  final Color line;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final streetPaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var index = 0; index < 5; index++) {
      final y = size.height * (.16 + index * .16);
      canvas.drawLine(
        Offset(-12, y),
        Offset(size.width + 12, y - 22),
        streetPaint,
      );
    }
    final path = Path()
      ..moveTo(size.width * .08, size.height * .62)
      ..cubicTo(
        size.width * .28,
        size.height * .12,
        size.width * .57,
        size.height * .82,
        size.width * .92,
        size.height * .28,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 4 : 3
        ..strokeCap = StrokeCap.round,
    );
    for (final point in <Offset>[
      Offset(size.width * .18, size.height * .45),
      Offset(size.width * .48, size.height * .52),
      Offset(size.width * .78, size.height * .36),
    ]) {
      canvas.drawCircle(point, 7, Paint()..color = signal);
      canvas.drawCircle(point, 3, Paint()..color = background);
    }
  }

  @override
  bool shouldRepaint(covariant _ZoneMapPainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.signal != signal ||
        oldDelegate.background != background ||
        oldDelegate.line != line ||
        oldDelegate.active != active;
  }
}
