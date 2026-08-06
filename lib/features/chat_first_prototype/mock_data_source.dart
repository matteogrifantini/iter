import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_data.dart';
import 'data_source.dart';

/// Deterministic in-memory source backing the prototype in debug and tests.
/// Behavior is identical to the pre-F0 demo data.
class MockDataSource implements IterDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<JourneyRoute>> fetchJourneys() async =>
      ChatFirstDemoData.trendJourneys();
}
