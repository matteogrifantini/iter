import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

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
  }) : _threads = seed ?? ChatFirstDemoData.seedThreads(),
       dataSource = dataSource ?? MockDataSource() {
    _unread = _sumUnread();
  }

  /// The resolved storage seam; mock by default, live when the build enables
  /// Supabase. [trendJourneys] falls back to the deterministic demo content
  /// until [loadTrendJourneys] replaces it.
  final IterDataSource dataSource;

  final List<ChatThread> _threads;

  /// Maps a stable client id (`c-<journey>`) to the persisted `conversations`
  /// row uuid, so message writes target the right row. Empty on the mock path.
  final Map<String, String> _dbIdByClientId = <String, String>{};

  /// In-flight conversation-creation futures keyed by client id, so concurrent
  /// writers never double-create the row for the same thread.
  final Map<String, Future<String?>> _pendingConversation =
      <String, Future<String?>>{};

  String? _activeThreadId;
  int _unread = 0;
  List<JourneyRoute>? _journeys;
  ThemeMode _themeMode = ThemeMode.light;
  List<String> _memoryTags = _demoMemoryTags;

  int get unread => _unread;
  String? get activeThreadId => _activeThreadId;

  /// The session theme. Defaults to light; [loadProfile] replaces it on
  /// Supabase with the persisted value, [setThemeMode] updates it.
  ThemeMode get themeMode => _themeMode;

  /// The learned memory tags shown in the profile. Demo tags on the mock path,
  /// the persisted tags on Supabase.
  List<String> get memoryTags => List<String>.unmodifiable(_memoryTags);

  static const _demoMemoryTags = <String>[
    'Ritmo lento e senza orari fissi',
    'Niente museo dopo il pomeriggio in città',
    'Almeno una tavola di quartiere per viaggio',
    'Preferisci la finestra sul corridoio in treno',
  ];

  /// Loads the persisted profile (theme and learned memory) from the resolved
  /// [dataSource]. On the mock path the row is always absent, so the light
  /// theme and the demo tags keep applying.
  Future<void> loadProfile() async {
    final profile = await dataSource.fetchProfile();
    if (profile == null) return;
    _themeMode = profile.themeMode;
    _memoryTags = List<String>.from(profile.memoryTags);
    notifyListeners();
  }

  /// Applies [mode] to the session and persists it best effort on the resolved
  /// [dataSource] (no-op on mock, upsert on Supabase).
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await dataSource.upsertProfile(themeMode: mode);
  }

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

  /// Replaces the in-memory threads with the persisted conversations when the
  /// store has any. On the mock path (empty list) the seeded demo threads stay,
  /// so debug and tests remain byte-identical.
  Future<void> restoreConversations() async {
    final rows = await dataSource.fetchConversations();
    if (rows.isEmpty) return;
    final restored = <ChatThread>[];
    final dbIds = <String, String>{};
    for (final row in rows) {
      final messages = await dataSource.fetchMessages(row.id);
      final thread = ChatThread(
        summary: row.conversation,
        script: const <ScriptedBeat>[],
        openedWith: messages,
      )..persistedCount = messages.length;
      restored.add(thread);
      dbIds[row.conversation.id] = row.id;
    }
    _threads
      ..clear()
      ..addAll(restored);
    _dbIdByClientId
      ..clear()
      ..addAll(dbIds);
    _recomputeUnread();
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

  int _sumUnread() => _threads.fold<int>(0, (sum, t) => sum + t.summary.unread);

  void _recomputeUnread() {
    _unread = _sumUnread();
  }

  /// Marks a conversation as read without navigating, and persists the reset
  /// when the conversation already exists in the store.
  void openConversation(String id) {
    final thread = threadOf(id);
    if (thread.summary.unread > 0) {
      thread.summary = thread.summary.copyWith(unread: 0);
      _recomputeUnread();
      final dbId = _dbIdByClientId[id];
      if (dbId != null) unawaited(dataSource.setConversationRead(dbId));
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
    final wasSettled = message.proposal?.outcome != null;
    thread.respondToProposal(message, accept: accept);
    _persistNewMessages(thread);
    if (accept && !wasSettled) _persistAcceptedPlan(thread);
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
    _persistNewMessages(thread);
    notifyListeners();
  }

  /// Responds to a clickable choice. Non-confirming choices (e.g. "Solo
  /// ispirazione") do not create a message and just record the intent. When
  /// [messageId] is given it must belong to the thread's current decision
  /// point, so a stale tap on an already-answered card never applies twice.
  void choose(
    ChatChoice choice, {
    required String conversationId,
    String? messageId,
  }) {
    final thread = threadOf(conversationId);
    if (!choice.confirm) {
      _activeThreadId = conversationId;
      notifyListeners();
      return;
    }
    if (messageId != null && !thread.acceptsChoiceFrom(messageId)) return;
    _advance(thread, choice.label);
  }

  void _advance(ChatThread thread, String traveledText) {
    _activeThreadId = thread.summary.id;
    thread.travelerMessage(traveledText);
    if (!thread.advance()) {
      thread.messages.add(ChatFirstDemoData.closingReply());
    }
    _persistNewMessages(thread);
    notifyListeners();
  }

  /// Opens (or creates) a guided-intake thread for a home destination trend.
  /// On Supabase a fresh thread is persisted right away so the conversation
  /// row exists before the first message lands.
  ChatThread startFromJourney(JourneyRoute journey) {
    final existing = threadForJourney(journey.id);
    if (existing != null) {
      openConversation(existing.summary.id);
      return existing;
    }
    final thread = ChatFirstDemoData.intakeThreadFor(journey);
    _threads.insert(0, thread);
    _activeThreadId = thread.summary.id;
    notifyListeners();
    _persistNewMessages(thread);
    return thread;
  }

  /// Opens (or creates) a free-talk thread: the traveler starts from their own
  /// words, and the destination is pinned mid-conversation. Reusing the same
  /// client id keeps repeat entries idempotent across sessions.
  ChatThread startFreeTalk() {
    ChatThread? existing;
    for (final thread in _threads) {
      if (thread.summary.id == kFreeTalkConversationId) {
        existing = thread;
        break;
      }
    }
    if (existing != null) {
      openConversation(existing.summary.id);
      return existing;
    }
    final thread = ChatFirstDemoData.freeTalkThread(trendJourneys);
    _threads.insert(0, thread);
    _activeThreadId = thread.summary.id;
    notifyListeners();
    _persistNewMessages(thread);
    return thread;
  }

  /// Persists every message of [thread] not yet saved, creating the
  /// conversation row on first use. On the mock path this is a no-op.
  Future<void> _persistNewMessages(ChatThread thread) async {
    try {
      final dbId = await _ensureConversation(thread);
      if (dbId == null) return;
      final unsaved = thread.messages.length - thread.persistedCount;
      for (var i = thread.persistedCount; i < thread.messages.length; i++) {
        await dataSource.insertMessage(dbId, thread.messages[i]);
      }
      thread.persistedCount += unsaved;
    } catch (_) {
      // The visible in-memory thread remains authoritative until persistence
      // becomes available again; this best-effort seam must not leak errors.
    }
  }

  /// Returns the persisted row uuid for [thread], creating the conversation on
  /// first touch. Null on the mock path or when the store is unreachable.
  /// Concurrent callers share the in-flight creation future, so the row is
  /// never created twice for the same thread.
  Future<String?> _ensureConversation(ChatThread thread) async {
    final existing = _dbIdByClientId[thread.summary.id];
    if (existing != null) return existing;
    final pending = _pendingConversation[thread.summary.id];
    if (pending != null) return pending;
    final future = _createConversation(thread);
    _pendingConversation[thread.summary.id] = future;
    return future;
  }

  Future<String?> _createConversation(ChatThread thread) async {
    try {
      final row = await dataSource.createConversation(thread.summary);
      if (row == null) return null;
      _dbIdByClientId[thread.summary.id] = row.id;
      return row.id;
    } catch (_) {
      return null;
    } finally {
      _pendingConversation.remove(thread.summary.id);
    }
  }

  /// Persists the accepted plan of [thread] as a new trip version (upserting
  /// the linked `trips` row). Best effort, exactly once, only when the plan has
  /// changed; rejecting a proposal never touches the trips.
  Future<void> _persistAcceptedPlan(ChatThread thread) async {
    final dbId = await _ensureConversation(thread);
    if (dbId == null) return;
    final snapshot = thread.summary.snapshot;
    if (snapshot == null) return;
    await dataSource.saveTripVersion(
      conversationId: dbId,
      title: thread.summary.title,
      snapshot: snapshot,
    );
  }
}
