import 'package:flutter/foundation.dart';

import 'plan_models.dart';

typedef PlanPatchEffect = String;

enum PlanPatchKind { addPlace, moveStop, removeStop, changeTime, toggleLock }

enum PlanPatchStatus {
  requiresConfirmation,
  requiresStrongConfirmation,
  conflicted,
  stale,
  applied,
}

@immutable
class PlanPatchIntent {
  const PlanPatchIntent._({
    required this.kind,
    this.item,
    this.itemId,
    this.targetDayId,
    this.targetIndex,
    this.startTime,
  });

  const PlanPatchIntent.addPlace({
    required TripItemSnapshot item,
    String? targetDayId,
    int? targetIndex,
  }) : this._(
         kind: PlanPatchKind.addPlace,
         item: item,
         targetDayId: targetDayId,
         targetIndex: targetIndex,
       );

  const PlanPatchIntent.moveStop({
    required String itemId,
    required String targetDayId,
    required int targetIndex,
  }) : this._(
         kind: PlanPatchKind.moveStop,
         itemId: itemId,
         targetDayId: targetDayId,
         targetIndex: targetIndex,
       );

  const PlanPatchIntent.removeStop({required String itemId})
    : this._(kind: PlanPatchKind.removeStop, itemId: itemId);

  const PlanPatchIntent.changeTime({
    required String itemId,
    required String startTime,
  }) : this._(
         kind: PlanPatchKind.changeTime,
         itemId: itemId,
         startTime: startTime,
       );

  const PlanPatchIntent.toggleLock({required String itemId})
    : this._(kind: PlanPatchKind.toggleLock, itemId: itemId);

  final PlanPatchKind kind;
  final TripItemSnapshot? item;
  final String? itemId;
  final String? targetDayId;
  final int? targetIndex;
  final String? startTime;
}

@immutable
class PlanPatchPreview {
  PlanPatchPreview({
    required this.conversationId,
    required this.baseRevision,
    required this.intent,
    required this.before,
    required this.after,
    required List<PlanPatchEffect> effects,
    required List<String> conflicts,
    required this.status,
  }) : effects = List<PlanPatchEffect>.unmodifiable(effects),
       conflicts = List<String>.unmodifiable(conflicts);

  final String conversationId;
  final int baseRevision;
  final PlanPatchIntent intent;
  final TripSnapshot before;
  final TripSnapshot after;
  final List<PlanPatchEffect> effects;
  final List<String> conflicts;
  final PlanPatchStatus status;

  PlanPatchKind get kind => intent.kind;

  bool get requiresConfirmation =>
      status == PlanPatchStatus.requiresConfirmation ||
      status == PlanPatchStatus.requiresStrongConfirmation;

  bool get requiresStrongConfirmation =>
      status == PlanPatchStatus.requiresStrongConfirmation;

  bool get canApply => requiresConfirmation;

  PlanPatchPreview copyWith({
    TripSnapshot? before,
    TripSnapshot? after,
    List<PlanPatchEffect>? effects,
    List<String>? conflicts,
    PlanPatchStatus? status,
  }) => PlanPatchPreview(
    conversationId: conversationId,
    baseRevision: baseRevision,
    intent: intent,
    before: before ?? this.before,
    after: after ?? this.after,
    effects: effects ?? this.effects,
    conflicts: conflicts ?? this.conflicts,
    status: status ?? this.status,
  );
}

class PlanEditor {
  const PlanEditor();

  PlanPatchPreview previewAddPlace({
    required String conversationId,
    required TripSnapshot snapshot,
    required TripItemSnapshot item,
    String? targetDayId,
    int? targetIndex,
  }) => _preview(
    conversationId: conversationId,
    snapshot: snapshot,
    intent: PlanPatchIntent.addPlace(
      item: item,
      targetDayId: targetDayId,
      targetIndex: targetIndex,
    ),
  );

  PlanPatchPreview previewMoveStop({
    required String conversationId,
    required TripSnapshot snapshot,
    required String itemId,
    required String targetDayId,
    required int targetIndex,
  }) => _preview(
    conversationId: conversationId,
    snapshot: snapshot,
    intent: PlanPatchIntent.moveStop(
      itemId: itemId,
      targetDayId: targetDayId,
      targetIndex: targetIndex,
    ),
  );

  PlanPatchPreview previewRemoveStop({
    required String conversationId,
    required TripSnapshot snapshot,
    required String itemId,
  }) => _preview(
    conversationId: conversationId,
    snapshot: snapshot,
    intent: PlanPatchIntent.removeStop(itemId: itemId),
  );

  PlanPatchPreview previewChangeTime({
    required String conversationId,
    required TripSnapshot snapshot,
    required String itemId,
    required String startTime,
  }) => _preview(
    conversationId: conversationId,
    snapshot: snapshot,
    intent: PlanPatchIntent.changeTime(itemId: itemId, startTime: startTime),
  );

  PlanPatchPreview previewToggleLock({
    required String conversationId,
    required TripSnapshot snapshot,
    required String itemId,
  }) => _preview(
    conversationId: conversationId,
    snapshot: snapshot,
    intent: PlanPatchIntent.toggleLock(itemId: itemId),
  );

  PlanPatchPreview rebase({
    required PlanPatchPreview preview,
    required TripSnapshot current,
  }) => _preview(
    conversationId: preview.conversationId,
    snapshot: current,
    intent: preview.intent,
  );

  PlanPatchPreview apply({
    required PlanPatchPreview preview,
    required TripSnapshot current,
    required String currentConversationId,
    required DateTime timestamp,
    PlanChangeOrigin origin = PlanChangeOrigin.manual,
  }) {
    if (preview.conversationId != currentConversationId) {
      return preview.copyWith(
        before: current,
        after: current,
        conflicts: <String>['L’anteprima appartiene a un’altra conversazione'],
        status: PlanPatchStatus.stale,
      );
    }
    if (preview.baseRevision != current.revision) {
      return preview.copyWith(
        before: current,
        after: current,
        conflicts: <String>['Il piano è stato aggiornato'],
        status: PlanPatchStatus.stale,
      );
    }
    if (!preview.canApply) return preview;

    final nextRevision = current.revision + 1;
    final revised = preview.after.copyWith(
      revision: nextRevision,
      revisionMetadata: PlanRevisionMetadata(
        id: '${preview.conversationId}-r$nextRevision',
        number: nextRevision,
        timestamp: timestamp,
        origin: origin,
        label: _revisionLabel(preview.kind),
      ),
    );
    return preview.copyWith(
      before: current,
      after: revised,
      status: PlanPatchStatus.applied,
    );
  }

  PlanPatchPreview _preview({
    required String conversationId,
    required TripSnapshot snapshot,
    required PlanPatchIntent intent,
  }) {
    return switch (intent.kind) {
      PlanPatchKind.addPlace => _previewAdd(conversationId, snapshot, intent),
      PlanPatchKind.moveStop => _previewMove(conversationId, snapshot, intent),
      PlanPatchKind.removeStop => _previewRemove(
        conversationId,
        snapshot,
        intent,
      ),
      PlanPatchKind.changeTime => _previewTime(
        conversationId,
        snapshot,
        intent,
      ),
      PlanPatchKind.toggleLock => _previewLock(
        conversationId,
        snapshot,
        intent,
      ),
    };
  }

  PlanPatchPreview _previewAdd(
    String conversationId,
    TripSnapshot snapshot,
    PlanPatchIntent intent,
  ) {
    final item = intent.item!;
    if (_allItems(snapshot).any((existing) => existing.id == item.id)) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        '${item.title} è già nel piano',
      );
    }

    if (intent.targetDayId == null) {
      final after = snapshot.copyWith(
        unplacedItems: <TripItemSnapshot>[...snapshot.unplacedItems, item],
      );
      return _result(conversationId, snapshot, intent, after, <PlanPatchEffect>[
        '${item.title} va in Da sistemare',
      ]);
    }

    final dayIndex = _dayIndex(snapshot, intent.targetDayId!);
    if (dayIndex < 0) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La giornata ${intent.targetDayId} non esiste',
      );
    }
    final day = snapshot.days[dayIndex];
    final insertionIndex = intent.targetIndex ?? day.items.length;
    if (insertionIndex < 0 || insertionIndex > day.items.length) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'Lo slot richiesto non è disponibile',
      );
    }

    final changedItems = <TripItemSnapshot>[...day.items]
      ..insert(insertionIndex, item);
    final recalculated = _recalculate(
      changedItems,
      _anchorFor(day.items, item),
    );
    if (recalculated == null) {
      return _scheduleOverflow(conversationId, snapshot, intent);
    }
    final days = <TripDaySnapshot>[...snapshot.days];
    days[dayIndex] = _withItems(day, recalculated);
    final after = snapshot.copyWith(days: days);
    return _result(conversationId, snapshot, intent, after, <PlanPatchEffect>[
      '${item.title} entra in ${day.label}',
      ..._timeEffects(snapshot, after),
    ]);
  }

  PlanPatchPreview _previewMove(
    String conversationId,
    TripSnapshot snapshot,
    PlanPatchIntent intent,
  ) {
    final location = _find(snapshot, intent.itemId!);
    if (location == null) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La tappa ${intent.itemId} non esiste',
      );
    }
    final targetDayIndex = _dayIndex(snapshot, intent.targetDayId!);
    if (targetDayIndex < 0) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La giornata ${intent.targetDayId} non esiste',
      );
    }

    final days = <TripDaySnapshot>[...snapshot.days];
    final unplaced = <TripItemSnapshot>[...snapshot.unplacedItems];
    final originalAnchors = <int, String>{};
    for (var index = 0; index < days.length; index++) {
      originalAnchors[index] = _anchorFor(days[index].items, location.item);
    }

    if (location.dayIndex == null) {
      unplaced.removeAt(location.itemIndex);
    } else {
      final source = days[location.dayIndex!];
      final sourceItems = <TripItemSnapshot>[...source.items]
        ..removeAt(location.itemIndex);
      days[location.dayIndex!] = _withItems(source, sourceItems);
    }

    final target = days[targetDayIndex];
    final targetItems = <TripItemSnapshot>[...target.items];
    final targetIndex = intent.targetIndex!;
    if (targetIndex < 0 || targetIndex > targetItems.length) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'Lo slot richiesto non è disponibile',
      );
    }
    targetItems.insert(targetIndex, location.item);
    days[targetDayIndex] = _withItems(target, targetItems);

    final changedDayIndexes = <int>{targetDayIndex};
    if (location.dayIndex != null) changedDayIndexes.add(location.dayIndex!);
    for (final index in changedDayIndexes) {
      final recalculated = _recalculate(
        days[index].items,
        originalAnchors[index]!,
      );
      if (recalculated == null) {
        return _scheduleOverflow(conversationId, snapshot, intent);
      }
      days[index] = _withItems(days[index], recalculated);
    }

    final after = snapshot.copyWith(days: days, unplacedItems: unplaced);
    final effects = <PlanPatchEffect>[
      '${location.item.title} si sposta in ${snapshot.days[targetDayIndex].label}',
      ..._timeEffects(snapshot, after),
    ];
    return _result(conversationId, snapshot, intent, after, effects);
  }

  PlanPatchPreview _previewRemove(
    String conversationId,
    TripSnapshot snapshot,
    PlanPatchIntent intent,
  ) {
    final location = _find(snapshot, intent.itemId!);
    if (location == null) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La tappa ${intent.itemId} non esiste',
      );
    }

    final days = <TripDaySnapshot>[...snapshot.days];
    final unplaced = <TripItemSnapshot>[...snapshot.unplacedItems];
    if (location.dayIndex == null) {
      unplaced.removeAt(location.itemIndex);
    } else {
      final day = days[location.dayIndex!];
      final items = <TripItemSnapshot>[...day.items]
        ..removeAt(location.itemIndex);
      final recalculated = _recalculate(
        items,
        _anchorFor(day.items, location.item),
      );
      if (recalculated == null) {
        return _scheduleOverflow(conversationId, snapshot, intent);
      }
      days[location.dayIndex!] = _withItems(day, recalculated);
    }
    final after = snapshot.copyWith(days: days, unplacedItems: unplaced);
    final effects = <PlanPatchEffect>[
      '${location.item.title} viene rimosso dal piano',
      ..._timeEffects(snapshot, after),
    ];
    return _result(conversationId, snapshot, intent, after, effects);
  }

  PlanPatchPreview _previewTime(
    String conversationId,
    TripSnapshot snapshot,
    PlanPatchIntent intent,
  ) {
    final location = _find(snapshot, intent.itemId!);
    if (location == null || location.dayIndex == null) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La tappa ${intent.itemId} non è in una giornata',
      );
    }
    if (_minutes(intent.startTime!) == null) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'L’orario ${intent.startTime} non è valido',
      );
    }

    final day = snapshot.days[location.dayIndex!];
    final changed = _withItem(location.item, startTime: intent.startTime);
    final items = <TripItemSnapshot>[...day.items];
    items[location.itemIndex] = changed;
    final days = <TripDaySnapshot>[...snapshot.days];
    days[location.dayIndex!] = _withItems(day, items);
    final after = snapshot.copyWith(days: days);
    final conflicts = _overlaps(changed, items);
    if (conflicts.isNotEmpty) {
      return PlanPatchPreview(
        conversationId: conversationId,
        baseRevision: snapshot.revision,
        intent: intent,
        before: snapshot,
        after: after,
        effects: <PlanPatchEffect>[
          '${changed.title} passa dalle ${location.item.startTime} alle ${changed.startTime}',
        ],
        conflicts: conflicts,
        status: PlanPatchStatus.conflicted,
      );
    }

    final effects = <PlanPatchEffect>[
      '${changed.title} passa dalle ${location.item.startTime} alle ${changed.startTime}',
    ];
    return _result(conversationId, snapshot, intent, after, effects);
  }

  PlanPatchPreview _previewLock(
    String conversationId,
    TripSnapshot snapshot,
    PlanPatchIntent intent,
  ) {
    final location = _find(snapshot, intent.itemId!);
    if (location == null) {
      return _conflict(
        conversationId,
        snapshot,
        intent,
        'La tappa ${intent.itemId} non esiste',
      );
    }

    final changed = _withItem(location.item, locked: !location.item.locked);
    final days = <TripDaySnapshot>[...snapshot.days];
    final unplaced = <TripItemSnapshot>[...snapshot.unplacedItems];
    if (location.dayIndex == null) {
      unplaced[location.itemIndex] = changed;
    } else {
      final day = days[location.dayIndex!];
      final items = <TripItemSnapshot>[...day.items];
      items[location.itemIndex] = changed;
      days[location.dayIndex!] = _withItems(day, items);
    }
    final after = snapshot.copyWith(days: days, unplacedItems: unplaced);
    return _result(conversationId, snapshot, intent, after, <PlanPatchEffect>[
      changed.locked
          ? '${changed.title} viene bloccato'
          : '${changed.title} viene sbloccato',
    ]);
  }
}

PlanPatchPreview _result(
  String conversationId,
  TripSnapshot before,
  PlanPatchIntent intent,
  TripSnapshot after,
  List<PlanPatchEffect> effects,
) {
  final changes = _changedItems(before, after);
  final lockedTitles = <String>{
    for (final change in changes)
      if (change.before?.locked == true || change.after?.locked == true)
        (change.before ?? change.after!).title,
  };
  final purchasedOptionIds = _purchasedOptionIds(before);
  final affectsPurchase = changes.any(
    (change) => <TripItemSnapshot?>[change.before, change.after]
        .whereType<TripItemSnapshot>()
        .any(
          (item) =>
              item.linkedPurchaseOptionIds.any(purchasedOptionIds.contains),
        ),
  );
  final strong = lockedTitles.isNotEmpty || affectsPurchase;
  return PlanPatchPreview(
    conversationId: conversationId,
    baseRevision: before.revision,
    intent: intent,
    before: before,
    after: after,
    effects: <PlanPatchEffect>[
      ...effects,
      for (final title in lockedTitles)
        if (!effects.contains('$title è bloccato')) '$title è bloccato',
      if (affectsPurchase &&
          !effects.contains('Il piano include una scelta acquistata'))
        'Il piano include una scelta acquistata',
    ],
    conflicts: const <String>[],
    status: strong
        ? PlanPatchStatus.requiresStrongConfirmation
        : PlanPatchStatus.requiresConfirmation,
  );
}

PlanPatchPreview _conflict(
  String conversationId,
  TripSnapshot snapshot,
  PlanPatchIntent intent,
  String conflict,
) => PlanPatchPreview(
  conversationId: conversationId,
  baseRevision: snapshot.revision,
  intent: intent,
  before: snapshot,
  after: snapshot,
  effects: const <PlanPatchEffect>[],
  conflicts: <String>[conflict],
  status: PlanPatchStatus.conflicted,
);

PlanPatchPreview _scheduleOverflow(
  String conversationId,
  TripSnapshot snapshot,
  PlanPatchIntent intent,
) => _conflict(
  conversationId,
  snapshot,
  intent,
  'Il ricalcolo supera la fine della giornata',
);

List<TripItemSnapshot> _allItems(TripSnapshot snapshot) => <TripItemSnapshot>[
  for (final day in snapshot.days) ...day.items,
  ...snapshot.unplacedItems,
];

int _dayIndex(TripSnapshot snapshot, String id) =>
    snapshot.days.indexWhere((day) => day.id == id);

_ItemLocation? _find(TripSnapshot snapshot, String id) {
  for (var dayIndex = 0; dayIndex < snapshot.days.length; dayIndex++) {
    final itemIndex = snapshot.days[dayIndex].items.indexWhere(
      (item) => item.id == id,
    );
    if (itemIndex >= 0) {
      return _ItemLocation(
        dayIndex: dayIndex,
        itemIndex: itemIndex,
        item: snapshot.days[dayIndex].items[itemIndex],
      );
    }
  }
  final itemIndex = snapshot.unplacedItems.indexWhere((item) => item.id == id);
  if (itemIndex < 0) return null;
  return _ItemLocation(
    dayIndex: null,
    itemIndex: itemIndex,
    item: snapshot.unplacedItems[itemIndex],
  );
}

String _anchorFor(List<TripItemSnapshot> items, TripItemSnapshot fallback) =>
    items.isEmpty ? fallback.startTime : items.first.startTime;

List<TripItemSnapshot>? _recalculate(
  List<TripItemSnapshot> items,
  String anchor,
) {
  if (items.isEmpty) return const <TripItemSnapshot>[];
  var next = _minutes(anchor) ?? _minutes(items.first.startTime) ?? 0;
  final recalculated = <TripItemSnapshot>[];
  for (final item in items) {
    if (next > 23 * 60 + 59 ||
        item.durationMinutes < 0 ||
        next + item.durationMinutes > 24 * 60) {
      return null;
    }
    recalculated.add(_withItem(item, startTime: _formatMinutes(next)));
    next += item.durationMinutes;
  }
  return List<TripItemSnapshot>.unmodifiable(recalculated);
}

TripDaySnapshot _withItems(TripDaySnapshot day, List<TripItemSnapshot> items) {
  final json = Map<String, dynamic>.of(day.toJson());
  json['items'] = items.map((item) => item.toJson()).toList(growable: false);
  return TripDaySnapshot.fromJson(json);
}

TripItemSnapshot _withItem(
  TripItemSnapshot item, {
  String? startTime,
  bool? locked,
}) {
  final json = Map<String, dynamic>.of(item.toJson());
  if (startTime != null) json['startTime'] = startTime;
  if (locked != null) json['locked'] = locked;
  return TripItemSnapshot.fromJson(json);
}

List<PlanPatchEffect> _timeEffects(TripSnapshot before, TripSnapshot after) {
  final beforeItems = <String, TripItemSnapshot>{
    for (final item in _allItems(before)) item.id: item,
  };
  final effects = <PlanPatchEffect>[];
  for (final item in _allItems(after)) {
    final previous = beforeItems[item.id];
    final oldMinutes = previous == null ? null : _minutes(previous.startTime);
    final newMinutes = _minutes(item.startTime);
    if (oldMinutes == null || newMinutes == null || oldMinutes == newMinutes) {
      continue;
    }
    final difference = newMinutes - oldMinutes;
    effects.add(
      difference > 0
          ? '${item.title} slitta di $difference min'
          : '${item.title} anticipa di ${-difference} min',
    );
  }
  return effects;
}

List<String> _overlaps(TripItemSnapshot changed, List<TripItemSnapshot> items) {
  final changedStart = _minutes(changed.startTime)!;
  final changedEnd = changedStart + changed.durationMinutes;
  final conflicts = <String>[];
  for (final other in items) {
    if (identical(other, changed) || other.id == changed.id) continue;
    final otherStart = _minutes(other.startTime);
    if (otherStart == null) continue;
    final otherEnd = otherStart + other.durationMinutes;
    if (changedStart < otherEnd && otherStart < changedEnd) {
      conflicts.add('${changed.title} si sovrappone a ${other.title}');
    }
  }
  return conflicts;
}

Set<String> _purchasedOptionIds(TripSnapshot snapshot) => <String>{
  if (snapshot.travelSelection?.option.purchaseState == PurchaseState.purchased)
    snapshot.travelSelection!.option.id,
  if (snapshot.staySelection?.option.purchaseState == PurchaseState.purchased)
    snapshot.staySelection!.option.id,
};

int? _minutes(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}

String _formatMinutes(int value) {
  final hours = value ~/ 60;
  final minutes = value % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String _revisionLabel(PlanPatchKind kind) => switch (kind) {
  PlanPatchKind.addPlace => 'Luogo aggiunto',
  PlanPatchKind.moveStop => 'Tappa spostata',
  PlanPatchKind.removeStop => 'Tappa rimossa',
  PlanPatchKind.changeTime => 'Orario modificato',
  PlanPatchKind.toggleLock => 'Vincolo modificato',
};

@immutable
class _ItemLocation {
  const _ItemLocation({
    required this.dayIndex,
    required this.itemIndex,
    required this.item,
  });

  final int? dayIndex;
  final int itemIndex;
  final TripItemSnapshot item;
}

List<_ItemChange> _changedItems(TripSnapshot before, TripSnapshot after) {
  final beforeItems = _itemStates(before);
  final afterItems = _itemStates(after);
  final changes = <_ItemChange>[];
  for (final id in <String>{...beforeItems.keys, ...afterItems.keys}) {
    final previous = beforeItems[id];
    final next = afterItems[id];
    if (previous == null ||
        next == null ||
        previous.location != next.location ||
        previous.item.startTime != next.item.startTime ||
        previous.item.locked != next.item.locked) {
      changes.add(_ItemChange(before: previous?.item, after: next?.item));
    }
  }
  return changes;
}

Map<String, _ItemState> _itemStates(TripSnapshot snapshot) =>
    <String, _ItemState>{
      for (final day in snapshot.days)
        for (var index = 0; index < day.items.length; index++)
          day.items[index].id: _ItemState(
            item: day.items[index],
            location: '${day.id}:$index',
          ),
      for (var index = 0; index < snapshot.unplacedItems.length; index++)
        snapshot.unplacedItems[index].id: _ItemState(
          item: snapshot.unplacedItems[index],
          location: 'unplaced:$index',
        ),
    };

@immutable
class _ItemState {
  const _ItemState({required this.item, required this.location});

  final TripItemSnapshot item;
  final String location;
}

@immutable
class _ItemChange {
  const _ItemChange({required this.before, required this.after});

  final TripItemSnapshot? before;
  final TripItemSnapshot? after;
}
