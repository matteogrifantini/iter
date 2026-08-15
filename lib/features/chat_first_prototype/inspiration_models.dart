import 'package:flutter/foundation.dart';

enum InspirationPlatform { instagram, tiktok, generic }

@immutable
class InspirationDraft {
  const InspirationDraft({
    required this.platform,
    required this.url,
    required this.title,
    required this.placeName,
    required this.destinationId,
    required this.moment,
    required this.suggestedCategory,
    required this.mediaAsset,
  });

  final InspirationPlatform platform;
  final String url;
  final String title;
  final String placeName;
  final String destinationId;
  final String moment;
  final String suggestedCategory;
  final String mediaAsset;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'platform': platform.name,
    'url': url,
    'title': title,
    'placeName': placeName,
    'destinationId': destinationId,
    'moment': moment,
    'suggestedCategory': suggestedCategory,
    'mediaAsset': mediaAsset,
  };

  factory InspirationDraft.fromJson(Map<String, dynamic> json) {
    final platformName = json['platform'] as String?;
    return InspirationDraft(
      platform: InspirationPlatform.values.firstWhere(
        (value) => value.name == platformName,
        orElse: () => InspirationPlatform.generic,
      ),
      url: (json['url'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      placeName: (json['placeName'] as String?) ?? '',
      destinationId: (json['destinationId'] as String?) ?? '',
      moment: (json['moment'] as String?) ?? '',
      suggestedCategory: (json['suggestedCategory'] as String?) ?? '',
      mediaAsset: (json['mediaAsset'] as String?) ?? '',
    );
  }
}

@immutable
class SavedInspiration extends InspirationDraft {
  const SavedInspiration({
    required this.id,
    required this.conversationId,
    required this.savedAt,
    required this.attachedToPlan,
    required super.platform,
    required super.url,
    required super.title,
    required super.placeName,
    required super.destinationId,
    required super.moment,
    required super.suggestedCategory,
    required super.mediaAsset,
  });

  final String id;
  final String conversationId;
  final DateTime savedAt;
  final bool attachedToPlan;

  SavedInspiration copyWith({
    String? conversationId,
    DateTime? savedAt,
    bool? attachedToPlan,
  }) {
    return SavedInspiration(
      id: id,
      conversationId: conversationId ?? this.conversationId,
      savedAt: savedAt ?? this.savedAt,
      attachedToPlan: attachedToPlan ?? this.attachedToPlan,
      platform: platform,
      url: url,
      title: title,
      placeName: placeName,
      destinationId: destinationId,
      moment: moment,
      suggestedCategory: suggestedCategory,
      mediaAsset: mediaAsset,
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'conversationId': conversationId,
    'savedAt': savedAt.toIso8601String(),
    'attachedToPlan': attachedToPlan,
    ...super.toJson(),
  };

  factory SavedInspiration.fromJson(Map<String, dynamic> json) {
    final draft = InspirationDraft.fromJson(json);
    return SavedInspiration(
      id: (json['id'] as String?) ?? '',
      conversationId: (json['conversationId'] as String?) ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      attachedToPlan: (json['attachedToPlan'] as bool?) ?? false,
      platform: draft.platform,
      url: draft.url,
      title: draft.title,
      placeName: draft.placeName,
      destinationId: draft.destinationId,
      moment: draft.moment,
      suggestedCategory: draft.suggestedCategory,
      mediaAsset: draft.mediaAsset,
    );
  }
}

@immutable
class InspirationImportResult {
  const InspirationImportResult.valid(InspirationDraft this.draft)
    : errorMessage = null;

  const InspirationImportResult.error(this.errorMessage) : draft = null;

  final InspirationDraft? draft;
  final String? errorMessage;

  bool get isValid => draft != null;
}
