import 'dart:async';
import 'package:flutter/foundation.dart';
import '../adapters/flight_search_adapter.dart';
import '../events/organization_events.dart';
import '../models/organization_card.dart';
import '../models/organization_models.dart';

/// Domande canoniche previste nel flusso essenziale e adattivo.
class OrganizationQuestions {
  static const String origin = 'origin';
  static const String dates = 'dates';
  static const String company = 'company';
  static const String transport = 'transport';
  static const String budget = 'budget';
  static const String pace = 'pace';
}

/// Orchestratore centrale reattivo del flusso di organizzazione viaggio.
class OrganizationOrchestrator extends ChangeNotifier {
  OrganizationOrchestrator({
    required this.tripId,
    this.flightAdapter = const FlightSearchAdapter(),
  });

  final String tripId;
  final FlightSearchAdapter flightAdapter;

  TripIntent? _intent;
  TripIntent? get intent => _intent;

  final List<OrganizationCard> _cards = <OrganizationCard>[];
  List<OrganizationCard> get cards => List.unmodifiable(_cards);

  final List<OrganizationEvent> _events = <OrganizationEvent>[];
  List<OrganizationEvent> get events => List.unmodifiable(_events);

  SearchSession? _currentSearchSession;
  SearchSession? get currentSearchSession => _currentSearchSession;

  List<ProviderOffer> _flightOffers = <ProviderOffer>[];
  List<ProviderOffer> get flightOffers => List.unmodifiable(_flightOffers);

  UserDecision? _flightDecision;
  UserDecision? get flightDecision => _flightDecision;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  int _questionsAskedCount = 0;
  static const int maxEssentialQuestions = 4;

  /// Avvia l'orchestrazione a partire dal testo di desiderio iniziale espresso dall'utente.
  Future<void> startWithDesire(String desireText) async {
    final now = DateTime.now();
    final detectedDestination = _detectDestinationFromText(desireText);
    final detectedBudget = _detectBudgetFromText(desireText);

    _intent = TripIntent(
      id: tripId,
      text: desireText,
      candidateDestinations: detectedDestination != null
          ? <String>[detectedDestination]
          : const <String>[],
      budgetEurPerPerson: detectedBudget,
      dateMode: OrganizationDateMode.flexible,
    );

    _emitEvent(
      IntentCreatedEvent(
        id: 'evt-intent-$tripId',
        tripId: tripId,
        timestamp: now,
        intent: _intent!,
      ),
    );

    // Aggiungi la IntentSummaryCard
    _cards.add(
      OrganizationCard(
        id: 'card-intent-$tripId',
        tripId: tripId,
        kind: OrganizationCardKind.intentSummary,
        state: OrganizationCardState.ready,
        title: 'Desiderio di viaggio',
        description: desireText,
        payload: <String, dynamic>{
          'candidateDestinations': _intent!.candidateDestinations,
          'budgetEurPerPerson': _intent!.budgetEurPerPerson,
        },
      ),
    );

    // Determina la prima domanda
    _askNextQuestion();
    notifyListeners();
  }

  /// Risponde a una domanda mirata ed avanza l'orchestrazione.
  Future<void> answerQuestion(String questionKey, dynamic answer) async {
    if (_intent == null) return;

    final now = DateTime.now();
    _emitEvent(
      UserAnswerConfirmedEvent(
        id: 'evt-ans-${_events.length + 1}',
        tripId: tripId,
        timestamp: now,
        questionKey: questionKey,
        answer: answer,
      ),
    );

    // Aggiorna l'intento in base alla risposta
    _updateIntentWithAnswer(questionKey, answer);

    // Marca la QuestionCard corrente come answered / confirmed
    final cardIndex = _cards.indexWhere(
      (c) =>
          c.kind == OrganizationCardKind.question &&
          c.payload['questionKey'] == questionKey,
    );
    if (cardIndex != -1) {
      _cards[cardIndex] = _cards[cardIndex].copyWith(
        state: OrganizationCardState.confirmed,
        description: 'Risposta: $answer',
      );
    }

    if (_hasEnoughContextForSearch()) {
      _intent = _intent!.copyWith(isComplete: true);
      await startFlightSearch();
    } else {
      _askNextQuestion();
    }
    notifyListeners();
  }

  /// Avvia la ricerca di trasporto/voli con i dati raccolti.
  Future<void> startFlightSearch({
    FlightSortCriterion sortBy = FlightSortCriterion.best,
  }) async {
    if (_intent == null) return;

    final now = DateTime.now();
    final sessionId = 'sess-${now.millisecondsSinceEpoch}';
    _isSearching = true;

    _currentSearchSession = SearchSession(
      id: sessionId,
      tripId: tripId,
      query:
          '${_intent!.origin ?? "Milano"} -> ${_intent!.candidateDestinations.isNotEmpty ? _intent!.candidateDestinations.first : "Budapest"}',
      providers: const <String>['fast-flights'],
      startedAt: now,
      updatedAt: now,
      status: SearchSessionStatus.searching,
    );

    _emitEvent(
      SearchStartedEvent(
        id: 'evt-search-start-${_events.length + 1}',
        tripId: tripId,
        timestamp: now,
        sessionId: sessionId,
        targetType: OfferType.flight,
        providers: _currentSearchSession!.providers,
      ),
    );

    // Aggiunge la SearchStatusCard
    final destination = _intent!.candidateDestinations.isNotEmpty
        ? _intent!.candidateDestinations.first
        : 'Budapest';
    final origin = _intent!.origin ?? 'Milano';

    final statusCard = OrganizationCard(
      id: 'card-status-$sessionId',
      tripId: tripId,
      kind: OrganizationCardKind.searchStatus,
      state: OrganizationCardState.searching,
      title: 'Ricerca voli reali in corso',
      description:
          'Confronto collegamenti diretti e alternativi da $origin verso $destination...',
      payload: <String, dynamic>{
        'sessionId': sessionId,
        'origin': origin,
        'destination': destination,
      },
    );
    _cards.add(statusCard);
    notifyListeners();

    _emitEvent(
      SearchProgressedEvent(
        id: 'evt-search-prog-${_events.length + 1}',
        tripId: tripId,
        timestamp: DateTime.now(),
        sessionId: sessionId,
        stageMessage: 'Interrogazione tariffe e disponibilità...',
      ),
    );

    // Esegue la ricerca tramite l'adapter
    final offers = await flightAdapter.searchFlights(
      destination: destination,
      originCity: origin,
      sortBy: sortBy,
      budgetPerPerson: _intent!.budgetEurPerPerson,
    );

    _flightOffers = offers;
    _isSearching = false;

    _currentSearchSession = _currentSearchSession!.copyWith(
      status: SearchSessionStatus.completed,
      partialResultsCount: offers.length,
      updatedAt: DateTime.now(),
    );

    _emitEvent(
      SearchCompletedEvent(
        id: 'evt-search-complete-${_events.length + 1}',
        tripId: tripId,
        timestamp: DateTime.now(),
        sessionId: sessionId,
        totalOffersFound: offers.length,
      ),
    );

    // Rimuove la search status card e aggiunge la FlightComparisonCard
    _cards.removeWhere((c) => c.id == statusCard.id);

    _cards.add(
      OrganizationCard(
        id: 'card-flights-$sessionId',
        tripId: tripId,
        kind: OrganizationCardKind.flightComparison,
        state: OrganizationCardState.ready,
        title: 'Confronto Voli per $destination',
        description:
            '${offers.length} combinazioni verificate con orari e prezzi reali.',
        payload: <String, dynamic>{
          'destination': destination,
          'offers': offers,
          'sortBy': sortBy.name,
        },
        actions: <CardAction>[
          const CardAction(
            id: 'act-sort-best',
            label: 'Miglior equilibrio',
            actionType: CardActionType.select,
            isPrimary: true,
          ),
        ],
        verifiedAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// Seleziona un'offerta volo (crea UserDecision provvisoria).
  void selectFlightOffer(ProviderOffer offer) {
    final now = DateTime.now();
    _flightDecision = UserDecision(
      id: 'dec-fl-${now.millisecondsSinceEpoch}',
      tripId: tripId,
      targetType: DecisionTargetType.flight,
      targetId: offer.id,
      selectedAt: now,
      status: DecisionStatus.provisional,
      requiresExplicitConfirmation: true,
    );

    _emitEvent(
      FlightSelectedEvent(
        id: 'evt-fl-sel-${_events.length + 1}',
        tripId: tripId,
        timestamp: now,
        flightOfferId: offer.id,
        decision: _flightDecision!,
      ),
    );

    // Aggiorna lo stato della card di confronto voli
    final compCardIndex = _cards.indexWhere(
      (c) => c.kind == OrganizationCardKind.flightComparison,
    );
    if (compCardIndex != -1) {
      _cards[compCardIndex] = _cards[compCardIndex].copyWith(
        state: OrganizationCardState.selected,
        description:
            'Volo selezionato: ${offer.origin} -> ${offer.destination} (${offer.priceEur.toStringAsFixed(2)} €)',
      );
    }

    notifyListeners();
  }

  void _askNextQuestion() {
    if (_questionsAskedCount >= maxEssentialQuestions) {
      if (_hasEnoughContextForSearch()) {
        startFlightSearch();
      }
      return;
    }

    if (_intent!.origin == null) {
      _createQuestionCard(
        key: OrganizationQuestions.origin,
        title: 'Da dove preferisci partire?',
        options: const <String>[
          'Milano',
          'Roma',
          'Bologna',
          'Napoli',
          'Venezia',
          'Non lo so ancora',
        ],
      );
      _questionsAskedCount++;
      return;
    }

    if (_intent!.candidateDestinations.isEmpty) {
      _createQuestionCard(
        key: 'destination',
        title: 'Hai in mente una destinazione specifica?',
        options: const <String>[
          'Budapest',
          'Porto',
          'Lisbona',
          'Roma',
          'Decidi tu (Mete del momento)',
        ],
      );
      _questionsAskedCount++;
      return;
    }

    if (_intent!.budgetEurPerPerson == null) {
      _createQuestionCard(
        key: OrganizationQuestions.budget,
        title: 'Qual è il tuo budget indicativo a persona?',
        options: const <String>[
          'Sotto i 150 €',
          '150–300 €',
          '300–500 €',
          'Libero / Non lo so',
        ],
      );
      _questionsAskedCount++;
      return;
    }
  }

  void _createQuestionCard({
    required String key,
    required String title,
    required List<String> options,
  }) {
    final cardId = 'card-q-$key-${DateTime.now().millisecondsSinceEpoch}';
    _emitEvent(
      QuestionRequestedEvent(
        id: 'evt-q-${_events.length + 1}',
        tripId: tripId,
        timestamp: DateTime.now(),
        questionKey: key,
        questionText: title,
        options: options,
      ),
    );

    _cards.add(
      OrganizationCard(
        id: cardId,
        tripId: tripId,
        kind: OrganizationCardKind.question,
        state: OrganizationCardState.ready,
        title: title,
        payload: <String, dynamic>{'questionKey': key, 'options': options},
        actions: options.map((opt) {
          return CardAction(
            id: 'act-$key-$opt',
            label: opt,
            actionType: CardActionType.select,
          );
        }).toList(),
      ),
    );
  }

  void _updateIntentWithAnswer(String key, dynamic answer) {
    if (_intent == null) return;
    switch (key) {
      case OrganizationQuestions.origin:
        final originStr = answer.toString();
        if (!originStr.toLowerCase().contains('non lo so')) {
          _intent = _intent!.copyWith(origin: originStr);
        } else {
          _intent = _intent!.copyWith(origin: 'Milano'); // fallback ragionato
        }
        break;
      case 'destination':
        final destStr = answer.toString();
        if (!destStr.toLowerCase().contains('decidi')) {
          _intent = _intent!.copyWith(candidateDestinations: <String>[destStr]);
        } else {
          _intent = _intent!.copyWith(
            candidateDestinations: const <String>['Budapest'],
          );
        }
        break;
      case OrganizationQuestions.budget:
        final bStr = answer.toString();
        if (bStr.contains('150–300')) {
          _intent = _intent!.copyWith(budgetEurPerPerson: 250.0);
        } else if (bStr.contains('Sotto i 150')) {
          _intent = _intent!.copyWith(budgetEurPerPerson: 120.0);
        } else if (bStr.contains('300–500')) {
          _intent = _intent!.copyWith(budgetEurPerPerson: 400.0);
        }
        break;
    }
  }

  bool _hasEnoughContextForSearch() {
    if (_intent == null) return false;
    return _intent!.origin != null && _intent!.candidateDestinations.isNotEmpty;
  }

  void _emitEvent(OrganizationEvent event) {
    _events.add(event);
  }

  String? _detectDestinationFromText(String text) {
    final lower = text.toLowerCase();
    const destinations = [
      'budapest',
      'porto',
      'lisbona',
      'roma',
      'barcellona',
      'parigi',
      'berlino',
      'praga',
      'amsterdam',
      'vienna',
      'madrid',
      'londra',
    ];
    for (final dest in destinations) {
      if (lower.contains(dest)) {
        return dest[0].toUpperCase() + dest.substring(1);
      }
    }
    return null;
  }

  double? _detectBudgetFromText(String text) {
    final match = RegExp(r'(\d+)\s*€').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
}
