import 'package:flutter/material.dart';
import '../../ai/gemini_models.dart';

class AnimatedRouteMapCard extends StatefulWidget {
  const AnimatedRouteMapCard({
    super.key,
    required this.destination,
    required this.day,
  });

  final String destination;
  final DailyPlanDraft day;

  @override
  State<AnimatedRouteMapCard> createState() => _AnimatedRouteMapCardState();
}

class _AnimatedRouteMapCardState extends State<AnimatedRouteMapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stops = widget.day.stops;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Mappa
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🗺️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotta Viva · Giorno ${widget.day.dayNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.day.theme,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.replay_rounded, size: 20),
                tooltip: 'Rianima rotta',
                onPressed: () {
                  _animController.reset();
                  _animController.forward();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Canvas Grafico della Rotta Animata
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 140,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RoutePainter(
                      progress: _animController.value,
                      stopsCount: stops.length,
                      lineColor: colorScheme.primary,
                      dotColor: colorScheme.onPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sequenza oraria e tappe ad incastro
          ...stops.asMap().entries.map((entry) {
            final idx = entry.key;
            final stop = entry.value;
            final isLast = idx == stops.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Dettagli Tappa
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            idx == 0
                                ? 'Mattina · Partenza a piedi'
                                : (isLast ? 'Golden hour & tramonto' : 'Pomeriggio · Tappa intermedia'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Pausa cibo autentica
          if (widget.day.diningRecommendation != null && widget.day.diningRecommendation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🍷', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pausa Gastronomica tipica',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          widget.day.diningRecommendation!,
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],

          // Stima km a piedi
          Row(
            children: [
              Icon(Icons.directions_walk_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '~${(stops.length * 1.3).toStringAsFixed(1)} km a piedi complessivi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Ritmo a misura d\'uomo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.progress,
    required this.stopsCount,
    required this.lineColor,
    required this.dotColor,
  });

  final double progress;
  final int stopsCount;
  final Color lineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (stopsCount < 2) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (stopsCount + 1);
    final points = <Offset>[];

    for (int i = 0; i < stopsCount; i++) {
      final x = stepX * (i + 1);
      final y = (i % 2 == 0) ? size.height * 0.35 : size.height * 0.65;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Draw animated portion
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paintLine);

      // Draw waypoints
      final activeCount = (stopsCount * progress).ceil();
      for (int i = 0; i < points.length; i++) {
        if (i < activeCount) {
          final pt = points[i];
          final dotPaint = Paint()..color = lineColor;
          canvas.drawCircle(pt, 7, dotPaint);

          final innerDotPaint = Paint()..color = dotColor;
          canvas.drawCircle(pt, 3.5, innerDotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
