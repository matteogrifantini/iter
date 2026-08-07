import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

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
  placeCard,
  transport,
  stayZone,
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

/// The persisted owner profile as stored by the data source: the chosen theme
/// and the learned memory tags. The mock always returns null so the demo
/// defaults keep applying.
@immutable
class ProfileRow {
  const ProfileRow({required this.themeMode, required this.memoryTags});

  final ThemeMode themeMode;
  final List<String> memoryTags;
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

/// A catalog place proposed one at a time during the in-chat curation,
/// rendered as a card with skip/save/must actions. Deliberately a light view
/// of the shared [Place] mock so serialization stays self-contained.
@immutable
class PlaceCard {
  const PlaceCard({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.durationMinutes,
    required this.whyFits,
    required this.bestMoment,
    this.imageAsset,
  });

  final String id;
  final String name;
  final String category;
  final String neighborhood;
  final int durationMinutes;
  final String whyFits;
  final String bestMoment;

  /// Optional destination poster shown above the card content. Null keeps the
  /// card text-only, so restored messages without media stay intact.
  final String? imageAsset;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'neighborhood': neighborhood,
        'durationMinutes': durationMinutes,
        'whyFits': whyFits,
        'bestMoment': bestMoment,
        if (imageAsset != null) 'imageAsset': imageAsset,
      };

  factory PlaceCard.fromJson(Map<String, dynamic> json) => PlaceCard(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        category: (json['category'] as String?) ?? '',
        neighborhood: (json['neighborhood'] as String?) ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        whyFits: (json['whyFits'] as String?) ?? '',
        bestMoment: (json['bestMoment'] as String?) ?? '',
        imageAsset: json['imageAsset'] as String?,
      );
}

/// One demo transport option shown in the in-chat comparison: reaching the
/// destination, with fake but destination-coherent price and duration.
@immutable
class TransportOptionView {
  const TransportOptionView({
    required this.label,
    required this.priceLabel,
    required this.durationLabel,
    this.isRecommended = false,
  });

  final String label;
  final String priceLabel;
  final String durationLabel;
  final bool isRecommended;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'priceLabel': priceLabel,
        'durationLabel': durationLabel,
        'isRecommended': isRecommended,
      };

  factory TransportOptionView.fromJson(Map<String, dynamic> json) =>
      TransportOptionView(
        label: (json['label'] as String?) ?? '',
        priceLabel: (json['priceLabel'] as String?) ?? '',
        durationLabel: (json['durationLabel'] as String?) ?? '',
        isRecommended: (json['isRecommended'] as bool?) ?? false,
      );
}

/// The in-chat transport comparison: a small list of demo [TransportOptionView]s.
@immutable
class TransportCompare {
  const TransportCompare({required this.options});

  final List<TransportOptionView> options;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'options': options.map((o) => o.toJson()).toList(growable: false),
      };

  factory TransportCompare.fromJson(Map<String, dynamic> json) =>
      TransportCompare(
        options: (json['options'] as List<dynamic>?)
                ?.map((o) => TransportOptionView.fromJson(o as Map<String, dynamic>))
                .toList(growable: false) ??
            const <TransportOptionView>[],
      );
}

/// The recommended stay zone for a destination, rendered with atmosphere and
/// walk times and a decorative demo "map" (no real map dependency).
@immutable
class StayZoneInfo {
  const StayZoneInfo({
    required this.name,
    required this.summary,
    required this.whyFits,
    required this.averageWalkMinutes,
  });

  final String name;
  final String summary;
  final String whyFits;
  final int averageWalkMinutes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'summary': summary,
        'whyFits': whyFits,
        'averageWalkMinutes': averageWalkMinutes,
      };

  factory StayZoneInfo.fromJson(Map<String, dynamic> json) => StayZoneInfo(
        name: (json['name'] as String?) ?? '',
        summary: (json['summary'] as String?) ?? '',
        whyFits: (json['whyFits'] as String?) ?? '',
        averageWalkMinutes: (json['averageWalkMinutes'] as num?)?.toInt() ?? 0,
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

  TripSnapshot copyWith({
    String? destinationTitle,
    String? country,
    String? durationLabel,
    String? statusLabel,
    String? dates,
    String? transport,
    String? stay,
    List<String>? placeLabels,
    List<TripDaySnapshot>? days,
  }) {
    return TripSnapshot(
      destinationTitle: destinationTitle ?? this.destinationTitle,
      country: country ?? this.country,
      durationLabel: durationLabel ?? this.durationLabel,
      statusLabel: statusLabel ?? this.statusLabel,
      dates: dates ?? this.dates,
      transport: transport ?? this.transport,
      stay: stay ?? this.stay,
      placeLabels: placeLabels ?? this.placeLabels,
      days: days ?? this.days,
    );
  }

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
    this.placeCard,
    this.transport,
    this.stayZone,
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

  /// Present only on [ChatMessageKind.placeCard].
  final PlaceCard? placeCard;

  /// Present only on [ChatMessageKind.transport].
  final TransportCompare? transport;

  /// Present only on [ChatMessageKind.stayZone].
  final StayZoneInfo? stayZone;

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
        if (placeCard != null) 'placeCard': placeCard!.toJson(),
        if (transport != null) 'transport': transport!.toJson(),
        if (stayZone != null) 'stayZone': stayZone!.toJson(),
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
        placeCard: json['placeCard'] is Map<String, dynamic>
            ? PlaceCard.fromJson(json['placeCard'] as Map<String, dynamic>)
            : null,
        transport: json['transport'] is Map<String, dynamic>
            ? TransportCompare.fromJson(
                json['transport'] as Map<String, dynamic>)
            : null,
        stayZone: json['stayZone'] is Map<String, dynamic>
            ? StayZoneInfo.fromJson(json['stayZone'] as Map<String, dynamic>)
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