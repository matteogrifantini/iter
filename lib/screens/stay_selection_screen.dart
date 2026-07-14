import 'dart:math' as math;

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
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (widget.zones.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Nessuna zona disponibile.')),
      );
    }
    if (_selectedIndex >= widget.zones.length) _selectedIndex = 0;
    final selected = widget.zones[_selectedIndex];
    final city =
        widget.destinationNames[selected.destinationId] ??
        widget.destination.name;
    final cityZones = widget.zones
        .where((zone) => zone.destinationId == selected.destinationId)
        .toList(growable: false);
    final cityPlaces = widget.savedPlaces
        .where((place) => place.destinationId == selected.destinationId)
        .toList(growable: false);
    final selectedCityIndex = cityZones.indexWhere(
      (zone) => zone.id == selected.id,
    );
    final zoneColors = _zoneColors(colors, cityZones.length);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Dove dormire'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(
              currentStep: 2,
              padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _NeighborhoodMapPainter(
                          background: colors.surfaceContainer,
                          street: colors.outlineVariant,
                          river: colors.primaryContainer,
                          zoneColors: zoneColors,
                          zoneNames: cityZones
                              .map((zone) => zone.name)
                              .toList(),
                          selectedZone: selectedCityIndex,
                          placeCount: cityPlaces.length,
                          pin: colors.onSurface,
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: colors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$city · ${cityPlaces.length} luoghi',
                                  style: Theme.of(context).textTheme.labelLarge,
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
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.zones.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final zone = widget.zones[index];
                  final zoneCity =
                      widget.destinationNames[zone.destinationId] ??
                      widget.destination.name;
                  return ChoiceChip(
                    label: Text('${zone.name} · $zoneCity'),
                    selected: index == _selectedIndex,
                    onSelected: (_) => setState(() => _selectedIndex = index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _ZoneSummary(
                zone: selected,
                city: city,
                placeCount: cityPlaces.length,
                onSelect: () => widget.onSelect(selected),
                onOpenHotelSearch: () =>
                    widget.onOpenHotelSearch(selected.hotelSearchUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneSummary extends StatelessWidget {
  const _ZoneSummary({
    required this.zone,
    required this.city,
    required this.placeCount,
    required this.onSelect,
    required this.onOpenHotelSearch,
  });

  final StayZone zone;
  final String city;
  final int placeCount;
  final VoidCallback onSelect;
  final VoidCallback onOpenHotelSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                zone.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '~${zone.averageWalkMinutes} min a piedi',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          zone.summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Cerca alloggi a $city',
              onPressed: onOpenHotelSearch,
              icon: const Icon(Icons.open_in_new),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onSelect,
                child: Text('Scegli ${zone.name}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

List<Color> _zoneColors(ColorScheme colors, int count) {
  final candidates = <Color>[colors.primary, colors.secondary, colors.tertiary];
  return List<Color>.generate(
    count,
    (index) => candidates[index % candidates.length],
  );
}

class _NeighborhoodMapPainter extends CustomPainter {
  const _NeighborhoodMapPainter({
    required this.background,
    required this.street,
    required this.river,
    required this.zoneColors,
    required this.zoneNames,
    required this.selectedZone,
    required this.placeCount,
    required this.pin,
  });

  final Color background;
  final Color street;
  final Color river;
  final List<Color> zoneColors;
  final List<String> zoneNames;
  final int selectedZone;
  final int placeCount;
  final Color pin;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final streetPaint = Paint()
      ..color = street
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var index = 0; index < 8; index++) {
      final y = size.height * (.1 + index * .12);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y - 34),
        streetPaint,
      );
    }
    for (var index = 0; index < 6; index++) {
      final x = size.width * (.08 + index * .18);
      canvas.drawLine(
        Offset(x, -10),
        Offset(x + 50, size.height + 10),
        streetPaint,
      );
    }

    final riverPath = Path()
      ..moveTo(-10, size.height * .72)
      ..cubicTo(
        size.width * .28,
        size.height * .55,
        size.width * .58,
        size.height * .96,
        size.width + 10,
        size.height * .68,
      );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = river
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );

    final zoneRects = <Rect>[
      Rect.fromLTWH(
        size.width * .08,
        size.height * .18,
        size.width * .38,
        size.height * .31,
      ),
      Rect.fromLTWH(
        size.width * .45,
        size.height * .11,
        size.width * .43,
        size.height * .34,
      ),
      Rect.fromLTWH(
        size.width * .28,
        size.height * .46,
        size.width * .45,
        size.height * .29,
      ),
    ];
    for (var index = 0; index < zoneNames.length; index++) {
      final rect = zoneRects[index % zoneRects.length];
      final color = zoneColors[index];
      final selected = index == selectedZone;
      final path = Path()
        ..moveTo(rect.left + rect.width * .08, rect.top + rect.height * .22)
        ..lineTo(rect.left + rect.width * .72, rect.top)
        ..lineTo(rect.right, rect.top + rect.height * .58)
        ..lineTo(rect.left + rect.width * .58, rect.bottom)
        ..lineTo(rect.left, rect.top + rect.height * .74)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: selected ? .36 : .19),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 1.5,
      );
      final text = TextPainter(
        text: TextSpan(
          text: zoneNames[index],
          style: TextStyle(
            color: pin,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: rect.width * .82);
      text.paint(
        canvas,
        Offset(rect.left + rect.width * .1, rect.center.dy - text.height / 2),
      );
    }

    final shownPlaces = math.min(math.max(placeCount, 1), 6);
    const points = <Offset>[
      Offset(.22, .36),
      Offset(.59, .26),
      Offset(.48, .58),
      Offset(.76, .52),
      Offset(.34, .68),
      Offset(.67, .41),
    ];
    for (var index = 0; index < shownPlaces; index++) {
      final point = Offset(
        size.width * points[index].dx,
        size.height * points[index].dy,
      );
      canvas.drawCircle(point, 9, Paint()..color = background);
      canvas.drawCircle(point, 6, Paint()..color = pin);
      canvas.drawCircle(point, 2, Paint()..color = background);
    }
  }

  @override
  bool shouldRepaint(covariant _NeighborhoodMapPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.street != street ||
      oldDelegate.selectedZone != selectedZone ||
      oldDelegate.placeCount != placeCount ||
      oldDelegate.zoneNames != zoneNames;
}
