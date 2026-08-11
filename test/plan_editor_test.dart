import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/plan_editor.dart';
import 'package:iter/features/chat_first_prototype/plan_models.dart';

void main() {
  group('PlanEditor previews', () {
    const editor = PlanEditor();

    test('adds a place in the requested slot and recalculates later times', () {
      final snapshot = _snapshot();
      const jardim = TripItemSnapshot(
        id: 'jardim',
        title: 'Jardim do Morro',
        category: 'Panorama',
        startTime: '18:00',
        durationMinutes: 30,
        locked: false,
      );

      final preview = editor.previewAddPlace(
        conversationId: 'c-porto',
        snapshot: snapshot,
        item: jardim,
        targetDayId: 'day-1',
        targetIndex: 1,
      );

      expect(preview.kind, PlanPatchKind.addPlace);
      expect(preview.status, PlanPatchStatus.requiresConfirmation);
      expect(preview.after.days.first.items.map((item) => item.id), <String>[
        'lello',
        'jardim',
        'clerigos',
      ]);
      expect(preview.after.days.first.items[1].startTime, '09:45');
      expect(preview.after.days.first.items[2].startTime, '10:15');
      expect(preview.effects, contains('Clérigos slitta di 30 min'));
      expect(snapshot.days.first.items[1].startTime, '09:45');
    });

    test('adds a place to Da sistemare when no day is selected', () {
      final snapshot = _snapshot();
      const jardim = TripItemSnapshot(
        id: 'jardim',
        title: 'Jardim do Morro',
        category: 'Panorama',
        startTime: '18:00',
        durationMinutes: 30,
        locked: false,
      );

      final preview = editor.previewAddPlace(
        conversationId: 'c-porto',
        snapshot: snapshot,
        item: jardim,
      );

      expect(preview.after.unplacedItems.single.id, 'jardim');
      expect(
        preview.after.days.map((day) => day.toJson()),
        snapshot.days.map((day) => day.toJson()),
      );
      expect(preview.effects, contains('Jardim do Morro va in Da sistemare'));
    });

    test(
      'moves a stop without mutating the source and reports time shifts',
      () {
        final snapshot = _snapshot();
        final originalJson = snapshot.toJson();

        final preview = editor.previewMoveStop(
          conversationId: 'c-porto',
          snapshot: snapshot,
          itemId: 'lello',
          targetDayId: 'day-2',
          targetIndex: 1,
        );

        expect(preview.baseRevision, snapshot.revision);
        expect(snapshot.days.first.items.first.id, 'lello');
        expect(preview.effects, contains('Ribeira slitta di 45 min'));
        expect(preview.after.days[1].items.map((item) => item.id), <String>[
          'foz',
          'lello',
          'ribeira',
        ]);
        expect(snapshot.toJson(), originalJson);
      },
    );

    test('reports a conflict when a changed time overlaps another stop', () {
      final snapshot = _snapshot();

      final preview = editor.previewChangeTime(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'clerigos',
        startTime: '09:15',
      );

      expect(preview.status, PlanPatchStatus.conflicted);
      expect(preview.conflicts, contains('Clérigos si sovrappone a Lello'));
      expect(preview.canApply, isFalse);
      expect(snapshot.days.first.items[1].startTime, '09:45');
    });

    test('requires strong confirmation for locked stops', () {
      final snapshot = _snapshot(lockedItemId: 'lello');

      final preview = editor.previewMoveStop(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'lello',
        targetDayId: 'day-2',
        targetIndex: 1,
      );

      expect(preview.status, PlanPatchStatus.requiresStrongConfirmation);
      expect(preview.requiresStrongConfirmation, isTrue);
      expect(preview.effects, contains('Lello è bloccato'));
    });

    test(
      'requires strong confirmation when a downstream locked stop shifts',
      () {
        final snapshot = _snapshot(lockedItemId: 'clerigos');
        const jardim = TripItemSnapshot(
          id: 'jardim',
          title: 'Jardim do Morro',
          category: 'Panorama',
          durationMinutes: 30,
          locked: false,
        );

        final preview = editor.previewAddPlace(
          conversationId: 'c-porto',
          snapshot: snapshot,
          item: jardim,
          targetDayId: 'day-1',
          targetIndex: 1,
        );

        expect(preview.after.days.first.items.last.startTime, '10:15');
        expect(preview.status, PlanPatchStatus.requiresStrongConfirmation);
        expect(preview.effects, contains('Clérigos è bloccato'));
      },
    );

    test(
      'requires strong confirmation when a changed stop links a purchase',
      () {
        final snapshot = _snapshot(
          hasPurchasedSelection: true,
          linkedPurchaseItemId: 'clerigos',
        );

        final preview = editor.previewChangeTime(
          conversationId: 'c-porto',
          snapshot: snapshot,
          itemId: 'clerigos',
          startTime: '12:00',
        );

        expect(preview.status, PlanPatchStatus.requiresStrongConfirmation);
        expect(
          preview.effects,
          contains('Il piano include una scelta acquistata'),
        );
      },
    );

    test('keeps normal confirmation for an unrelated purchased choice', () {
      final snapshot = _snapshot(hasPurchasedSelection: true);

      final preview = editor.previewChangeTime(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'clerigos',
        startTime: '12:00',
      );

      expect(preview.status, PlanPatchStatus.requiresConfirmation);
      expect(
        preview.effects,
        isNot(contains('Il piano include una scelta acquistata')),
      );
    });

    test('always requires confirmation before removing an unlocked stop', () {
      final snapshot = _snapshot();

      final preview = editor.previewRemoveStop(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'clerigos',
      );

      expect(preview.kind, PlanPatchKind.removeStop);
      expect(preview.status, PlanPatchStatus.requiresConfirmation);
      expect(preview.requiresConfirmation, isTrue);
      expect(preview.after.days.first.items.map((item) => item.id), <String>[
        'lello',
      ]);
    });

    test('changes a stop time when the requested slot is free', () {
      final snapshot = _snapshot();

      final preview = editor.previewChangeTime(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'clerigos',
        startTime: '12:00',
      );

      expect(preview.kind, PlanPatchKind.changeTime);
      expect(preview.status, PlanPatchStatus.requiresConfirmation);
      expect(preview.after.days.first.items[1].startTime, '12:00');
      expect(
        preview.effects,
        contains('Clérigos passa dalle 09:45 alle 12:00'),
      );
    });

    test('locks and unlocks a stop through immutable previews', () {
      final snapshot = _snapshot();

      final locked = editor.previewToggleLock(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'lello',
      );
      final unlocked = editor.previewToggleLock(
        conversationId: 'c-porto',
        snapshot: locked.after,
        itemId: 'lello',
      );

      expect(locked.after.days.first.items.first.locked, isTrue);
      expect(locked.status, PlanPatchStatus.requiresStrongConfirmation);
      expect(unlocked.after.days.first.items.first.locked, isFalse);
      expect(unlocked.status, PlanPatchStatus.requiresStrongConfirmation);
      expect(snapshot.days.first.items.first.locked, isFalse);
    });

    test('rejects schedule recalculation beyond the end of the day', () {
      final snapshot = _snapshotWithLateSchedule();
      const lateStop = TripItemSnapshot(
        id: 'late-stop',
        title: 'Passeggiata notturna',
        category: 'Passeggiata',
        durationMinutes: 90,
        locked: false,
      );

      final preview = editor.previewAddPlace(
        conversationId: 'c-porto',
        snapshot: snapshot,
        item: lateStop,
        targetDayId: 'day-1',
        targetIndex: 1,
      );

      expect(preview.status, PlanPatchStatus.conflicted);
      expect(preview.canApply, isFalse);
      expect(preview.conflicts, isNotEmpty);
      expect(preview.after, same(snapshot));
    });
  });

  group('PlanEditor revisions', () {
    const editor = PlanEditor();

    test('rejects stale apply and rebase recalculates the same intent', () {
      final snapshot = _snapshot();
      final preview = editor.previewMoveStop(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'lello',
        targetDayId: 'day-2',
        targetIndex: 1,
      );
      final current = snapshot.copyWith(revision: snapshot.revision + 1);

      final stale = editor.apply(
        preview: preview,
        current: current,
        currentConversationId: 'c-porto',
        timestamp: DateTime.utc(2026, 8, 11, 10),
      );
      final rebased = editor.rebase(preview: preview, current: current);

      expect(stale.status, PlanPatchStatus.stale);
      expect(stale.after, same(current));
      expect(rebased.baseRevision, current.revision);
      expect(rebased.intent, preview.intent);
      expect(rebased.after.days[1].items.map((item) => item.id), <String>[
        'foz',
        'lello',
        'ribeira',
      ]);
    });

    test('apply increments revision and creates deterministic metadata', () {
      final snapshot = _snapshot();
      final preview = editor.previewRemoveStop(
        conversationId: 'c-porto',
        snapshot: snapshot,
        itemId: 'clerigos',
      );

      final applied = editor.apply(
        preview: preview,
        current: snapshot,
        currentConversationId: 'c-porto',
        timestamp: DateTime.utc(2026, 8, 11, 10),
        origin: PlanChangeOrigin.chat,
      );

      expect(applied.status, PlanPatchStatus.applied);
      expect(applied.before, same(snapshot));
      expect(applied.after.revision, 4);
      expect(applied.after.revisionMetadata!.id, 'c-porto-r4');
      expect(applied.after.revisionMetadata!.number, 4);
      expect(
        applied.after.revisionMetadata!.timestamp,
        DateTime.utc(2026, 8, 11, 10),
      );
      expect(applied.after.revisionMetadata!.origin, PlanChangeOrigin.chat);
      expect(snapshot.revision, 3);
      expect(snapshot.days.first.items.length, 2);
    });

    test(
      'rejects a preview from another conversation at the same revision',
      () {
        final snapshot = _snapshot();
        final preview = editor.previewRemoveStop(
          conversationId: 'c-porto',
          snapshot: snapshot,
          itemId: 'clerigos',
        );

        final rejected = editor.apply(
          preview: preview,
          current: snapshot,
          currentConversationId: 'c-roma',
          timestamp: DateTime.utc(2026, 8, 11, 10),
        );

        expect(rejected.status, PlanPatchStatus.stale);
        expect(rejected.after, same(snapshot));
        expect(rejected.conflicts, isNotEmpty);
        expect(snapshot.days.first.items.length, 2);
      },
    );
  });
}

TripSnapshot _snapshot({
  String? lockedItemId,
  bool hasPurchasedSelection = false,
  String? linkedPurchaseItemId,
}) {
  final snapshot = TripSnapshot(
    destinationTitle: 'Porto',
    country: 'Portogallo',
    durationLabel: '2 giorni',
    statusLabel: 'In pianificazione',
    dates: '14–15 ottobre',
    transport: 'Treno',
    stay: 'Ribeira',
    revision: 3,
    travelSelection: TravelPlanSelection(
      option: TravelOption(
        id: 'train',
        label: 'Treno',
        purchaseState: hasPurchasedSelection
            ? PurchaseState.purchased
            : PurchaseState.estimate,
      ),
    ),
    days: <TripDaySnapshot>[
      TripDaySnapshot(
        id: 'day-1',
        label: 'Giorno 1',
        theme: 'Centro',
        items: <TripItemSnapshot>[
          TripItemSnapshot(
            id: 'lello',
            title: 'Lello',
            category: 'Libreria',
            startTime: '09:00',
            durationMinutes: 45,
            locked: lockedItemId == 'lello',
          ),
          TripItemSnapshot(
            id: 'clerigos',
            title: 'Clérigos',
            category: 'Monumento',
            startTime: '09:45',
            durationMinutes: 60,
            locked: lockedItemId == 'clerigos',
          ),
        ],
      ),
      TripDaySnapshot(
        id: 'day-2',
        label: 'Giorno 2',
        theme: 'Atlantico',
        items: <TripItemSnapshot>[
          const TripItemSnapshot(
            id: 'foz',
            title: 'Foz',
            category: 'Quartiere',
            startTime: '09:00',
            durationMinutes: 90,
            locked: false,
          ),
          const TripItemSnapshot(
            id: 'ribeira',
            title: 'Ribeira',
            category: 'Quartiere',
            startTime: '10:30',
            durationMinutes: 60,
            locked: false,
          ),
        ],
      ),
    ],
  );
  if (linkedPurchaseItemId == null) return snapshot;

  final json = snapshot.toJson();
  final days = json['days']! as List<dynamic>;
  for (final day in days.cast<Map<String, dynamic>>()) {
    final items = day['items']! as List<dynamic>;
    for (final item in items.cast<Map<String, dynamic>>()) {
      if (item['id'] == linkedPurchaseItemId) {
        item['linkedPurchaseOptionIds'] = <String>['train'];
      }
    }
  }
  return TripSnapshot.fromJson(json);
}

TripSnapshot _snapshotWithLateSchedule() {
  final snapshot = _snapshot();
  return snapshot.copyWith(
    days: <TripDaySnapshot>[
      TripDaySnapshot(
        id: 'day-1',
        label: 'Giorno 1',
        theme: 'Notte',
        items: const <TripItemSnapshot>[
          TripItemSnapshot(
            id: 'sunset',
            title: 'Tramonto',
            category: 'Panorama',
            startTime: '23:00',
            durationMinutes: 30,
            locked: false,
          ),
          TripItemSnapshot(
            id: 'night-view',
            title: 'Vista notturna',
            category: 'Panorama',
            startTime: '23:30',
            durationMinutes: 30,
            locked: false,
          ),
        ],
      ),
      snapshot.days[1],
    ],
  );
}
