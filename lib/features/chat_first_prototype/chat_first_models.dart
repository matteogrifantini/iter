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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'changeLabel': changeLabel,
        'snapshot': snapshot.toJson(),
        'outcome': outcome?.name,
      };

  factory PlanProposal.fromJson(Map<String, dynamic> json) {
    final proposal = PlanProposal(
      changeLabel: (json['changeLabel'] as String?) ?? '',
      snapshot: TripSnapshot.fromJson(
        (json['snapshot'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
    final outcomeName = json['outcome'] as String?;
    if (outcomeName != null) {
      proposal.outcome = PlanProposalOutcome.values.asNameMap()[outcomeName];
    }
    return proposal;
  }
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

/// A persisted conversation as stored by the data source. Kept separate from
/// [Conversation] so the DB mapping (uuid id, updated_at) stays explicit while
/// the widgets keep using the richer [Conversation] model.
@immutable
class ConversationRow {
  const ConversationRow({
    required this.id,
    required this.conversation,
    required this.updatedAt,
  });

  /// The database (uuid) id of the conversation row.
  final String id;

  /// The full in-memory conversation shape, whose own [Conversation.id] is the
  /// stable client key used by the controller and widgets.
  final Conversation conversation;

  final DateTime updatedAt;

  String get title => conversation.title;
  int get unread => conversation.unread;
  TripSnapshot? get snapshot => conversation.snapshot;
  String get avatarAsset => conversation.avatar.asset;

  /// Parses a database row (uuid id + serialized conversation) back into a row
  /// model. Degrades gracefully when the stored summary is missing or broken.
  /// The `unread` and `updated_at` columns win over the serialized summary so
  /// badges and ordering always reflect the authoritative DB state; `title` and
  /// `avatar_asset` fill any gap left by a sparse or empty summary.
  factory ConversationRow.fromDbRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final raw = row['summary'];
    Conversation conversation = raw is Map<String, dynamic>
        ? Conversation.fromJson(raw)
        : Conversation.fromJson(const <String, dynamic>{});
    final title = conversation.title.isEmpty
        ? (row['title'] as String?) ?? ''
        : conversation.title;
    final avatarAsset = conversation.avatar.asset.isEmpty
        ? (row['avatar_asset'] as String?) ?? ''
        : conversation.avatar.asset;
    final needsPatch = title != conversation.title ||
        avatarAsset != conversation.avatar.asset;
    if (needsPatch) {
      final json = conversation.toJson();
      json['title'] = title;
      json['avatar'] = <String, dynamic>{'asset': avatarAsset};
      conversation = Conversation.fromJson(json);
    }
    final unreadColumn = (row['unread'] as num?)?.toInt();
    if (unreadColumn != null) {
      conversation = conversation.copyWith(unread: unreadColumn);
    }
    final updatedRaw = row['updated_at'];
    return ConversationRow(
      id: id,
      conversation: conversation,
      updatedAt: updatedRaw is String
          ? DateTime.tryParse(updatedRaw) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// A profile picture or poster thumb used as the conversation avatar.
class ChatAvatar {
  const ChatAvatar(this.asset, {this.label});

  final String asset;
  final String? label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'asset': asset,
        if (label != null) 'label': label,
      };

  factory ChatAvatar.fromJson(Map<String, dynamic> json) => ChatAvatar(
        (json['asset'] as String?) ?? '',
        label: json['label'] as String?,
      );
}

/// One selectable option inside a [ChatMessageKind.choices] bubble.
@immutable
class ChatChoice {
  const ChatChoice({required this.label, this.confirm = true});

  final String label;

  /// Whether picking it immediately advances the thread ([confirm]) or just
  /// records the intent without creating a new message ([confirm] == false).
  final bool confirm;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'confirm': confirm,
      };

  factory ChatChoice.fromJson(Map<String, dynamic> json) => ChatChoice(
        label: (json['label'] as String?) ?? '',
        confirm: (json['confirm'] as bool?) ?? true,
      );
}

/// A media attachment shown inside a thread. Videos reuse the local vertical
/// demo clips; images reuse the travel posters.
@immutable
class ChatMedia {
  const ChatMedia({required this.asset, required this.isVideo});

  final String asset;
  final bool isVideo;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'asset': asset,
        'isVideo': isVideo,
      };

  factory ChatMedia.fromJson(Map<String, dynamic> json) => ChatMedia(
        asset: (json['asset'] as String?) ?? '',
        isVideo: (json['isVideo'] as bool?) ?? false,
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'destinationTitle': destinationTitle,
        'country': country,
        'durationLabel': durationLabel,
        'statusLabel': statusLabel,
        'dates': dates,
        'transport': transport,
        'stay': stay,
        'placeLabels': placeLabels,
        'days': days.map((d) => d.toJson()).toList(growable: false),
      };

  factory TripSnapshot.fromJson(Map<String, dynamic> json) => TripSnapshot(
        destinationTitle: (json['destinationTitle'] as String?) ?? '',
        country: (json['country'] as String?) ?? '',
        durationLabel: (json['durationLabel'] as String?) ?? '',
        statusLabel: (json['statusLabel'] as String?) ?? '',
        dates: (json['dates'] as String?) ?? '',
        transport: (json['transport'] as String?) ?? '',
        stay: (json['stay'] as String?) ?? '',
        placeLabels: (json['placeLabels'] as List<dynamic>?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[],
        days: (json['days'] as List<dynamic>?)
                ?.map((d) => TripDaySnapshot.fromJson(d as Map<String, dynamic>))
                .toList(growable: false) ??
            const <TripDaySnapshot>[],
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'theme': theme,
        'items': items.map((i) => i.toJson()).toList(growable: false),
      };

  factory TripDaySnapshot.fromJson(Map<String, dynamic> json) => TripDaySnapshot(
        label: (json['label'] as String?) ?? '',
        theme: (json['theme'] as String?) ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => TripItemSnapshot.fromJson(i as Map<String, dynamic>))
                .toList(growable: false) ??
            const <TripItemSnapshot>[],
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'category': category,
        'time': time,
        'locked': locked,
      };

  factory TripItemSnapshot.fromJson(Map<String, dynamic> json) =>
      TripItemSnapshot(
        title: (json['title'] as String?) ?? '',
        category: (json['category'] as String?) ?? '',
        time: (json['time'] as String?) ?? '',
        locked: (json['locked'] as bool?) ?? false,
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'role': role.name,
        'kind': kind.name,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        if (media != null) 'media': media!.toJson(),
        'choices': choices.map((c) => c.toJson()).toList(growable: false),
        if (audioDuration != null) 'audioDuration': audioDuration,
        if (summary != null) 'summary': summary!.toJson(),
        if (proposal != null) 'proposal': proposal!.toJson(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as String?) ?? '',
        role: ChatRole.values.asNameMap()[json['role']] ?? ChatRole.assistant,
        kind: ChatMessageKind.values.asNameMap()[json['kind']] ??
            ChatMessageKind.text,
        text: (json['text'] as String?) ?? '',
        sentAt: DateTime.tryParse((json['sentAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        media: json['media'] is Map<String, dynamic>
            ? ChatMedia.fromJson(json['media'] as Map<String, dynamic>)
            : null,
        choices: (json['choices'] as List<dynamic>?)
                ?.map((c) => ChatChoice.fromJson(c as Map<String, dynamic>))
                .toList(growable: false) ??
            const <ChatChoice>[],
        audioDuration: json['audioDuration'] as String?,
        summary: json['summary'] is Map<String, dynamic>
            ? TripSnapshot.fromJson(json['summary'] as Map<String, dynamic>)
            : null,
        proposal: json['proposal'] is Map<String, dynamic>
            ? PlanProposal.fromJson(json['proposal'] as Map<String, dynamic>)
            : null,
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'avatar': avatar.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'unread': unread,
        'lastPreview': lastPreview,
        if (snapshot != null) 'snapshot': snapshot!.toJson(),
        'isTrending': isTrending,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        subtitle: (json['subtitle'] as String?) ?? '',
        avatar: json['avatar'] is Map<String, dynamic>
            ? ChatAvatar.fromJson(json['avatar'] as Map<String, dynamic>)
            : ChatAvatar(''),
        timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        unread: (json['unread'] as num?)?.toInt() ?? 0,
        lastPreview: (json['lastPreview'] as String?) ?? '',
        snapshot: json['snapshot'] is Map<String, dynamic>
            ? TripSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>)
            : null,
        isTrending: (json['isTrending'] as bool?) ?? false,
      );
}