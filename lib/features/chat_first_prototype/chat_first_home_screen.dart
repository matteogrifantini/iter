import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/iter_theme.dart';
import 'adaptive_home_model.dart';
import 'chat_first_data.dart';
import 'rotta_viva_home_sections.dart';

import 'rotta_viva_mark.dart';

/// Rotta viva is the dynamic, adaptive Home: it welcomes the traveler with inspiration,
/// a prominent trip planning system, and adaptive sections for active itineraries.
class ChatFirstHomeScreen extends StatefulWidget {
  const ChatFirstHomeScreen({
    super.key,
    required this.model,
    required this.unread,
    required this.onSubmitIntent,
    required this.onVoiceIntent,
    required this.onPhotoIntent,
    required this.onOpenThread,
    required this.onOpenTrips,
    this.onStartAnotherJourney,
  });

  final AdaptiveHomeModel model;
  final int unread;
  final FutureOr<void> Function(String) onSubmitIntent;
  final VoidCallback onVoiceIntent;
  final ValueChanged<String> onPhotoIntent;
  final ValueChanged<ChatThread> onOpenThread;
  final VoidCallback onOpenTrips;
  final Future<void> Function()? onStartAnotherJourney;

  @override
  State<ChatFirstHomeScreen> createState() => _ChatFirstHomeScreenState();
}

class _ChatFirstHomeScreenState extends State<ChatFirstHomeScreen> {
  final _composer = TextEditingController();
  final _selectedClues = <String>{};
  var _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _toggleSeed(({String label, String clue, String semantics}) seed) {
    setState(() {
      if (_selectedClues.remove(seed.clue)) {
        _composer.text = _removeClue(_composer.text, seed.clue);
      } else {
        _selectedClues.add(seed.clue);
        _composer.text = _appendClue(_composer.text, seed.clue);
      }
      _composer.selection = TextSelection.collapsed(
        offset: _composer.text.length,
      );
    });
  }

  String _appendClue(String current, String clue) {
    final trimmed = current.trim();
    if (trimmed.isEmpty) return clue;
    return '$trimmed · $clue';
  }

  String _removeClue(String current, String clue) {
    return current
        .split(' · ')
        .where((part) => part.trim() != clue)
        .join(' · ')
        .trim();
  }

  Future<void> _submit() async {
    final intent = _composer.text.trim();
    if (intent.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await Future<void>.sync(() => widget.onSubmitIntent(intent));
      if (!mounted) return;
      setState(() {
        _composer.clear();
        _selectedClues.clear();
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Non riesco a iniziare il viaggio. Riprova.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final side = width <= 320 ? 16.0 : 24.0;
    final colors = Theme.of(context).colorScheme;
    final isActive = widget.model.kind == AdaptiveHomeKind.active;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isActive ? 0 : side,
          16,
          isActive ? 0 : side,
          112,
        ),
        children: <Widget>[
          if (isActive)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: const _HomeTopBar(),
            )
          else
            const _HomeTopBar(),
          const SizedBox(height: 16),

          if (widget.model.kind == AdaptiveHomeKind.empty) ...<Widget>[
            // 1. HERO TITLE & CONVERSATIONAL COMPOSER
            Text(
              'Dove vorresti andare?',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Scrivi una città, un’idea o descrivi il tipo di esperienza che cerchi.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            RottaVivaComposer(
              key: const Key('home-composer'),
              controller: _composer,
              onChanged: (_) => setState(() {}),
              onSubmit: _submit,
              onVoice: widget.onVoiceIntent,
              onPhoto: () => showDemoPhotoPicker(
                context,
                onSelected: widget.onPhotoIntent,
              ),
            ),
            if (_submitError != null) ...<Widget>[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _submitError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.error),
                ),
              ),
              TextButton(
                onPressed: _submitting ? null : _submit,
                child: const Text('Riprova'),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Puoi partire da qui',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RottaVivaSeedRow(
              selectedClues: _selectedClues,
              onToggle: _toggleSeed,
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: const RottaVivaRouteTrace(
                state: RottaVivaRouteState.empty,
              ),
            ),
          ] else if (widget.model.kind ==
              AdaptiveHomeKind.planning) ...<Widget>[
            Builder(
              builder: (context) {
                final thread = widget.model.thread!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AdaptivePlanningSection(
                      thread: thread,
                      onOpenThread: widget.onOpenThread,
                      onStartAnotherJourney: widget.onStartAnotherJourney,
                    ),
                    if (thread.summary.snapshot == null) ...<Widget>[
                      const SizedBox(height: 28),
                      Text(
                        'Continua da qui',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      RottaVivaComposer(
                        key: const Key('home-composer'),
                        controller: _composer,
                        onChanged: (_) => setState(() {}),
                        onSubmit: _submit,
                        onVoice: widget.onVoiceIntent,
                        onPhoto: () => showDemoPhotoPicker(
                          context,
                          onSelected: widget.onPhotoIntent,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: const RottaVivaRouteTrace(
                state: RottaVivaRouteState.planning,
              ),
            ),
          ] else ...<Widget>[
            ActiveDestinationStage(
              thread: widget.model.thread!,
              onOpenThread: widget.onOpenThread,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 28, side, 0),
              child: ActiveTimelineSection(
                thread: widget.model.thread!,
                onOpenThread: widget.onOpenThread,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 24, side, 0),
              child: Text(
                'Hai un cambio?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 12, side, 0),
              child: RottaVivaComposer(
                key: const Key('home-composer'),
                controller: _composer,
                onChanged: (_) => setState(() {}),
                onSubmit: _submit,
                onVoice: widget.onVoiceIntent,
                onPhoto: () => showDemoPhotoPicker(
                  context,
                  onSelected: widget.onPhotoIntent,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: const RottaVivaRouteTrace(
                state: RottaVivaRouteState.active,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('home-top-bar'),
      children: <Widget>[
        Text('iter', style: IterTheme.wordmarkTextStyle),
        const SizedBox(width: 12),
        const RottaVivaMark(size: Size(54, 26)),
        const Spacer(),
      ],
    );
  }
}
