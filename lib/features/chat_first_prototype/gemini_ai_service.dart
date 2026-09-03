import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../app/app_config.dart';
import 'plan_models.dart';

/// Service interfacing with the Supabase Edge Function `plan` powered by Google Gemini.
class GeminiAiService {
  const GeminiAiService({required this.config, this.httpClient});

  final AppConfig config;
  final http.Client? httpClient;

  http.Client get _client => httpClient ?? http.Client();

  /// Invokes the `plan` Edge Function for destination discovery or itinerary composition.
  Future<AiPlanResult> generatePlan({
    required String operation,
    String? message,
    String? destination,
    List<String>? selectedPlaceIds,
    Map<String, dynamic>? currentItinerary,
  }) async {
    if (!config.usesSupabase) {
      return const AiPlanResult.offline();
    }

    final url = Uri.parse('${config.supabaseUrl}/functions/v1/plan');
    final payload = <String, dynamic>{
      'operation': operation,
      'clientRequestId': 'iter-client-${DateTime.now().millisecondsSinceEpoch}',
      'context': <String, dynamic>{
        'message': ?message,
        'destination': ?destination,
        'selectedPlaceIds': ?selectedPlaceIds,
        'itinerary': ?currentItinerary,
      },
    };

    try {
      final response = await _client.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'apikey': config.supabaseAnonKey,
          'Authorization': 'Bearer ${config.supabaseAnonKey}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        return AiPlanResult.error(
          'Status ${response.statusCode}: ${response.body}',
        );
      }

      return _parseSseStream(response.body);
    } catch (e) {
      return AiPlanResult.error(e.toString());
    }
  }

  /// Parses SSE event stream from the plan function into a structured result.
  AiPlanResult _parseSseStream(String body) {
    String? destinationName;
    String? destinationCountry;
    String? destinationWhy;
    final places = <PlanPlaceV1>[];
    var days = <TripDaySnapshot>[];
    String? statusMessage;

    final lines = body.split('\n');
    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final rawData = line.substring(6).trim();
        if (rawData.isEmpty) continue;
        try {
          final data = jsonDecode(rawData) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'stage') {
            statusMessage = data['message'] as String?;
          } else if (type == 'proposal') {
            final kind = data['kind'] as String?;
            if (kind == 'destination' && data['destination'] != null) {
              final dest = data['destination'] as Map<String, dynamic>;
              destinationName = dest['name'] as String?;
              destinationCountry = dest['country'] as String?;
              destinationWhy = dest['why'] as String?;
            }
          } else if (type == 'complete' && data['draft'] != null) {
            final draft = data['draft'] as Map<String, dynamic>;
            destinationName ??= draft['destination'] as String?;

            if (draft['places'] != null) {
              final rawPlaces = draft['places'] as List<dynamic>;
              for (final p in rawPlaces) {
                final pMap = p as Map<String, dynamic>;
                places.add(
                  PlanPlaceV1(
                    poiId: (pMap['poiId'] as String?) ?? 'place',
                    title: (pMap['title'] as String?) ?? 'Luogo',
                    category: (pMap['category'] as String?) ?? 'cultura',
                  ),
                );
              }
            }

            if (draft['days'] != null) {
              final rawDays = draft['days'] as List<dynamic>;
              days = rawDays.map<TripDaySnapshot>((d) {
                final dayMap = d as Map<String, dynamic>;
                final items = (dayMap['items'] as List<dynamic>? ?? <dynamic>[])
                    .map<TripItemSnapshot>((it) {
                      final itMap = it as Map<String, dynamic>;
                      return TripItemSnapshot(
                        id: (itMap['poiId'] as String?) ?? 'item',
                        startTime: (itMap['timeSlot'] as String?) ?? '09:00',
                        title: (itMap['title'] as String?) ?? 'Tappa',
                        category: (itMap['category'] as String?) ?? 'cultura',
                        locked: (itMap['locked'] == true),
                      );
                    })
                    .toList();

                return TripDaySnapshot(
                  id: 'day-${dayMap['dayIndex'] ?? 1}',
                  label:
                      (dayMap['title'] as String?) ??
                      'Giorno ${dayMap['dayIndex'] ?? 1}',
                  theme: 'Esplorazione',
                  items: items,
                );
              }).toList();
            }
          }
        } catch (_) {}
      }
    }

    if (destinationName == null && days.isEmpty) {
      return const AiPlanResult.offline();
    }

    return AiPlanResult.success(
      destinationName: destinationName ?? 'Destinazione',
      destinationCountry: destinationCountry ?? '',
      destinationWhy: destinationWhy ?? '',
      places: places,
      days: days,
      statusMessage: statusMessage,
    );
  }
}

class PlanPlaceV1 {
  const PlanPlaceV1({
    required this.poiId,
    required this.title,
    required this.category,
  });

  final String poiId;
  final String title;
  final String category;
}

class AiPlanResult {
  const AiPlanResult({
    required this.isSuccess,
    this.destinationName,
    this.destinationCountry,
    this.destinationWhy,
    this.places = const <PlanPlaceV1>[],
    this.days = const <TripDaySnapshot>[],
    this.statusMessage,
    this.errorMessage,
  });

  const AiPlanResult.offline()
    : isSuccess = false,
      destinationName = null,
      destinationCountry = null,
      destinationWhy = null,
      places = const <PlanPlaceV1>[],
      days = const <TripDaySnapshot>[],
      statusMessage = null,
      errorMessage = 'Offline / Fallback';

  const AiPlanResult.error(String message)
    : isSuccess = false,
      destinationName = null,
      destinationCountry = null,
      destinationWhy = null,
      places = const <PlanPlaceV1>[],
      days = const <TripDaySnapshot>[],
      statusMessage = null,
      errorMessage = message;

  const AiPlanResult.success({
    required this.destinationName,
    required this.destinationCountry,
    required this.destinationWhy,
    this.places = const <PlanPlaceV1>[],
    this.days = const <TripDaySnapshot>[],
    this.statusMessage,
  }) : isSuccess = true,
       errorMessage = null;

  final bool isSuccess;
  final String? destinationName;
  final String? destinationCountry;
  final String? destinationWhy;
  final List<PlanPlaceV1> places;
  final List<TripDaySnapshot> days;
  final String? statusMessage;
  final String? errorMessage;
}
