import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'plan_models.dart';

export 'plan_models.dart';

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
        (json['snapshot'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
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
    final needsPatch =
        title != conversation.title || avatarAsset != conversation.avatar.asset;
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
        options:
            (json['options'] as List<dynamic>?)
                ?.map(
                  (o) =>
                      TransportOptionView.fromJson(o as Map<String, dynamic>),
                )
                .toList(growable: false) ??
            const <TransportOptionView>[],
      );
}

/// Complete, deterministic flight inventory rendered inside the chat. It keeps
/// the practical information next to the explicit planning choice.
@immutable
class FlightCompare {
  const FlightCompare({
    required this.options,
    required this.recommendedId,
    required this.quotedAt,
    this.travelDateLabel = '',
    this.travelDateReason = '',
    this.recommendationReason = '',
  });

  final List<FlightOptionInfo> options;
  final String recommendedId;
  final DateTime quotedAt;
  final String travelDateLabel;
  final String travelDateReason;
  final String recommendationReason;

  FlightOptionInfo get recommended =>
      options.firstWhere((option) => option.id == recommendedId);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'options': options.map((option) => option.toJson()).toList(growable: false),
    'recommendedId': recommendedId,
    'quotedAt': quotedAt.toIso8601String(),
    'travelDateLabel': travelDateLabel,
    'travelDateReason': travelDateReason,
    'recommendationReason': recommendationReason,
  };

  factory FlightCompare.fromJson(Map<String, dynamic> json) => FlightCompare(
    options:
        (json['options'] as List<dynamic>?)
            ?.map(
              (item) => FlightOptionInfo.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        const <FlightOptionInfo>[],
    recommendedId: (json['recommendedId'] as String?) ?? '',
    quotedAt:
        DateTime.tryParse((json['quotedAt'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    travelDateLabel: (json['travelDateLabel'] as String?) ?? '',
    travelDateReason: (json['travelDateReason'] as String?) ?? '',
    recommendationReason: (json['recommendationReason'] as String?) ?? '',
  );
}

@immutable
class FlightOptionInfo {
  const FlightOptionInfo({
    required this.id,
    required this.provider,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureAt,
    required this.arrivalAt,
    required this.durationMinutes,
    required this.stops,
    required this.baggage,
    required this.priceCents,
    required this.tradeoff,
  });

  final String id;
  final String provider;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final int durationMinutes;
  final int stops;
  final String baggage;
  final int priceCents;
  final String tradeoff;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'provider': provider,
    'departureAirport': departureAirport,
    'arrivalAirport': arrivalAirport,
    'departureAt': departureAt.toIso8601String(),
    'arrivalAt': arrivalAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'stops': stops,
    'baggage': baggage,
    'priceCents': priceCents,
    'tradeoff': tradeoff,
  };

  factory FlightOptionInfo.fromJson(Map<String, dynamic> json) =>
      FlightOptionInfo(
        id: (json['id'] as String?) ?? '',
        provider: (json['provider'] as String?) ?? '',
        departureAirport: (json['departureAirport'] as String?) ?? '',
        arrivalAirport: (json['arrivalAirport'] as String?) ?? '',
        departureAt:
            DateTime.tryParse((json['departureAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        arrivalAt:
            DateTime.tryParse((json['arrivalAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        stops: (json['stops'] as num?)?.toInt() ?? 0,
        baggage: (json['baggage'] as String?) ?? '',
        priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
        tradeoff: (json['tradeoff'] as String?) ?? '',
      );
}

@immutable
class StayCompare {
  const StayCompare({
    required this.options,
    required this.recommendedId,
    this.stayDatesLabel = '',
    this.recommendationReason = '',
  });
  final List<StayOptionInfo> options;
  final String recommendedId;
  final String stayDatesLabel;
  final String recommendationReason;
  StayOptionInfo get recommended =>
      options.firstWhere((option) => option.id == recommendedId);
  Map<String, dynamic> toJson() => <String, dynamic>{
    'options': options.map((option) => option.toJson()).toList(growable: false),
    'recommendedId': recommendedId,
    'stayDatesLabel': stayDatesLabel,
    'recommendationReason': recommendationReason,
  };
  factory StayCompare.fromJson(Map<String, dynamic> json) => StayCompare(
    options:
        (json['options'] as List<dynamic>?)
            ?.map(
              (item) => StayOptionInfo.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        const <StayOptionInfo>[],
    recommendedId: (json['recommendedId'] as String?) ?? '',
    stayDatesLabel: (json['stayDatesLabel'] as String?) ?? '',
    recommendationReason: (json['recommendationReason'] as String?) ?? '',
  );
}

@immutable
class StayOptionInfo {
  const StayOptionInfo({
    required this.id,
    required this.name,
    required this.zone,
    required this.nights,
    required this.priceCents,
    required this.conditions,
    required this.averageWalkMinutes,
    required this.atmosphere,
    required this.tradeoff,
    required this.provider,
  });
  final String id;
  final String name;
  final String zone;
  final int nights;
  final int priceCents;
  final String conditions;
  final int averageWalkMinutes;
  final String atmosphere;
  final String tradeoff;
  final String provider;
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'zone': zone,
    'nights': nights,
    'priceCents': priceCents,
    'conditions': conditions,
    'averageWalkMinutes': averageWalkMinutes,
    'atmosphere': atmosphere,
    'tradeoff': tradeoff,
    'provider': provider,
  };
  factory StayOptionInfo.fromJson(Map<String, dynamic> json) => StayOptionInfo(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    zone: (json['zone'] as String?) ?? '',
    nights: (json['nights'] as num?)?.toInt() ?? 0,
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
    conditions: (json['conditions'] as String?) ?? '',
    averageWalkMinutes: (json['averageWalkMinutes'] as num?)?.toInt() ?? 0,
    atmosphere: (json['atmosphere'] as String?) ?? '',
    tradeoff: (json['tradeoff'] as String?) ?? '',
    provider: (json['provider'] as String?) ?? '',
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
    this.flightCompare,
    this.stayCompare,
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

  /// Complete operational alternatives, available only on the F5 chat beats.
  final FlightCompare? flightCompare;
  final StayCompare? stayCompare;

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
    if (flightCompare != null) 'flightCompare': flightCompare!.toJson(),
    if (stayCompare != null) 'stayCompare': stayCompare!.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] as String?) ?? '',
    role: ChatRole.values.asNameMap()[json['role']] ?? ChatRole.assistant,
    kind:
        ChatMessageKind.values.asNameMap()[json['kind']] ??
        ChatMessageKind.text,
    text: (json['text'] as String?) ?? '',
    sentAt:
        DateTime.tryParse((json['sentAt'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    media: json['media'] is Map<String, dynamic>
        ? ChatMedia.fromJson(json['media'] as Map<String, dynamic>)
        : null,
    choices:
        (json['choices'] as List<dynamic>?)
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
        ? TransportCompare.fromJson(json['transport'] as Map<String, dynamic>)
        : null,
    stayZone: json['stayZone'] is Map<String, dynamic>
        ? StayZoneInfo.fromJson(json['stayZone'] as Map<String, dynamic>)
        : null,
    flightCompare: json['flightCompare'] is Map<String, dynamic>
        ? FlightCompare.fromJson(json['flightCompare'] as Map<String, dynamic>)
        : null,
    stayCompare: json['stayCompare'] is Map<String, dynamic>
        ? StayCompare.fromJson(json['stayCompare'] as Map<String, dynamic>)
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
    String? title,
    int? unread,
    String? lastPreview,
    TripSnapshot? snapshot,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
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
    timestamp:
        DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    unread: (json['unread'] as num?)?.toInt() ?? 0,
    lastPreview: (json['lastPreview'] as String?) ?? '',
    snapshot: json['snapshot'] is Map<String, dynamic>
        ? TripSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>)
        : null,
    isTrending: (json['isTrending'] as bool?) ?? false,
  );
}
