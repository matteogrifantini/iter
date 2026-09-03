import 'package:flutter/foundation.dart';
import '../events/organization_events.dart';
import '../models/organization_models.dart';
import '../models/organization_state.dart';

@immutable
class OrganizationAiContext {
  OrganizationAiContext({
    required this.intent,
    List<ProfileSignal> profileSignals = const <ProfileSignal>[],
    List<OrganizationEvent> recentEvents = const <OrganizationEvent>[],
    required this.questionBudget,
  }) : profileSignals = List<ProfileSignal>.unmodifiable(profileSignals),
       recentEvents = List<OrganizationEvent>.unmodifiable(recentEvents);

  final TripIntent intent;
  final List<ProfileSignal> profileSignals;
  final List<OrganizationEvent> recentEvents;
  final QuestionBudget questionBudget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationAiContext &&
          runtimeType == other.runtimeType &&
          intent == other.intent &&
          listEquals(profileSignals, other.profileSignals) &&
          listEquals(recentEvents, other.recentEvents) &&
          questionBudget == other.questionBudget;

  @override
  int get hashCode => Object.hash(
    intent,
    Object.hashAll(profileSignals),
    Object.hashAll(recentEvents),
    questionBudget,
  );
}

@immutable
class AiOrganizationResponse {
  AiOrganizationResponse({
    this.nextQuestion,
    this.explanation,
    List<String> rankings = const <String>[],
    List<String> zoneProposalIds = const <String>[],
  }) : rankings = List<String>.unmodifiable(rankings),
       zoneProposalIds = List<String>.unmodifiable(zoneProposalIds);

  final OrganizationQuestion? nextQuestion;
  final String? explanation;
  final List<String> rankings;
  final List<String> zoneProposalIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiOrganizationResponse &&
          runtimeType == other.runtimeType &&
          nextQuestion == other.nextQuestion &&
          explanation == other.explanation &&
          listEquals(rankings, other.rankings) &&
          listEquals(zoneProposalIds, other.zoneProposalIds);

  @override
  int get hashCode => Object.hash(
    nextQuestion,
    explanation,
    Object.hashAll(rankings),
    Object.hashAll(zoneProposalIds),
  );
}

abstract interface class OrganizationAiGateway {
  Future<AiOrganizationResponse> decideNextStep(OrganizationAiContext context);
}
