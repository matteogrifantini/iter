import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'chat_first_models.dart';

typedef PlanReelControllerFactory =
    PlanReelPlaybackController Function(String asset);

abstract class PlanReelPlaybackController extends ChangeNotifier {
  bool get isInitialized;
  bool get isPlaying;
  bool get isMuted;
  bool get hasError;

  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> setMuted(bool value);
  Future<void> setLooping(bool value);
  Widget buildVideo(BuildContext context);
}

class VideoPlayerReelPlaybackController extends PlanReelPlaybackController {
  VideoPlayerReelPlaybackController(String asset)
    : _controller = VideoPlayerController.asset(asset) {
    _controller.addListener(notifyListeners);
  }

  final VideoPlayerController _controller;

  @override
  bool get hasError => _controller.value.hasError;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isMuted => _controller.value.volume == 0;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  Widget buildVideo(BuildContext context) => VideoPlayer(_controller);

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> setLooping(bool value) => _controller.setLooping(value);

  @override
  Future<void> setMuted(bool value) => _controller.setVolume(value ? 0 : 1);

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}

class PlaceReelScreen extends StatefulWidget {
  const PlaceReelScreen({
    super.key,
    required this.placeTitle,
    required this.media,
    this.controllerFactory = _defaultControllerFactory,
  });

  final String placeTitle;
  final PlanMedia media;
  final PlanReelControllerFactory controllerFactory;

  static PlanReelPlaybackController _defaultControllerFactory(String asset) =>
      VideoPlayerReelPlaybackController(asset);

  @override
  State<PlaceReelScreen> createState() => _PlaceReelScreenState();
}

class _PlaceReelScreenState extends State<PlaceReelScreen> {
  PlanReelPlaybackController? _playback;
  var _initializationStarted = false;
  var _initializationFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializationStarted) return;
    _initializationStarted = true;
    final reel = widget.media.reelUrl;
    if (reel == null || reel.isEmpty) return;
    _playback = widget.controllerFactory(reel);
    _playback!.addListener(_handlePlaybackChanged);
    _initializePlayback();
  }

  void _handlePlaybackChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initializePlayback() async {
    final playback = _playback;
    if (playback == null) return;
    try {
      await playback.setMuted(true);
      await playback.initialize();
      if (!mounted || playback != _playback) return;
      final reducedMotion = MediaQuery.disableAnimationsOf(context);
      await playback.setLooping(!reducedMotion);
      if (!mounted || playback != _playback) return;
      if (!reducedMotion) await playback.play();
      if (!mounted || playback != _playback) return;
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _initializationFailed = true);
    }
  }

  @override
  void dispose() {
    _playback?.removeListener(_handlePlaybackChanged);
    _playback?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final playback = _playback;
    final videoReady =
        playback != null &&
        playback.isInitialized &&
        !playback.hasError &&
        !_initializationFailed;
    return Scaffold(
      backgroundColor: colors.inverseSurface,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (videoReady)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: 1080,
                height: 1920,
                child: playback.buildVideo(context),
              ),
            )
          else
            _ReelPhotoFallback(
              imageAsset: widget.media.imageUrl,
              showError: _initializationFailed || playback?.hasError == true,
              placeTitle: widget.placeTitle,
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filledTonal(
                  tooltip: 'Chiudi reel',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Material(
                  color: colors.inverseSurface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.placeTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: colors.onInverseSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _sourceLabel(widget.media),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colors.onInverseSurface.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: playback?.isPlaying == true
                              ? 'Pausa'
                              : 'Riprendi',
                          onPressed: videoReady
                              ? () async {
                                  if (playback.isPlaying) {
                                    await playback.pause();
                                  } else {
                                    await playback.play();
                                  }
                                }
                              : null,
                          color: colors.onInverseSurface,
                          icon: Icon(
                            playback?.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                        IconButton(
                          tooltip: playback?.isMuted != false
                              ? 'Attiva audio'
                              : 'Disattiva audio',
                          onPressed: videoReady
                              ? () async {
                                  await playback.setMuted(!playback.isMuted);
                                }
                              : null,
                          color: colors.onInverseSurface,
                          icon: Icon(
                            playback?.isMuted != false
                                ? Icons.volume_off_outlined
                                : Icons.volume_up_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPhotoFallback extends StatelessWidget {
  const _ReelPhotoFallback({
    required this.imageAsset,
    required this.showError,
    required this.placeTitle,
  });

  final String? imageAsset;
  final bool showError;
  final String placeTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = imageAsset;
    return Semantics(
      image: true,
      label: 'Foto di $placeTitle',
      child: Stack(
        key: const Key('place-reel-photo-fallback'),
        fit: StackFit.expand,
        children: <Widget>[
          if (asset != null && asset.isNotEmpty)
            ExcludeSemantics(
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.photo_outlined,
                    size: 64,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ColoredBox(
              color: colors.surfaceContainerHighest,
              child: Icon(
                Icons.photo_outlined,
                size: 64,
                color: colors.onSurfaceVariant,
              ),
            ),
          if (showError)
            Center(
              child: Material(
                color: colors.inverseSurface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    'Video non disponibile',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _sourceLabel(PlanMedia media) {
  final attribution = media.reelAttribution ?? media.photoAttribution;
  if (attribution == null || attribution.author.isEmpty) {
    return 'Fonte non disponibile';
  }
  return 'Fonte: ${attribution.author}';
}
