import 'package:flutter/foundation.dart';

import '../../app/app_config.dart';
import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_models.dart'
    show
        ChatMessage,
        Conversation,
        ConversationRow,
        DestinationPoint,
        TripSnapshot;
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

  /// All persisted conversations, most recently updated first. The mock
  /// returns an empty list (the seeded threads stay purely in-memory).
  Future<List<ConversationRow>> fetchConversations();

  /// All messages of one conversation, oldest first. Empty list on missing
  /// data or failure, never a crash.
  Future<List<ChatMessage>> fetchMessages(String conversationId);

  /// Persists a single message of an already-existing conversation.
  Future<void> insertMessage(String conversationId, ChatMessage message);

  /// Marks a conversation as fully read (unread = 0).
  Future<void> setConversationRead(String conversationId);

  /// Bumps the unread counter of a conversation by one.
  Future<void> incrementUnread(String conversationId);

  /// Persists a brand-new conversation and returns its database row, or null
  /// when the insert failed.
  Future<ConversationRow?> createConversation(Conversation summary);

  /// Persists an accepted plan for [conversationId]: upserts the linked `trips`
  /// row (creating it on first use) and appends a new `trip_versions` entry so
  /// the plan survives restarts and reverts stay verifiable. No-op on the mock
  /// path, best effort on the live path.
  Future<void> saveTripVersion({
    required String conversationId,
    required String title,
    required TripSnapshot snapshot,
  });
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
