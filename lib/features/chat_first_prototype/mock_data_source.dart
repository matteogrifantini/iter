import '../../data/mock_data.dart';
import '../../models/trip_models.dart' show JourneyRoute, Place;
import 'chat_first_data.dart';
import 'chat_first_models.dart' show DestinationPoint;
import 'data_source.dart';

/// Deterministic in-memory source backing the prototype in debug and tests.
/// Behavior is identical to the pre-F0 demo data.
class MockDataSource implements IterDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<JourneyRoute>> fetchJourneys() async =>
      ChatFirstDemoData.trendJourneys();

  @override
  Future<List<DestinationPoint>> fetchPois(String destinationSlug) async {
    final places = MockData.places
        .where((place) => place.destinationId == destinationSlug)
        .toList(growable: false);
    return places.map(_fromPlace).toList(growable: false);
  }

  /// Maps a mock [Place] to the light [DestinationPoint] shape the preview
  /// sheet needs. The emoji is derived from the category so the demo stays
  /// deterministic and needs no extra data.
  DestinationPoint _fromPlace(Place place) => DestinationPoint(
        id: place.id,
        name: place.name,
        category: place.category,
        emoji: _emojiFor(place.category),
        whyFits: place.whyItFits,
      );

  static String _emojiFor(String category) {
    final text = category.toLowerCase();
    if (text.contains('cibo') || text.contains('colazione') || text.contains('degustazione')) {
      return '🍽️';
    }
    if (text.contains('mare')) return '🌊';
    if (text.contains('mercato')) return '🧺';
    if (text.contains('verde')) return '🌳';
    if (text.contains('panorama') || text.contains('passeggiata')) return '🌅';
    if (text.contains('arte') || text.contains('cultura')) return '🎭';
    if (text.contains('architettura')) return '🏛️';
    if (text.contains('musica')) return '🎶';
    if (text.contains('quartiere')) return '🏘️';
    if (text.contains('storia')) return '📜';
    if (text.contains('design')) return '🪑';
    if (text.contains('serata')) return '🌙';
    if (text.contains('azulejos')) return '💠';
    return '📍';
  }
}
