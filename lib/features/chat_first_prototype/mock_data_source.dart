import 'package:flutter/material.dart' show ThemeMode;

import '../../data/mock_data.dart';
import '../../models/trip_models.dart' show JourneyRoute, Place;
import 'chat_first_data.dart';
import 'chat_first_models.dart'
    show
        ChatMessage,
        Conversation,
        ConversationRow,
        DestinationPoint,
        ProfileRow,
        TripSnapshot;
import 'data_source.dart';

/// Deterministic in-memory source backing the prototype in debug and tests.
/// Behavior is identical to the pre-F0 demo data. Persistence methods are
/// no-ops: conversations and messages live only in the controller memory, so
/// the mock and the tests keep working without a database.
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

  @override
  Future<List<ConversationRow>> fetchConversations() async =>
      const <ConversationRow>[];

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async =>
      const <ChatMessage>[];

  @override
  Future<void> insertMessage(
    String conversationId,
    ChatMessage message,
  ) async {}

  @override
  Future<void> setConversationRead(String conversationId) async {}

  @override
  Future<void> incrementUnread(String conversationId) async {}

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      null;

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async => const PlanSaveResult.success();

  @override
  Future<ProfileRow?> fetchProfile() async => null;

  @override
  Future<void> upsertProfile({
    ThemeMode? themeMode,
    List<String>? memoryTags,
  }) async {}

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
    if (text.contains('cibo') ||
        text.contains('colazione') ||
        text.contains('degustazione')) {
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
