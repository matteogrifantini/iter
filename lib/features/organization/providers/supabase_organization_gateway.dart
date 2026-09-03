import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_state.dart';
import 'organization_ai_gateway.dart';

/// Gateway concreto per invocare la Supabase Edge Function `organization-step`.
/// Gestisce la trasparenza di configurazione: se Supabase o la Edge Function
/// non sono configurate o falliscono, degrada in modo onesto su un'euristica locale
/// senza bloccare il flusso dell'utente o generare dati inventati.
class SupabaseOrganizationGateway implements OrganizationAiGateway {
  SupabaseOrganizationGateway({this.client});

  final SupabaseClient? client;

  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    final supabase = client ?? _safeGetSupabaseInstance();

    if (supabase == null) {
      return _fallbackHeuristic(context, reason: 'Supabase non inizializzato');
    }

    try {
      final response = await supabase.functions.invoke(
        'organization-step',
        body: <String, dynamic>{
          'tripId': context.intent.tripId,
          'rawDesire': context.intent.rawDesire,
          'phase': 'collectingIntent',
          'intent': <String, dynamic>{
            'candidateDestinations': context.intent.candidateDestinations,
            'origin': context.intent.origin,
            'travelers': <String, dynamic>{
              'adults': context.intent.travelers.adults,
              'children': context.intent.travelers.children,
            },
          },
        },
      );

      if (response.status != 200 || response.data == null) {
        return _fallbackHeuristic(
          context,
          reason: 'Edge Function status ${response.status}',
        );
      }

      final Map<String, dynamic> data = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final questionText = data['suggestedQuestion'] as String?;
      final options =
          (data['questionOptions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[];
      final explanation = data['reasoning'] as String?;

      return AiOrganizationResponse(
        explanation: explanation,
        nextQuestion: questionText != null
            ? OrganizationQuestion(
                key: 'q-edge-step',
                prompt: questionText,
                options: options,
              )
            : null,
      );
    } catch (e) {
      return _fallbackHeuristic(context, reason: e.toString());
    }
  }

  SupabaseClient? _safeGetSupabaseInstance() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AiOrganizationResponse _fallbackHeuristic(
    OrganizationAiContext context, {
    required String reason,
  }) {
    final desire = context.intent.rawDesire.toLowerCase();
    final hasDates = context.intent.dateConstraint != null;

    if (!hasDates && context.questionBudget.canAskEssential) {
      return AiOrganizationResponse(
        explanation: 'Identificazione del periodo di viaggio ($reason)',
        nextQuestion: OrganizationQuestion(
          key: 'q-travel-dates',
          prompt: 'In quali date o mese preferiresti partire?',
          essential: true,
          options: const <String>[
            'Questo weekend',
            'Il prossimo mese',
            'Non ho ancora date precise',
          ],
        ),
      );
    }

    if (desire.contains('cibo') || desire.contains('gastronomia')) {
      return AiOrganizationResponse(
        explanation: 'Focus gastronomico rilevato nel desiderio ($reason)',
        nextQuestion: OrganizationQuestion(
          key: 'q-food-pref',
          prompt: 'Che tipo di esperienze culinarie cerchi principalmente?',
          essential: false,
          options: const <String>[
            'Mercati rionali e street food tipico',
            'Ristoranti tradizionali e trattorie storiche',
            'Degustazioni gourmet e cantine',
          ],
        ),
      );
    }

    return AiOrganizationResponse(
      explanation: 'Pianificazione standard con euristica ($reason)',
      nextQuestion: OrganizationQuestion(
        key: 'q-pace',
        prompt: 'Quale ritmo preferisci per le tue giornate di viaggio?',
        essential: false,
        options: const <String>[
          'Rilassato (1-2 attività al giorno)',
          'Bilanciato (ritmo moderato con pause)',
          'Intenso (vedere il più possibile)',
        ],
      ),
    );
  }
}
