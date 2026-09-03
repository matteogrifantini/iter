import '../events/organization_events.dart';
import '../models/organization_card.dart';
import '../models/organization_models.dart';
import '../models/organization_state.dart';

/// Reducer puro per il calcolo deterministico del prossimo [OrganizationState].
/// Applica rigorosamente la matrice di transizione e le invarianti di business.
OrganizationState reduceOrganizationState(
  OrganizationState current,
  OrganizationEvent event,
) {
  // L'evento error non muta lo stato protetto
  if (event.kind == OrganizationEventKind.error) {
    return current;
  }

  switch (event.kind) {
    case OrganizationEventKind.intentCreated:
      final newIntent = event is IntentCreatedEvent
          ? event.intent
          : current.intent;
      final summaryCard = OrganizationCard(
        id: 'card-intent-${event.tripId}',
        tripId: event.tripId,
        kind: OrganizationCardKind.intentSummary,
        state: OrganizationCardState.ready,
        title: 'Desiderio di viaggio',
        description: newIntent.rawDesire,
        payload: <String, dynamic>{
          'rawDesire': newIntent.rawDesire,
          'candidateDestinations': newIntent.candidateDestinations,
          'budgetEurPerPerson': newIntent.budgetEurPerPerson,
        },
      );
      return current.copyWith(
        phase: OrganizationPhase.collectingIntent,
        intent: newIntent,
        cards: <OrganizationCard>[summaryCard],
      );

    case OrganizationEventKind.questionRequested:
      if (current.phase != OrganizationPhase.collectingIntent) {
        return current;
      }
      final payload = event.payload;
      final qKey = payload['questionKey']?.toString() ?? 'question';
      final qText = payload['questionText']?.toString() ?? '';
      final options =
          (payload['options'] as List<dynamic>?)?.cast<String>() ??
          const <String>[];
      final isAdaptive = payload['isAdaptive'] as bool? ?? false;

      final questionCard = OrganizationCard(
        id: 'card-q-${event.tripId}-$qKey',
        tripId: event.tripId,
        kind: OrganizationCardKind.question,
        state: OrganizationCardState.ready,
        title: 'Domanda',
        description: qText,
        payload: <String, dynamic>{
          'questionKey': qKey,
          'questionText': qText,
          'options': options,
          'isAdaptive': isAdaptive,
        },
      );
      return current.copyWith(
        cards: <OrganizationCard>[...current.cards, questionCard],
      );

    case OrganizationEventKind.answerConfirmed:
      final payload = event.payload;
      final qKey = payload['questionKey']?.toString() ?? '';
      final answer = payload['answer'];

      final updatedCards = current.cards.map((card) {
        if (card.kind == OrganizationCardKind.question &&
            card.payload['questionKey'] == qKey) {
          return card.copyWith(
            state: OrganizationCardState.confirmed,
            description: 'Risposta: $answer',
          );
        }
        return card;
      }).toList();

      return current.copyWith(cards: updatedCards);

    case OrganizationEventKind.searchStarted:
      final payload = event.payload;
      final targetType = payload['targetType']?.toString() ?? 'flight';
      final isStay = targetType == 'stay';

      // Invariante: ricerca alloggi bloccata finché il volo non è confermato
      if (isStay && current.confirmedFlight == null) {
        return current;
      }

      final nextPhase = isStay
          ? OrganizationPhase.searchingStay
          : OrganizationPhase.searchingTransport;

      final sessionId =
          payload['sessionId']?.toString() ?? 'session-${event.sequence}';
      final searchCard = OrganizationCard(
        id: 'card-search-$sessionId',
        tripId: event.tripId,
        kind: OrganizationCardKind.searchStatus,
        state: OrganizationCardState.ready,
        title: isStay ? 'Ricerca alloggi in corso' : 'Ricerca voli in corso',
        description: 'Scansione delle migliori opzioni...',
        payload: <String, dynamic>{
          'sessionId': sessionId,
          'targetType': targetType,
        },
      );

      final newSession = SearchSession(
        id: sessionId,
        tripId: event.tripId,
        query: isStay ? 'Alloggi' : 'Voli',
        startedAt: event.occurredAt,
        updatedAt: event.occurredAt,
        status: SearchSessionStatus.searching,
      );

      return current.copyWith(
        phase: nextPhase,
        cards: <OrganizationCard>[...current.cards, searchCard],
        searchSessions: <SearchSession>[...current.searchSessions, newSession],
      );

    case OrganizationEventKind.searchProgressed:
      final payload = event.payload;
      final sessionId = payload['sessionId']?.toString();
      final stageMessage = payload['stageMessage']?.toString() ?? '';

      final updatedCards = current.cards.map((card) {
        if (card.kind == OrganizationCardKind.searchStatus &&
            card.payload['sessionId'] == sessionId) {
          return card.copyWith(description: stageMessage);
        }
        return card;
      }).toList();

      return current.copyWith(cards: updatedCards);

    case OrganizationEventKind.searchPartialResults:
      final offers = event is SearchPartialResultsEvent
          ? event.offers
          : const <ProviderOffer>[];
      final isStay = current.phase == OrganizationPhase.searchingStay;

      final comparisonCard = OrganizationCard(
        id: 'card-comparison-${event.tripId}',
        tripId: event.tripId,
        kind: isStay
            ? OrganizationCardKind.stayComparison
            : OrganizationCardKind.flightComparison,
        state: OrganizationCardState.ready,
        title: isStay ? 'Alloggi individuati' : 'Voli individuati',
        payload: <String, dynamic>{
          'offersCount': offers.length,
          'offers': offers,
        },
      );

      final cards = List<OrganizationCard>.from(current.cards);
      final existingIndex = cards.indexWhere(
        (c) =>
            c.kind ==
            (isStay
                ? OrganizationCardKind.stayComparison
                : OrganizationCardKind.flightComparison),
      );
      if (existingIndex != -1) {
        cards[existingIndex] = comparisonCard;
      } else {
        cards.add(comparisonCard);
      }

      return current.copyWith(cards: cards);

    case OrganizationEventKind.searchCompleted:
      final isStay =
          current.phase == OrganizationPhase.searchingStay ||
          current.phase == OrganizationPhase.awaitingStayPurchase;
      final nextPhase = isStay
          ? OrganizationPhase.awaitingStayPurchase
          : OrganizationPhase.awaitingFlightPurchase;

      final updatedCards = current.cards.map((card) {
        if (card.kind == OrganizationCardKind.searchStatus) {
          return card.copyWith(
            state: OrganizationCardState.confirmed,
            description: 'Ricerca completata.',
          );
        }
        return card;
      }).toList();

      if (isStay &&
          !updatedCards.any(
            (c) => c.kind == OrganizationCardKind.stayComparison,
          )) {
        updatedCards.add(
          OrganizationCard(
            id: 'card-stay-comparison-${event.tripId}',
            tripId: event.tripId,
            kind: OrganizationCardKind.stayComparison,
            state: OrganizationCardState.ready,
            title: 'Alloggi consigliati',
            payload: const <String, dynamic>{'offers': <ProviderOffer>[]},
          ),
        );
      }

      return current.copyWith(phase: nextPhase, cards: updatedCards);

    case OrganizationEventKind.flightSelected:
      final flightId = event.payload['flightOfferId']?.toString() ?? '';
      final decision = UserDecision(
        id: 'dec-flight-$flightId',
        tripId: event.tripId,
        target: DecisionTarget.flight,
        targetId: flightId,
        status: DecisionStatus.selected,
        createdAt: event.occurredAt,
      );

      return current.copyWith(
        phase: OrganizationPhase.awaitingFlightPurchase,
        decisions: <UserDecision>[...current.decisions, decision],
      );

    case OrganizationEventKind.externalPurchaseOpened:
      final isStay =
          current.phase == OrganizationPhase.awaitingStayPurchase ||
          current.phase == OrganizationPhase.awaitingStayConfirmation;

      final nextPhase = isStay
          ? OrganizationPhase.awaitingStayConfirmation
          : OrganizationPhase.awaitingFlightConfirmation;

      final offerId = event.payload['targetOfferId']?.toString() ?? '';
      final updatedDecisions = current.decisions.map((d) {
        if (d.targetId == offerId) {
          return d.copyWith(status: DecisionStatus.awaitingConfirmation);
        }
        return d;
      }).toList();

      return current.copyWith(phase: nextPhase, decisions: updatedDecisions);

    case OrganizationEventKind.flightConfirmationRequested:
      return current.copyWith(
        phase: OrganizationPhase.awaitingFlightConfirmation,
      );

    case OrganizationEventKind.flightConfirmed:
      // Invariante: Solo la conferma esplicita sblocca l'esperienza e alloggi
      final flightId = event.payload['flightOfferId']?.toString() ?? '';
      ProviderOffer? confirmed;
      if (event is FlightConfirmedEvent) {
        confirmed = ProviderOffer(
          id: flightId,
          providerId: 'fast-flights',
          kind: OfferKind.flight,
          origin: 'FCO',
          destination: 'LIS',
          departureDate: event.occurredAt.add(const Duration(days: 30)),
          priceCents: 5000,
          externalBookingUrl: 'https://example.com',
          fetchedAt: event.occurredAt,
          tradeoffSummary: 'Volo confermato',
        );
      }

      final updatedDecisions = current.decisions.map((d) {
        if (d.targetId == flightId) {
          return d.copyWith(
            status: DecisionStatus.confirmed,
            confirmedAt: event.occurredAt,
          );
        }
        return d;
      }).toList();

      return current.copyWith(
        phase: OrganizationPhase.collectingExperience,
        confirmedFlight: () => confirmed ?? current.confirmedFlight,
        decisions: updatedDecisions,
      );

    case OrganizationEventKind.experienceContextRequested:
      if (current.confirmedFlight == null) return current;
      return current.copyWith(phase: OrganizationPhase.collectingExperience);

    case OrganizationEventKind.zoneProposed:
      if (current.confirmedFlight == null) return current;
      final zoneNames =
          (event.payload['zoneNames'] as List<dynamic>?)?.cast<String>() ??
          const <String>[];
      final zoneCard = OrganizationCard(
        id: 'card-zone-${event.tripId}',
        tripId: event.tripId,
        kind: OrganizationCardKind.zoneProposal,
        state: OrganizationCardState.ready,
        title: 'Zone consigliate',
        payload: <String, dynamic>{
          'zoneNames': zoneNames,
          'motivationSummary': event.payload['motivationSummary'],
        },
      );

      return current.copyWith(
        phase: OrganizationPhase.proposingZones,
        cards: <OrganizationCard>[...current.cards, zoneCard],
      );

    case OrganizationEventKind.staySearchStarted:
      if (current.confirmedFlight == null) return current;
      final sessionId =
          event.payload['sessionId']?.toString() ?? 'stay-${event.sequence}';
      final staySearchCard = OrganizationCard(
        id: 'card-stay-search-$sessionId',
        tripId: event.tripId,
        kind: OrganizationCardKind.searchStatus,
        state: OrganizationCardState.ready,
        title: 'Ricerca alloggi',
        description: 'Scansione disponibilità...',
        payload: <String, dynamic>{
          'sessionId': sessionId,
          'zone': event.payload['zone'],
        },
      );

      return current.copyWith(
        phase: OrganizationPhase.searchingStay,
        cards: <OrganizationCard>[...current.cards, staySearchCard],
      );

    case OrganizationEventKind.stayPartialResults:
      return current;

    case OrganizationEventKind.staySelected:
      final stayId = event.payload['stayOfferId']?.toString() ?? '';
      final decision = UserDecision(
        id: 'dec-stay-$stayId',
        tripId: event.tripId,
        target: DecisionTarget.stay,
        targetId: stayId,
        status: DecisionStatus.selected,
        createdAt: event.occurredAt,
      );

      return current.copyWith(
        phase: OrganizationPhase.awaitingStayPurchase,
        decisions: <UserDecision>[...current.decisions, decision],
      );

    case OrganizationEventKind.stayConfirmationRequested:
      return current.copyWith(
        phase: OrganizationPhase.awaitingStayConfirmation,
      );

    case OrganizationEventKind.stayConfirmed:
      final stayId = event.payload['stayOfferId']?.toString() ?? '';
      ProviderOffer? confirmedStay;
      if (event is StayConfirmedEvent) {
        confirmedStay = ProviderOffer(
          id: stayId,
          providerId: 'unavailable-stays',
          kind: OfferKind.stay,
          origin: 'LIS',
          destination: 'LIS',
          departureDate: event.occurredAt.add(const Duration(days: 30)),
          priceCents: 10000,
          externalBookingUrl: 'https://example.com',
          fetchedAt: event.occurredAt,
          tradeoffSummary: 'Soggiorno confermato',
        );
      }

      final updatedDecisions = current.decisions.map((d) {
        if (d.targetId == stayId) {
          return d.copyWith(
            status: DecisionStatus.confirmed,
            confirmedAt: event.occurredAt,
          );
        }
        return d;
      }).toList();

      return current.copyWith(
        phase: OrganizationPhase.readyForPlan,
        confirmedStay: () => confirmedStay ?? current.confirmedStay,
        decisions: updatedDecisions,
      );

    case OrganizationEventKind.planProposed:
      // Invariante: Solo con volo E alloggio confermati si può proporre il piano
      if (current.confirmedFlight == null || current.confirmedStay == null) {
        return current;
      }
      final planCard = event is PlanProposedEvent
          ? event.planCard
          : OrganizationCard(
              id: 'card-plan-${event.tripId}',
              tripId: event.tripId,
              kind: OrganizationCardKind.planProposal,
              title: 'Piano di viaggio pronto',
            );

      return current.copyWith(
        phase: OrganizationPhase.readyForPlan,
        cards: <OrganizationCard>[...current.cards, planCard],
      );

    case OrganizationEventKind.providerDegraded:
      final updatedCards = current.cards.map((card) {
        if (card.kind == OrganizationCardKind.searchStatus) {
          return card.copyWith(
            description:
                'Avviso: ${event.payload['reason'] ?? "Provider degradato"}',
          );
        }
        return card;
      }).toList();
      return current.copyWith(cards: updatedCards);

    case OrganizationEventKind.offerExpired:
      final offerId = event.payload['offerId']?.toString();
      final updatedCards = current.cards.map((card) {
        if (card.payload['targetOfferId'] == offerId || card.id == offerId) {
          return card.copyWith(state: OrganizationCardState.stale);
        }
        return card;
      }).toList();
      return current.copyWith(cards: updatedCards);

    case OrganizationEventKind.error:
      return current;
  }
}
