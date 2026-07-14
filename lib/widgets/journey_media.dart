import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/iter_theme.dart';

class JourneyVideo extends StatefulWidget {
  const JourneyVideo({
    super.key,
    required this.asset,
    this.autoplay = true,
    this.showControl = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String asset;
  final bool autoplay;
  final bool showControl;
  final BorderRadius borderRadius;

  @override
  State<JourneyVideo> createState() => _JourneyVideoState();
}

class _JourneyVideoState extends State<JourneyVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _userStartedPlayback = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant JourneyVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _userStartedPlayback = false;
      _initialize();
      return;
    }
    if (widget.autoplay && !oldWidget.autoplay) {
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reducedMotion) _controller?.play();
    } else if (!widget.autoplay && oldWidget.autoplay) {
      _userStartedPlayback = false;
      _controller?.pause();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(widget.asset);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      final reducedMotion = mounted
          ? MediaQuery.maybeOf(context)?.disableAnimations ?? false
          : false;
      if (widget.autoplay && !reducedMotion) await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      _failed = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        _userStartedPlayback = false;
        controller.pause();
      } else {
        _userStartedPlayback = true;
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (ready &&
        reducedMotion &&
        !_userStartedPlayback &&
        controller.value.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.pause());
    }
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            CustomPaint(
              painter: _VideoFallbackPainter(
                background: context.iterColors.raised,
                route: context.iterColors.route,
                signal: context.iterColors.routeSignal,
              ),
              child: Center(
                child: _failed
                    ? const Icon(Icons.landscape_outlined, size: 36)
                    : const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),
          if (ready && widget.showControl)
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filledTonal(
                tooltip: controller.value.isPlaying
                    ? 'Metti in pausa il video'
                    : 'Riproduci il video',
                onPressed: _togglePlayback,
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class JourneyRouteLine extends StatelessWidget {
  const JourneyRouteLine({
    super.key,
    required this.progress,
    this.horizontal = false,
  });

  final double progress;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Percorso di scoperta',
      value: '${(progress.clamp(0, 1) * 100).round()} per cento',
      child: CustomPaint(
        painter: _RouteLinePainter(
          progress: progress.clamp(0, 1),
          route: context.iterColors.route,
          signal: context.iterColors.routeSignal,
          inactive: Theme.of(context).colorScheme.outlineVariant,
          horizontal: horizontal,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({
    required this.progress,
    required this.route,
    required this.signal,
    required this.inactive,
    required this.horizontal,
  });

  final double progress;
  final Color route;
  final Color signal;
  final Color inactive;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (horizontal) {
      path
        ..moveTo(8, size.height * .58)
        ..cubicTo(
          size.width * .3,
          0,
          size.width * .55,
          size.height,
          size.width - 8,
          size.height * .42,
        );
    } else {
      path
        ..moveTo(size.width * .55, 8)
        ..cubicTo(
          0,
          size.height * .28,
          size.width,
          size.height * .57,
          size.width * .42,
          size.height - 8,
        );
    }
    final backgroundPaint = Paint()
      ..color = inactive
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, backgroundPaint);

    final metrics = path.computeMetrics().first;
    final activePath = metrics.extractPath(0, metrics.length * progress);
    final activePaint = Paint()
      ..color = route
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, activePaint);

    final tangent = metrics.getTangentForOffset(metrics.length * progress);
    if (tangent != null) {
      canvas.drawCircle(tangent.position, 8, Paint()..color = signal);
      canvas.drawCircle(
        tangent.position,
        13,
        Paint()
          ..color = signal.withValues(alpha: .22)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.route != route ||
        oldDelegate.signal != signal ||
        oldDelegate.horizontal != horizontal;
  }
}

class _VideoFallbackPainter extends CustomPainter {
  const _VideoFallbackPainter({
    required this.background,
    required this.route,
    required this.signal,
  });

  final Color background;
  final Color route;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final path = Path()
      ..moveTo(-12, size.height * .75)
      ..cubicTo(
        size.width * .28,
        size.height * .2,
        size.width * .58,
        size.height,
        size.width + 12,
        size.height * .32,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      Offset(size.width * .66, size.height * .62),
      10,
      Paint()..color = signal,
    );
  }

  @override
  bool shouldRepaint(covariant _VideoFallbackPainter oldDelegate) => false;
}
