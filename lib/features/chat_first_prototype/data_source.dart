import 'package:flutter/foundation.dart';

import '../../app/app_config.dart';
import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_models.dart' show DestinationPoint;
import 'mock_data_source.dart';
import 'supabase_data_source.dart';

/// Storage seam for the chat-first prototype. The controller talks to this
/// interface and never to a database directly. [MockDataSource] is the default
/// in debug and tests; [SupabaseDataSource] takes over only when the build was
/// started with an explicit Supabase backend (see [AppConfig.usesSupabase]).
@immutable
abstract class IterDataSource {
  /// Connects and signs in anonymously (Supabase) or no-ops (mock).
  Future<void> init();

  /// The discoverable journeys shown on Home: cities and routes.
  Future<List<JourneyRoute>> fetchJourneys();

  /// The must-see points for one destination, keyed by its slug (e.g. 'roma').
  /// Mock returns deterministic demo places; Supabase reads the live `pois`
  /// table. Empty list on missing data or failure, never a crash.
  Future<List<DestinationPoint>> fetchPois(String destinationSlug);
}

/// Picks the live source when the app was started with Supabase configured,
/// otherwise the deterministic mock used in debug and tests.
IterDataSource resolveDataSource() {
  final config = AppConfig.fromEnvironment();
  if (config.usesSupabase) {
    return SupabaseDataSource(config: config);
  }
  return MockDataSource();
}
