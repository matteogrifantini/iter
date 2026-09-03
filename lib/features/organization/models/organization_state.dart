import 'package:flutter/foundation.dart';
import '../../chat_first_prototype/plan_models.dart';
import 'organization_card.dart';
import 'organization_models.dart';

/// Alias per la rappresentazione downstream del piano di viaggio.
typedef TripPlan = TripSnapshot;

/// Le 10 fasi canoniche del flusso di organizzazione viaggio.
enum OrganizationPhase {
  collectingIntent,
  searchingTransport,
  awaitingFlightPurchase,
  awaitingFlightConfirmation,
  collectingExperience,
  proposingZones,
  searchingStay,
  awaitingStayPurchase,
  awaitingStayConfirmation,
  readyForPlan,
}

/// Stato immutabile dell'organizzazione per un dato [tripId].
@immutable
class OrganizationState {
  OrganizationState({
    required this.tripId,
    required this.phase,
    required this.intent,
    List<OrganizationCard> cards = const <OrganizationCard>[],
    List<UserDecision> decisions = const <UserDecision>[],
    List<SearchSession> searchSessions = const <SearchSession>[],
    this.confirmedFlight,
    this.confirmedStay,
    this.plan,
  }) : cards = List<OrganizationCard>.unmodifiable(cards),
       decisions = List<UserDecision>.unmodifiable(decisions),
       searchSessions = List<SearchSession>.unmodifiable(searchSessions);

  final String tripId;
  final OrganizationPhase phase;
  final TripIntent intent;
  final List<OrganizationCard> cards;
  final List<UserDecision> decisions;
  final List<SearchSession> searchSessions;
  final ProviderOffer? confirmedFlight;
  final ProviderOffer? confirmedStay;
  final TripPlan? plan;

  /// Offerte di volo caricate nella sessione o nell'ultima card di confronto voli.
  List<ProviderOffer> get flightOffers {
    for (final card in cards.reversed) {
      if (card.kind == OrganizationCardKind.flightComparison) {
        final offers = card.payload['offers'] as List?;
        if (offers != null) {
          return offers.whereType<ProviderOffer>().toList();
        }
      }
    }
    return const <ProviderOffer>[];
  }

  /// ID del volo attualmente selezionato (se presente).
  String? get selectedFlightId {
    for (final decision in decisions.reversed) {
      if (decision.target == DecisionTarget.flight &&
          (decision.status == DecisionStatus.selected ||
              decision.status == DecisionStatus.confirmed)) {
        return decision.targetId;
      }
    }
    return null;
  }

  /// Decisione confermata per il volo (se presente).
  UserDecision? get confirmedFlightDecision {
    for (final decision in decisions.reversed) {
      if (decision.target == DecisionTarget.flight &&
          decision.status == DecisionStatus.confirmed) {
        return decision;
      }
    }
    return null;
  }

  OrganizationState copyWith({
    String? tripId,
    OrganizationPhase? phase,
    TripIntent? intent,
    List<OrganizationCard>? cards,
    List<UserDecision>? decisions,
    List<SearchSession>? searchSessions,
    ProviderOffer? Function()? confirmedFlight,
    ProviderOffer? Function()? confirmedStay,
    TripPlan? Function()? plan,
  }) {
    return OrganizationState(
      tripId: tripId ?? this.tripId,
      phase: phase ?? this.phase,
      intent: intent ?? this.intent,
      cards: cards ?? this.cards,
      decisions: decisions ?? this.decisions,
      searchSessions: searchSessions ?? this.searchSessions,
      confirmedFlight: confirmedFlight != null
          ? confirmedFlight()
          : this.confirmedFlight,
      confirmedStay: confirmedStay != null
          ? confirmedStay()
          : this.confirmedStay,
      plan: plan != null ? plan() : this.plan,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationState &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          phase == other.phase &&
          intent == other.intent &&
          listEquals(cards, other.cards) &&
          listEquals(decisions, other.decisions) &&
          listEquals(searchSessions, other.searchSessions) &&
          confirmedFlight == other.confirmedFlight &&
          confirmedStay == other.confirmedStay &&
          plan == other.plan;

  @override
  int get hashCode => Object.hash(
    tripId,
    phase,
    intent,
    Object.hashAll(cards),
    Object.hashAll(decisions),
    Object.hashAll(searchSessions),
    confirmedFlight,
    confirmedStay,
    plan,
  );
}

/// Risposta a una domanda con chiave e valore associato.
@immutable
class OrganizationAnswer {
  const OrganizationAnswer({required this.key, required this.value});

  final String key;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationAnswer &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value;

  @override
  int get hashCode => Object.hash(key, value);
}

/// Modifica mirata a un singolo campo dell'intento.
@immutable
class IntentPatch {
  const IntentPatch({required this.field, required this.value});

  final String field;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntentPatch &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, value);
}

/// Contesto di esperienza per la scelta di zone e alloggi.
@immutable
class ExperienceContext {
  ExperienceContext({
    List<String> priorities = const <String>[],
    required this.pace,
    required this.walkingTolerance,
    required this.singleBase,
  }) : priorities = List<String>.unmodifiable(priorities);

  final List<String> priorities;
  final String pace;
  final String walkingTolerance;
  final bool singleBase;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperienceContext &&
          runtimeType == other.runtimeType &&
          listEquals(priorities, other.priorities) &&
          pace == other.pace &&
          walkingTolerance == other.walkingTolerance &&
          singleBase == other.singleBase;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorities),
    pace,
    walkingTolerance,
    singleBase,
  );
}

/// Budget per domande essenziali e adattive.
@immutable
class QuestionBudget {
  const QuestionBudget({required this.essential, required this.adaptive});

  final int essential;
  final int adaptive;

  bool get canAskEssential => essential > 0;
  bool get canAskAdaptive => adaptive > 0;
  bool get hasRemaining => essential > 0 || adaptive > 0;

  QuestionBudget consumeEssential() => QuestionBudget(
    essential: (essential - 1).clamp(0, 99),
    adaptive: adaptive,
  );

  QuestionBudget consumeAdaptive() => QuestionBudget(
    essential: essential,
    adaptive: (adaptive - 1).clamp(0, 99),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionBudget &&
          runtimeType == other.runtimeType &&
          essential == other.essential &&
          adaptive == other.adaptive;

  @override
  int get hashCode => Object.hash(essential, adaptive);
}

/// Domanda mirata posta al viaggiatore.
@immutable
class OrganizationQuestion {
  OrganizationQuestion({
    String? key,
    String? id,
    required this.prompt,
    bool? essential,
    bool? isAdaptive,
    List<String> options = const <String>[],
  }) : key = key ?? id ?? '',
       essential = essential ?? (isAdaptive != null ? !isAdaptive : true),
       options = List<String>.unmodifiable(options);

  final String key;
  final String prompt;
  final bool essential;
  final List<String> options;

  String get id => key;
  bool get isAdaptive => !essential;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationQuestion &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          prompt == other.prompt &&
          essential == other.essential &&
          listEquals(options, other.options);

  @override
  int get hashCode =>
      Object.hash(key, prompt, essential, Object.hashAll(options));
}
