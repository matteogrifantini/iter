import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
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

  test('direct legacy snapshots receive stable unique editing IDs', () {
    TripSnapshot build() => TripSnapshot(
      destinationTitle: 'Roma',
      country: 'Italia',
      durationLabel: '2 giorni',
      statusLabel: 'In viaggio',
      dates: '11–12 agosto',
      transport: 'A piedi',
      stay: 'Centro',
      days: <TripDaySnapshot>[
        TripDaySnapshot(
          label: 'Oggi',
          theme: 'Roma antica',
          items: const <TripItemSnapshot>[
            TripItemSnapshot(
              title: 'Foro Romano',
              category: 'Storia',
              locked: false,
            ),
            TripItemSnapshot(
              title: 'Passeggiata ai Fori',
              category: 'Passeggiata',
              locked: true,
            ),
          ],
        ),
        TripDaySnapshot(
          id: 'day-canonical',
          label: 'Domani',
          theme: 'Verde',
          items: const <TripItemSnapshot>[
            TripItemSnapshot(
              id: 'item-canonical',
              title: 'Villa Borghese',
              category: 'Parco',
              locked: false,
            ),
          ],
        ),
      ],
      unplacedItems: const <TripItemSnapshot>[
        TripItemSnapshot(
          title: 'Trastevere',
          category: 'Quartiere',
          locked: false,
        ),
      ],
    );

    final first = build();
    final second = build();
    final firstDayIds = first.days.map((day) => day.id).toList();
    final firstItemIds = <String>[
      ...first.days.expand((day) => day.items).map((item) => item.id),
      ...first.unplacedItems.map((item) => item.id),
    ];

    expect(firstDayIds, everyElement(isNotEmpty));
    expect(firstDayIds.toSet(), hasLength(firstDayIds.length));
    expect(firstItemIds, everyElement(isNotEmpty));
    expect(firstItemIds.toSet(), hasLength(firstItemIds.length));
    expect(second.days.map((day) => day.id), firstDayIds);
    expect(<String>[
      ...second.days.expand((day) => day.items).map((item) => item.id),
      ...second.unplacedItems.map((item) => item.id),
    ], firstItemIds);
    expect(first.days.last.id, 'day-canonical');
    expect(first.days.last.items.single.id, 'item-canonical');
  });

  test('legacy JSON editing IDs survive deterministic round trips', () {
    const legacy = <String, dynamic>{
      'destinationTitle': 'Roma',
      'days': <Map<String, dynamic>>[
        <String, dynamic>{
          'label': 'Oggi',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'title': 'Foro Romano'},
            <String, dynamic>{'title': 'Passeggiata ai Fori'},
          ],
        },
      ],
      'unplacedItems': <Map<String, dynamic>>[
        <String, dynamic>{'title': 'Trastevere'},
      ],
    };

    final first = TripSnapshot.fromJson(legacy);
    final rebuilt = TripSnapshot.fromJson(legacy);
    final roundTripped = TripSnapshot.fromJson(first.toJson());
    final firstIds = <String>[
      first.days.single.id,
      ...first.days.single.items.map((item) => item.id),
      first.unplacedItems.single.id,
    ];

    expect(firstIds, everyElement(isNotEmpty));
    expect(firstIds.toSet(), hasLength(firstIds.length));
    expect(<String>[
      rebuilt.days.single.id,
      ...rebuilt.days.single.items.map((item) => item.id),
      rebuilt.unplacedItems.single.id,
    ], firstIds);
    expect(<String>[
      roundTripped.days.single.id,
      ...roundTripped.days.single.items.map((item) => item.id),
      roundTripped.unplacedItems.single.id,
    ], firstIds);
  });

  test('Roma active route exposes distinct non-empty editing IDs', () {
    final snapshot = ChatFirstDemoData.seedThreads()
        .singleWhere((thread) => thread.summary.id == 'c-roma-active')
        .summary
        .snapshot!;
    final dayIds = snapshot.days.map((day) => day.id).toList();
    final itemIds = <String>[
      ...snapshot.days.expand((day) => day.items).map((item) => item.id),
      ...snapshot.unplacedItems.map((item) => item.id),
    ];

    expect(dayIds, everyElement(isNotEmpty));
    expect(dayIds.toSet(), hasLength(dayIds.length));
    expect(itemIds, everyElement(isNotEmpty));
    expect(itemIds.toSet(), hasLength(itemIds.length));
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

  test('plan selections round trip immutable alternatives', () {
    final suppliedTravelAlternatives = <TravelOption>[
      const TravelOption(id: 'flight-b', label: 'Volo B', priceCents: 12000),
      const TravelOption(id: 'flight-c', label: 'Volo C', priceCents: 14000),
    ];
    final suppliedStayAlternatives = <StayOption>[
      const StayOption(id: 'stay-b', label: 'Hotel B', priceCents: 22000),
    ];
    final snapshot = TripSnapshot(
      destinationTitle: 'Porto',
      country: 'Portogallo',
      durationLabel: '2 giorni',
      statusLabel: 'In pianificazione',
      dates: '17–18 ottobre',
      transport: 'Volo A',
      stay: 'Hotel A',
      travelSelection: TravelPlanSelection(
        option: const TravelOption(
          id: 'flight-a',
          label: 'Volo A',
          priceCents: 18000,
          purchaseState: PurchaseState.selected,
        ),
        alternatives: suppliedTravelAlternatives,
      ),
      staySelection: StayPlanSelection(
        option: const StayOption(
          id: 'stay-a',
          label: 'Hotel A',
          priceCents: 30000,
          purchaseState: PurchaseState.selected,
        ),
        alternatives: suppliedStayAlternatives,
      ),
    );

    suppliedTravelAlternatives.clear();
    suppliedStayAlternatives.clear();
    final restored = TripSnapshot.fromJson(snapshot.toJson());

    expect(snapshot.travelSelection?.option.id, 'flight-a');
    expect(
      snapshot.travelSelection?.alternatives.map((option) => option.id),
      <String>['flight-b', 'flight-c'],
    );
    expect(
      restored.travelSelection?.alternatives.map((option) => option.id),
      <String>['flight-b', 'flight-c'],
    );
    expect(
      restored.staySelection?.alternatives.map((option) => option.id),
      <String>['stay-b'],
    );
    expect(
      restored.travelSelection?.toJson()['option'],
      restored.travelSelection?.option.toJson(),
    );
    expect(
      () => snapshot.travelSelection!.alternatives.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.staySelection!.alternatives.clear(),
      throwsUnsupportedError,
    );
  });

  test('legacy plan selections default alternatives to empty', () {
    final snapshot = TripSnapshot.fromJson(<String, dynamic>{
      'travelSelection': <String, dynamic>{
        'option': <String, dynamic>{'id': 'flight-a', 'label': 'Volo A'},
      },
      'staySelection': <String, dynamic>{
        'option': <String, dynamic>{'id': 'stay-a', 'label': 'Hotel A'},
      },
    });

    expect(snapshot.travelSelection?.option.id, 'flight-a');
    expect(snapshot.travelSelection?.alternatives, isEmpty);
    expect(snapshot.staySelection?.option.id, 'stay-a');
    expect(snapshot.staySelection?.alternatives, isEmpty);
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

  test(
    'Porto operational fixture has local attributed media and complete offers',
    () {
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');

      expect(fixture.snapshot.days, hasLength(2));
      expect(
        fixture.placeCatalog.map((place) => place.name),
        contains('Livraria Lello'),
      );
      expect(
        fixture.media.imageUrl,
        'assets/images/travel/porto_livraria_lello.jpg',
      );
      expect(
        fixture.media.reelUrl,
        'assets/videos/vertical/porto_livraria_lello_reel.mp4',
      );
      expect(fixture.media.photoAttribution!.author, 'JaimeMSilva');
      expect(
        fixture.media.photoAttribution!.sourceUrl,
        startsWith('https://commons.wikimedia.org/'),
      );
      expect(
        fixture.media.reelAttribution!.author,
        'JaimeMSilva / Iter demo edit',
      );
      expect(
        fixture.media.reelAttribution!.sourceUrl,
        startsWith('https://commons.wikimedia.org/'),
      );
      expect(fixture.flights, hasLength(4));
      expect(fixture.hotels, hasLength(4));
      expect(fixture.quotedAt, DateTime.utc(2026, 8, 11, 9));
    },
  );

  test('only Livraria Lello owns the approved place media', () {
    final porto = ChatFirstDemoData.operationalFixtureFor('porto');
    final roma = ChatFirstDemoData.operationalFixtureFor('roma');
    final lello = porto.placeCatalog.singleWhere(
      (place) => place.id == 'porto-livraria-lello',
    );

    expect(lello.media, same(porto.media));
    expect(
      lello.media!.imageUrl,
      'assets/images/travel/porto_livraria_lello.jpg',
    );
    expect(
      lello.media!.reelUrl,
      'assets/videos/vertical/porto_livraria_lello_reel.mp4',
    );
    expect(
      porto.placeCatalog
          .where((place) => place.id != 'porto-livraria-lello')
          .every((place) => place.media == null),
      isTrue,
    );
    expect(roma.placeCatalog.every((place) => place.media == null), isTrue);
  });

  test(
    'operational fixture IDs, coordinates, costs and provider URIs are valid',
    () {
      final porto = ChatFirstDemoData.operationalFixtureFor('porto');
      final roma = ChatFirstDemoData.operationalFixtureFor('roma');
      final ids = <String>{
        ...porto.placeCatalog.map((place) => place.id),
        ...porto.flights.map((flight) => flight.id),
        ...porto.hotels.map((hotel) => hotel.id),
        ...roma.placeCatalog.map((place) => place.id),
        ...roma.flights.map((flight) => flight.id),
        ...roma.hotels.map((hotel) => hotel.id),
      };

      expect(ids.length, 16);
      const allowedProviderHosts = <String>{
        'www.flytap.com',
        'www.ryanair.com',
        'www.iberia.com',
        'www.vueling.com',
        'www.booking.com',
        'www.hotels.com',
        'www.expedia.com',
      };
      for (final fixture in <OperationalTripFixture>[porto, roma]) {
        for (final place in fixture.placeCatalog) {
          expect(place.latitude, inInclusiveRange(-90, 90));
          expect(place.longitude, inInclusiveRange(-180, 180));
        }
        for (final option in [...fixture.flights, ...fixture.hotels]) {
          expect(option.priceCents, greaterThan(0));
          expect(option.providerUrl.scheme, 'https');
          expect(allowedProviderHosts, contains(option.providerUrl.host));
        }
      }
    },
  );

  test(
    'flight duration matches deterministic departure and arrival instants',
    () {
      final flights = ChatFirstDemoData.operationalFixtureFor('porto').flights;

      for (final flight in flights) {
        expect(
          flight.arrivalAt.difference(flight.departureAt).inMinutes,
          flight.durationMinutes,
          reason: flight.id,
        );
      }
    },
  );

  test('Porto hotel totals match the single-night itinerary', () {
    final fixture = ChatFirstDemoData.operationalFixtureFor('porto');

    expect(fixture.snapshot.dates, '17–18 ottobre 2026');
    expect(fixture.snapshot.durationLabel, '2 giorni');
    for (final hotel in fixture.hotels) {
      expect(hotel.nights, 1, reason: hotel.id);
      expect(
        hotel.priceCents,
        hotel.nightlyPriceCents * hotel.nights,
        reason: hotel.id,
      );
    }
  });

  test(
    'every itinerary stop links to matching destination catalogue details',
    () {
      for (final destinationId in <String>['porto', 'roma']) {
        final fixture = ChatFirstDemoData.operationalFixtureFor(destinationId);
        final catalogById = <String, OperationalPlaceFixture>{
          for (final place in fixture.placeCatalog) place.id: place,
        };

        for (final item in fixture.snapshot.days.expand((day) => day.items)) {
          final details = item.place;
          expect(details, isNotNull, reason: item.id);
          final catalogPlace = catalogById[details!.id];
          expect(catalogPlace, isNotNull, reason: item.id);
          expect(details.title, catalogPlace!.name, reason: item.id);
          expect(
            details.description,
            catalogPlace.description,
            reason: item.id,
          );
          expect(catalogPlace.latitude, inInclusiveRange(-90, 90));
          expect(catalogPlace.longitude, inInclusiveRange(-180, 180));
        }
      }
    },
  );

  test('operational flight and hotel lists reject mutation', () {
    final fixture = ChatFirstDemoData.operationalFixtureFor('porto');

    expect(fixture.flights.clear, throwsUnsupportedError);
    expect(fixture.hotels.clear, throwsUnsupportedError);
  });

  test(
    'operational fixture resolver accepts only canonical destination title',
    () {
      final porto = ChatFirstDemoData.operationalFixtureFor('porto').snapshot;

      expect(
        ChatFirstDemoData.operationalFixtureForSnapshot(
          porto.copyWith(destinationTitle: '  PORTO  '),
        )?.destinationId,
        'porto',
      );
      expect(
        ChatFirstDemoData.operationalFixtureForSnapshot(
          porto.copyWith(destinationTitle: 'Roma'),
        )?.destinationId,
        'roma',
      );
      for (final title in <String>[
        'Porto e Roma',
        'Portorose',
        'Roma Nord',
        '',
      ]) {
        expect(
          ChatFirstDemoData.operationalFixtureForSnapshot(
            porto.copyWith(destinationTitle: title),
          ),
          isNull,
          reason: title,
        );
      }
    },
  );
}
