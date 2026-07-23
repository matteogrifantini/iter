import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'new_trip_lab_models.dart';
import 'new_trip_lab_proposals.dart';

class NewTripPrototypeController extends ChangeNotifier {
  NewTripPrototypeController({
    DateTime Function()? clock,
    Iterable<DateTime> savedFreeDays = const <DateTime>[],
    this.proposalSource = const DeterministicPrototypeProposalSource(),
    this.autoAdvanceDelay = const Duration(milliseconds: 200),
    this.searchStageDelay = const Duration(milliseconds: 360),
  }) : today = calendarDate((clock ?? DateTime.now)()) {
    final lastDate = DateTime(today.year + 1, today.month, today.day);
    final normalized =
        savedFreeDays
            .map(calendarDate)
            .where((date) => !date.isBefore(today))
            .where((date) => !date.isAfter(lastDate))
            .toSet()
            .toList()
          ..sort();
    _savedFreeDays = List<DateTime>.unmodifiable(normalized);
  }

  static const List<NewTripPrototypeStep> _baseQuestionSteps =
      <NewTripPrototypeStep>[
        NewTripPrototypeStep.dates,
        NewTripPrototypeStep.company,
        NewTripPrototypeStep.transport,
        NewTripPrototypeStep.budget,
        NewTripPrototypeStep.travelStyle,
        NewTripPrototypeStep.pace,
        NewTripPrototypeStep.walking,
      ];

  final DateTime today;
  final Duration autoAdvanceDelay;
  final Duration searchStageDelay;
  late final List<DateTime> _savedFreeDays;
  final PrototypeProposalSource proposalSource;

  NewTripFlowStage _stage = NewTripFlowStage.questions;
  NewTripPrototypeStep _currentStep = NewTripPrototypeStep.origin;
  int _furthestStepIndex = 0;
  PrototypeOriginStatus _originStatus = PrototypeOriginStatus.idle;
  PrototypeOriginSelection? _originSelection;
  PrototypeOriginFailure? _originFailure;

  PrototypeDateMode? _dateMode;
  DateTime? _exactStart;
  DateTime? _exactEnd;
  final Set<DateTime> _departureDates = <DateTime>{};
  final Set<String> _excludedSavedWindows = <String>{};
  PrototypeDurationPreset? _manualDuration;
  PrototypeDurationPreset? _savedDuration;
  PrototypeDurationPreset? _openDuration;
  int _manualCustomMin = 3;
  int _manualCustomMax = 5;
  int _savedCustomMin = 3;
  int _savedCustomMax = 5;
  int _openCustomMin = 3;
  int _openCustomMax = 5;
  int _openHorizonMonths = 12;
  bool _openHorizonWasExplicit = false;

  PrototypeCompany? _company;
  int _adults = 1;
  int _children = 0;
  final Set<PrototypeTransport> _transports = <PrototypeTransport>{};
  int? _budgetPerPerson;
  bool _budgetIsOpenEnded = false;
  final Set<PrototypeTravelStyle> _styles = <PrototypeTravelStyle>{};
  PrototypePace? _pace;
  PrototypeWalking? _walking;

  int _searchMessageIndex = 0;
  List<PrototypeTravelProposal> _proposals = const <PrototypeTravelProposal>[];
  PrototypeProposalSort _proposalSort = PrototypeProposalSort.balanced;
  final LinkedHashSet<String> _shortlistIds = LinkedHashSet<String>();
  String? _selectedProposalId;
  String? _activeRelaxation;
  int _relaxedDurationDays = 0;
  bool _includeNearbyOrigins = false;
  int _relaxedBudgetIncrease = 0;
  bool _returnToSummaryAfterStep = false;
  Timer? _autoAdvanceTimer;
  bool _disposed = false;

  NewTripFlowStage get stage => _stage;
  NewTripPrototypeStep get currentStep => _currentStep;
  int get furthestStepIndex => _furthestStepIndex;
  PrototypeOriginStatus get originStatus => _originStatus;
  PrototypeOriginSelection? get originSelection => _originSelection;
  PrototypeOriginFailure? get originFailure => _originFailure;
  String? get origin => _originSelection?.label.trim();
  bool get hasOrigin => origin?.isNotEmpty == true;
  bool get originFromDevice =>
      _originSelection?.source == PrototypeOriginSource.device;

  List<NewTripPrototypeStep> get questionSteps =>
      List<NewTripPrototypeStep>.unmodifiable(<NewTripPrototypeStep>[
        if (!hasOrigin || _currentStep == NewTripPrototypeStep.origin)
          NewTripPrototypeStep.origin,
        ..._baseQuestionSteps,
      ]);

  int get currentStepIndex {
    final index = questionSteps.indexOf(_currentStep);
    return index < 0 ? 0 : index;
  }

  int get totalSteps => questionSteps.length;
  double get progress => (currentStepIndex + 1) / totalSteps;
  int get completedQuestionCount =>
      _baseQuestionSteps.where(isStepComplete).length;

  PrototypeDateMode? get dateMode => _dateMode;
  DateTime? get exactStart => _exactStart;
  DateTime? get exactEnd => _exactEnd;
  DateTime get lastSelectableDate =>
      DateTime(today.year + 1, today.month, today.day);
  UnmodifiableSetView<DateTime> get departureDates =>
      UnmodifiableSetView<DateTime>(_departureDates);
  List<DateTime> get savedFreeDays => _savedFreeDays;
  bool get hasSavedFreeDays => _savedFreeDays.isNotEmpty;
  PrototypeDurationPreset? get manualDuration => _manualDuration;
  PrototypeDurationPreset? get savedDuration => _savedDuration;
  PrototypeDurationPreset? get openDuration => _openDuration;
  int get manualCustomMin => _manualCustomMin;
  int get manualCustomMax => _manualCustomMax;
  int get savedCustomMin => _savedCustomMin;
  int get savedCustomMax => _savedCustomMax;
  int get openCustomMin => _openCustomMin;
  int get openCustomMax => _openCustomMax;
  int get openHorizonMonths => _openHorizonMonths;
  bool get openHorizonWasExplicit => _openHorizonWasExplicit;
  PrototypeCompany? get company => _company;
  int get adults => _adults;
  int get children => _children;
  int get travelers => _adults + _children;
  UnmodifiableSetView<PrototypeTransport> get transports =>
      UnmodifiableSetView<PrototypeTransport>(_transports);
  bool get acceptsAnyTransport =>
      _transports.length == PrototypeTransport.values.length;
  int? get budgetPerPerson => _budgetPerPerson;
  bool get budgetIsOpenEnded => _budgetIsOpenEnded;
  UnmodifiableSetView<PrototypeTravelStyle> get styles =>
      UnmodifiableSetView<PrototypeTravelStyle>(_styles);
  bool get hasReachedStyleLimit => _styles.length >= 3;
  PrototypePace? get pace => _pace;
  PrototypeWalking? get walking => _walking;

  List<PrototypeDateWindow> get savedWindows =>
      groupConsecutiveDates(_savedFreeDays);

  List<PrototypeDateWindow> get activeSavedWindows => savedWindows
      .where((window) => !_excludedSavedWindows.contains(window.key))
      .toList(growable: false);

  List<PrototypeDateWindow> get usableSavedWindows {
    final duration = _savedDuration;
    if (duration == null) return const <PrototypeDateWindow>[];
    final minimum = _durationBounds(
      duration,
      _savedCustomMin,
      _savedCustomMax,
    ).$1;
    return activeSavedWindows
        .where((window) => window.dayCount >= minimum)
        .toList(growable: false);
  }

  int get exactNights {
    final start = _exactStart;
    final end = _exactEnd;
    if (start == null || end == null || !end.isAfter(start)) return 0;
    return calendarDayDifference(start, end);
  }

  bool get canGoBack {
    if (_stage != NewTripFlowStage.questions) return true;
    if (_currentStep == NewTripPrototypeStep.dates && _dateMode != null) {
      return true;
    }
    return currentStepIndex > 0;
  }

  bool get canStartSearch =>
      hasOrigin && _baseQuestionSteps.every(isStepComplete);

  String? get contextualActionLabel => switch (_currentStep) {
    NewTripPrototypeStep.dates when _dateMode != null => switch (_dateMode!) {
      PrototypeDateMode.exact => 'Usa queste date',
      PrototypeDateMode.manualAvailability => 'Usa queste partenze',
      PrototypeDateMode.savedAvailability => 'Usa i giorni liberi',
      PrototypeDateMode.open => 'Usa questo periodo',
    },
    NewTripPrototypeStep.company
        when _company == PrototypeCompany.friends ||
            _company == PrototypeCompany.family =>
      'Fatto · $travelers ${travelers == 1 ? 'persona' : 'persone'}',
    NewTripPrototypeStep.transport when _transports.isNotEmpty =>
      'Fatto (${_transports.length})',
    NewTripPrototypeStep.travelStyle when _styles.isNotEmpty =>
      'Fatto (${_styles.length})',
    _ => null,
  };

  bool get canPerformContextualAction => isStepComplete(_currentStep);

  void beginOriginResolution() {
    _cancelAutoAdvance();
    _originStatus = PrototypeOriginStatus.locating;
    _originFailure = null;
    if (!hasOrigin) _currentStep = NewTripPrototypeStep.origin;
    notifyListeners();
  }

  void applyOriginResolution(PrototypeOriginResolution resolution) {
    if (resolution.isResolved) {
      _originSelection = resolution.selection;
      _originStatus = PrototypeOriginStatus.resolved;
      _originFailure = null;
      notifyListeners();
      if (_currentStep == NewTripPrototypeStep.origin) {
        _scheduleAdvance(NewTripPrototypeStep.origin);
      }
      return;
    }
    _originStatus = PrototypeOriginStatus.manualRequired;
    _originFailure = resolution.failure ?? PrototypeOriginFailure.unavailable;
    _currentStep = NewTripPrototypeStep.origin;
    notifyListeners();
  }

  void setManualOrigin(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    _originSelection = PrototypeOriginSelection(
      label: normalized,
      source: PrototypeOriginSource.manual,
    );
    _originStatus = PrototypeOriginStatus.resolved;
    _originFailure = null;
    notifyListeners();
    if (_currentStep == NewTripPrototypeStep.origin) {
      _scheduleAdvance(NewTripPrototypeStep.origin);
    }
  }

  void setDateMode(PrototypeDateMode mode) {
    if (mode == PrototypeDateMode.savedAvailability && !hasSavedFreeDays) {
      return;
    }
    _dateMode = mode;
    notifyListeners();
  }

  void showDateModePicker() {
    if (_dateMode == null) return;
    _dateMode = null;
    notifyListeners();
  }

  void setExactDates(List<DateTime> dates) {
    _exactStart = dates.isEmpty ? null : calendarDate(dates.first);
    _exactEnd = dates.length < 2 ? null : calendarDate(dates[1]);
    notifyListeners();
  }

  void setDepartureDates(List<DateTime> dates) {
    _departureDates
      ..clear()
      ..addAll(
        dates
            .map(calendarDate)
            .where((date) => !date.isBefore(today))
            .where((date) => !date.isAfter(lastSelectableDate)),
      );
    notifyListeners();
  }

  void setDurationPreset(
    PrototypeDateMode mode,
    PrototypeDurationPreset preset,
  ) {
    switch (mode) {
      case PrototypeDateMode.manualAvailability:
        _manualDuration = preset;
        break;
      case PrototypeDateMode.savedAvailability:
        _savedDuration = preset;
        break;
      case PrototypeDateMode.open:
        _openDuration = preset;
        break;
      case PrototypeDateMode.exact:
        return;
    }
    notifyListeners();
  }

  void setCustomDuration(PrototypeDateMode mode, {int? minimum, int? maximum}) {
    switch (mode) {
      case PrototypeDateMode.manualAvailability:
        final bounds = _normalizedDuration(
          minimum ?? _manualCustomMin,
          maximum ?? _manualCustomMax,
        );
        _manualCustomMin = bounds.$1;
        _manualCustomMax = bounds.$2;
        break;
      case PrototypeDateMode.savedAvailability:
        final bounds = _normalizedDuration(
          minimum ?? _savedCustomMin,
          maximum ?? _savedCustomMax,
        );
        _savedCustomMin = bounds.$1;
        _savedCustomMax = bounds.$2;
        break;
      case PrototypeDateMode.open:
        final bounds = _normalizedDuration(
          minimum ?? _openCustomMin,
          maximum ?? _openCustomMax,
        );
        _openCustomMin = bounds.$1;
        _openCustomMax = bounds.$2;
        break;
      case PrototypeDateMode.exact:
        return;
    }
    notifyListeners();
  }

  void toggleSavedWindow(PrototypeDateWindow window) {
    if (!_excludedSavedWindows.add(window.key)) {
      _excludedSavedWindows.remove(window.key);
    }
    notifyListeners();
  }

  bool isSavedWindowIncluded(PrototypeDateWindow window) =>
      !_excludedSavedWindows.contains(window.key);

  void setOpenHorizon(int months) {
    if (!const <int>{3, 6, 12}.contains(months)) return;
    _openHorizonMonths = months;
    _openHorizonWasExplicit = true;
    notifyListeners();
  }

  void selectCompany(PrototypeCompany value) {
    _cancelAutoAdvance();
    _company = value;
    switch (value) {
      case PrototypeCompany.solo:
        _adults = 1;
        _children = 0;
        break;
      case PrototypeCompany.couple:
        _adults = 2;
        _children = 0;
        break;
      case PrototypeCompany.friends:
        _adults = 3;
        _children = 0;
        break;
      case PrototypeCompany.family:
        _adults = 2;
        _children = 1;
        break;
    }
    notifyListeners();
    if (value == PrototypeCompany.solo || value == PrototypeCompany.couple) {
      _scheduleAdvance(NewTripPrototypeStep.company);
    }
  }

  void setAdults(int value) {
    final minimum = _company == PrototypeCompany.friends ? 2 : 1;
    _adults = value.clamp(minimum, 12);
    notifyListeners();
  }

  void setChildren(int value) {
    _children = value.clamp(0, 8);
    notifyListeners();
  }

  void toggleTransport(PrototypeTransport value) {
    _cancelAutoAdvance();
    if (!_transports.add(value)) _transports.remove(value);
    notifyListeners();
  }

  void selectAnyTransport() {
    _cancelAutoAdvance();
    _transports
      ..clear()
      ..addAll(PrototypeTransport.values);
    notifyListeners();
    _scheduleAdvance(NewTripPrototypeStep.transport);
  }

  void setBudget(
    int? value, {
    bool openEnded = false,
    bool autoAdvance = false,
  }) {
    _cancelAutoAdvance();
    _budgetPerPerson = value?.clamp(0, 20000);
    _budgetIsOpenEnded = value != null && openEnded;
    notifyListeners();
    if (autoAdvance && isStepComplete(NewTripPrototypeStep.budget)) {
      _scheduleAdvance(NewTripPrototypeStep.budget);
    }
  }

  void setBudgetFromText(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    setBudget(int.tryParse(digits));
  }

  void submitBudget() {
    if (isStepComplete(NewTripPrototypeStep.budget)) {
      _scheduleAdvance(NewTripPrototypeStep.budget);
    }
  }

  void toggleTravelStyle(PrototypeTravelStyle value) {
    if (_styles.remove(value)) {
      notifyListeners();
      return;
    }
    if (_styles.length >= 3) return;
    _styles.add(value);
    notifyListeners();
  }

  void selectPace(PrototypePace value) {
    _cancelAutoAdvance();
    _pace = value;
    notifyListeners();
    _scheduleAdvance(NewTripPrototypeStep.pace);
  }

  void selectWalking(PrototypeWalking value) {
    _cancelAutoAdvance();
    _walking = value;
    notifyListeners();
    _scheduleAdvance(NewTripPrototypeStep.walking);
  }

  bool isStepComplete(NewTripPrototypeStep step) => switch (step) {
    NewTripPrototypeStep.origin => hasOrigin,
    NewTripPrototypeStep.dates => _isDatePreferenceValid,
    NewTripPrototypeStep.company => _company != null && travelers > 0,
    NewTripPrototypeStep.transport => _transports.isNotEmpty,
    NewTripPrototypeStep.budget => (_budgetPerPerson ?? 0) >= 100,
    NewTripPrototypeStep.travelStyle => _styles.isNotEmpty,
    NewTripPrototypeStep.pace => _pace != null,
    NewTripPrototypeStep.walking => _walking != null,
  };

  bool get _isDatePreferenceValid => switch (_dateMode) {
    PrototypeDateMode.exact => exactNights >= 1,
    PrototypeDateMode.manualAvailability =>
      _departureDates.isNotEmpty && _manualDuration != null,
    PrototypeDateMode.savedAvailability =>
      _savedDuration != null && usableSavedWindows.isNotEmpty,
    PrototypeDateMode.open => _openDuration != null,
    null => false,
  };

  String? get dateValidationMessage => switch (_dateMode) {
    PrototypeDateMode.exact =>
      _exactStart == null
          ? 'Scegli il giorno di partenza.'
          : (_exactEnd == null || exactNights < 1)
          ? 'Scegli un ritorno: serve almeno una notte.'
          : null,
    PrototypeDateMode.manualAvailability =>
      _departureDates.isEmpty
          ? 'Segna almeno un possibile giorno di partenza.'
          : _manualDuration == null
          ? 'Indica quanto potrebbe durare il viaggio.'
          : null,
    PrototypeDateMode.savedAvailability =>
      !hasSavedFreeDays
          ? 'Aggiungi prima almeno un giorno nella scatola Giorni liberi.'
          : _savedDuration == null
          ? 'Indica quanto potrebbe durare il viaggio.'
          : usableSavedWindows.isEmpty
          ? 'Nessuna finestra inclusa è abbastanza lunga.'
          : null,
    PrototypeDateMode.open =>
      _openDuration == null ? 'Scegli una durata oppure Indifferente.' : null,
    null => null,
  };

  void performContextualAction() {
    if (!canPerformContextualAction) return;
    _advanceFrom(_currentStep);
  }

  void goToQuestion(NewTripPrototypeStep step, {bool returnToSummary = false}) {
    _cancelAutoAdvance();
    _clearRelaxation();
    _returnToSummaryAfterStep = returnToSummary;
    _stage = NewTripFlowStage.questions;
    _currentStep = step;
    if (step.index > _furthestStepIndex) _furthestStepIndex = step.index;
    notifyListeners();
  }

  bool consumeBack() {
    _cancelAutoAdvance();
    switch (_stage) {
      case NewTripFlowStage.questions:
        if (_returnToSummaryAfterStep) {
          _returnToSummaryAfterStep = false;
          _stage = NewTripFlowStage.summary;
          notifyListeners();
          return true;
        }
        if (_currentStep == NewTripPrototypeStep.dates && _dateMode != null) {
          showDateModePicker();
          return true;
        }
        final steps = questionSteps;
        final index = steps.indexOf(_currentStep);
        if (index <= 0) return false;
        _currentStep = steps[index - 1];
        break;
      case NewTripFlowStage.summary:
        _stage = NewTripFlowStage.questions;
        _currentStep = NewTripPrototypeStep.walking;
        break;
      case NewTripFlowStage.searching:
        _stage = NewTripFlowStage.summary;
        notifyListeners();
        return true;
      case NewTripFlowStage.results:
        _stage = NewTripFlowStage.summary;
        break;
      case NewTripFlowStage.compare:
        _stage = NewTripFlowStage.results;
        break;
      case NewTripFlowStage.selected:
        _stage = _shortlistIds.length >= 2
            ? NewTripFlowStage.compare
            : NewTripFlowStage.results;
        break;
    }
    notifyListeners();
    return true;
  }

  Future<void> startSearch() => _runSearch(clearRelaxation: true);

  Future<void> _runSearch({required bool clearRelaxation}) async {
    if (_stage != NewTripFlowStage.summary || !canStartSearch) return;
    if (clearRelaxation) _clearRelaxation();
    _stage = NewTripFlowStage.searching;
    _searchMessageIndex = 0;
    notifyListeners();
    for (var index = 1; index < searchMessages.length; index++) {
      await Future<void>.delayed(searchStageDelay);
      if (_disposed || _stage != NewTripFlowStage.searching) return;
      _searchMessageIndex = index;
      notifyListeners();
    }
    final found = await proposalSource.search(proposalQuery);
    if (_disposed || _stage != NewTripFlowStage.searching) return;
    _proposals = List<PrototypeTravelProposal>.unmodifiable(found);
    _shortlistIds.removeWhere(
      (id) => !_proposals.any((proposal) => proposal.id == id),
    );
    _stage = NewTripFlowStage.results;
    notifyListeners();
  }

  List<String> get searchMessages => const <String>[
    'Incrociamo date e durata',
    'Confrontiamo costi e collegamenti',
    'Rendiamo visibili i compromessi',
  ];

  int get searchMessageIndex => _searchMessageIndex;

  PrototypeProposalQuery get proposalQuery {
    final mode = _dateMode;
    final budget = _budgetPerPerson;
    final selectedPace = _pace;
    final selectedWalking = _walking;
    assert(
      mode != null &&
          budget != null &&
          selectedPace != null &&
          selectedWalking != null,
    );
    final bounds = durationBounds;
    return PrototypeProposalQuery(
      origin: origin!,
      dateMode: mode!,
      exactStart: _exactStart,
      exactEnd: _exactEnd,
      departureDates: List<DateTime>.unmodifiable(_departureDates),
      savedWindows: List<PrototypeDateWindow>.unmodifiable(usableSavedWindows),
      minimumDuration: bounds.$1,
      maximumDuration: (bounds.$2 + _relaxedDurationDays).clamp(1, 30),
      referenceDate: today,
      openHorizonMonths: _openHorizonMonths,
      travelers: travelers,
      transports: Set<PrototypeTransport>.unmodifiable(_transports),
      budgetPerPerson: budget! + _relaxedBudgetIncrease,
      styles: Set<PrototypeTravelStyle>.unmodifiable(_styles),
      pace: selectedPace!,
      walking: selectedWalking!,
      relaxationLabel: _activeRelaxation,
      extraDurationDays: _relaxedDurationDays,
      includeNearbyOrigins: _includeNearbyOrigins,
      budgetIncrease: _relaxedBudgetIncrease,
    );
  }

  (int, int) get durationBounds => switch (_dateMode) {
    PrototypeDateMode.exact => (exactNights, exactNights),
    PrototypeDateMode.manualAvailability => _durationBounds(
      _manualDuration!,
      _manualCustomMin,
      _manualCustomMax,
    ),
    PrototypeDateMode.savedAvailability => _durationBounds(
      _savedDuration!,
      _savedCustomMin,
      _savedCustomMax,
    ),
    PrototypeDateMode.open => _durationBounds(
      _openDuration!,
      _openCustomMin,
      _openCustomMax,
    ),
    null => (1, 14),
  };

  List<PrototypeTravelProposal> get proposals => _proposals;
  PrototypeProposalSort get proposalSort => _proposalSort;

  List<PrototypeTravelProposal> get sortedProposals {
    final sorted = <PrototypeTravelProposal>[..._proposals];
    int compare(PrototypeTravelProposal left, PrototypeTravelProposal right) {
      final result = switch (_proposalSort) {
        PrototypeProposalSort.lowestCost => left.cost.total.compareTo(
          right.cost.total,
        ),
        PrototypeProposalSort.shortestTravel =>
          left.changesCount != right.changesCount
              ? left.changesCount.compareTo(right.changesCount)
              : left.travelMinutes.compareTo(right.travelMinutes),
        PrototypeProposalSort.bestFit => right.fitScore.compareTo(
          left.fitScore,
        ),
        PrototypeProposalSort.balanced => _balanceScore(
          right,
        ).compareTo(_balanceScore(left)),
      };
      return result == 0
          ? left.sourceIndex.compareTo(right.sourceIndex)
          : result;
    }

    sorted.sort(compare);
    return List<PrototypeTravelProposal>.unmodifiable(sorted);
  }

  int _balanceScore(PrototypeTravelProposal proposal) {
    final budget = _budgetPerPerson ?? proposal.cost.total;
    final overBudget = (proposal.cost.total - budget).clamp(0, 20000);
    return proposal.fitScore * 10 - overBudget - proposal.travelMinutes ~/ 4;
  }

  void setProposalSort(PrototypeProposalSort value) {
    _proposalSort = value;
    notifyListeners();
  }

  UnmodifiableSetView<String> get shortlistIds =>
      UnmodifiableSetView<String>(_shortlistIds);
  bool get canCompare => _shortlistIds.length >= 2;
  bool get shortlistIsFull => _shortlistIds.length >= 4;

  bool isShortlisted(String id) => _shortlistIds.contains(id);

  void toggleShortlist(String id) {
    if (_shortlistIds.remove(id)) {
      notifyListeners();
      return;
    }
    if (shortlistIsFull || !_proposals.any((proposal) => proposal.id == id)) {
      return;
    }
    _shortlistIds.add(id);
    notifyListeners();
  }

  List<PrototypeTravelProposal> get comparisonProposals =>
      List<PrototypeTravelProposal>.unmodifiable(<PrototypeTravelProposal>[
        for (final id in _shortlistIds)
          _proposals.firstWhere((proposal) => proposal.id == id),
      ]);

  void openComparison() {
    if (!canCompare) return;
    _stage = NewTripFlowStage.compare;
    notifyListeners();
  }

  void returnToResults() {
    _stage = NewTripFlowStage.results;
    notifyListeners();
  }

  void chooseProposal(String id) {
    if (!_proposals.any((proposal) => proposal.id == id)) return;
    _selectedProposalId = id;
    _stage = NewTripFlowStage.selected;
    notifyListeners();
  }

  PrototypeTravelProposal? get selectedProposal {
    final id = _selectedProposalId;
    if (id == null) return null;
    return _proposals.firstWhere((proposal) => proposal.id == id);
  }

  List<PrototypeTravelProposal> get selectedAlternatives => comparisonProposals
      .where((proposal) => proposal.id != _selectedProposalId)
      .toList(growable: false);

  String? get activeRelaxation => _activeRelaxation;

  Future<void> retryWithRelaxation(String label) async {
    _clearRelaxation();
    switch (label) {
      case '+1 giorno':
        _relaxedDurationDays = 1;
        break;
      case 'Aeroporto vicino':
        _includeNearbyOrigins = true;
        break;
      case '+€100':
        _relaxedBudgetIncrease = 100;
        break;
      default:
        return;
    }
    _activeRelaxation = label;
    _stage = NewTripFlowStage.summary;
    notifyListeners();
    await _runSearch(clearRelaxation: false);
  }

  void _clearRelaxation() {
    _activeRelaxation = null;
    _relaxedDurationDays = 0;
    _includeNearbyOrigins = false;
    _relaxedBudgetIncrease = 0;
  }

  String plainSummaryFor(NewTripPrototypeStep step) => switch (step) {
    NewTripPrototypeStep.origin => origin ?? 'Da scegliere',
    NewTripPrototypeStep.dates => switch (_dateMode) {
      PrototypeDateMode.exact =>
        exactNights == 0
            ? 'Date da completare'
            : '$exactNights ${exactNights == 1 ? 'notte' : 'notti'}',
      PrototypeDateMode.manualAvailability =>
        '${_departureDates.length} ${_departureDates.length == 1 ? 'partenza possibile' : 'partenze possibili'} · ${_durationLabel(_manualDuration, _manualCustomMin, _manualCustomMax)}',
      PrototypeDateMode.savedAvailability =>
        '${usableSavedWindows.length} finestre dai giorni liberi · ${_durationLabel(_savedDuration, _savedCustomMin, _savedCustomMax)}',
      PrototypeDateMode.open =>
        'Date aperte · entro $_openHorizonMonths mesi · ${_durationLabel(_openDuration, _openCustomMin, _openCustomMax)}',
      null => 'Da scegliere',
    },
    NewTripPrototypeStep.company =>
      _company == null
          ? 'Da scegliere'
          : '${_company!.label} · $travelers ${travelers == 1 ? 'persona' : 'persone'}',
    NewTripPrototypeStep.transport =>
      _transports.isEmpty
          ? 'Da scegliere'
          : acceptsAnyTransport
          ? 'Qualsiasi, se conviene'
          : _transports.map((item) => item.label).join(', '),
    NewTripPrototypeStep.budget =>
      _budgetPerPerson == null
          ? 'Da scegliere'
          : '€$_budgetPerPerson${_budgetIsOpenEnded ? '+' : ''} a persona',
    NewTripPrototypeStep.travelStyle =>
      _styles.isEmpty
          ? 'Da scegliere'
          : _styles.map((item) => item.label).join(', '),
    NewTripPrototypeStep.pace => _pace?.label ?? 'Da scegliere',
    NewTripPrototypeStep.walking => _walking?.label ?? 'Da scegliere',
  };

  String originFailureMessage() => switch (_originFailure) {
    PrototypeOriginFailure.servicesDisabled =>
      'La localizzazione è disattivata. Inserisci città, aeroporto o stazione.',
    PrototypeOriginFailure.permissionDenied =>
      'Non hai autorizzato la posizione. Puoi inserire la partenza manualmente.',
    PrototypeOriginFailure.permissionDeniedForever =>
      'Il permesso è bloccato nelle impostazioni. Per ora inserisci la partenza.',
    PrototypeOriginFailure.timedOut =>
      'La posizione sta impiegando troppo tempo. Inserisci la partenza.',
    PrototypeOriginFailure.lookupFailed =>
      'Abbiamo trovato la posizione, ma non la città. Inseriscila manualmente.',
    PrototypeOriginFailure.unavailable ||
    null => 'Non riusciamo a rilevare la partenza. Inseriscila manualmente.',
  };

  void _scheduleAdvance(NewTripPrototypeStep expectedStep) {
    _cancelAutoAdvance();
    _autoAdvanceTimer = Timer(autoAdvanceDelay, () {
      if (_disposed) return;
      _advanceFrom(expectedStep);
    });
  }

  void _advanceFrom(NewTripPrototypeStep expectedStep) {
    _cancelAutoAdvance();
    if (_stage != NewTripFlowStage.questions ||
        _currentStep != expectedStep ||
        !isStepComplete(expectedStep)) {
      return;
    }
    if (_returnToSummaryAfterStep) {
      _returnToSummaryAfterStep = false;
      _stage = NewTripFlowStage.summary;
      notifyListeners();
      return;
    }
    final index = NewTripPrototypeStep.values.indexOf(expectedStep);
    if (index >= NewTripPrototypeStep.values.length - 1) {
      _furthestStepIndex = NewTripPrototypeStep.walking.index;
      _stage = NewTripFlowStage.summary;
      notifyListeners();
      return;
    }
    _currentStep = NewTripPrototypeStep.values[index + 1];
    if (_currentStep.index > _furthestStepIndex) {
      _furthestStepIndex = _currentStep.index;
    }
    notifyListeners();
  }

  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  (int, int) _durationBounds(
    PrototypeDurationPreset preset,
    int customMin,
    int customMax,
  ) => preset == PrototypeDurationPreset.custom
      ? _normalizedDuration(customMin, customMax)
      : (preset.minimumDays, preset.maximumDays);

  (int, int) _normalizedDuration(int minimum, int maximum) {
    final min = minimum.clamp(1, 30);
    final max = maximum.clamp(1, 30);
    return min <= max ? (min, max) : (max, min);
  }

  String _durationLabel(
    PrototypeDurationPreset? preset,
    int customMin,
    int customMax,
  ) {
    if (preset == null) return 'durata da scegliere';
    if (preset == PrototypeDurationPreset.any) return 'durata indifferente';
    final bounds = _durationBounds(preset, customMin, customMax);
    return '${bounds.$1}–${bounds.$2} giorni';
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAutoAdvance();
    super.dispose();
  }
}
