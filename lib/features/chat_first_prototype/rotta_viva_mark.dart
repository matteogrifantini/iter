import 'package:flutter/material.dart';

enum RottaVivaRouteState { empty, planning, active }

/// The small route cue used by Rotta viva: a waypoint, continuous route and
/// direction arrow. It is intentionally supplementary to familiar Material
/// icons, never a replacement for an action icon.
class RottaVivaMark extends StatelessWidget {
  const RottaVivaMark({super.key, this.size = const Size(76, 34)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Iter, la rotta che prende forma',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: _RottaVivaPainter(
              route: colors.primary,
              signal: colors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// State-bound Home trace. The route reveals its current extent without
/// inventing a loading state; reduced motion paints the final extent at once.
class RottaVivaRouteTrace extends StatelessWidget {
  const RottaVivaRouteTrace({super.key, required this.state});

  final RottaVivaRouteState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final label = switch (state) {
      RottaVivaRouteState.empty =>
        'Rotta vuota, pronta a raccogliere un desiderio',
      RottaVivaRouteState.planning =>
        'Rotta in pianificazione, una scelta alla volta',
      RottaVivaRouteState.active => 'Rotta attiva, piano di oggi',
    };
    final progress = switch (state) {
      RottaVivaRouteState.empty => .28,
      RottaVivaRouteState.planning => .66,
      RottaVivaRouteState.active => 1.0,
    };
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 104,
          height: 42,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              painter: _RottaVivaTracePainter(
                route: colors.primary,
                signal: colors.tertiary,
                progress: value,
                showArrow: state == RottaVivaRouteState.active,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RottaVivaTracePainter extends CustomPainter {
  const _RottaVivaTracePainter({
    required this.route,
    required this.signal,
    required this.progress,
    required this.showArrow,
  });

  final Color route;
  final Color signal;
  final double progress;
  final bool showArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(10, size.height * .65)
      ..cubicTo(
        size.width * .30,
        3,
        size.width * .60,
        size.height,
        size.width * .82,
        size.height * .42,
      );
    final paint = Paint()
      ..color = route
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isNotEmpty) {
      canvas.drawPath(
        metrics.single.extractPath(0, metrics.single.length * progress),
        paint,
      );
    }
    canvas.drawCircle(const Offset(10, 27), 5, Paint()..color = route);
    if (progress >= .66) {
      canvas.drawCircle(
        Offset(size.width * .58, size.height * .66),
        4,
        Paint()..color = signal,
      );
    }
    if (showArrow && progress >= .99) {
      final arrow = Path()
        ..moveTo(size.width * .78, size.height * .43)
        ..lineTo(size.width * .92, size.height * .25)
        ..lineTo(size.width * .88, size.height * .54);
      canvas.drawPath(arrow, paint..color = signal);
    }
  }

  @override
  bool shouldRepaint(covariant _RottaVivaTracePainter oldDelegate) =>
      oldDelegate.route != route ||
      oldDelegate.signal != signal ||
      oldDelegate.progress != progress ||
      oldDelegate.showArrow != showArrow;
}

class _RottaVivaPainter extends CustomPainter {
  const _RottaVivaPainter({required this.route, required this.signal});

  final Color route;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = route
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final point = Offset(size.width * .13, size.height * .54);
    final routePath = Path()
      ..moveTo(point.dx + 6, point.dy)
      ..cubicTo(
        size.width * .36,
        size.height * .06,
        size.width * .55,
        size.height * .92,
        size.width * .78,
        size.height * .45,
      );
    canvas.drawPath(routePath, stroke);
    canvas.drawCircle(point, 5, Paint()..color = route);

    final tip = Offset(size.width * .9, size.height * .3);
    final arrow = Path()
      ..moveTo(size.width * .73, size.height * .45)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(size.width * .84, size.height * .62);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = signal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RottaVivaPainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.signal != signal;
}
