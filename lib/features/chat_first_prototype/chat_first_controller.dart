import 'package:flutter/foundation.dart';

import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'data_source.dart';
import 'mock_data_source.dart';

/// Isolated demo store for the chat-first prototype. It never touches the
/// legacy [IterStore]; data is deterministic and lives only for the session.
class ChatFirstPrototypeController extends ChangeNotifier {
  ChatFirstPrototypeController({
    List<ChatThread>? seed,
    IterDataSource? dataSource,
  })  : _threads = seed ?? ChatFirstDemoData.seedThreads(),
        dataSource = dataSource ?? MockDataSource() {
    _unread = _sumUnread();
  }

  /// The resolved storage seam; mock by default, live when the build enables
  /// Supabase. [trendJourneys] falls back to the deterministic demo content
  /// until [loadTrendJourneys] replaces it.
  final IterDataSource dataSource;

  final List<ChatThread> _threads;
  String? _activeThreadId;
  int _unread = 0;
  List<JourneyRoute>? _journeys;

  int get unread => _unread;
  String? get activeThreadId => _activeThreadId;

  List<ChatThread> get threads => List<ChatThread>.unmodifiable(_threads);

  ChatThread? get activeThread {
    final id = _activeThreadId;
    if (id == null) return null;
    return threadOf(id);
  }

  /// The discoverable journeys. Until [loadTrendJourneys] completes this keeps
  /// the deterministic demo content, so the mock path is byte-identical.
  List<JourneyRoute> get trendJourneys =>
      _journeys ?? ChatFirstDemoData.trendJourneys();

  /// Loads the journeys from the resolved [dataSource]. On Supabase this reads
  /// the live catalog; on failure the demo content stays in place.
  Future<void> loadTrendJourneys() async {
    final journeys = await dataSource.fetchJourneys();
    if (journeys.isEmpty) return;
    _journeys = journeys;
    notifyListeners();
  }

  /// The must-see points for a journey's first destination. On Supabase this
  /// reads the live `pois` rows; on failure an empty list is returned.
  Future<List<DestinationPoint>> poisFor(JourneyRoute journey) async {
    if (journey.destinationIds.isEmpty) return const <DestinationPoint>[];
    return dataSource.fetchPois(journey.destinationIds.first);
  }

  ChatThread threadOf(String id) =>
      _threads.firstWhere((thread) => thread.summary.id == id);

  Conversation conversationOf(String id) => threadOf(id).summary;

  ChatThread? threadForJourney(String journeyId) {
    for (final thread in _threads) {
      if (thread.summary.id == 'c-$journeyId') return thread;
    }
    return null;
  }

  int _sumUnread() =>
      _threads.fold<int>(0, (sum, t) => sum + t.summary.unread);

  void _recomputeUnread() {
    _unread = _sumUnread();
  }

  /// Marks a conversation as read without navigating.
  void openConversation(String id) {
    final thread = threadOf(id);
    if (thread.summary.unread > 0) {
      thread.summary = thread.summary.copyWith(unread: 0);
      _recomputeUnread();
    }
    _activeThreadId = id;
    notifyListeners();
  }

  /// Accepts a concrete plan proposal in the conversation.
  void acceptProposal(String conversationId, String messageId) {
    _settleProposal(conversationId, messageId, accept: true);
  }

  /// Rejects a concrete plan proposal, keeping the current plan.
  void rejectProposal(String conversationId, String messageId) {
    _settleProposal(conversationId, messageId, accept: false);
  }

  void _settleProposal(
    String conversationId,
    String messageId, {
    required bool accept,
  }) {
    final thread = threadOf(conversationId);
    ChatMessage? message;
    for (final candidate in thread.messages) {
      if (candidate.id == messageId) {
        message = candidate;
        break;
      }
    }
    if (message == null) return;
    _activeThreadId = conversationId;
    thread.respondToProposal(message, accept: accept);
    notifyListeners();
  }

  /// Sends a typed traveler message and advances the thread deterministically.
  void sendText(String text) {
    final thread = activeThread;
    if (thread == null || text.trim().isEmpty) return;
    _advance(thread, text.trim());
  }

  /// Sends a mock voice note from the traveler.
  void sendAudio() {
    final thread = activeThread;
    if (thread == null) return;
    _activeThreadId = thread.summary.id;
    thread.travelerAudioMessage();
    _reply(thread);
  }

  /// Sends a traveler attachment (a demo image or video) and advances.
  void sendMedia({required String asset, required bool isVideo}) {
    final thread = activeThread;
    if (thread == null) return;
    _activeThreadId = thread.summary.id;
    thread.travelerMediaMessage(asset, isVideo: isVideo);
    _reply(thread);
  }

  void _reply(ChatThread thread) {
    if (!thread.advance()) {
      thread.messages.add(ChatFirstDemoData.closingReply());
    }
    notifyListeners();
  }

  /// Responds to a clickable choice. Non-confirming choices (e.g. "Solo
  /// ispirazione") do not create a message and just record the intent.
  void choose(ChatChoice choice, {required String conversationId}) {
    final thread = threadOf(conversationId);
    if (!choice.confirm) {
      _activeThreadId = conversationId;
      notifyListeners();
      return;
    }
    _advance(thread, choice.label);
  }

  void _advance(ChatThread thread, String traveledText) {
    _activeThreadId = thread.summary.id;
    thread.travelerMessage(traveledText);
    if (!thread.advance()) {
      thread.messages.add(ChatFirstDemoData.closingReply());
    }
    notifyListeners();
  }

  /// Opens (or creates) a planning thread for a home destination trend.
  ChatThread startFromJourney(JourneyRoute journey) {
    final existing = threadForJourney(journey.id);
    if (existing != null) {
      openConversation(existing.summary.id);
      return existing;
    }
    final thread = ChatFirstDemoData.planningThreadFor(journey);
    _threads.insert(0, thread);
    _activeThreadId = thread.summary.id;
    notifyListeners();
    return thread;
  }
}