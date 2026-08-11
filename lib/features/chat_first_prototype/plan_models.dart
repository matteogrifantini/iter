// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

enum PurchaseState { estimate, selected, purchaseOpened, purchased }

enum PlanChangeOrigin { manual, chat, share }

enum PlanItemSource { iter, manual, chat, share }

@immutable
class MediaAttribution {
  const MediaAttribution({required this.author, required this.sourceUrl});

  final String author;
  final String sourceUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'author': author,
    'sourceUrl': sourceUrl,
  };

  factory MediaAttribution.fromJson(Map<String, dynamic> json) =>
      MediaAttribution(
        author: (json['author'] as String?) ?? '',
        sourceUrl: (json['sourceUrl'] as String?) ?? '',
      );
}

@immutable
class PlanMedia {
  const PlanMedia({
    this.imageUrl,
    this.reelUrl,
    this.photoAttribution,
    this.reelAttribution,
  });

  final String? imageUrl;
  final String? reelUrl;
  final MediaAttribution? photoAttribution;
  final MediaAttribution? reelAttribution;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (reelUrl != null) 'reelUrl': reelUrl,
    if (photoAttribution != null)
      'photoAttribution': photoAttribution!.toJson(),
    if (reelAttribution != null) 'reelAttribution': reelAttribution!.toJson(),
  };

  factory PlanMedia.fromJson(Map<String, dynamic> json) => PlanMedia(
    imageUrl: json['imageUrl'] as String?,
    reelUrl: json['reelUrl'] as String?,
    photoAttribution: _map(json['photoAttribution'], MediaAttribution.fromJson),
    reelAttribution: _map(json['reelAttribution'], MediaAttribution.fromJson),
  );
}

@immutable
class PlanPlaceDetails {
  const PlanPlaceDetails({
    required this.id,
    required this.title,
    this.description = '',
  });

  final String id;
  final String title;
  final String description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
  };

  factory PlanPlaceDetails.fromJson(Map<String, dynamic> json) =>
      PlanPlaceDetails(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
      );
}

@immutable
class TravelOption {
  const TravelOption({
    required this.id,
    required this.label,
    this.priceCents = 0,
    this.purchaseState = PurchaseState.estimate,
  });

  final String id;
  final String label;
  final int priceCents;
  final PurchaseState purchaseState;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'priceCents': priceCents,
    'purchaseState': purchaseState.name,
  };

  factory TravelOption.fromJson(Map<String, dynamic> json) => TravelOption(
    id: (json['id'] as String?) ?? '',
    label: (json['label'] as String?) ?? '',
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
    purchaseState:
        PurchaseState.values.asNameMap()[json['purchaseState']] ??
        PurchaseState.estimate,
  );
}

@immutable
class StayOption {
  const StayOption({
    required this.id,
    required this.label,
    this.priceCents = 0,
    this.purchaseState = PurchaseState.estimate,
  });

  final String id;
  final String label;
  final int priceCents;
  final PurchaseState purchaseState;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'priceCents': priceCents,
    'purchaseState': purchaseState.name,
  };

  factory StayOption.fromJson(Map<String, dynamic> json) => StayOption(
    id: (json['id'] as String?) ?? '',
    label: (json['label'] as String?) ?? '',
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
    purchaseState:
        PurchaseState.values.asNameMap()[json['purchaseState']] ??
        PurchaseState.estimate,
  );
}

@immutable
class TravelPlanSelection {
  const TravelPlanSelection({required this.option});

  final TravelOption option;

  Map<String, dynamic> toJson() => <String, dynamic>{'option': option.toJson()};

  factory TravelPlanSelection.fromJson(Map<String, dynamic> json) =>
      TravelPlanSelection(
        option:
            _map(json['option'], TravelOption.fromJson) ??
            const TravelOption(id: '', label: ''),
      );
}

@immutable
class StayPlanSelection {
  const StayPlanSelection({required this.option});

  final StayOption option;

  Map<String, dynamic> toJson() => <String, dynamic>{'option': option.toJson()};

  factory StayPlanSelection.fromJson(Map<String, dynamic> json) =>
      StayPlanSelection(
        option:
            _map(json['option'], StayOption.fromJson) ??
            const StayOption(id: '', label: ''),
      );
}

@immutable
class PlanCostSummary {
  const PlanCostSummary({
    String currencyCode = 'EUR',
    this.projectedTotalCents = 0,
  }) : currencyCode = 'EUR';

  final String currencyCode;
  final int projectedTotalCents;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currencyCode': currencyCode,
    'projectedTotalCents': projectedTotalCents,
  };

  factory PlanCostSummary.fromJson(Map<String, dynamic> json) =>
      PlanCostSummary(
        projectedTotalCents:
            (json['projectedTotalCents'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class PlanRevisionMetadata {
  const PlanRevisionMetadata({
    required this.id,
    required this.number,
    required this.timestamp,
    required this.origin,
    required this.label,
  });

  final String id;
  final int number;
  final DateTime timestamp;
  final PlanChangeOrigin origin;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'number': number,
    'timestamp': timestamp.toIso8601String(),
    'origin': origin.name,
    'label': label,
  };

  factory PlanRevisionMetadata.fromJson(Map<String, dynamic> json) =>
      PlanRevisionMetadata(
        id: (json['id'] as String?) ?? '',
        number: (json['number'] as num?)?.toInt() ?? 0,
        timestamp:
            DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        origin:
            PlanChangeOrigin.values.asNameMap()[json['origin']] ??
            PlanChangeOrigin.manual,
        label: (json['label'] as String?) ?? '',
      );
}

@immutable
class TripItemSnapshot {
  const TripItemSnapshot({
    this.id = '',
    required this.title,
    required this.category,
    String? time,
    String? startTime,
    this.durationMinutes = 0,
    this.source = PlanItemSource.iter,
    this.place,
    required this.locked,
  }) : startTime = startTime ?? time ?? '';

  final String id;
  final String title;
  final String category;
  final String startTime;
  final int durationMinutes;
  final PlanItemSource source;
  final PlanPlaceDetails? place;
  final bool locked;

  String get time => startTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'category': category,
    'startTime': startTime,
    'durationMinutes': durationMinutes,
    'source': source.name,
    if (place != null) 'place': place!.toJson(),
    'locked': locked,
  };

  factory TripItemSnapshot.fromJson(Map<String, dynamic> json) =>
      TripItemSnapshot(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        category: (json['category'] as String?) ?? '',
        startTime:
            (json['startTime'] as String?) ?? (json['time'] as String?) ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        source:
            PlanItemSource.values.asNameMap()[json['source']] ??
            PlanItemSource.iter,
        place: _map(json['place'], PlanPlaceDetails.fromJson),
        locked: (json['locked'] as bool?) ?? false,
      );
}

@immutable
class TripDaySnapshot {
  TripDaySnapshot({
    this.id = '',
    DateTime? date,
    required this.label,
    required this.theme,
    List<TripItemSnapshot> items = const <TripItemSnapshot>[],
  }) : _date = date,
       _items = List<TripItemSnapshot>.unmodifiable(items);

  final String id;
  final DateTime? _date;
  final String label;
  final String theme;
  final List<TripItemSnapshot> _items;

  DateTime get date =>
      _date ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  List<TripItemSnapshot> get items => _items;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    if (_date != null) 'date': _date.toIso8601String(),
    'label': label,
    'theme': theme,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };

  factory TripDaySnapshot.fromJson(Map<String, dynamic> json) =>
      TripDaySnapshot(
        id: (json['id'] as String?) ?? '',
        date: DateTime.tryParse((json['date'] as String?) ?? ''),
        label: (json['label'] as String?) ?? '',
        theme: (json['theme'] as String?) ?? '',
        items: _list(json['items'], TripItemSnapshot.fromJson),
      );
}

@immutable
class TripSnapshot {
  TripSnapshot({
    required this.destinationTitle,
    required this.country,
    required this.durationLabel,
    required this.statusLabel,
    required this.dates,
    required this.transport,
    required this.stay,
    List<String> placeLabels = const <String>[],
    List<TripDaySnapshot> days = const <TripDaySnapshot>[],
    this.revision = 1,
    this.revisionMetadata,
    this.destinationMedia,
    this.travelSelection,
    this.staySelection,
    this.costSummary = const PlanCostSummary(),
    List<TripItemSnapshot> unplacedItems = const <TripItemSnapshot>[],
  }) : _placeLabels = List<String>.unmodifiable(placeLabels),
       _days = List<TripDaySnapshot>.unmodifiable(days),
       _unplacedItems = List<TripItemSnapshot>.unmodifiable(unplacedItems);

  final String destinationTitle;
  final String country;
  final String durationLabel;
  final String statusLabel;
  final String dates;
  final String transport;
  final String stay;
  final int revision;
  final PlanRevisionMetadata? revisionMetadata;
  final PlanMedia? destinationMedia;
  final TravelPlanSelection? travelSelection;
  final StayPlanSelection? staySelection;
  final PlanCostSummary costSummary;
  final List<String> _placeLabels;
  final List<TripDaySnapshot> _days;
  final List<TripItemSnapshot> _unplacedItems;

  List<String> get placeLabels => _placeLabels;
  List<TripDaySnapshot> get days => _days;
  List<TripItemSnapshot> get unplacedItems => _unplacedItems;

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
    int? revision,
    PlanRevisionMetadata? revisionMetadata,
    PlanMedia? destinationMedia,
    TravelPlanSelection? travelSelection,
    StayPlanSelection? staySelection,
    PlanCostSummary? costSummary,
    List<TripItemSnapshot>? unplacedItems,
  }) => TripSnapshot(
    destinationTitle: destinationTitle ?? this.destinationTitle,
    country: country ?? this.country,
    durationLabel: durationLabel ?? this.durationLabel,
    statusLabel: statusLabel ?? this.statusLabel,
    dates: dates ?? this.dates,
    transport: transport ?? this.transport,
    stay: stay ?? this.stay,
    placeLabels: placeLabels ?? this.placeLabels,
    days: days ?? this.days,
    revision: revision ?? this.revision,
    revisionMetadata: revisionMetadata ?? this.revisionMetadata,
    destinationMedia: destinationMedia ?? this.destinationMedia,
    travelSelection: travelSelection ?? this.travelSelection,
    staySelection: staySelection ?? this.staySelection,
    costSummary: costSummary ?? this.costSummary,
    unplacedItems: unplacedItems ?? this.unplacedItems,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'destinationTitle': destinationTitle,
    'country': country,
    'durationLabel': durationLabel,
    'statusLabel': statusLabel,
    'dates': dates,
    'transport': transport,
    'stay': stay,
    'placeLabels': placeLabels,
    'days': days.map((day) => day.toJson()).toList(growable: false),
    'revision': revision,
    if (revisionMetadata != null)
      'revisionMetadata': revisionMetadata!.toJson(),
    if (destinationMedia != null)
      'destinationMedia': destinationMedia!.toJson(),
    if (travelSelection != null) 'travelSelection': travelSelection!.toJson(),
    if (staySelection != null) 'staySelection': staySelection!.toJson(),
    'costSummary': costSummary.toJson(),
    'unplacedItems': unplacedItems
        .map((item) => item.toJson())
        .toList(growable: false),
  };

  factory TripSnapshot.fromJson(Map<String, dynamic> json) => TripSnapshot(
    destinationTitle: (json['destinationTitle'] as String?) ?? '',
    country: (json['country'] as String?) ?? '',
    durationLabel: (json['durationLabel'] as String?) ?? '',
    statusLabel: (json['statusLabel'] as String?) ?? '',
    dates: (json['dates'] as String?) ?? '',
    transport: (json['transport'] as String?) ?? '',
    stay: (json['stay'] as String?) ?? '',
    placeLabels:
        (json['placeLabels'] as List<dynamic>?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[],
    days: _list(json['days'], TripDaySnapshot.fromJson),
    revision: json.containsKey('revision')
        ? (json['revision'] as num?)?.toInt() ?? 0
        : 0,
    revisionMetadata: _map(
      json['revisionMetadata'],
      PlanRevisionMetadata.fromJson,
    ),
    destinationMedia: _map(json['destinationMedia'], PlanMedia.fromJson),
    travelSelection: _map(
      json['travelSelection'],
      TravelPlanSelection.fromJson,
    ),
    staySelection: _map(json['staySelection'], StayPlanSelection.fromJson),
    costSummary:
        _map(json['costSummary'], PlanCostSummary.fromJson) ??
        const PlanCostSummary(),
    unplacedItems: _list(json['unplacedItems'], TripItemSnapshot.fromJson),
  );
}

T? _map<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  return value is Map<String, dynamic> ? parse(value) : null;
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List<dynamic>) return <T>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}
