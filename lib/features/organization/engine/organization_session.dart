import 'dart:async';
import '../../chat_first_prototype/plan_models.dart';
import '../adapters/trip_plan_mapper.dart';
import '../events/organization_events.dart';
import '../models/organization_card.dart';
import '../models/organization_models.dart';
import '../models/organization_state.dart';
import '../providers/organization_ai_gateway.dart';
import '../providers/stay_search_provider.dart';
import '../providers/travel_search_provider.dart';
import 'organization_reducer.dart';

/// Sessione reattiva di organizzazione viaggio.
/// Coordina la macchina a stati, il gateway AI e i provider di ricerca reali o mock.
class OrganizationSession {
  OrganizationSession({
    required this.tripId,
    required this.aiGateway,
    required this.travelProvider,
    required this.stayProvider,
    OrganizationState? initialState,
  }) : _state =
           initialState ??
           OrganizationState(
             tripId: tripId,
             phase: OrganizationPhase.collectingIntent,
             intent: TripIntent(tripId: tripId, rawDesire: ''),
           );

  final String tripId;
  final OrganizationAiGateway aiGateway;
  final TravelSearchProvider travelProvider;
  final StaySearchProvider stayProvider;

  OrganizationState _state;
  OrganizationState get state => _state;

  final StreamController<OrganizationState> _stateController =
      StreamController<OrganizationState>.broadcast();
  Stream<OrganizationState> get states => _stateController.stream;

  final StreamController<OrganizationEvent> _eventController =
      StreamController<OrganizationEvent>.broadcast();
  Stream<OrganizationEvent> get events => _eventController.stream;

  int _sequence = 0;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void _dispatch(OrganizationEvent event) {
    if (_isDisposed) return;
    _state = reduceOrganizationState(_state, event);
    _eventController.add(event);
    _stateController.add(_state);
  }

  /// Invia il desiderio iniziale dell'utente.
  Future<void> submitDesire(String desire) async {
    if (desire.trim().isEmpty) {
      _dispatch(
        OrganizationEvent(
          sequence: ++_sequence,
          tripId: tripId,
          kind: OrganizationEventKind.error,
          payload: const <String, Object?>{'code': 'empty_desire'},
        ),
      );
      return;
    }

    final newIntent = _state.intent.copyWith(rawDesire: desire, tripId: tripId);

    _dispatch(
      IntentCreatedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        intent: newIntent,
      ),
    );

    // Consulta l'AI gateway per il prossimo passo
    final aiResponse = await aiGateway.decideNextStep(
      OrganizationAiContext(
        intent: newIntent,
        questionBudget: const QuestionBudget(essential: 3, adaptive: 2),
      ),
    );

    if (aiResponse.nextQuestion != null) {
      final q = aiResponse.nextQuestion!;
      _dispatch(
        QuestionRequestedEvent(
          sequence: ++_sequence,
          tripId: tripId,
          questionKey: q.id,
          questionText: q.prompt,
          options: q.options,
          isAdaptive: q.isAdaptive,
        ),
      );
    }
  }

  /// Conferma la risposta a una domanda mirata.
  Future<void> answerQuestion({
    required String questionKey,
    required dynamic answer,
  }) async {
    _dispatch(
      UserAnswerConfirmedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        questionKey: questionKey,
        answer: answer,
      ),
    );
  }

  /// Avvia la ricerca di trasporto con i criteri correnti.
  Future<void> startTravelSearch() async {
    final query = TravelSearchQuery(
      tripId: tripId,
      originCandidates: _state.intent.originCandidates,
      destinationCandidates: _state.intent.destinationCandidates,
      dateConstraint:
          _state.intent.dateConstraint ??
          ExactDates(
            departure: DateTime(2026, 11, 20),
            returnDate: DateTime(2026, 11, 24),
          ),
      duration:
          _state.intent.duration ??
          const DurationRange(minimumDays: 2, maximumDays: 5),
      travelers: _state.intent.travelers,
      acceptedModes: _state.intent.acceptedModes,
      budgetCentsPerPerson: _state.intent.budgetCentsPerPerson,
    );

    _dispatch(
      SearchStartedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        sessionId: 'sess-$tripId-$_sequence',
        targetType: OfferKind.flight,
      ),
    );

    await for (final update in travelProvider.search(query)) {
      if (_isDisposed) break;
      switch (update.kind) {
        case ProviderUpdateKind.started:
          break;
        case ProviderUpdateKind.progressed:
          _dispatch(
            SearchProgressedEvent(
              sequence: ++_sequence,
              tripId: tripId,
              sessionId: 'sess-$tripId',
              stageMessage: update.message ?? '',
            ),
          );
          break;
        case ProviderUpdateKind.partial:
          _dispatch(
            SearchPartialResultsEvent(
              sequence: ++_sequence,
              tripId: tripId,
              sessionId: 'sess-$tripId',
              offers: update.offers,
            ),
          );
          break;
        case ProviderUpdateKind.completed:
          _dispatch(
            SearchCompletedEvent(
              sequence: ++_sequence,
              tripId: tripId,
              sessionId: 'sess-$tripId',
              totalOffersFound: update.offers.length,
            ),
          );
          break;
        case ProviderUpdateKind.degraded:
          _dispatch(
            ProviderDegradedEvent(
              sequence: ++_sequence,
              tripId: tripId,
              providerId: update.providerId,
              reason: update.message ?? 'Degradato',
            ),
          );
          break;
        case ProviderUpdateKind.failed:
          _dispatch(
            OrganizationEvent(
              sequence: ++_sequence,
              tripId: tripId,
              kind: OrganizationEventKind.error,
              payload: <String, Object?>{'code': 'search_failed'},
            ),
          );
          break;
      }
    }
  }

  /// Seleziona un'offerta volo.
  Future<void> selectFlight(String offerId) async {
    _dispatch(
      FlightSelectedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        flightOfferId: offerId,
        decision: UserDecision(
          id: 'dec-flight-$offerId',
          tripId: tripId,
          target: DecisionTarget.flight,
          targetId: offerId,
          status: DecisionStatus.selected,
        ),
      ),
    );
  }

  /// Apre il link di acquisto partner esterno.
  /// Porta la fase ad `awaitingFlightConfirmation` o `awaitingStayConfirmation`.
  Future<void> openExternalPurchase(
    String offerId, {
    String? purchaseUrl,
  }) async {
    _dispatch(
      ExternalPurchaseOpenedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        targetOfferId: offerId,
        url: purchaseUrl ?? 'https://example.com/checkout/$offerId',
      ),
    );
  }

  /// Conferma esplicita dell'utente di aver acquistato il volo.
  /// Questa azione sblocca la raccolta preferenze di esperienza.
  Future<void> confirmFlightPurchase(
    String offerId, {
    String? bookingReference,
  }) async {
    _dispatch(
      FlightConfirmedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        flightOfferId: offerId,
        bookingReference: bookingReference,
        decision: UserDecision(
          id: 'dec-flight-$offerId',
          tripId: tripId,
          target: DecisionTarget.flight,
          targetId: offerId,
          status: DecisionStatus.confirmed,
          confirmedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Invia il contesto e le preferenze di esperienza.
  Future<void> submitExperiencePreferences(ExperienceContext context) async {
    if (_state.confirmedFlight == null) {
      _dispatch(
        OrganizationEvent(
          sequence: ++_sequence,
          tripId: tripId,
          kind: OrganizationEventKind.error,
          payload: const <String, Object?>{'code': 'flight_not_confirmed'},
        ),
      );
      return;
    }

    _dispatch(
      ExperienceContextRequestedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        destination: _state.intent.candidateDestinations.isNotEmpty
            ? _state.intent.candidateDestinations.first
            : 'Lisbona',
      ),
    );
  }

  /// Proposta delle zone consigliate per la sistemazione.
  Future<void> proposeZones(List<String> zones) async {
    if (_state.confirmedFlight == null) {
      _dispatch(
        OrganizationEvent(
          sequence: ++_sequence,
          tripId: tripId,
          kind: OrganizationEventKind.error,
          payload: const <String, Object?>{'code': 'flight_not_confirmed'},
        ),
      );
      return;
    }

    _dispatch(
      ZoneProposedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        zoneNames: zones,
      ),
    );
  }

  /// Seleziona una zona per il soggiorno ed esegue la ricerca con stayProvider.
  Future<void> selectZone(String zoneName) async {
    if (_state.confirmedFlight == null) {
      _dispatch(
        OrganizationEvent(
          sequence: ++_sequence,
          tripId: tripId,
          kind: OrganizationEventKind.error,
          payload: const <String, Object?>{'code': 'flight_not_confirmed'},
        ),
      );
      return;
    }

    final sessId = 'sess-stay-$_sequence';
    _dispatch(
      StaySearchStartedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        sessionId: sessId,
        zone: zoneName,
      ),
    );

    final query = StaySearchQuery(
      tripId: tripId,
      confirmedFlight: _state.confirmedFlight!,
      zoneId: 'zone-${zoneName.toLowerCase().replaceAll(' ', '-')}',
      zoneLabel: zoneName,
      zoneLatitude: 38.7118,
      zoneLongitude: -9.1366,
      travelers: _state.intent.travelers,
    );

    await for (final update in stayProvider.search(query)) {
      if (_isDisposed) break;
      if (update.offers.isNotEmpty) {
        _dispatch(
          SearchPartialResultsEvent(
            sequence: ++_sequence,
            tripId: tripId,
            sessionId: sessId,
            offers: update.offers,
          ),
        );
      }
      if (update.kind == ProviderUpdateKind.degraded) {
        _dispatch(
          ProviderDegradedEvent(
            sequence: ++_sequence,
            tripId: tripId,
            providerId: update.providerId,
            reason: update.message ?? 'Nessun provider alloggi configurato',
          ),
        );
      } else if (update.kind == ProviderUpdateKind.completed ||
          update.kind == ProviderUpdateKind.failed) {
        _dispatch(
          SearchCompletedEvent(
            sequence: ++_sequence,
            tripId: tripId,
            sessionId: sessId,
            totalOffersFound: update.offers.length,
          ),
        );
      }
    }
  }

  /// Seleziona un'offerta soggiorno.
  Future<void> selectStay(String offerId) async {
    _dispatch(
      StaySelectedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        stayOfferId: offerId,
        decision: UserDecision(
          id: 'dec-stay-$offerId',
          tripId: tripId,
          target: DecisionTarget.stay,
          targetId: offerId,
          status: DecisionStatus.selected,
        ),
      ),
    );
  }

  /// Conferma esplicita dell'utente di aver acquistato il soggiorno.
  /// Questa azione sblocca la formulazione del piano di viaggio.
  Future<void> confirmStayPurchase(String offerId) async {
    _dispatch(
      StayConfirmedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        stayOfferId: offerId,
        decision: UserDecision(
          id: 'dec-stay-$offerId',
          tripId: tripId,
          target: DecisionTarget.stay,
          targetId: offerId,
          status: DecisionStatus.confirmed,
          confirmedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Genera il piano di viaggio definitivo mappato dai dati confermati.
  Future<TripSnapshot> generatePlan() async {
    if (_state.confirmedFlight == null || _state.confirmedStay == null) {
      _dispatch(
        OrganizationEvent(
          sequence: ++_sequence,
          tripId: tripId,
          kind: OrganizationEventKind.error,
          payload: const <String, Object?>{
            'code': 'missing_confirmed_flight_or_stay',
          },
        ),
      );
      throw StateError(
        'Impossibile generare il piano: volo e alloggio devono essere entrambi confermati.',
      );
    }

    final snapshot = TripPlanMapper.mapStateToSnapshot(_state);

    _dispatch(
      PlanProposedEvent(
        sequence: ++_sequence,
        tripId: tripId,
        planCard: OrganizationCard(
          id: 'card-plan-$tripId',
          tripId: tripId,
          kind: OrganizationCardKind.planProposal,
          state: OrganizationCardState.ready,
          title: 'Piano di viaggio pronto',
          description:
              'Abbiamo strutturato l\'itinerario di ${snapshot.durationLabel} a ${snapshot.destinationTitle} attorno ai tuoi voli e alla tua zona.',
          payload: <String, dynamic>{
            'destination': snapshot.destinationTitle,
            'daysCount': snapshot.days.length,
            'totalEur': snapshot.costSummary.projectedTotalCents / 100,
          },
        ),
      ),
    );

    return snapshot;
  }

  /// Rilascia le risorse e chiude gli stream della sessione.

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stateController.close();
    _eventController.close();
  }
}
