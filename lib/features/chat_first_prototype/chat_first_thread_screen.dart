import 'package:flutter/material.dart';

import '../../widgets/journey_media.dart';
import 'chat_first_controller.dart';
import 'chat_first_models.dart';

class ChatFirstThreadScreen extends StatefulWidget {
  const ChatFirstThreadScreen({
    super.key,
    required this.controller,
    required this.conversationId,
    required this.onOpenSnapshot,
  });

  final ChatFirstPrototypeController controller;
  final String conversationId;
  final ValueChanged<TripSnapshot> onOpenSnapshot;

  @override
  State<ChatFirstThreadScreen> createState() => _ChatFirstThreadScreenState();
}

class _ChatFirstThreadScreenState extends State<ChatFirstThreadScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    widget.controller.sendText(text);
    _jumpToBottom();
  }

  void _sendAudio() {
    widget.controller.sendAudio();
    _jumpToBottom();
  }

  Future<void> _showAttachments() async {
    final picked = await showModalBottomSheet<_PickedAsset>(
      context: context,
      builder: (context) => const _AttachmentPicker(),
    );
    if (picked == null) return;
    widget.controller.sendMedia(asset: picked.asset, isVideo: picked.isVideo);
    _jumpToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final thread = widget.controller.threadOf(widget.conversationId);
        final summary = thread.summary;
        final messages = thread.messages;
        if (messages.length != _lastMessageCount) {
          _lastMessageCount = messages.length;
          _jumpToBottom();
        }
        final reducedMotion = MediaQuery.disableAnimationsOf(context);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: _ThreadTitle(summary: summary),
            actions: [
              if (summary.snapshot != null)
                IconButton(
                  tooltip: 'Apri il piano',
                  onPressed: () => widget.onOpenSnapshot(summary.snapshot!),
                  icon: const Icon(Icons.route_outlined),
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showDayDivider = index == 0 ||
                        messages[index - 1].sentAt.day != message.sentAt.day;
                    return _MessageRow(
                      message: message,
                      showDayDivider: showDayDivider,
                      avatar: summary.avatar,
                      onChoice: (choice) {
                        widget.controller.choose(
                          choice,
                          conversationId: widget.conversationId,
                        );
                        _jumpToBottom();
                      },
                      onAcceptProposal: () {
                        widget.controller.acceptProposal(
                          widget.conversationId,
                          message.id,
                        );
                        _jumpToBottom();
                      },
                      onRejectProposal: () {
                        widget.controller.rejectProposal(
                          widget.conversationId,
                          message.id,
                        );
                        _jumpToBottom();
                      },
                      reducedMotion: reducedMotion,
                    );
                  },
                ),
              ),
              _Composer(
                controller: _composer,
                onSend: _send,
                onSendAudio: _sendAudio,
                onAttach: _showAttachments,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThreadTitle extends StatelessWidget {
  const _ThreadTitle({required this.summary});

  final Conversation summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leading = CircleAvatar(
      radius: 20,
      backgroundImage: AssetImage(summary.avatar.asset),
    );
    return Row(
      children: <Widget>[
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                summary.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary.subtitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.showDayDivider,
    required this.avatar,
    required this.onChoice,
    required this.reducedMotion,
    this.onAcceptProposal,
    this.onRejectProposal,
  });

  final ChatMessage message;
  final bool showDayDivider;
  final ChatAvatar avatar;
  final ValueChanged<ChatChoice> onChoice;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.system) {
      return _SystemDivider(text: message.text);
    }
    final isIncoming = message.isIncoming;
    final align = isIncoming ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    Widget body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(
          crossAxisAlignment: align,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isIncoming)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 22),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundImage: AssetImage(avatar.asset),
                    ),
                  ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: align,
                    children: <Widget>[
                      _Bubble(
                        message: message,
                        onAcceptProposal: onAcceptProposal,
                        onRejectProposal: onRejectProposal,
                      ),
                      if (message.choices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: isIncoming
                                ? WrapAlignment.start
                                : WrapAlignment.end,
                            children: <Widget>[
                              for (final choice in message.choices)
                                ActionChip(
                                  label: Text(choice.label),
                                  onPressed: () => onChoice(choice),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!reducedMotion && isIncoming) {
      body = AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        reverseDuration: Duration.zero,
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(message.id), child: body),
      );
    }

    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        if (showDayDivider)
          _DayDivider(
            label: _dayLabel(message.sentAt),
            reducedMotion: reducedMotion,
          ),
        body,
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    this.onAcceptProposal,
    this.onRejectProposal,
  });

  final ChatMessage message;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isIncoming = message.isIncoming;
    final background = isIncoming
        ? colors.surfaceContainerHighest
        : colors.secondaryContainer;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isIncoming ? 6 : 20),
      bottomRight: Radius.circular(isIncoming ? 20 : 6),
    );
    final content = _MessageContent(
      message: message,
      isIncoming: isIncoming,
      onAcceptProposal: onAcceptProposal,
      onRejectProposal: onRejectProposal,
    );
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          content,
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _timeLabel(message.sentAt),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  color: isIncoming
                      ? colors.onSurfaceVariant
                      : colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.isIncoming,
    this.onAcceptProposal,
    this.onRejectProposal,
  });

  final ChatMessage message;
  final bool isIncoming;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;

  @override
  Widget build(BuildContext context) {
    final textColor = isIncoming
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSecondaryContainer;
    switch (message.kind) {
      case ChatMessageKind.text:
      case ChatMessageKind.choices:
        return Text(
          message.text,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: textColor),
        );
      case ChatMessageKind.media:
        return _MediaContent(message: message);
      case ChatMessageKind.audio:
        return _AudioContent(message: message, isIncoming: isIncoming);
      case ChatMessageKind.tripSummary:
        final summary = message.summary;
        if (summary == null) return const SizedBox.shrink();
        return _SummaryCard(
          snapshot: summary,
          text: message.text,
        );
      case ChatMessageKind.operational:
        return _OperationalContent(message: message, isIncoming: isIncoming);
      case ChatMessageKind.planProposal:
        return _ProposalCard(
          message: message,
          onAccept: onAcceptProposal,
          onReject: onRejectProposal,
        );
      case ChatMessageKind.system:
        return const SizedBox.shrink();
    }
  }
}

class _MediaContent extends StatelessWidget {
  const _MediaContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    if (media == null) return const SizedBox.shrink();
    final size = Size(MediaQuery.sizeOf(context).width * 0.66, 216);
    if (media.isVideo) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: JourneyVideoSequence(
          assets: <String>[media.asset],
          showControl: true,
          showProgress: false,
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        media.asset,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _AudioContent extends StatelessWidget {
  const _AudioContent({required this.message, required this.isIncoming});

  final ChatMessage message;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isIncoming ? colors.primary : colors.onSecondaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Waveform(),
        const SizedBox(height: 4),
        Text(
          message.audioDuration ?? '0:12',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 13,
            color: isIncoming ? null : accent,
          ),
        ),
      ],
    );
  }
}

class Waveform extends StatelessWidget {
  const Waveform({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        for (var index = 0; index < 14; index++)
          Container(
            width: 2,
            height: 5.0 + (index % 5) * 3,
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}

class _OperationalContent extends StatelessWidget {
  const _OperationalContent({required this.message, required this.isIncoming});

  final ChatMessage message;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isIncoming ? colors.primary : colors.onSecondaryContainer;
    final textColor = isIncoming
        ? colors.onSurface
        : colors.onSecondaryContainer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.change_circle_outlined, size: 18, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.snapshot,
    this.text = '',
  });

  final TripSnapshot snapshot;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.route_outlined,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary.destinationTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${summary.durationLabel} · ${summary.statusLabel}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (summary.placeLabels.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                for (final label in summary.placeLabels.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check_circle_outline,
                            size: 15, color: colors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// An in-chat plan proposal: what changes, a preview of the resulting plan and
/// explicit Accetta/Annulla actions. Once settled the actions become a status
/// line and the decision is never re-openable.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.message,
    this.onAccept,
    this.onReject,
  });

  final ChatMessage message;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final proposal = message.proposal;
    if (proposal == null) return const SizedBox.shrink();
    final outcome = proposal.outcome;
    final accepted = outcome == PlanProposalOutcome.accepted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.tune, size: 18, color: colors.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  proposal.changeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SummaryCard(snapshot: proposal.snapshot),
        const SizedBox(height: 12),
        if (outcome == null)
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onAccept,
                  child: const Text('Accetta'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Annulla'),
                ),
              ),
            ],
          )
        else
          Row(
            children: <Widget>[
              Icon(
                accepted
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                size: 18,
                color: accepted ? colors.tertiary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  accepted ? 'Modifica applicata' : 'Modifica annullata',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accepted
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SystemDivider extends StatelessWidget {
  const _SystemDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label, required this.reducedMotion});

  final String label;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onSendAudio,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendAudio;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final hasText = controller.text.isNotEmpty;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: onAttach,
                  tooltip: 'Allegato',
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 26,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Scrivi a Iter…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasText)
                  IconButton.filled(
                    onPressed: onSend,
                    tooltip: 'Invia',
                    icon: const Icon(Icons.arrow_upward),
                  )
                else
                  IconButton(
                    onPressed: onSendAudio,
                    tooltip: 'Registra vocale (demo)',
                    icon: const Icon(Icons.mic_none),
                    iconSize: 26,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _timeLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _dayLabel(DateTime time) {
  const weekdays = <String>[
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica',
  ];
  const months = <String>[
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  final weekday = weekdays[time.weekday - 1];
  return '$weekday ${time.day} ${months[time.month - 1]}';
}

class _PickedAsset {
  const _PickedAsset({required this.asset, required this.isVideo});

  final String asset;
  final bool isVideo;
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker();

  static const _photos = <String>[
    'assets/images/travel/porto_river.jpg',
    'assets/images/travel/lisbon_street.jpg',
    'assets/images/travel/rome_city.jpg',
    'assets/images/travel/paris_eiffel.jpg',
    'assets/images/travel/barcelona_square.jpg',
    'assets/images/travel/rail_coast.jpg',
  ];

  static const _videos = <String>[
    'assets/videos/vertical/porto_sequence.mp4',
    'assets/videos/vertical/lisbon_sequence.mp4',
    'assets/videos/vertical/rome_sequence.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.add_photo_alternate_outlined,
                    color: colors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Invia una foto o un video',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final asset = _photos[index];
                  return _PickTile(asset: asset, isVideo: false);
                },
              ),
            ),
            const SizedBox(height: 14),
            Text('Video demo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _videos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final asset = _videos[index];
                  return _PickTile(asset: asset, isVideo: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.asset,
    required this.isVideo,
  });

  final String asset;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _humanAssetLabel(asset, isVideo: isVideo),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(
          _PickedAsset(asset: asset, isVideo: isVideo),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 76,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(asset, fit: BoxFit.cover),
                if (isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white70,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A readable screen-reader label derived from the demo asset filename,
/// e.g. "Foto Porto" or "Video Roma", with a generic fallback.
String _humanAssetLabel(String asset, {required bool isVideo}) {
  final name = asset.split('/').last;
  final key = name.split('_').first;
  const names = <String, String>{
    'porto': 'Porto',
    'lisbon': 'Lisbona',
    'rome': 'Roma',
    'paris': 'Parigi',
    'barcelona': 'Barcellona',
    'rail': 'Costa',
  };
  final destination = names[key] ?? key;
  return '${isVideo ? 'Video' : 'Foto'} $destination';
}