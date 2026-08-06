import 'package:flutter/foundation.dart';

/// Who produced a message in a chat-first thread.
enum ChatRole { traveler, assistant, system }

/// The visual/behavioural kind of a message. Every kind is rendered inside the
/// familiar bubble grammar except [system], which is a slim centered divider.
enum ChatMessageKind {
  text,
  choices,
  media,
  audio,
  tripSummary,
  operational,
  planProposal,
  system,
}

/// How a traveler settled a concrete [PlanProposal].
enum PlanProposalOutcome { accepted, rejected }

/// A concrete change to the plan that Iter offers in-chat. The traveler must
/// explicitly accept or reject it; accepting makes [snapshot] the new current
/// plan of the conversation.
class PlanProposal {
  PlanProposal({required this.changeLabel, required this.snapshot});

  /// Short human summary of what changes, e.g. 'Foro Romano alle 10:30'.
  final String changeLabel;

  /// The resulting plan if the traveler accepts.
  final TripSnapshot snapshot;

  /// Null until the traveler settles the proposal; never resettable.
  PlanProposalOutcome? outcome;
}

/// A must-see point inside a destination: what makes it special, with a small
/// emoji and the Iter why. Kept deliberately light so both the mock and the
/// live Supabase rows map onto it.
@immutable
class DestinationPoint {
  const DestinationPoint({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.whyFits,
  });

  final String id;
  final String name;
  final String category;
  final String emoji;
  final String whyFits;
}

/// A profile picture or poster thumb used as the conversation avatar.
class ChatAvatar {
  const ChatAvatar(this.asset, {this.label});

  final String asset;
  final String? label;
}

/// One selectable option inside a [ChatMessageKind.choices] bubble.
@immutable
class ChatChoice {
  const ChatChoice({required this.label, this.confirm = true});

  final String label;

  /// Whether picking it immediately advances the thread ([confirm]) or just
  /// records the intent without creating a new message ([confirm] == false).
  final bool confirm;
}

/// A media attachment shown inside a thread. Videos reuse the local vertical
/// demo clips; images reuse the travel posters.
@immutable
class ChatMedia {
  const ChatMedia({required this.asset, required this.isVideo});

  final String asset;
  final bool isVideo;
}

/// A read-only snapshot of the trip tied to a conversation. The prototype never
/// writes to the legacy [IterStore]: everything here is deterministic demo data.
@immutable
class TripSnapshot {
  const TripSnapshot({
    required this.destinationTitle,
    required this.country,
    required this.durationLabel,
    required this.statusLabel,
    required this.dates,
    required this.transport,
    required this.stay,
    required this.placeLabels,
    required this.days,
  });

  final String destinationTitle;
  final String country;
  final String durationLabel;

  /// e.g. 'In pianificazione' or 'In viaggio'.
  final String statusLabel;

  /// Short human date range, e.g. '14–17 ottobre'.
  final String dates;
  final String transport;
  final String stay;
  final List<String> placeLabels;
  final List<TripDaySnapshot> days;
}

@immutable
class TripDaySnapshot {
  const TripDaySnapshot({
    required this.label,
    required this.theme,
    required this.items,
  });

  final String label;
  final String theme;
  final List<TripItemSnapshot> items;
}

@immutable
class TripItemSnapshot {
  const TripItemSnapshot({
    required this.title,
    required this.category,
    required this.time,
    required this.locked,
  });

  final String title;
  final String category;
  final String time;
  final bool locked;
}

/// A single message in a conversation thread.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.kind,
    this.text = '',
    required this.sentAt,
    this.media,
    this.choices = const <ChatChoice>[],
    this.audioDuration,
    this.summary,
    this.proposal,
  });

  final String id;
  final ChatRole role;
  final ChatMessageKind kind;
  final String text;
  final DateTime sentAt;
  final ChatMedia? media;
  final List<ChatChoice> choices;

  /// Only on [ChatMessageKind.audio]; a short human duration like '0:14'.
  final String? audioDuration;

  /// Present only on [ChatMessageKind.tripSummary].
  final TripSnapshot? summary;

  /// Present only on [ChatMessageKind.planProposal].
  final PlanProposal? proposal;

  bool get isIncoming => role != ChatRole.traveler;
}

/// A conversation owns at most one [TripSnapshot]; opening the title opens that
/// read-only snapshot.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.timestamp,
    this.unread = 0,
    required this.lastPreview,
    this.snapshot,
    this.isTrending = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final ChatAvatar avatar;
  final DateTime timestamp;
  final int unread;
  final String lastPreview;
  final TripSnapshot? snapshot;
  final bool isTrending;

  Conversation copyWith({
    int? unread,
    String? lastPreview,
    TripSnapshot? snapshot,
  }) {
    return Conversation(
      id: id,
      title: title,
      subtitle: subtitle,
      avatar: avatar,
      timestamp: timestamp,
      unread: unread ?? this.unread,
      lastPreview: lastPreview ?? this.lastPreview,
      snapshot: snapshot ?? this.snapshot,
      isTrending: isTrending,
    );
  }
}