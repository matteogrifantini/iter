import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/journey_media.dart';
import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'inspiration_import_sheet.dart';
import 'iter_glass_primitives.dart';
import 'iter_ui_primitives.dart';

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
    void clamp() {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }

    // Clamp to the bottom on this frame and re-clamp over the following ones
    // so content that settles after the first layout (e.g. async-decoded card
    // images that grow the last message) never leaves the new chips off-screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      clamp();
      for (var i = 1; i <= 3; i++) {
        WidgetsBinding.instance.addPostFrameCallback((_) => clamp());
      }
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
    if (picked.isInspiration) {
      if (!mounted) return;
      final proposed = await showInspirationImportSheet(
        context: context,
        controller: widget.controller,
        initialConversationId: widget.conversationId,
      );
      if (proposed == true) _jumpToBottom();
      return;
    }
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
        final selectedFlightId = summary.snapshot?.travelSelection?.option.id;
        final selectedStayId = summary.snapshot?.staySelection?.option.id;
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
          body: IterPageFrame(
            padding: EdgeInsets.zero,
            expandHeight: true,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    key: const Key('thread-message-list'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final showDayDivider =
                          index == 0 ||
                          messages[index - 1].sentAt.day != message.sentAt.day;
                      final interactive =
                          messages.isNotEmpty &&
                          messages.last.choices.isNotEmpty;
                      return _MessageRow(
                        message: message,
                        showDayDivider: showDayDivider,
                        avatar: summary.avatar,
                        enabled: interactive && index == messages.length - 1,
                        onChoice: (choice) {
                          widget.controller.choose(
                            choice,
                            conversationId: widget.conversationId,
                            messageId: message.id,
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
                        onOpenPlan: message.proposal == null
                            ? null
                            : () => widget.onOpenSnapshot(
                                message.proposal!.snapshot,
                              ),
                        onSelectFlight: (optionId) {
                          widget.controller.selectTravelOption(
                            conversationId: widget.conversationId,
                            optionId: optionId,
                          );
                          _jumpToBottom();
                        },
                        onSelectStay: (optionId) {
                          widget.controller.selectStayOption(
                            conversationId: widget.conversationId,
                            optionId: optionId,
                          );
                          _jumpToBottom();
                        },
                        onProposeNightsChange: (nights) {
                          widget.controller.proposeStayNightsChange(
                            conversationId: widget.conversationId,
                            nights: nights,
                          );
                          _jumpToBottom();
                        },
                        selectedFlightId: selectedFlightId,
                        selectedStayId: selectedStayId,
                        reducedMotion: reducedMotion,
                      );
                    },
                  ),
                ),
                if (widget.controller.placeComposerContext(
                      widget.conversationId,
                    )
                    case final place?)
                  _PlaceComposerContext(
                    place: place,
                    onClear: () => widget.controller.clearPlaceComposerContext(
                      widget.conversationId,
                    ),
                  ),
                _Composer(
                  key: const Key('chat-composer'),
                  controller: _composer,
                  onSend: _send,
                  onSendAudio: _sendAudio,
                  onAttach: _showAttachments,
                ),
              ],
            ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
    this.enabled = true,
    this.onAcceptProposal,
    this.onRejectProposal,
    this.onOpenPlan,
    this.onSelectFlight,
    this.onSelectStay,
    this.onProposeNightsChange,
    this.selectedFlightId,
    this.selectedStayId,
  });

  final ChatMessage message;
  final bool showDayDivider;
  final ChatAvatar avatar;
  final ValueChanged<ChatChoice> onChoice;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;
  final VoidCallback? onOpenPlan;
  final ValueChanged<String>? onSelectFlight;
  final ValueChanged<String>? onSelectStay;
  final ValueChanged<int>? onProposeNightsChange;
  final String? selectedFlightId;
  final String? selectedStayId;
  final bool reducedMotion;

  /// Whether the chips below this message are still actionable. Only the
  /// thread's current decision point enables them; older messages show the
  /// chips read-only.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.system) {
      return _SystemDivider(text: message.text);
    }
    final isIncoming = message.isIncoming;
    final align = isIncoming
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;

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
                        onOpenPlan: onOpenPlan,
                        onSelectFlight: onSelectFlight,
                        onSelectStay: onSelectStay,
                        onProposeNightsChange: onProposeNightsChange,
                        selectedFlightId: selectedFlightId,
                        selectedStayId: selectedStayId,
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
                                  onPressed: enabled
                                      ? () => onChoice(choice)
                                      : null,
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
    this.onOpenPlan,
    this.onSelectFlight,
    this.onSelectStay,
    this.onProposeNightsChange,
    this.selectedFlightId,
    this.selectedStayId,
  });

  final ChatMessage message;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;
  final VoidCallback? onOpenPlan;
  final ValueChanged<String>? onSelectFlight;
  final ValueChanged<String>? onSelectStay;
  final ValueChanged<int>? onProposeNightsChange;
  final String? selectedFlightId;
  final String? selectedStayId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isIncoming = message.isIncoming;
    final background = isIncoming
        ? colors.surfaceContainerHighest
        : colors.secondaryContainer;
    const radius = BorderRadius.all(Radius.circular(20));
    final content = _MessageContent(
      message: message,
      isIncoming: isIncoming,
      onAcceptProposal: onAcceptProposal,
      onRejectProposal: onRejectProposal,
      onOpenPlan: onOpenPlan,
      onSelectFlight: onSelectFlight,
      onSelectStay: onSelectStay,
      onProposeNightsChange: onProposeNightsChange,
      selectedFlightId: selectedFlightId,
      selectedStayId: selectedStayId,
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
    this.onOpenPlan,
    this.onSelectFlight,
    this.onSelectStay,
    this.onProposeNightsChange,
    this.selectedFlightId,
    this.selectedStayId,
  });

  final ChatMessage message;
  final bool isIncoming;
  final VoidCallback? onAcceptProposal;
  final VoidCallback? onRejectProposal;
  final VoidCallback? onOpenPlan;
  final ValueChanged<String>? onSelectFlight;
  final ValueChanged<String>? onSelectStay;
  final ValueChanged<int>? onProposeNightsChange;
  final String? selectedFlightId;
  final String? selectedStayId;

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
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: textColor),
        );
      case ChatMessageKind.media:
        return _MediaContent(message: message);
      case ChatMessageKind.audio:
        return _AudioContent(message: message, isIncoming: isIncoming);
      case ChatMessageKind.tripSummary:
        final summary = message.summary;
        if (summary == null) return const SizedBox.shrink();
        return _SummaryCard(snapshot: summary, text: message.text);
      case ChatMessageKind.operational:
        return _OperationalContent(message: message, isIncoming: isIncoming);
      case ChatMessageKind.planProposal:
        return _ProposalCard(
          message: message,
          onAccept: onAcceptProposal,
          onReject: onRejectProposal,
          onOpenPlan: onOpenPlan,
        );
      case ChatMessageKind.placeCard:
        return _PlaceCardContent(message: message);
      case ChatMessageKind.transport:
        final flightCompare = message.flightCompare;
        if (flightCompare != null && flightCompare.options.isNotEmpty) {
          return _FlightCompareContent(
            message: message,
            selectedOptionId: selectedFlightId,
            onSelectFlight: onSelectFlight,
          );
        }
        return _TransportContent(message: message);
      case ChatMessageKind.stayZone:
        final stayCompare = message.stayCompare;
        if (stayCompare != null && stayCompare.options.isNotEmpty) {
          return _StayCompareContent(
            message: message,
            selectedOptionId: selectedStayId,
            onSelectStay: onSelectStay,
            onProposeNightsChange: onProposeNightsChange,
          );
        }
        return _StayZoneContent(message: message);
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.snapshot, this.text = ''});

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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.route_outlined, size: 18, color: colors.primary),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (summary.placeLabels.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                for (final label in summary.placeLabels.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_outline,
                          size: 15,
                          color: colors.primary,
                        ),
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

/// A place proposed during the in-chat curation: a light card with category,
/// neighborhood, why-it-fits and the best moment, plus Passa/Salva/Irrinunciabile
/// actions rendered as choices below the bubble.
class _PlaceCardContent extends StatelessWidget {
  const _PlaceCardContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final card = message.placeCard;
    if (card == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (card.imageAsset != null) ...<Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    card.imageAsset!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                card.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.place_outlined, size: 15, color: colors.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${card.category} · ${card.neighborhood}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(card.whyFits, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.schedule, size: 15, color: colors.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${card.durationMinutes} min · ${card.bestMoment}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The in-chat transport comparison: a small table of demo options (plane,
/// train, car) with price and duration, with the recommended one highlighted.
class _TransportContent extends StatelessWidget {
  const _TransportContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compare = message.transport;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
        if (compare != null)
          for (final option in compare.options)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.directions_outlined,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          option.durationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          option.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (option.isRecommended) ...<Widget>[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.recommend,
                            size: 13,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Consigliato',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
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

/// The stay-zone context: the recommended zone with its atmosphere and walk
/// times, plus a decorative demo "map" box (no real map dependency). The zone
/// choice renders as choices below the bubble.
class _StayZoneContent extends StatelessWidget {
  const _StayZoneContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final zone = message.stayZone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
        if (zone != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  zone.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  zone.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.directions_walk,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${zone.averageWalkMinutes} min a piedi dalle tappe · '
                        '${zone.whyFits}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primaryContainer),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.location_on, size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Mappa demo — zona consigliata',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The operational flight inventory inside the chat: the recommended option
/// first, then every fixture alternative in a readable panel with an explicit
/// Scegli action. Rendered only when the message carries a non-empty
/// [FlightCompare]; otherwise the classic [TransportCompare] table is used.
class _FlightCompareContent extends StatelessWidget {
  const _FlightCompareContent({
    required this.message,
    this.selectedOptionId,
    this.onSelectFlight,
  });

  final ChatMessage message;
  final String? selectedOptionId;
  final ValueChanged<String>? onSelectFlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compare = message.flightCompare;
    if (compare == null || compare.options.isEmpty) {
      return const SizedBox.shrink();
    }
    final cheapestId = _cheapestFlightId(compare.options);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
        _FlightCompareOverview(
          compare: compare,
          selectedOptionId: selectedOptionId,
          onSelectFlight: onSelectFlight,
        ),
        for (final option in compare.options)
          _FlightOptionPanel(
            option: option,
            quotedAt: compare.quotedAt,
            isRecommended: option.id == compare.recommendedId,
            isCheapest: option.id == cheapestId,
            isSelected: option.id == selectedOptionId,
            onSelect: onSelectFlight == null
                ? null
                : () => onSelectFlight!(option.id),
          ),
      ],
    );
  }
}

class _FlightCompareOverview extends StatelessWidget {
  const _FlightCompareOverview({
    required this.compare,
    this.selectedOptionId,
    this.onSelectFlight,
  });

  final FlightCompare compare;
  final String? selectedOptionId;
  final ValueChanged<String>? onSelectFlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = compare.options.first;
    final minPrice = compare.options
        .map((option) => option.priceCents)
        .reduce(math.min);
    final maxPrice = compare.options
        .map((option) => option.priceCents)
        .reduce(math.max);
    final cheapest = compare.options.reduce(
      (first, next) => next.priceCents < first.priceCents ? next : first,
    );
    final recommended = compare.options.firstWhere(
      (option) => option.id == compare.recommendedId,
      orElse: () => first,
    );
    final dateLabel = compare.travelDateLabel.isEmpty
        ? _dateLabel(first.departureAt)
        : compare.travelDateLabel;
    final dateReason = compare.travelDateReason.isEmpty
        ? 'Confronto locale: la disponibilità reale va verificata prima di '
              'prenotare.'
        : compare.travelDateReason;
    final recommendationReason = compare.recommendationReason.isEmpty
        ? first.tradeoff
        : compare.recommendationReason;

    return IterMaterialSurface(
      key: const Key('flight-comparison-overview'),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.flight_takeoff, color: colors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Volo · ${first.departureAirport} → ${first.arrivalAirport}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${compare.options.length} alternative · '
                      '${_priceRangeLabel(minPrice, maxPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Giorno migliore del piano',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            dateLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            dateReason,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ComparisonMetric(
                icon: Icons.sell_outlined,
                label: 'Prezzo più basso',
                value: formatEuroCents(cheapest.priceCents),
                detail: cheapest.provider,
              ),
              _ComparisonMetric(
                icon: Icons.recommend_outlined,
                label: 'Scelta consigliata',
                value: recommended.provider,
                detail:
                    '${_stopsLabel(recommended.stops)} · '
                    '${formatEuroCents(recommended.priceCents)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Confronto rapido',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Scorri a destra per confrontare tutti i dettagli.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('flight-comparison-table'),
              showCheckboxColumn: false,
              horizontalMargin: 0,
              columnSpacing: 18,
              headingRowHeight: 38,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 72,
              columns: const <DataColumn>[
                DataColumn(label: Text('Volo')),
                DataColumn(label: Text('Prezzo')),
                DataColumn(label: Text('Orari')),
                DataColumn(label: Text('Durata')),
                DataColumn(label: Text('Scali')),
              ],
              rows: <DataRow>[
                for (final option in compare.options)
                  DataRow(
                    selected: option.id == selectedOptionId,
                    onSelectChanged: onSelectFlight == null
                        ? null
                        : (_) => onSelectFlight!(option.id),
                    cells: <DataCell>[
                      DataCell(Text(option.provider)),
                      DataCell(Text(formatEuroCents(option.priceCents))),
                      DataCell(
                        Text(
                          '${_timeLabel(option.departureAt)}–'
                          '${_timeLabel(option.arrivalAt)}',
                        ),
                      ),
                      DataCell(Text(_durationLabel(option.durationMinutes))),
                      DataCell(Text(_stopsLabel(option.stops))),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Perché questa scelta',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            recommendationReason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Dati demo · quotazione ${_dateLabel(compare.quotedAt)} · '
            'prezzi e disponibilità non sono in tempo reale',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  const _ComparisonMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 136, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightOptionPanel extends StatelessWidget {
  const _FlightOptionPanel({
    required this.option,
    required this.quotedAt,
    required this.isRecommended,
    this.isCheapest = false,
    this.isSelected = false,
    this.onSelect,
  });

  final FlightOptionInfo option;
  final DateTime quotedAt;
  final bool isRecommended;
  final bool isCheapest;
  final bool isSelected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stops = option.stops == 0
        ? 'Diretto'
        : '${option.stops} ${option.stops == 1 ? 'scalo' : 'scali'}';
    return Container(
      key: ValueKey<String>('flight-option-${option.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecommended ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isRecommended || isCheapest) ...<Widget>[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (isRecommended) const _RecommendedChip(),
                if (isCheapest)
                  const _RecommendedChip(
                    label: 'Prezzo più basso',
                    icon: Icons.sell_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: <Widget>[
              Icon(Icons.flight_takeoff, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.provider,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatEuroCents(option.priceCents),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.schedule,
            label:
                '${_timeLabel(option.departureAt)}–${_timeLabel(option.arrivalAt)} '
                '· ${option.departureAirport}→${option.arrivalAirport}',
          ),
          _DetailRow(
            icon: Icons.hourglass_bottom,
            label: 'Durata ${_durationLabel(option.durationMinutes)} · $stops',
          ),
          _DetailRow(icon: Icons.luggage_outlined, label: option.baggage),
          _DetailRow(
            icon: Icons.compare_arrows_outlined,
            label: option.tradeoff,
          ),
          _DetailRow(
            icon: Icons.schedule_send_outlined,
            label:
                'Dati demo · quotazione ${_dateLabel(quotedAt)} · prezzi e '
                'disponibilità non in tempo reale',
          ),
          if (onSelect != null) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                onPressed: isSelected ? null : onSelect,
                child: const Text('Scegli'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The recommended hotel inventory inside the chat, with a minimal nights
/// stepper whose changes surface as a confirmable [PlanProposal]. Rendered only
/// when the message carries a non-empty [StayCompare].
class _StayCompareOverview extends StatelessWidget {
  const _StayCompareOverview({
    required this.compare,
    this.selectedOptionId,
    this.onSelectStay,
  });

  final StayCompare compare;
  final String? selectedOptionId;
  final ValueChanged<String>? onSelectStay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = compare.options.first;
    final minPrice = compare.options
        .map((option) => option.priceCents)
        .reduce(math.min);
    final maxPrice = compare.options
        .map((option) => option.priceCents)
        .reduce(math.max);
    final cheapest = compare.options.reduce(
      (first, next) => next.priceCents < first.priceCents ? next : first,
    );
    final recommended = compare.options.firstWhere(
      (option) => option.id == compare.recommendedId,
      orElse: () => first,
    );
    final nightsLabel = first.nights == 1 ? '1 notte' : '${first.nights} notti';
    final datesLabel = compare.stayDatesLabel.isEmpty
        ? 'Date da confermare'
        : '${compare.stayDatesLabel} · $nightsLabel';
    final recommendationReason = compare.recommendationReason.isEmpty
        ? first.tradeoff
        : compare.recommendationReason;

    return IterMaterialSurface(
      key: const Key('stay-comparison-overview'),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.hotel_outlined, color: colors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hotel per il soggiorno',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${compare.options.length} strutture · '
                      '${_priceRangeLabel(minPrice, maxPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Date del soggiorno',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            datesLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'La tariffa si riferisce a questa durata; cambiando le notti '
            'Iter prepara una nuova proposta da confermare.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ComparisonMetric(
                icon: Icons.sell_outlined,
                label: 'Tariffa più bassa',
                value: formatEuroCents(cheapest.priceCents),
                detail: cheapest.name,
              ),
              _ComparisonMetric(
                icon: Icons.recommend_outlined,
                label: 'Scelta consigliata',
                value: recommended.name,
                detail:
                    '${recommended.zone} · '
                    '${formatEuroCents(recommended.priceCents)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Confronto rapido',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Scorri a destra per confrontare tutti i dettagli.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('stay-comparison-table'),
              showCheckboxColumn: false,
              horizontalMargin: 0,
              columnSpacing: 18,
              headingRowHeight: 38,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 72,
              columns: const <DataColumn>[
                DataColumn(label: Text('Struttura')),
                DataColumn(label: Text('Prezzo')),
                DataColumn(label: Text('Zona')),
                DataColumn(label: Text('Notti')),
                DataColumn(label: Text('Distanza')),
              ],
              rows: <DataRow>[
                for (final option in compare.options)
                  DataRow(
                    selected: option.id == selectedOptionId,
                    onSelectChanged: onSelectStay == null
                        ? null
                        : (_) => onSelectStay!(option.id),
                    cells: <DataCell>[
                      DataCell(Text(option.name)),
                      DataCell(Text(formatEuroCents(option.priceCents))),
                      DataCell(Text(option.zone)),
                      DataCell(Text('${option.nights}')),
                      DataCell(Text('${option.averageWalkMinutes} min')),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Perché questa scelta',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            recommendationReason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Dati demo · prezzi e disponibilità non sono in tempo reale',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StayCompareContent extends StatefulWidget {
  const _StayCompareContent({
    required this.message,
    this.selectedOptionId,
    this.onSelectStay,
    this.onProposeNightsChange,
  });

  final ChatMessage message;
  final String? selectedOptionId;
  final ValueChanged<String>? onSelectStay;
  final ValueChanged<int>? onProposeNightsChange;

  @override
  State<_StayCompareContent> createState() => _StayCompareContentState();
}

class _StayCompareContentState extends State<_StayCompareContent> {
  late int _nights;

  @override
  void initState() {
    super.initState();
    final compare = widget.message.stayCompare;
    final source = _nightlySource(compare);
    _nights = source?.nights ?? 2;
  }

  /// The single hotel the stepper's preview is priced from: the current
  /// selection when present, otherwise the recommended one. Mirrors the
  /// controller so the preview and the proposal always agree.
  StayOptionInfo? _nightlySource(StayCompare? compare) {
    if (compare == null || compare.options.isEmpty) return null;
    if (widget.selectedOptionId != null) {
      return compare.options.firstWhere(
        (option) => option.id == widget.selectedOptionId,
        orElse: () => compare.recommended,
      );
    }
    return compare.recommended;
  }

  void _changeNights(int delta) {
    final next = _nights + delta;
    if (next < 1) return;
    setState(() => _nights = next);
    widget.onProposeNightsChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compare = widget.message.stayCompare;
    if (compare == null || compare.options.isEmpty) {
      return const SizedBox.shrink();
    }
    final source = _nightlySource(compare)!;
    final cheapestId = _cheapestStayId(compare.options);
    final nightlyCents = stayNightlyPriceCents(
      priceCents: source.priceCents,
      nights: source.nights,
    );
    final nightsLabel = _nights == 1 ? '1 notte' : '$_nights notti';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
        _StayCompareOverview(
          compare: compare,
          selectedOptionId: widget.selectedOptionId,
          onSelectStay: widget.onSelectStay,
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.bed_outlined, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$nightsLabel · ${formatEuroCents(nightlyCents * _nights)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Ogni modifica diventa una proposta da confermare.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Dati demo · prezzi e disponibilità non in tempo reale',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Riduci notti',
                onPressed: _nights > 1 ? () => _changeNights(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_nights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Aggiungi notti',
                onPressed: () => _changeNights(1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        for (final option in compare.options)
          _StayOptionPanel(
            option: option,
            isRecommended: option.id == compare.recommendedId,
            isCheapest: option.id == cheapestId,
            isSelected: option.id == widget.selectedOptionId,
            onSelect: widget.onSelectStay == null
                ? null
                : () => widget.onSelectStay!(option.id),
          ),
      ],
    );
  }
}

class _StayOptionPanel extends StatelessWidget {
  const _StayOptionPanel({
    required this.option,
    required this.isRecommended,
    this.isCheapest = false,
    this.isSelected = false,
    this.onSelect,
  });

  final StayOptionInfo option;
  final bool isRecommended;
  final bool isCheapest;
  final bool isSelected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey<String>('stay-option-${option.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecommended ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isRecommended || isCheapest) ...<Widget>[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (isRecommended) const _RecommendedChip(),
                if (isCheapest)
                  const _RecommendedChip(
                    label: 'Prezzo più basso',
                    icon: Icons.sell_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: <Widget>[
              Icon(Icons.hotel_outlined, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatEuroCents(option.priceCents),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.place_outlined,
            label:
                '${option.zone} · ${option.nights == 1 ? '1 notte' : '${option.nights} notti'}',
          ),
          _DetailRow(
            icon: Icons.directions_walk,
            label: '${option.averageWalkMinutes} min a piedi dalle tappe',
          ),
          _DetailRow(
            icon: Icons.local_fire_department_outlined,
            label: option.atmosphere,
          ),
          _DetailRow(icon: Icons.verified_outlined, label: option.conditions),
          _DetailRow(
            icon: Icons.compare_arrows_outlined,
            label: option.tradeoff,
          ),
          if (onSelect != null) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                onPressed: isSelected ? null : onSelect,
                child: const Text('Scegli'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The reusable in-chat "Consigliato" chip used by the rich modules.
class _RecommendedChip extends StatelessWidget {
  const _RecommendedChip({
    this.label = 'Consigliato',
    this.icon = Icons.recommend,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One compact icon+label line inside a rich module panel.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

String? _cheapestFlightId(List<FlightOptionInfo> options) {
  if (options.isEmpty) return null;
  return options
      .reduce(
        (first, next) => next.priceCents < first.priceCents ? next : first,
      )
      .id;
}

String? _cheapestStayId(List<StayOptionInfo> options) {
  if (options.isEmpty) return null;
  return options
      .reduce(
        (first, next) => next.priceCents < first.priceCents ? next : first,
      )
      .id;
}

String _stopsLabel(int stops) =>
    stops == 0 ? 'Diretto' : '$stops ${stops == 1 ? 'scalo' : 'scali'}';

String _priceRangeLabel(int minCents, int maxCents) {
  if (minCents == maxCents) return formatEuroCents(minCents);
  return 'da ${formatEuroCents(minCents)} a ${formatEuroCents(maxCents)}';
}

String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  return '${hours}h ${rest.toString().padLeft(2, '0')}m';
}

String _dateLabel(DateTime time) {
  final day = time.day.toString().padLeft(2, '0');
  final month = time.month.toString().padLeft(2, '0');
  return '$day/$month/${time.year}';
}

/// An in-chat plan proposal: the change stays compact and the full snapshot is
/// opened on demand. Once settled the actions become a status line.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.message,
    this.onAccept,
    this.onReject,
    this.onOpenPlan,
  });

  final ChatMessage message;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onOpenPlan;

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
        Container(
          key: const Key('chat-proposal-change'),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (outcome == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('chat-proposal-open-plan'),
                onPressed: onOpenPlan,
                icon: const Icon(Icons.route_outlined),
                label: const Text('Vedi il piano completo'),
              ),
              const SizedBox(height: 8),
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
              ),
            ],
          )
        else
          Row(
            children: <Widget>[
              Icon(
                accepted ? Icons.check_circle : Icons.cancel_outlined,
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
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

class _PlaceComposerContext extends StatelessWidget {
  const _PlaceComposerContext({required this.place, required this.onClear});

  final PlanPlaceDetails place;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Contesto luogo, ${place.title}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: 16, right: 8),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.place_outlined,
              size: 20,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Su ${place.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Rimuovi contesto luogo',
              onPressed: onClear,
              color: colors.onSecondaryContainer,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
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
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: IterGlassBar(
                padding: const EdgeInsets.all(6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      onPressed: onAttach,
                      tooltip: 'Allegato',
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 28,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 2,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: InputDecoration(
                            hintText: 'Scrivi a Iter…',
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (hasText)
                      IconButton.filled(
                        onPressed: onSend,
                        tooltip: 'Invia',
                        icon: const Icon(Icons.arrow_upward_rounded),
                      )
                    else
                      IconButton(
                        onPressed: onSendAudio,
                        tooltip: 'Registra vocale (demo)',
                        icon: const Icon(Icons.mic_none_rounded),
                        iconSize: 28,
                      ),
                  ],
                ),
              ),
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
  const _PickedAsset({required this.asset, required this.isVideo})
    : isInspiration = false;

  const _PickedAsset.inspiration()
    : asset = '',
      isVideo = false,
      isInspiration = true;

  final String asset;
  final bool isVideo;
  final bool isInspiration;
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link_outlined, color: colors.primary),
              title: const Text('Importa link Reel/TikTok'),
              subtitle: const Text(
                'Salvalo nel viaggio e chiedi a Iter di integrarlo',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).pop(const _PickedAsset.inspiration()),
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colors.primary,
                  size: 22,
                ),
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
  const _PickTile({required this.asset, required this.isVideo});

  final String asset;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _humanAssetLabel(asset, isVideo: isVideo),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(
          context,
        ).pop(_PickedAsset(asset: asset, isVideo: isVideo)),
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
