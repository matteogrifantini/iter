import 'package:flutter/material.dart';

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
