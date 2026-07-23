import 'package:flutter/foundation.dart';

import '../../models/trip_models.dart';

enum NewTripFlowStage {
  questions,
  summary,
  searching,
  results,
  compare,
  selected,
}

enum NewTripPrototypeStep {
  origin,
  dates,
  company,
  transport,
  budget,
  travelStyle,
  pace,
  walking,
}

extension NewTripPrototypeStepCopy on NewTripPrototypeStep {
  String get label => switch (this) {
    NewTripPrototypeStep.origin => 'Partenza',
    NewTripPrototypeStep.dates => 'Quando',
    NewTripPrototypeStep.company => 'Compagnia',
    NewTripPrototypeStep.transport => 'Mezzi',
    NewTripPrototypeStep.budget => 'Budget',
    NewTripPrototypeStep.travelStyle => 'Stile',
    NewTripPrototypeStep.pace => 'Ritmo',
    NewTripPrototypeStep.walking => 'Camminate',
  };

  String get title => switch (this) {
    NewTripPrototypeStep.origin => 'Da dove vuoi partire?',
    NewTripPrototypeStep.dates => 'Quando potresti partire?',
    NewTripPrototypeStep.company => 'Con chi immagini questo viaggio?',
    NewTripPrototypeStep.transport => 'Come sei disposto a muoverti?',
    NewTripPrototypeStep.budget => 'Quanto vuoi spendere?',
    NewTripPrototypeStep.travelStyle => 'Che viaggio stai cercando?',
    NewTripPrototypeStep.pace => 'Che ritmo vuoi avere?',
    NewTripPrototypeStep.walking => 'Quanto vuoi camminare?',
  };

  String get support => switch (this) {
    NewTripPrototypeStep.origin =>
      'La rileviamo automaticamente, ma resta sempre modificabile.',
    NewTripPrototypeStep.dates =>
      'Più possibilità ci dai, più combinazioni convenienti possiamo trovare.',
    NewTripPrototypeStep.company =>
      'Il numero di persone cambia alloggi, spostamenti e costi.',
    NewTripPrototypeStep.transport =>
      'Puoi accettare più mezzi: confronteremo le alternative sensate.',
    NewTripPrototypeStep.budget =>
      'Tutto incluso, per persona: viaggio, alloggio e spese stimate.',
    NewTripPrototypeStep.travelStyle =>
      'Scegli fino a tre priorità: serviranno a spiegare ogni proposta.',
    NewTripPrototypeStep.pace =>
      'Il ritmo influenza distanze, tappe e tempo davvero libero.',
    NewTripPrototypeStep.walking =>
      'Serve a evitare proposte belle sulla carta ma scomode nella realtà.',
  };
}

enum PrototypeOriginStatus { idle, locating, resolved, manualRequired, error }

enum PrototypeOriginSource { device, manual }

enum PrototypeOriginFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  lookupFailed,
  unavailable,
}

@immutable
class PrototypeOriginSelection {
  const PrototypeOriginSelection({
    required this.label,
    required this.source,
    this.latitude,
    this.longitude,
  });

  final String label;
  final PrototypeOriginSource source;
  final double? latitude;
  final double? longitude;
}

@immutable
class PrototypeOriginResolution {
  const PrototypeOriginResolution.resolved(this.selection) : failure = null;

  const PrototypeOriginResolution.failed(this.failure) : selection = null;

  final PrototypeOriginSelection? selection;
  final PrototypeOriginFailure? failure;

  bool get isResolved => selection != null;
}

enum PrototypeDateMode { exact, manualAvailability, savedAvailability, open }

extension PrototypeDateModeCopy on PrototypeDateMode {
  String get label => switch (this) {
    PrototypeDateMode.exact => 'Ho già le date',
    PrototypeDateMode.manualAvailability => 'Ho più possibilità',
    PrototypeDateMode.savedAvailability => 'Usa i miei giorni liberi',
    PrototypeDateMode.open => 'Non lo so ancora',
  };

  String get description => switch (this) {
    PrototypeDateMode.exact => 'Partenza e ritorno precisi.',
    PrototypeDateMode.manualAvailability =>
      'Indica anche singoli giorni possibili di partenza.',
    PrototypeDateMode.savedAvailability =>
      'Parti dalle disponibilità che hai già registrato.',
    PrototypeDateMode.open => 'Esplora mesi e stagioni con prezzi indicativi.',
  };
}

enum PrototypeDurationPreset {
  oneTwo,
  threeFour,
  fiveSeven,
  eightPlus,
  any,
  custom,
}

extension PrototypeDurationPresetCopy on PrototypeDurationPreset {
  String get label => switch (this) {
    PrototypeDurationPreset.oneTwo => '1–2',
    PrototypeDurationPreset.threeFour => '3–4',
    PrototypeDurationPreset.fiveSeven => '5–7',
    PrototypeDurationPreset.eightPlus => '8+',
    PrototypeDurationPreset.any => 'Indifferente',
    PrototypeDurationPreset.custom => 'Personalizza',
  };

  int get minimumDays => switch (this) {
    PrototypeDurationPreset.oneTwo => 1,
    PrototypeDurationPreset.threeFour => 3,
    PrototypeDurationPreset.fiveSeven => 5,
    PrototypeDurationPreset.eightPlus => 8,
    PrototypeDurationPreset.any => 1,
    PrototypeDurationPreset.custom => 1,
  };

  int get maximumDays => switch (this) {
    PrototypeDurationPreset.oneTwo => 2,
    PrototypeDurationPreset.threeFour => 4,
    PrototypeDurationPreset.fiveSeven => 7,
    PrototypeDurationPreset.eightPlus => 14,
    PrototypeDurationPreset.any => 14,
    PrototypeDurationPreset.custom => 30,
  };
}

enum PrototypeCompany { solo, couple, friends, family }

extension PrototypeCompanyCopy on PrototypeCompany {
  String get label => switch (this) {
    PrototypeCompany.solo => 'Solo',
    PrototypeCompany.couple => 'In coppia',
    PrototypeCompany.friends => 'Con amici',
    PrototypeCompany.family => 'In famiglia',
  };
}

enum PrototypeTransport { flight, train, bus, car }

extension PrototypeTransportCopy on PrototypeTransport {
  String get label => switch (this) {
    PrototypeTransport.flight => 'Volo',
    PrototypeTransport.train => 'Treno',
    PrototypeTransport.bus => 'Bus',
    PrototypeTransport.car => 'Auto',
  };
}

enum PrototypeTravelStyle {
  culture,
  food,
  nature,
  sea,
  rest,
  localLife,
  nightlife,
}

extension PrototypeTravelStyleCopy on PrototypeTravelStyle {
  String get label => switch (this) {
    PrototypeTravelStyle.culture => 'Cultura',
    PrototypeTravelStyle.food => 'Cibo',
    PrototypeTravelStyle.nature => 'Natura',
    PrototypeTravelStyle.sea => 'Mare',
    PrototypeTravelStyle.rest => 'Riposo',
    PrototypeTravelStyle.localLife => 'Vita locale',
    PrototypeTravelStyle.nightlife => 'Energia e notte',
  };
}

enum PrototypePace { relaxed, balanced, intense }

extension PrototypePaceCopy on PrototypePace {
  String get label => switch (this) {
    PrototypePace.relaxed => 'Rilassato',
    PrototypePace.balanced => 'Equilibrato',
    PrototypePace.intense => 'Intenso',
  };

  String get description => switch (this) {
    PrototypePace.relaxed => 'Poche tappe e molto spazio libero.',
    PrototypePace.balanced => 'Un filo chiaro, senza correre.',
    PrototypePace.intense => 'Giornate piene e più cose da vedere.',
  };
}

enum PrototypeWalking { little, normal, much, accessibility }

extension PrototypeWalkingCopy on PrototypeWalking {
  String get label => switch (this) {
    PrototypeWalking.little => 'Poco',
    PrototypeWalking.normal => 'Il giusto',
    PrototypeWalking.much => 'Molto',
    PrototypeWalking.accessibility => 'Priorità accessibilità',
  };
}

enum PrototypeSelectionPolicy {
  singleAutoAdvance,
  multipleConfirm,
  contextualConfirm,
}

enum PrototypeProposalSort { balanced, lowestCost, shortestTravel, bestFit }

extension PrototypeProposalSortCopy on PrototypeProposalSort {
  String get label => switch (this) {
    PrototypeProposalSort.balanced => 'Miglior equilibrio',
    PrototypeProposalSort.lowestCost => 'Prezzo più basso',
    PrototypeProposalSort.shortestTravel => 'Viaggio più semplice',
    PrototypeProposalSort.bestFit => 'Migliore compatibilità',
  };
}

enum PrototypePriceConfidence { high, medium, indicative }

extension PrototypePriceConfidenceCopy on PrototypePriceConfidence {
  String get label => switch (this) {
    PrototypePriceConfidence.high => 'Stima solida',
    PrototypePriceConfidence.medium => 'Stima media',
    PrototypePriceConfidence.indicative => 'Range indicativo',
  };
}

@immutable
class PrototypeDateWindow {
  const PrototypeDateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get dayCount => calendarDayDifference(start, end) + 1;

  String get key =>
      '${start.year}-${start.month}-${start.day}:${end.year}-${end.month}-${end.day}';

  @override
  bool operator ==(Object other) =>
      other is PrototypeDateWindow &&
      isSameCalendarDay(start, other.start) &&
      isSameCalendarDay(end, other.end);

  @override
  int get hashCode => Object.hash(
    start.year,
    start.month,
    start.day,
    end.year,
    end.month,
    end.day,
  );
}

@immutable
class PrototypeCostBreakdown {
  const PrototypeCostBreakdown({
    required this.transport,
    required this.stay,
    required this.local,
  });

  final int transport;
  final int stay;
  final int local;

  int get total => transport + stay + local;
}

@immutable
class PrototypeTravelProposal {
  const PrototypeTravelProposal({
    required this.journey,
    required this.heroAsset,
    required this.bestDateLabel,
    required this.alternativeDates,
    required this.durationDays,
    required this.cost,
    required this.priceRangeMax,
    required this.arrivalTransport,
    required this.travelMinutes,
    required this.changesCount,
    required this.matchReasons,
    required this.compromise,
    required this.confidence,
    required this.freshnessLabel,
    required this.fitScore,
    required this.sourceIndex,
  });

  final JourneyRoute journey;
  final String heroAsset;
  final String bestDateLabel;
  final List<String> alternativeDates;
  final int durationDays;
  final PrototypeCostBreakdown cost;
  final int? priceRangeMax;
  final PrototypeTransport arrivalTransport;
  final int travelMinutes;
  final int changesCount;
  final List<String> matchReasons;
  final String compromise;
  final PrototypePriceConfidence confidence;
  final String freshnessLabel;
  final int fitScore;
  final int sourceIndex;

  String get id => journey.id;
  bool get hasPriceRange => priceRangeMax != null;
  int groupTotal(int travelers) => cost.total * travelers;
}

@immutable
class PrototypeProposalQuery {
  const PrototypeProposalQuery({
    required this.origin,
    required this.dateMode,
    required this.exactStart,
    required this.exactEnd,
    required this.departureDates,
    required this.savedWindows,
    required this.minimumDuration,
    required this.maximumDuration,
    required this.referenceDate,
    required this.openHorizonMonths,
    required this.travelers,
    required this.transports,
    required this.budgetPerPerson,
    required this.styles,
    required this.pace,
    required this.walking,
    required this.relaxationLabel,
    required this.extraDurationDays,
    required this.includeNearbyOrigins,
    required this.budgetIncrease,
  });

  final String origin;
  final PrototypeDateMode dateMode;
  final DateTime? exactStart;
  final DateTime? exactEnd;
  final List<DateTime> departureDates;
  final List<PrototypeDateWindow> savedWindows;
  final int minimumDuration;
  final int maximumDuration;
  final DateTime referenceDate;
  final int openHorizonMonths;
  final int travelers;
  final Set<PrototypeTransport> transports;
  final int budgetPerPerson;
  final Set<PrototypeTravelStyle> styles;
  final PrototypePace pace;
  final PrototypeWalking walking;
  final String? relaxationLabel;
  final int extraDurationDays;
  final bool includeNearbyOrigins;
  final int budgetIncrease;
}

DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime nextCalendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

bool isSameCalendarDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

int calendarDayDifference(DateTime start, DateTime end) => DateTime.utc(
  end.year,
  end.month,
  end.day,
).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

List<PrototypeDateWindow> groupConsecutiveDates(Iterable<DateTime> dates) {
  final normalized = dates.map(calendarDate).toSet().toList()
    ..sort((left, right) => left.compareTo(right));
  if (normalized.isEmpty) return const <PrototypeDateWindow>[];

  final windows = <PrototypeDateWindow>[];
  var start = normalized.first;
  var previous = normalized.first;
  for (final date in normalized.skip(1)) {
    if (isSameCalendarDay(date, nextCalendarDay(previous))) {
      previous = date;
      continue;
    }
    windows.add(PrototypeDateWindow(start: start, end: previous));
    start = date;
    previous = date;
  }
  windows.add(PrototypeDateWindow(start: start, end: previous));
  return List<PrototypeDateWindow>.unmodifiable(windows);
}
