import 'package:flutter/material.dart';

import '../../app/iter_theme.dart';
import 'adaptive_home_model.dart';
import 'chat_first_data.dart';
import 'rotta_viva_home_sections.dart';
import 'rotta_viva_mark.dart';

/// Rotta viva is one adaptive, vertical Home: it starts with a human wish,
/// resumes one unresolved plan, or grounds the traveller in today's route.
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
  });

  final AdaptiveHomeModel model;
  final int unread;
  final ValueChanged<String> onSubmitIntent;
  final VoidCallback onVoiceIntent;
  final ValueChanged<String> onPhotoIntent;
  final ValueChanged<ChatThread> onOpenThread;
  final VoidCallback onOpenTrips;

  @override
  State<ChatFirstHomeScreen> createState() => _ChatFirstHomeScreenState();
}

class _ChatFirstHomeScreenState extends State<ChatFirstHomeScreen> {
  final _composer = TextEditingController();
  final _selectedClues = <String>{};

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

  void _submit() {
    final intent = _composer.text.trim();
    if (intent.isEmpty) return;
    try {
      widget.onSubmitIntent(intent);
      setState(() {
        _composer.clear();
        _selectedClues.clear();
      });
    } catch (_) {
      // The typed intent is preserved so the person can retry after a failed
      // synchronous hand-off to navigation or the demo controller.
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final side = width <= 320 ? 16.0 : 24.0;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(side, 20, side, 112),
        children: <Widget>[
          _HomeTopBar(unread: widget.unread, onOpenTrips: widget.onOpenTrips),
          const SizedBox(height: 32),
          if (widget.model.kind == AdaptiveHomeKind.empty) ...<Widget>[
            Text(
              'Dimmi che viaggio hai in mente',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Raccontami il momento. Alla destinazione penso io.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            RottaVivaComposer(
              controller: _composer,
              onChanged: (_) => setState(() {}),
              onSubmit: _submit,
              onVoice: widget.onVoiceIntent,
              onPhoto: () => showDemoPhotoPicker(
                context,
                onSelected: widget.onPhotoIntent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Puoi partire da qui',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RottaVivaSeedRow(
              selectedClues: _selectedClues,
              onToggle: _toggleSeed,
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: RottaVivaMark(),
            ),
          ] else if (widget.model.kind ==
              AdaptiveHomeKind.planning) ...<Widget>[
            AdaptivePlanningSection(
              thread: widget.model.thread!,
              onOpenThread: widget.onOpenThread,
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: RottaVivaMark(),
            ),
          ] else ...<Widget>[
            ActiveTimelineSection(
              thread: widget.model.thread!,
              onOpenThread: widget.onOpenThread,
            ),
            const SizedBox(height: 24),
            Text(
              'Hai un cambio?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RottaVivaComposer(
              controller: _composer,
              onChanged: (_) => setState(() {}),
              onSubmit: _submit,
              onVoice: widget.onVoiceIntent,
              onPhoto: () => showDemoPhotoPicker(
                context,
                onSelected: widget.onPhotoIntent,
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: RottaVivaMark(),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.unread, required this.onOpenTrips});

  final int unread;
  final VoidCallback onOpenTrips;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Text('iter', style: IterTheme.wordmarkTextStyle),
        const SizedBox(width: 12),
        const RottaVivaMark(size: Size(54, 26)),
        const Spacer(),
        Semantics(
          label: unread > 0 ? 'Viaggi, $unread messaggi non letti' : 'Viaggi',
          button: true,
          child: IconButton(
            tooltip: 'Viaggi',
            onPressed: onOpenTrips,
            icon: unread > 0
                ? Badge.count(
                    count: unread,
                    backgroundColor: colors.primary,
                    textColor: colors.onPrimary,
                    child: const Icon(Icons.forum_outlined),
                  )
                : const Icon(Icons.forum_outlined),
          ),
        ),
      ],
    );
  }
}
