import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_config.dart';
import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_models.dart' show DestinationPoint;
import 'data_source.dart';

/// Live source backed by the Supabase `iter` project. Only used when the build
/// was started with `--dart-define=ITER_BACKEND=supabase` plus a URL and key.
class SupabaseDataSource implements IterDataSource {
  SupabaseDataSource({required this.config});

  final AppConfig config;

  @override
  Future<void> init() async {
    if (Supabase.instance.isInitialized) return;
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }

  @override
  Future<List<JourneyRoute>> fetchJourneys() async {
    try {
      final rows = await Supabase.instance.client
          .from('destinations')
          .select()
          .order('match_score', ascending: false);
      return rows.map(_fromRow).toList();
    } catch (_) {
      return const <JourneyRoute>[];
    }
  }

  @override
  Future<List<DestinationPoint>> fetchPois(String destinationSlug) async {
    try {
      final client = Supabase.instance.client;
      final destination = await client
          .from('destinations')
          .select('id')
          .eq('slug', destinationSlug)
          .maybeSingle();
      if (destination == null) return const <DestinationPoint>[];
      final rows = await client
          .from('pois')
          .select('id, name, category, emoji, why_fits')
          .eq('destination_id', destination['id'])
          .order('name');
      return rows.map(_fromPoiRow).toList();
    } catch (_) {
      return const <DestinationPoint>[];
    }
  }

  /// Maps a `pois` row to the light preview-sheet shape. Missing cosmetic
  /// fields degrade to friendly defaults so the sheet never breaks.
  DestinationPoint _fromPoiRow(Map<String, dynamic> row) => DestinationPoint(
        id: (row['id'] as String),
        name: (row['name'] as String?) ?? '',
        category: (row['category'] as String?) ?? '',
        emoji: (row['emoji'] as String?) ?? '📍',
        whyFits: (row['why_fits'] as String?) ?? '',
      );

  /// Maps a `destinations` row (city or route) to the shared journey model.
  /// A city without stops falls back to its own name and slug so the Home
  /// posters and "Organizza un viaggio" entry keep working.
  JourneyRoute _fromRow(Map<String, dynamic> row) {
    final id = row['slug'] as String;
    final name = row['name'] as String;
    final stops = (row['stops'] as List<dynamic>?)?.cast<String>();
    final destinationIds =
        (row['destination_ids'] as List<dynamic>?)?.cast<String>();
    return JourneyRoute(
      id: id,
      title: name,
      summary: (row['description'] as String?) ?? name,
      durationLabel: (row['duration_label'] as String?) ?? '',
      stops: stops != null && stops.isNotEmpty ? stops : <String>[name],
      destinationIds: destinationIds != null && destinationIds.isNotEmpty
          ? destinationIds
          : <String>[id],
      whyItFits: (row['why_it_fits'] as String?) ?? '',
      season: (row['season'] as String?) ?? '',
      travelMode: (row['travel_mode'] as String?) ?? '',
      videoAssets: (row['video_assets'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      matchScore: (row['match_score'] as int?) ?? 0,
    );
  }
}
