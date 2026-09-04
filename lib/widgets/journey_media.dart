import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/iter_theme.dart';

abstract final class DemoMedia {
  static const _byDestination = <String, List<String>>{
    'porto': <String>['assets/videos/vertical/porto_sequence.mp4'],
    'lisbona': <String>['assets/videos/vertical/lisbon_sequence.mp4'],
    'roma': <String>['assets/videos/vertical/rome_sequence.mp4'],
    'parigi': <String>['assets/videos/vertical/paris_sequence.mp4'],
    'barcellona': <String>['assets/videos/vertical/barcelona_sequence.mp4'],
  };

  static List<String> forDestination(String id) =>
      _byDestination[id] ??
      const <String>['assets/videos/vertical/rail_sequence.mp4'];

  static List<String> postersForDestination(String id) => switch (id) {
    'porto' => const <String>[
      'assets/images/travel/porto_river.jpg',
      'assets/images/travel/porto_rooftops.jpg',
    ],
    'lisbona' => const <String>[
      'assets/images/travel/lisbon_street.jpg',
      'assets/images/travel/lisbon_evening.jpg',
    ],
    'roma' => const <String>[
      'assets/images/travel/rome_city.jpg',
      'assets/images/travel/rome_vespa.jpg',
    ],
    'parigi' => const <String>[
      'assets/images/travel/paris_eiffel.jpg',
      'assets/images/travel/paris_cloudy.jpg',
    ],
    'barcellona' => const <String>[
      'assets/images/travel/barcelona_street.jpg',
      'assets/images/travel/barcelona_square.jpg',
    ],
    _ => const <String>[
      'assets/images/travel/rail_coast.jpg',
      'assets/images/travel/rail_window.jpg',
    ],
  };
}

class JourneyVideoSequence extends StatefulWidget {
  const JourneyVideoSequence({
    super.key,
    required this.assets,
    this.active = true,
    this.showControl = true,
    this.showProgress = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  }) : assert(assets.length > 0);

  final List<String> assets;
  final bool active;
  final bool showControl;
  final bool showProgress;
  final BorderRadius borderRadius;

  @override
  State<JourneyVideoSequence> createState() => _JourneyVideoSequenceState();
}

class _JourneyVideoSequenceState extends State<JourneyVideoSequence> {
  Timer? _timer;
  var _index = 0;
  var _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTimer());
  }

  @override
  void didUpdateWidget(covariant JourneyVideoSequence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assets != widget.assets) _index = 0;
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.active ||
        _paused ||
        reducedMotion ||
        widget.assets.length < 2) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.assets.length);
    });
  }

  void _toggle() {
    setState(() => _paused = !_paused);
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final playing = widget.active && !_paused && !reducedMotion;
    final asset = widget.assets[_index];
    final poster = _posterFor(asset);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: widget.active
                ? JourneyVideo(
                    key: ValueKey('video-$asset'),
                    asset: asset,
                    placeholderAsset: poster,
                    autoplay: playing,
                    showControl: false,
                    borderRadius: BorderRadius.zero,
                  )
                : poster != null
                ? Image.asset(
                    poster,
                    key: ValueKey('poster-$asset'),
                    fit: BoxFit.cover,
                  )
                : JourneyVideo(
                    key: ValueKey('inactive-$asset'),
                    asset: asset,
                    autoplay: false,
                    showControl: false,
                    borderRadius: BorderRadius.zero,
                  ),
          ),
          if (widget.showProgress)
            Positioned(
              left: 10,
              right: 10,
              top: 10,
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < widget.assets.length;
                    index++
                  ) ...[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: index <= _index
                              ? Colors.white
                              : Colors.white.withValues(alpha: .38),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (index != widget.assets.length - 1)
                      const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          if (widget.showControl)
            Positioned(
              right: 10,
              top: 20,
              child: IconButton.filledTonal(
                tooltip: playing ? 'Metti in pausa' : 'Riproduci i video',
                onPressed: _toggle,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
            ),
        ],
      ),
    );
  }

  String? _posterFor(String asset) {
    const prefix = 'assets/videos/vertical/';
    if (!asset.startsWith(prefix) || !asset.endsWith('.mp4')) return null;
    final name = asset.substring(prefix.length, asset.length - 4);
    return 'assets/images/travel/$name.jpg';
  }
}

class JourneyVideo extends StatefulWidget {
  const JourneyVideo({
    super.key,
    required this.asset,
    this.placeholderAsset,
    this.autoplay = true,
    this.showControl = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String asset;
  final String? placeholderAsset;
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
            IgnorePointer(
              ignoring: !widget.showControl,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          else if (widget.placeholderAsset != null)
            Image.asset(widget.placeholderAsset!, fit: BoxFit.cover)
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
