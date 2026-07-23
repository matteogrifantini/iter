import '../../data/mock_data.dart';
import '../../models/trip_models.dart';
import 'new_trip_lab_models.dart';

abstract interface class PrototypeProposalSource {
  Future<List<PrototypeTravelProposal>> search(PrototypeProposalQuery query);
}

class DeterministicPrototypeProposalSource implements PrototypeProposalSource {
  const DeterministicPrototypeProposalSource();

  static const Map<String, _ProposalSeed> _seeds = <String, _ProposalSeed>{
    'atlantic-rail': _ProposalSeed(
      heroAsset: 'assets/images/travel/rail_sequence.jpg',
      transport: 180,
      stay: 320,
      local: 190,
      durationDays: 6,
      preferredArrival: PrototypeTransport.train,
      travelMinutes: 285,
      changes: 1,
      openMonthOffset: 2,
      walkingDemand: 2,
      compromise: 'Due tappe richiedono un cambio di base.',
    ),
    'porto-slow': _ProposalSeed(
      heroAsset: 'assets/images/travel/porto_sequence.jpg',
      transport: 130,
      stay: 240,
      local: 150,
      durationDays: 5,
      preferredArrival: PrototypeTransport.flight,
      travelMinutes: 195,
      changes: 0,
      openMonthOffset: 3,
      walkingDemand: 2,
      compromise: 'La valle del Douro rende meglio con una giornata intera.',
    ),
    'lisbon-light': _ProposalSeed(
      heroAsset: 'assets/images/travel/lisbon_sequence.jpg',
      transport: 120,
      stay: 190,
      local: 120,
      durationDays: 4,
      preferredArrival: PrototypeTransport.flight,
      travelMinutes: 185,
      changes: 0,
      openMonthOffset: 1,
      walkingDemand: 3,
      compromise: 'Le salite richiedono un po’ più di energia.',
    ),
    'roma-city': _ProposalSeed(
      heroAsset: 'assets/images/travel/rome_sequence.jpg',
      transport: 80,
      stay: 180,
      local: 110,
      durationDays: 3,
      preferredArrival: PrototypeTransport.train,
      travelMinutes: 105,
      changes: 0,
      openMonthOffset: 0,
      walkingDemand: 3,
      compromise: 'Le zone centrali convenienti si esauriscono presto.',
    ),
    'paris-city': _ProposalSeed(
      heroAsset: 'assets/images/travel/paris_sequence.jpg',
      transport: 170,
      stay: 280,
      local: 160,
      durationDays: 3,
      preferredArrival: PrototypeTransport.train,
      travelMinutes: 150,
      changes: 0,
      openMonthOffset: 4,
      walkingDemand: 2,
      compromise: 'Il budget lascia meno spazio alle esperienze premium.',
    ),
    'barcelona-city': _ProposalSeed(
      heroAsset: 'assets/images/travel/barcelona_sequence.jpg',
      transport: 140,
      stay: 220,
      local: 120,
      durationDays: 4,
      preferredArrival: PrototypeTransport.flight,
      travelMinutes: 125,
      changes: 0,
      openMonthOffset: 5,
      walkingDemand: 2,
      compromise: 'Le aree sul mare sono più care nei weekend.',
    ),
  };

  @override
  Future<List<PrototypeTravelProposal>> search(
    PrototypeProposalQuery query,
  ) async {
    assert(
      MockData.journeys.every((journey) => _seeds.containsKey(journey.id)),
      'Ogni JourneyRoute deve avere una fixture di prezzo nel laboratorio.',
    );
    return <PrototypeTravelProposal>[
      for (var index = 0; index < MockData.journeys.length; index++)
        _buildProposal(
          MockData.journeys[index],
          _seeds[MockData.journeys[index].id]!,
          query,
          index,
        ),
    ];
  }

  PrototypeTravelProposal _buildProposal(
    JourneyRoute journey,
    _ProposalSeed seed,
    PrototypeProposalQuery query,
    int index,
  ) {
    final duration = seed.durationDays.clamp(
      query.minimumDuration,
      query.maximumDuration,
    );
    final concreteDates = query.dateMode != PrototypeDateMode.open;
    final arrivalTransport = _arrivalTransport(query, seed.preferredArrival);
    final originSignal = _originSignal(query.origin);
    final transportCost =
        (seed.transport +
                _transportCostOffset(arrivalTransport) -
                _transportCostOffset(seed.preferredArrival) +
                (originSignal % 5) * 8)
            .clamp(35, 2000);
    final travelMinutes =
        (seed.travelMinutes +
                _transportTimeOffset(arrivalTransport) -
                _transportTimeOffset(seed.preferredArrival) +
                (originSignal % 7) * 6)
            .clamp(45, 1440);
    final changes =
        arrivalTransport == PrototypeTransport.bus ||
            arrivalTransport == PrototypeTransport.car
        ? 0
        : seed.changes;
    final openPeriod = _openPeriod(query, seed.openMonthOffset);
    final cost = PrototypeCostBreakdown(
      transport: transportCost,
      stay: seed.stay,
      local: seed.local,
    );
    final overBudget = cost.total - query.budgetPerPerson;
    final styleReason = query.styles.isEmpty
        ? journey.whyItFits
        : '${query.styles.first.label} e ${query.pace.label.toLowerCase()} sono ben rappresentati.';
    return PrototypeTravelProposal(
      journey: journey,
      heroAsset: seed.heroAsset,
      bestDateLabel: _bestDateLabel(query, openPeriod, duration),
      alternativeDates: _alternativeDates(query, openPeriod),
      durationDays: duration,
      cost: cost,
      priceRangeMax: concreteDates ? null : cost.total + 120 + index * 15,
      arrivalTransport: arrivalTransport,
      travelMinutes: travelMinutes,
      changesCount: changes,
      matchReasons: <String>[
        styleReason,
        _transportReason(query, arrivalTransport),
        _walkingReason(query.walking, seed.walkingDemand),
        if (query.includeNearbyOrigins)
          'Include anche aeroporti e stazioni vicini alla partenza.',
      ],
      compromise: _walkingCompromise(
        query.walking,
        seed.walkingDemand,
        overBudget > 0
            ? 'Circa €$overBudget oltre il budget indicato: valuta una data alternativa.'
            : seed.compromise,
      ),
      confidence: switch (query.dateMode) {
        PrototypeDateMode.exact => PrototypePriceConfidence.high,
        PrototypeDateMode.manualAvailability ||
        PrototypeDateMode.savedAvailability => PrototypePriceConfidence.medium,
        PrototypeDateMode.open => PrototypePriceConfidence.indicative,
      },
      freshnessLabel: concreteDates
          ? 'Stima demo aggiornata oggi'
          : 'Range demo stagionale',
      fitScore:
          journey.matchScore -
          index +
          _walkingFitAdjustment(query.walking, seed.walkingDemand),
      sourceIndex: index,
    );
  }

  PrototypeTransport _arrivalTransport(
    PrototypeProposalQuery query,
    PrototypeTransport preferred,
  ) {
    if (query.transports.contains(preferred)) return preferred;
    return PrototypeTransport.values.firstWhere(query.transports.contains);
  }

  int _transportCostOffset(PrototypeTransport transport) => switch (transport) {
    PrototypeTransport.flight => 40,
    PrototypeTransport.train => 20,
    PrototypeTransport.bus => -30,
    PrototypeTransport.car => 10,
  };

  int _transportTimeOffset(PrototypeTransport transport) => switch (transport) {
    PrototypeTransport.flight => 0,
    PrototypeTransport.train => 90,
    PrototypeTransport.bus => 300,
    PrototypeTransport.car => 180,
  };

  String _transportReason(
    PrototypeProposalQuery query,
    PrototypeTransport arrivalTransport,
  ) {
    if (query.transports.length == PrototypeTransport.values.length) {
      return 'Da ${query.origin}, ${arrivalTransport.label.toLowerCase()} è il collegamento più equilibrato.';
    }
    return 'Da ${query.origin} in ${arrivalTransport.label.toLowerCase()}, coerente con i mezzi selezionati.';
  }

  int _originSignal(String origin) {
    final normalized = origin.trim().toLowerCase().runes.toList();
    var signal = 0;
    for (var index = 0; index < normalized.length; index++) {
      signal += (index + 1) * normalized[index];
    }
    return signal;
  }

  String _bestDateLabel(
    PrototypeProposalQuery query,
    String openPeriod,
    int duration,
  ) {
    return switch (query.dateMode) {
      PrototypeDateMode.exact =>
        '${_formatDayMonth(query.exactStart!)}–${_formatDayMonth(query.exactEnd!)}',
      PrototypeDateMode.manualAvailability =>
        'Partenza ${_formatDayMonth(_sorted(query.departureDates).first)} · $duration giorni',
      PrototypeDateMode.savedAvailability =>
        '${_formatDayMonth(query.savedWindows.first.start)}–${_formatDayMonth(query.savedWindows.first.end)}',
      PrototypeDateMode.open =>
        '$openPeriod · $duration ${duration == 1 ? 'giorno' : 'giorni'}',
    };
  }

  List<String> _alternativeDates(
    PrototypeProposalQuery query,
    String openPeriod,
  ) {
    return switch (query.dateMode) {
      PrototypeDateMode.exact => <String>[
        'Stesse date · partenza serale',
        '±1 giorno · prezzo da verificare',
      ],
      PrototypeDateMode.manualAvailability => <String>[
        for (final date in _sorted(query.departureDates).skip(1).take(3))
          'Partenza ${_formatDayMonth(date)}',
      ],
      PrototypeDateMode.savedAvailability => <String>[
        for (final window in query.savedWindows.skip(1).take(3))
          '${_formatDayMonth(window.start)}–${_formatDayMonth(window.end)}',
      ],
      PrototypeDateMode.open => <String>[
        '$openPeriod · infrasettimanale',
        'Mese vicino · prezzo simile',
      ],
    };
  }

  String _openPeriod(PrototypeProposalQuery query, int seedOffset) {
    final horizon = query.openHorizonMonths.clamp(1, 12);
    final monthOffset = 1 + seedOffset % horizon;
    final date = DateTime(
      query.referenceDate.year,
      query.referenceDate.month + monthOffset,
    );
    const months = <String>[
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _walkingReason(PrototypeWalking walking, int demand) =>
      switch (walking) {
        PrototypeWalking.little =>
          demand == 1
              ? 'Pochi tratti a piedi.'
              : 'Gli spostamenti a piedi possono essere ridotti.',
        PrototypeWalking.normal =>
          'Camminate compatibili con un ritmo equilibrato.',
        PrototypeWalking.much =>
          'Il percorso valorizza gli spostamenti a piedi.',
        PrototypeWalking.accessibility =>
          demand == 1
              ? 'Profilo adatto alla priorità accessibilità.'
              : 'Accessibilità da verificare nei tratti con più dislivello.',
      };

  int _walkingFitAdjustment(PrototypeWalking walking, int demand) =>
      switch (walking) {
        PrototypeWalking.little => -demand * 2,
        PrototypeWalking.normal => 0,
        PrototypeWalking.much => demand * 2,
        PrototypeWalking.accessibility => -demand * 4,
      };

  String _walkingCompromise(PrototypeWalking walking, int demand, String base) {
    if (walking != PrototypeWalking.accessibility || demand == 1) return base;
    return '$base Alcuni tratti richiedono una verifica puntuale dell’accessibilità.';
  }

  List<DateTime> _sorted(List<DateTime> dates) =>
      <DateTime>[...dates]..sort((left, right) => left.compareTo(right));
}

class EmptyPrototypeProposalSource implements PrototypeProposalSource {
  const EmptyPrototypeProposalSource();

  @override
  Future<List<PrototypeTravelProposal>> search(
    PrototypeProposalQuery query,
  ) async => const <PrototypeTravelProposal>[];
}

class _ProposalSeed {
  const _ProposalSeed({
    required this.heroAsset,
    required this.transport,
    required this.stay,
    required this.local,
    required this.durationDays,
    required this.preferredArrival,
    required this.travelMinutes,
    required this.changes,
    required this.openMonthOffset,
    required this.walkingDemand,
    required this.compromise,
  });

  final String heroAsset;
  final int transport;
  final int stay;
  final int local;
  final int durationDays;
  final PrototypeTransport preferredArrival;
  final int travelMinutes;
  final int changes;
  final int openMonthOffset;
  final int walkingDemand;
  final String compromise;
}

const List<String> _monthNames = <String>[
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String _formatDayMonth(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]}';
