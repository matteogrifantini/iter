import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'data_source.dart';
import 'mock_data_source.dart';
import 'plan_editor.dart';

enum PlanPersistenceStatus { idle, saving, saved, failed }

@immutable
class PlanPersistenceState {
  const PlanPersistenceState({
    required this.status,
    this.revision,
    this.errorCode,
  });

  const PlanPersistenceState.idle()
    : status = PlanPersistenceStatus.idle,
      revision = null,
      errorCode = null;

  final PlanPersistenceStatus status;
  final int? revision;
  final String? errorCode;
}

@immutable
class PlanRevisionRecord {
  const PlanRevisionRecord({required this.before, required this.after});

  final TripSnapshot before;
  final TripSnapshot after;
}

@immutable
class _PlanSaveAttempt {
  const _PlanSaveAttempt({
    required this.conversationId,
    required this.conversation,
    required this.snapshot,
  });

  final String conversationId;
  final Conversation conversation;
  final TripSnapshot snapshot;
}

/// Isolated demo store for the chat-first prototype. It never touches the
/// legacy [IterStore]; data is deterministic and lives only for the session.
class ChatFirstPrototypeController extends ChangeNotifier {
  ChatFirstPrototypeController({
    List<ChatThread>? seed,
    IterDataSource? dataSource,
    DateTime Function()? now,
  }) : _threads = seed ?? ChatFirstDemoData.seedThreads(),
       dataSource = dataSource ?? MockDataSource(),
       _now = now ?? DateTime.now {
    _unread = _sumUnread();
  }

  /// The resolved storage seam; mock by default, live when the build enables
  /// Supabase. [trendJourneys] falls back to the deterministic demo content
  /// until [loadTrendJourneys] replaces it.
  final IterDataSource dataSource;
  final PlanEditor _planEditor = const PlanEditor();
  final DateTime Function() _now;

  final List<ChatThread> _threads;

  /// Maps a stable client id (`c-<journey>`) to the persisted `conversations`
  /// row uuid, so message writes target the right row. Empty on the mock path.
  final Map<String, String> _dbIdByClientId = <String, String>{};

  /// In-flight conversation-creation futures keyed by client id, so concurrent
  /// writers never double-create the row for the same thread.
  final Map<String, Future<String?>> _pendingConversation =
      <String, Future<String?>>{};

  final Map<String, PlanPatchPreview> _pendingPlanPatches =
      <String, PlanPatchPreview>{};
  final Map<String, List<PlanRevisionRecord>> _planRevisionHistory =
      <String, List<PlanRevisionRecord>>{};
  final Map<String, PlanPersistenceState> _planPersistence =
      <String, PlanPersistenceState>{};
  final Map<String, _PlanSaveAttempt> _failedPlanSaves =
      <String, _PlanSaveAttempt>{};
  final Map<String, Future<void>> _planSaveQueues = <String, Future<void>>{};
  final Map<String, int> _latestPlanSaveRevision = <String, int>{};
  final Map<String, PlanPlaceDetails> _placeComposerContexts =
      <String, PlanPlaceDetails>{};

  String? _activeThreadId;
  int _unread = 0;
  List<JourneyRoute>? _journeys;
  ThemeMode _themeMode = ThemeMode.light;
  List<String> _memoryTags = _demoMemoryTags;
  ChatThread? _pendingHomeThread;
  String? _pendingHomeIntent;
  bool _disposed = false;

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

  PlanPatchPreview? pendingPlanPatch(String conversationId) =>
      _pendingPlanPatches[conversationId];

  List<PlanRevisionRecord> planRevisionHistory(String conversationId) =>
      List<PlanRevisionRecord>.unmodifiable(
        _planRevisionHistory[conversationId] ?? const <PlanRevisionRecord>[],
      );

  PlanPersistenceState planPersistenceState(String conversationId) =>
      _planPersistence[conversationId] ?? const PlanPersistenceState.idle();

  PlanPlaceDetails? placeComposerContext(String conversationId) =>
      _placeComposerContexts[conversationId];

  PlanPatchPreview previewAddPlace({
    required String conversationId,
    required TripItemSnapshot item,
    String? targetDayId,
    int? targetIndex,
  }) => _rememberPlanPreview(
    _planEditor.previewAddPlace(
      conversationId: conversationId,
      snapshot: _planSnapshot(conversationId),
      item: item,
      targetDayId: targetDayId,
      targetIndex: targetIndex,
    ),
  );

  PlanPatchPreview previewMoveStop({
    required String conversationId,
    required String itemId,
    required String targetDayId,
    required int targetIndex,
  }) => _rememberPlanPreview(
    _planEditor.previewMoveStop(
      conversationId: conversationId,
      snapshot: _planSnapshot(conversationId),
      itemId: itemId,
      targetDayId: targetDayId,
      targetIndex: targetIndex,
    ),
  );

  PlanPatchPreview previewRemoveStop({
    required String conversationId,
    required String itemId,
  }) => _rememberPlanPreview(
    _planEditor.previewRemoveStop(
      conversationId: conversationId,
      snapshot: _planSnapshot(conversationId),
      itemId: itemId,
    ),
  );

  PlanPatchPreview previewChangeTime({
    required String conversationId,
    required String itemId,
    required String startTime,
  }) => _rememberPlanPreview(
    _planEditor.previewChangeTime(
      conversationId: conversationId,
      snapshot: _planSnapshot(conversationId),
      itemId: itemId,
      startTime: startTime,
    ),
  );

  PlanPatchPreview previewToggleLock({
    required String conversationId,
    required String itemId,
  }) => _rememberPlanPreview(
    _planEditor.previewToggleLock(
      conversationId: conversationId,
      snapshot: _planSnapshot(conversationId),
      itemId: itemId,
    ),
  );

  /// Applies the current preview once. A stale preview is recalculated against
  /// the current snapshot and remains pending for a fresh explicit confirm.
  PlanPatchPreview? confirmPlanPatch(String conversationId) {
    final pending = _pendingPlanPatches[conversationId];
    if (pending == null) return null;
    final current = _planSnapshot(conversationId);
    if (pending.baseRevision != current.revision) {
      final rebased = _planEditor.rebase(preview: pending, current: current);
      _pendingPlanPatches[conversationId] = rebased;
      notifyListeners();
      return rebased;
    }
    final applied = _planEditor.apply(
      preview: pending,
      current: current,
      currentConversationId: conversationId,
      timestamp: _now().toUtc(),
    );
    if (applied.status != PlanPatchStatus.applied) return applied;
    _pendingPlanPatches.remove(conversationId);
    _commitPlanRevision(
      conversationId: conversationId,
      before: current,
      after: applied.after,
    );
    return applied;
  }

  bool cancelPlanPatch(String conversationId) {
    final removed = _pendingPlanPatches.remove(conversationId) != null;
    if (removed) notifyListeners();
    return removed;
  }

  /// Restores the previous snapshot content as a new, observable revision.
  bool undoLastPlanRevision(String conversationId) {
    final history = _planRevisionHistory[conversationId];
    if (history == null || history.isEmpty) return false;
    final current = _planSnapshot(conversationId);
    final previous = history.last.before;
    final revision = current.revision + 1;
    final json = Map<String, dynamic>.of(previous.toJson())
      ..['revision'] = revision
      ..['revisionMetadata'] = PlanRevisionMetadata(
        id: '$conversationId-r$revision',
        number: revision,
        timestamp: _now().toUtc(),
        origin: PlanChangeOrigin.manual,
        label: 'Annulla ultima modifica',
      ).toJson();
    final restored = TripSnapshot.fromJson(json);
    _commitPlanRevision(
      conversationId: conversationId,
      before: current,
      after: restored,
    );
    return true;
  }

  Future<bool> retryPlanPersistence(String conversationId) async {
    final failed = _failedPlanSaves[conversationId];
    if (failed == null) return false;
    final currentRevision = _planSnapshot(conversationId).revision;
    if (failed.snapshot.revision != currentRevision ||
        _latestPlanSaveRevision[conversationId] != currentRevision) {
      _failedPlanSaves.remove(conversationId);
      return false;
    }
    await _enqueuePlanSave(failed);
    return true;
  }

  void setPlaceComposerContext(String conversationId, PlanPlaceDetails place) {
    threadOf(conversationId);
    _placeComposerContexts[conversationId] = place;
    notifyListeners();
  }

  bool clearPlaceComposerContext(String conversationId) {
    final removed = _placeComposerContexts.remove(conversationId) != null;
    if (removed) notifyListeners();
    return removed;
  }

  bool selectTravelOption({
    required String conversationId,
    required String optionId,
  }) {
    final current = _planSnapshot(conversationId);
    final option = ChatFirstDemoData.travelOptionFor(
      snapshot: current,
      optionId: optionId,
    );
    if (option == null) return false;
    final alternatives = ChatFirstDemoData.travelOptionsFor(
      current,
    ).where((candidate) => candidate.id != option.id).toList(growable: false);
    final next = current.copyWith(
      transport: option.label,
      travelSelection: TravelPlanSelection(
        option: option,
        alternatives: alternatives,
      ),
      revision: current.revision + 1,
      revisionMetadata: _selectionMetadata(
        conversationId,
        current.revision + 1,
        'Volo selezionato',
      ),
    );
    _commitPlanRevision(
      conversationId: conversationId,
      before: current,
      after: next,
    );
    return true;
  }

  bool selectStayOption({
    required String conversationId,
    required String optionId,
  }) {
    final current = _planSnapshot(conversationId);
    final option = ChatFirstDemoData.stayOptionFor(
      snapshot: current,
      optionId: optionId,
    );
    if (option == null) return false;
    final alternatives = ChatFirstDemoData.stayOptionsFor(
      current,
    ).where((candidate) => candidate.id != option.id).toList(growable: false);
    final next = current.copyWith(
      stay: option.label,
      staySelection: StayPlanSelection(
        option: option,
        alternatives: alternatives,
      ),
      revision: current.revision + 1,
      revisionMetadata: _selectionMetadata(
        conversationId,
        current.revision + 1,
        'Hotel selezionato',
      ),
    );
    _commitPlanRevision(
      conversationId: conversationId,
      before: current,
      after: next,
    );
    return true;
  }

  TripSnapshot _planSnapshot(String conversationId) {
    final snapshot = conversationOf(conversationId).snapshot;
    if (snapshot == null) {
      throw StateError('Conversation $conversationId has no plan snapshot.');
    }
    return snapshot;
  }

  PlanPatchPreview _rememberPlanPreview(PlanPatchPreview preview) {
    _pendingPlanPatches[preview.conversationId] = preview;
    notifyListeners();
    return preview;
  }

  PlanRevisionMetadata _selectionMetadata(
    String conversationId,
    int revision,
    String label,
  ) => PlanRevisionMetadata(
    id: '$conversationId-r$revision',
    number: revision,
    timestamp: _now().toUtc(),
    origin: PlanChangeOrigin.manual,
    label: label,
  );

  void _commitPlanRevision({
    required String conversationId,
    required TripSnapshot before,
    required TripSnapshot after,
  }) {
    final thread = threadOf(conversationId);
    thread.summary = thread.summary.copyWith(snapshot: after);
    final history = _planRevisionHistory.putIfAbsent(
      conversationId,
      () => <PlanRevisionRecord>[],
    );
    history.add(PlanRevisionRecord(before: before, after: after));
    if (history.length > 10) history.removeRange(0, history.length - 10);
    notifyListeners();
    unawaited(
      _enqueuePlanSave(
        _PlanSaveAttempt(
          conversationId: conversationId,
          conversation: thread.summary,
          snapshot: after,
        ),
      ),
    );
  }

  Future<void> _enqueuePlanSave(_PlanSaveAttempt attempt) {
    if (_disposed) return Future<void>.value();
    final conversationId = attempt.conversationId;
    final latestRevision = _latestPlanSaveRevision[conversationId];
    if (latestRevision == null || attempt.snapshot.revision > latestRevision) {
      _latestPlanSaveRevision[conversationId] = attempt.snapshot.revision;
    }
    if (_planSnapshot(conversationId).revision == attempt.snapshot.revision &&
        _latestPlanSaveRevision[conversationId] == attempt.snapshot.revision) {
      _planPersistence[conversationId] = PlanPersistenceState(
        status: PlanPersistenceStatus.saving,
        revision: attempt.snapshot.revision,
      );
      notifyListeners();
    }
    final previous = _planSaveQueues[conversationId] ?? Future<void>.value();
    final next = previous
        .catchError((Object _) {})
        .then((_) => _performPlanSave(attempt));
    _planSaveQueues[conversationId] = next;
    unawaited(
      next.whenComplete(() {
        if (_disposed) return;
        if (identical(_planSaveQueues[conversationId], next)) {
          _planSaveQueues.remove(conversationId);
        }
      }),
    );
    return next;
  }

  Future<void> _performPlanSave(_PlanSaveAttempt attempt) async {
    PlanSaveResult result;
    try {
      final dbId = await _ensureConversation(threadOf(attempt.conversationId));
      if (_disposed) return;
      result = await dataSource.saveTripVersion(
        conversationId: dbId ?? attempt.conversationId,
        conversation: attempt.conversation,
        snapshot: attempt.snapshot,
      );
    } catch (_) {
      result = const PlanSaveResult.failure('unexpected');
    }
    if (_disposed) return;

    final conversationId = attempt.conversationId;
    final isCurrent =
        _planSnapshot(conversationId).revision == attempt.snapshot.revision &&
        _latestPlanSaveRevision[conversationId] == attempt.snapshot.revision;
    if (result.succeeded) {
      final failed = _failedPlanSaves[conversationId];
      if (failed != null &&
          failed.snapshot.revision <= attempt.snapshot.revision) {
        _failedPlanSaves.remove(conversationId);
      }
      if (isCurrent) {
        _planPersistence[conversationId] = PlanPersistenceState(
          status: PlanPersistenceStatus.saved,
          revision: attempt.snapshot.revision,
        );
        notifyListeners();
      }
      return;
    }

    if (isCurrent) {
      _failedPlanSaves[conversationId] = attempt;
      _planPersistence[conversationId] = PlanPersistenceState(
        status: PlanPersistenceStatus.failed,
        revision: attempt.snapshot.revision,
        errorCode: result.errorCode ?? 'unexpected',
      );
      notifyListeners();
    }
  }

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
    final proposal = message.proposal;
    final before = thread.summary.snapshot;
    final appliesAcceptedPlan =
        accept &&
        proposal != null &&
        proposal.outcome == null &&
        before != null;
    thread.respondToProposal(message, accept: accept);
    if (appliesAcceptedPlan) {
      final revision = before.revision + 1;
      final accepted = proposal.snapshot.copyWith(
        revision: revision,
        revisionMetadata: PlanRevisionMetadata(
          id: '$conversationId-r$revision',
          number: revision,
          timestamp: _now().toUtc(),
          origin: PlanChangeOrigin.chat,
          label: proposal.changeLabel,
        ),
      );
      _commitPlanRevision(
        conversationId: conversationId,
        before: before,
        after: accepted,
      );
    }
    _persistNewMessages(thread);
    notifyListeners();
  }

  /// Sends a typed traveler message and advances the thread deterministically.
  void sendText(String text) {
    final thread = activeThread;
    if (thread == null || text.trim().isEmpty) return;
    _advance(thread, text.trim());
    _consumePlaceComposerContext(thread.summary.id);
  }

  /// Sends a mock voice note from the traveler.
  void sendAudio() {
    final thread = activeThread;
    if (thread == null) return;
    _activeThreadId = thread.summary.id;
    thread.travelerAudioMessage();
    _reply(thread);
    _consumePlaceComposerContext(thread.summary.id);
  }

  /// Sends a traveler attachment (a demo image or video) and advances.
  void sendMedia({required String asset, required bool isVideo}) {
    final thread = activeThread;
    if (thread == null) return;
    _activeThreadId = thread.summary.id;
    thread.travelerMediaMessage(asset, isVideo: isVideo);
    _reply(thread);
    _consumePlaceComposerContext(thread.summary.id);
  }

  void _consumePlaceComposerContext(String conversationId) {
    if (_placeComposerContexts.remove(conversationId) != null) {
      notifyListeners();
    }
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

  /// Home uses the only awaited persistence path: its new free-talk exchange is
  /// committed before the shell navigates. A failed retry reuses the exact
  /// in-memory batch, therefore it cannot duplicate the traveler message or
  /// advance the deterministic script twice. Mock storage returns null and is a
  /// successful no-op by contract.
  Future<ChatThread> submitHomeIntent(String text) async {
    final intent = text.trim();
    if (intent.isEmpty) throw ArgumentError.value(text, 'text', 'empty intent');
    var thread = _pendingHomeThread;
    if (thread == null) {
      thread =
          _threads.cast<ChatThread?>().firstWhere(
            (candidate) => candidate?.summary.id == kFreeTalkConversationId,
            orElse: () => null,
          ) ??
          ChatFirstDemoData.freeTalkThread(trendJourneys);
      if (!_threads.contains(thread)) {
        _threads.insert(0, thread);
      }
      _activeThreadId = thread.summary.id;
      thread.travelerMessage(intent);
      if (!thread.advance()) {
        thread.messages.add(ChatFirstDemoData.closingReply());
      }
      _pendingHomeThread = thread;
      _pendingHomeIntent = intent;
    } else if (_pendingHomeIntent != intent) {
      throw StateError('A home intent is already waiting to be persisted.');
    }

    await _persistNewMessagesRequired(thread);
    _pendingHomeThread = null;
    _pendingHomeIntent = null;
    notifyListeners();
    return thread;
  }

  /// Persists every message of [thread] not yet saved, creating the
  /// conversation row on first use. On the mock path this is a no-op.
  Future<void> _persistNewMessages(ChatThread thread) async {
    try {
      final dbId = await _ensureConversation(thread);
      if (dbId == null) return;
      for (var i = thread.persistedCount; i < thread.messages.length; i++) {
        await dataSource.insertMessage(dbId, thread.messages[i]);
        thread.persistedCount++;
      }
    } catch (_) {
      // The visible in-memory thread remains authoritative until persistence
      // becomes available again; this best-effort seam must not leak errors.
    }
  }

  Future<void> _persistNewMessagesRequired(ChatThread thread) async {
    final dbId = await _ensureConversation(thread);
    if (dbId == null) return;
    for (var i = thread.persistedCount; i < thread.messages.length; i++) {
      await dataSource.insertMessage(dbId, thread.messages[i]);
      thread.persistedCount++;
    }
  }

  /// Returns the persisted row uuid for [thread], creating the conversation on
  /// first touch. Null on the mock path or when the store is unreachable.
  /// Concurrent callers share the in-flight creation future, so the row is
  /// never created twice for the same thread.
  Future<String?> _ensureConversation(ChatThread thread) async {
    if (_disposed) return null;
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
      if (_disposed) return null;
      if (row == null) return null;
      _dbIdByClientId[thread.summary.id] = row.id;
      return row.id;
    } finally {
      if (!_disposed) _pendingConversation.remove(thread.summary.id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
