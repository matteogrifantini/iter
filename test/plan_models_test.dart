import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';

void main() {
  test('legacy snapshot remains readable', () {
    final snapshot = TripSnapshot.fromJson(const <String, dynamic>{
      'destinationTitle': 'Porto',
      'country': 'Portogallo',
      'durationLabel': '4 giorni',
      'statusLabel': 'In pianificazione',
      'dates': '14–17 ottobre',
      'transport': 'da definire',
      'stay': 'da definire',
      'placeLabels': <String>['Ribeira'],
      'days': <Map<String, dynamic>>[],
    });

    expect(snapshot.revision, 0);
    expect(snapshot.costSummary.projectedTotalCents, 0);
  });

  test('complete snapshot round trips canonical plan data', () {
    final snapshot = TripSnapshot(
      destinationTitle: 'Porto',
      country: 'Portogallo',
      durationLabel: '4 giorni',
      statusLabel: 'In pianificazione',
      dates: '14–17 ottobre',
      transport: 'Treno',
      stay: 'Ribeira',
      placeLabels: <String>['Ribeira'],
      days: <TripDaySnapshot>[
        TripDaySnapshot(
          id: 'day-1',
          date: DateTime.utc(2026, 10, 14),
          label: 'Giorno 1',
          theme: 'Fiume',
          items: <TripItemSnapshot>[
            TripItemSnapshot(
              id: 'item-1',
              title: 'Ribeira',
              category: 'Quartiere',
              startTime: '10:00',
              durationMinutes: 90,
              source: PlanItemSource.manual,
              locked: true,
              place: PlanPlaceDetails(id: 'ribeira', title: 'Ribeira'),
            ),
          ],
        ),
      ],
      revisionMetadata: PlanRevisionMetadata(
        id: 'revision-1',
        number: 1,
        timestamp: DateTime.utc(2026, 10, 1, 12),
        origin: PlanChangeOrigin.chat,
        label: 'Prima bozza',
      ),
      destinationMedia: PlanMedia(
        imageUrl: 'porto.jpg',
        photoAttribution: MediaAttribution(
          author: 'Ana',
          sourceUrl: 'https://example.com/photo',
        ),
        reelAttribution: MediaAttribution(
          author: 'Luca',
          sourceUrl: 'https://example.com/reel',
        ),
      ),
      travelSelection: TravelPlanSelection(
        option: TravelOption(
          id: 'train',
          label: 'Treno',
          priceCents: 4500,
          purchaseState: PurchaseState.selected,
        ),
      ),
      staySelection: StayPlanSelection(
        option: StayOption(id: 'stay', label: 'Ribeira', priceCents: 36000),
      ),
      costSummary: PlanCostSummary(
        currencyCode: 'EUR',
        projectedTotalCents: 40500,
      ),
      unplacedItems: <TripItemSnapshot>[],
    );

    final restored = TripSnapshot.fromJson(snapshot.toJson());

    expect(restored.revision, 1);
    expect(restored.days.single.id, 'day-1');
    expect(restored.days.single.date, DateTime.utc(2026, 10, 14));
    expect(restored.days.single.items.single.startTime, '10:00');
    expect(restored.days.single.items.single.time, '10:00');
    expect(restored.destinationMedia!.photoAttribution!.author, 'Ana');
    expect(restored.destinationMedia!.reelAttribution!.author, 'Luca');
    expect(restored.costSummary.currencyCode, 'EUR');
    expect(restored.costSummary.projectedTotalCents, 40500);
  });

  test('unknown enums fall back safely and canonical lists are immutable', () {
    final snapshot = TripSnapshot.fromJson(<String, dynamic>{
      'revision': 1,
      'travelSelection': <String, dynamic>{
        'option': <String, dynamic>{
          'id': 'train',
          'label': 'Treno',
          'priceCents': 4500,
          'purchaseState': 'unknown',
        },
      },
      'days': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'day-1',
          'date': '2026-10-14T00:00:00.000Z',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'item-1', 'source': 'unknown'},
          ],
        },
      ],
    });

    expect(
      snapshot.travelSelection!.option.purchaseState,
      PurchaseState.estimate,
    );
    expect(snapshot.days.single.items.single.source, PlanItemSource.iter);
    expect(
      () => snapshot.days.add(TripDaySnapshot(label: '', theme: '', items: [])),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.days.single.items.add(
        const TripItemSnapshot(
          title: '',
          category: '',
          time: '',
          locked: false,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('cost summaries normalize non-EUR JSON currency', () {
    final summary = PlanCostSummary.fromJson(<String, dynamic>{
      'currencyCode': 'USD',
      'projectedTotalCents': 4500,
    });

    expect(summary.currencyCode, 'EUR');
    expect(summary.toJson()['currencyCode'], 'EUR');
    expect(summary.projectedTotalCents, 4500);
  });

  test('day snapshots defensively copy input items', () {
    final suppliedItems = <TripItemSnapshot>[
      const TripItemSnapshot(
        id: 'original',
        title: 'Ribeira',
        category: 'Quartiere',
        time: '10:00',
        locked: false,
      ),
    ];
    final day = TripDaySnapshot(
      label: 'Giorno 1',
      theme: 'Fiume',
      items: suppliedItems,
    );

    suppliedItems
      ..clear()
      ..add(
        const TripItemSnapshot(
          id: 'later',
          title: 'Foz',
          category: 'Mare',
          time: '14:00',
          locked: false,
        ),
      );

    expect(day.items.single.id, 'original');
  });

  test('purchase links round trip and remain defensively immutable', () {
    final suppliedLinks = <String>['train'];
    final item = TripItemSnapshot.fromJson(<String, dynamic>{
      'id': 'clerigos',
      'title': 'Clérigos',
      'category': 'Monumento',
      'linkedPurchaseOptionIds': suppliedLinks,
    });

    suppliedLinks.add('stay');

    expect(item.linkedPurchaseOptionIds, <String>['train']);
    expect(item.toJson()['linkedPurchaseOptionIds'], <String>['train']);
    expect(
      () => item.linkedPurchaseOptionIds.add('stay'),
      throwsUnsupportedError,
    );
    expect(
      const TripItemSnapshot(
        title: 'Legacy',
        category: 'Luogo',
        locked: false,
      ).linkedPurchaseOptionIds,
      isEmpty,
    );
  });
}
