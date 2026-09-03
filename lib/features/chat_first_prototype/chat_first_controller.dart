import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show AppLifecycleState, ThemeMode;

import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'data_source.dart';
import 'gemini_ai_service.dart';
import 'inspiration_models.dart';
import 'mock_data_source.dart';
import 'plan_editor.dart';
import 'plan_external_launcher.dart';
import 'profile_models.dart';

enum PlanPersistenceStatus { idle, saving, saved, failed }

/// Which purchase the traveler is settling: the outbound/return journey or the
/// stay. Mirrors [TripSnapshot.travelSelection] / [TripSnapshot.staySelection].
enum ExternalPurchaseKind { travel, stay }

/// A return from an external purchase the traveler is asked to settle. It
/// carries no sensitive data: only the conversation and the purchase identity,
/// which the shell resolves against the plan snapshot for the dialog copy.
@immutable
class PurchaseReturnPrompt {
  const PurchaseReturnPrompt({
    required this.conversationId,
    required this.kind,
    required this.optionId,
  });

  final String conversationId;
  final ExternalPurchaseKind kind;
  final String optionId;
}

/// The expected-return intent registered right before an external launch.
@immutable
class _PurchaseReturnIntent {
  const _PurchaseReturnIntent({required this.kind, required this.optionId});

  final ExternalPurchaseKind kind;
  final String optionId;
}

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

/// Isolated controller for the new-only chat-first app. Mock data is
/// deterministic and lives only for the session unless the optional data source
/// is explicitly configured.
class ChatFirstPrototypeController extends ChangeNotifier {
  ChatFirstPrototypeController({
    List<ChatThread>? seed,
    IterDataSource? dataSource,
    this.aiService,
    DateTime Function()? now,
  }) : _threads = seed ?? ChatFirstDemoData.seedThreads(),
       dataSource = dataSource ?? MockDataSource(),
       _now = now ?? DateTime.now,
       _availability = List<AvailabilityEntry>.of(_demoAvailability) {
    _unread = _sumUnread();
  }

  /// The resolved storage seam; mock by default, live when the build enables
  /// Supabase. [trendJourneys] falls back to the deterministic demo content
  /// until [loadTrendJourneys] replaces it.
  final IterDataSource dataSource;
  final GeminiAiService? aiService;
  final PlanEditor _planEditor = const PlanEditor();
  final DateTime Function() _now;

  final List<ChatThread> _threads;
  final List<AvailabilityEntry> _availability;
  final TravelStats _travelStats = const TravelStats(
    completedTrips: 3,
    visitedPlaces: 18,
    estimatedKilometers: 1240,
  );
  final List<SavedInspiration> _savedInspirations = <SavedInspiration>[];
  final Map<String, String> _inspirationProposalIds = <String, String>{};

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

  /// Per-conversation external purchase lifecycle: the expected-return intent
  /// (registered before the launch), whether the launch succeeded in THIS
  /// session, whether the resume prompt was already consumed, and whether the
  /// prompt is still waiting for an app resume. Process death clears all of
  /// them because they are session state; the persisted `purchaseOpened`
  /// selection survives instead.
  final Map<String, _PurchaseReturnIntent> _purchaseReturns =
      <String, _PurchaseReturnIntent>{};
  final Map<String, bool> _purchaseLaunchSucceeded = <String, bool>{};
  final Map<String, bool> _purchasePromptConsumed = <String, bool>{};
  final Map<String, bool> _purchaseAwaitingResume = <String, bool>{};

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

  List<AvailabilityEntry> get availability =>
      List<AvailabilityEntry>.unmodifiable(_availability);

  TravelStats get travelStats => _travelStats;

  List<SavedInspiration> get savedInspirations =>
      List<SavedInspiration>.unmodifiable(_savedInspirations);

  /// Current user's email if signed in via Supabase Auth, or null in guest/mock mode.
  String? get currentUserEmail => dataSource.currentUserEmail;

  /// Signs in using a Magic Link email OTP.
  Future<bool> signInWithEmail(String email) async {
    final ok = await dataSource.signInWithEmail(email);
    notifyListeners();
    return ok;
  }

  /// Signs out of the current session.
  Future<void> signOut() async {
    await dataSource.signOut();
    notifyListeners();
  }

  List<SavedInspiration> savedInspirationsFor(String conversationId) =>
      List<SavedInspiration>.unmodifiable(
        _savedInspirations.where(
          (inspiration) => inspiration.conversationId == conversationId,
        ),
      );

  static const _demoMemoryTags = <String>[
    'Ritmo lento e senza orari fissi',
    'Niente museo dopo il pomeriggio in città',
    'Almeno una tavola di quartiere per viaggio',
    'Preferisci la finestra sul corridoio in treno',
  ];

  static final List<AvailabilityEntry> _demoAvailability = <AvailabilityEntry>[
    AvailabilityEntry(
      id: 'availability-1',
      date: DateTime(2026, 10, 17),
      kind: AvailabilityKind.free,
      timeRange: 'Tutto il giorno',
      note: 'Weekend libero',
    ),
    AvailabilityEntry(
      id: 'availability-2',
      date: DateTime(2026, 10, 20),
      kind: AvailabilityKind.work,
      timeRange: '09:00–18:00',
      note: 'Turno in ufficio',
    ),
  ];

  String addAvailability({
    required DateTime date,
    required AvailabilityKind kind,
    required String timeRange,
    String note = '',
  }) {
    final id = 'availability-${_nextAvailabilityId()}';
    _availability.add(
      AvailabilityEntry(
        id: id,
        date: date,
        kind: kind,
        timeRange: timeRange.trim(),
        note: note.trim(),
      ),
    );
    notifyListeners();
    unawaited(dataSource.saveAvailability(_availability));
    return id;
  }

  bool removeAvailability(String id) {
    final before = _availability.length;
    _availability.removeWhere((entry) => entry.id == id);
    final removed = _availability.length != before;
    if (removed) {
      notifyListeners();
      unawaited(dataSource.saveAvailability(_availability));
    }
    return removed;
  }

  int _nextAvailabilityId() {
    var candidate = _availability.length + 1;
    while (_availability.any(
      (entry) => entry.id == 'availability-$candidate',
    )) {
      candidate++;
    }
    return candidate;
  }

  SavedInspiration? saveInspiration({
    required String conversationId,
    required InspirationDraft draft,
  }) {
    threadOf(conversationId);
    for (final existing in _savedInspirations) {
      if (existing.conversationId == conversationId &&
          existing.url == draft.url) {
        return existing;
      }
    }
    final saved = SavedInspiration(
      id: 'inspiration-${_savedInspirations.length + 1}',
      conversationId: conversationId,
      savedAt: _now().toUtc(),
      attachedToPlan: false,
      platform: draft.platform,
      url: draft.url,
      title: draft.title,
      placeName: draft.placeName,
      destinationId: draft.destinationId,
      moment: draft.moment,
      suggestedCategory: draft.suggestedCategory,
      mediaAsset: draft.mediaAsset,
    );
    _savedInspirations.add(saved);
    notifyListeners();
    return saved;
  }

  bool proposeInspiration(String conversationId, String inspirationId) {
    final inspiration = _savedInspirations.cast<SavedInspiration?>().firstWhere(
      (candidate) =>
          candidate?.id == inspirationId &&
          candidate?.conversationId == conversationId,
      orElse: () => null,
    );
    if (inspiration == null) return false;
    final current = _planSnapshot(conversationId);
    if (_destinationIdForSnapshot(current) != inspiration.destinationId) {
      return false;
    }

    final item = TripItemSnapshot(
      id: '${inspiration.id}-stop',
      title: inspiration.placeName,
      category: inspiration.suggestedCategory,
      startTime: _inspirationTime(inspiration.moment),
      durationMinutes: 90,
      source: PlanItemSource.share,
      place: PlanPlaceDetails(
        id: '${inspiration.destinationId}-${inspiration.id}',
        title: inspiration.placeName,
        description: inspiration.title,
      ),
      locked: false,
    );
    final days = current.days.toList(growable: true);
    final unplacedItems = current.unplacedItems.toList(growable: true);
    if (days.isEmpty) {
      // A new plan can exist before Iter has enough information to create its
      // first day. Keep the shared place visible in the plan without inventing
      // a date or time; the traveler can place it later from the editor.
      unplacedItems.add(item);
    } else {
      final firstDay = days.first;
      days[0] = TripDaySnapshot(
        id: firstDay.id,
        date: firstDay.date,
        label: firstDay.label,
        theme: firstDay.theme,
        items: <TripItemSnapshot>[...firstDay.items, item],
      );
    }
    final placeLabels = current.placeLabels.contains(inspiration.placeName)
        ? current.placeLabels
        : <String>[...current.placeLabels, inspiration.placeName];
    final revision = current.revision + 1;
    final candidate = current.copyWith(
      placeLabels: placeLabels,
      days: days,
      unplacedItems: unplacedItems,
      revision: revision,
      revisionMetadata: PlanRevisionMetadata(
        id: '$conversationId-r$revision',
        number: revision,
        timestamp: _now().toUtc(),
        origin: PlanChangeOrigin.share,
        label: 'Ispirazione salvata',
      ),
    );
    final thread = threadOf(conversationId);
    final messageId =
        'm-$conversationId-inspiration-${inspiration.id}-r$revision-t${thread.messages.length}';
    thread.messages.add(
      ChatMessage(
        id: messageId,
        role: ChatRole.assistant,
        kind: ChatMessageKind.planProposal,
        text:
            'Ho estratto ${inspiration.placeName} da “${inspiration.title}”. '
            'Vuoi inserirlo nel piano?',
        sentAt: _now().toUtc(),
        proposal: PlanProposal(
          changeLabel:
              'Aggiungi ${inspiration.placeName} · ${inspiration.moment}',
          snapshot: candidate,
        ),
      ),
    );
    _inspirationProposalIds[messageId] = inspiration.id;
    _persistNewMessages(thread);
    notifyListeners();
    return true;
  }

  static String _inspirationTime(String moment) => switch (moment) {
    'Mattina' => '09:30',
    'Tramonto' => '18:00',
    _ => '11:00',
  };

  static String _destinationIdForSnapshot(TripSnapshot snapshot) =>
      snapshot.destinationTitle.trim().toLowerCase();

  /// Loads the persisted profile (theme and learned memory) from the resolved
  /// [dataSource]. On the mock path this restores locally saved preferences
  /// or falls back to demo defaults.
  Future<void> loadProfile() async {
    final profile = await dataSource.fetchProfile();
    if (profile != null) {
      _themeMode = profile.themeMode;
      _memoryTags = List<String>.from(profile.memoryTags);
      notifyListeners();
    }
    final savedAvailability = await dataSource.fetchAvailability();
    if (savedAvailability != null && savedAvailability.isNotEmpty) {
      _availability
        ..clear()
        ..addAll(savedAvailability);
      notifyListeners();
    }
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

  /// Opens an external purchase page for the selected [optionId]. The expected
  /// return is registered BEFORE the launch: a resume in the same session can
  /// then ask the traveler to settle the purchase. A failed launch clears the
  /// intent and never marks the selection `purchaseOpened`. Returns whether
  /// the external page was actually opened.
  Future<bool> openExternalPurchase({
    required String conversationId,
    required ExternalPurchaseKind kind,
    required String optionId,
    required Uri uri,
    required PlanExternalLauncher launcher,
  }) async {
    // Refuse to launch when there is no applicable selection to settle: the
    // post-launch mark would otherwise have nothing to update.
    if (!_hasSelection(conversationId, kind, optionId)) return false;
    _purchaseReturns[conversationId] = _PurchaseReturnIntent(
      kind: kind,
      optionId: optionId,
    );
    _purchasePromptConsumed[conversationId] = false;
    final opened = await launcher.open(uri);
    if (!opened) {
      _purchaseReturns.remove(conversationId);
      _purchaseLaunchSucceeded.remove(conversationId);
      _purchasePromptConsumed.remove(conversationId);
      _purchaseAwaitingResume.remove(conversationId);
      return false;
    }
    _purchaseLaunchSucceeded[conversationId] = true;
    // The resume gate is armed only once the launch succeeded in this
    // session: a `resumed` arriving while the launch is still in flight never
    // leaves the prompt permanently stuck waiting.
    _purchaseAwaitingResume[conversationId] = true;
    _markPurchaseOpened(conversationId, kind, optionId);
    return true;
  }

  /// The prompts waiting to be shown after an app resume. A prompt is exposed
  /// only when a launch succeeded in the current session AND the app resumed
  /// (the shell consumes it once, so a second resume never re-shows it).
  List<PurchaseReturnPrompt> get pendingPurchasePrompts {
    final prompts = <PurchaseReturnPrompt>[];
    for (final entry in _purchaseReturns.entries) {
      final conversationId = entry.key;
      if (_purchaseAwaitingResume[conversationId] ?? false) continue;
      if (!(_purchaseLaunchSucceeded[conversationId] ?? false)) continue;
      if (_purchasePromptConsumed[conversationId] ?? false) continue;
      prompts.add(
        PurchaseReturnPrompt(
          conversationId: conversationId,
          kind: entry.value.kind,
          optionId: entry.value.optionId,
        ),
      );
    }
    return List<PurchaseReturnPrompt>.unmodifiable(prompts);
  }

  /// Whether an expected return for [conversationId] is currently registered.
  /// Testable read of the pre-launch intent; the shell uses the snapshot for
  /// the dialog copy instead.
  bool hasExpectedPurchaseReturn(String conversationId) =>
      _purchaseReturns.containsKey(conversationId);

  /// Marks the resume prompt for [conversationId] as shown. The shell calls
  /// this once before displaying the dialog, so a second resume stays silent.
  bool consumePurchasePrompt(String conversationId) {
    if (!_purchaseReturns.containsKey(conversationId)) return false;
    _purchasePromptConsumed[conversationId] = true;
    notifyListeners();
    return true;
  }

  /// Translates a lifecycle state into a purchase-return prompt. Only a
  /// `resumed` state with a successful launch in this session exposes the
  /// prompt (still not consumed); everything else stays silent.
  void handleAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    var changed = false;
    for (final conversationId in _purchaseReturns.keys.toList()) {
      if (!(_purchaseAwaitingResume[conversationId] ?? false)) continue;
      if (!(_purchaseLaunchSucceeded[conversationId] ?? false)) continue;
      if (_purchasePromptConsumed[conversationId] ?? false) continue;
      _purchaseAwaitingResume[conversationId] = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// "Sì, aggiorna": settles the purchase as completed. Only the authorized
  /// fields of the selection change — provider/option identity, price,
  /// timestamp and purchase state (plus the plan revision). Every other part
  /// of the snapshot stays byte-identical.
  void confirmExternalPurchase({
    required String conversationId,
    required ExternalPurchaseKind kind,
    required String optionId,
  }) {
    final next = _selectionWithState(
      conversationId: conversationId,
      kind: kind,
      optionId: optionId,
      state: PurchaseState.purchased,
      label: 'Acquisto confermato',
    );
    if (next != null) {
      _commitPlanRevision(
        conversationId: conversationId,
        before: _planSnapshot(conversationId),
        after: next,
      );
    }
    // Whatever the outcome, the settled purchase stops lingering as a prompt.
    _clearPurchaseReturn(conversationId);
  }

  /// "Non ancora": restores the previous `selected` state in memory without
  /// ever marking the purchase as completed. If the selection is gone or was
  /// never there, the snapshot stays unchanged.
  void dismissExternalPurchasePrompt({
    required String conversationId,
    required ExternalPurchaseKind kind,
    required String optionId,
  }) {
    final next = _selectionWithState(
      conversationId: conversationId,
      kind: kind,
      optionId: optionId,
      state: PurchaseState.selected,
      label: 'Acquisto non confermato',
    );
    if (next != null) {
      _commitPlanRevision(
        conversationId: conversationId,
        before: _planSnapshot(conversationId),
        after: next,
      );
    }
    // Same cleanup as the confirm path: no residual intent or consumed flag.
    _clearPurchaseReturn(conversationId);
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

  bool mockPurchasesConfirmed(String conversationId) {
    final snapshot = conversationOf(conversationId).snapshot;
    return snapshot?.travelSelection?.option.purchaseState ==
            PurchaseState.purchased &&
        snapshot?.staySelection?.option.purchaseState ==
            PurchaseState.purchased;
  }

  /// Settles the selected flight and stay in one explicit, local-only demo
  /// action. It never opens a provider and never handles payment details.
  bool confirmMockPurchases(String conversationId) {
    final current = _planSnapshot(conversationId);
    if (mockPurchasesConfirmed(conversationId)) return true;

    final travelOptions = ChatFirstDemoData.travelOptionsFor(current);
    final stayOptions = ChatFirstDemoData.stayOptionsFor(current);
    if (travelOptions.isEmpty || stayOptions.isEmpty) return false;

    final currentTravel = current.travelSelection;
    final travelOption = currentTravel?.option ?? travelOptions.first;
    final currentStay = current.staySelection;
    final stayOption = currentStay?.option ?? stayOptions.first;
    final travelAlternatives =
        currentTravel?.alternatives ??
        travelOptions
            .where((option) => option.id != travelOption.id)
            .toList(growable: false);
    final stayAlternatives =
        currentStay?.alternatives ??
        stayOptions
            .where((option) => option.id != stayOption.id)
            .toList(growable: false);
    final revision = current.revision + 1;
    final next = current.copyWith(
      travelSelection: TravelPlanSelection(
        option: TravelOption(
          id: travelOption.id,
          label: travelOption.label,
          priceCents: travelOption.priceCents,
          purchaseState: PurchaseState.purchased,
        ),
        alternatives: travelAlternatives,
      ),
      staySelection: StayPlanSelection(
        option: StayOption(
          id: stayOption.id,
          label: stayOption.label,
          priceCents: stayOption.priceCents,
          purchaseState: PurchaseState.purchased,
        ),
        alternatives: stayAlternatives,
      ),
      revision: revision,
      revisionMetadata: PlanRevisionMetadata(
        id: '$conversationId-r$revision',
        number: revision,
        timestamp: _now().toUtc(),
        origin: PlanChangeOrigin.manual,
        label: 'Conferma acquisti demo',
      ),
    );
    _commitPlanRevision(
      conversationId: conversationId,
      before: current,
      after: next,
    );
    return true;
  }

  /// Proposes a concrete stay change (number of nights) without applying it:
  /// the traveler confirms or rejects through the standard proposal flow. The
  /// candidate mirrors the flight/hotel selections: proportional price from the
  /// fixture's nightly rate and a fresh manual revision. Returns false when the
  /// conversation has no operational hotel inventory or [nights] is invalid.
  bool proposeStayNightsChange({
    required String conversationId,
    required int nights,
  }) {
    if (nights < 1) return false;
    final current = _planSnapshot(conversationId);
    final fixture = ChatFirstDemoData.operationalFixtureForSnapshot(current);
    if (fixture == null || fixture.hotels.isEmpty) return false;
    var hotel = fixture.hotels.first;
    final selected = current.staySelection?.option;
    if (selected != null) {
      for (final candidate in fixture.hotels) {
        if (candidate.id == selected.id) {
          hotel = candidate;
          break;
        }
      }
    }
    final nightly = stayNightlyPriceCents(
      priceCents: hotel.priceCents,
      nights: hotel.nights,
      nightlyPriceCents: hotel.nightlyPriceCents,
    );
    final totalCents = nightly * nights;
    final nightsLabel = nights == 1 ? '1 notte' : '$nights notti';
    final revision = current.revision + 1;
    final candidate = current.copyWith(
      stay: '${hotel.name}, $nightsLabel · ${formatEuroCents(totalCents)}',
      staySelection: StayPlanSelection(
        option: StayOption(
          id: hotel.id,
          label: hotel.name,
          priceCents: totalCents,
          purchaseState: PurchaseState.selected,
        ),
        alternatives:
            current.staySelection?.alternatives ??
            ChatFirstDemoData.stayOptionsFor(current),
      ),
      revision: revision,
      revisionMetadata: _selectionMetadata(
        conversationId,
        revision,
        'Date ricalcolate',
      ),
    );
    final thread = threadOf(conversationId);
    thread.messages.add(
      ChatMessage(
        id: 'm-$conversationId-nights-$nights-r$revision-t${thread.messages.length}',
        role: ChatRole.assistant,
        kind: ChatMessageKind.planProposal,
        text:
            'Come cambierebbe il soggiorno: $nightsLabel a ${hotel.name}, '
            '${formatEuroCents(totalCents)} in totale.',
        sentAt: _now().toUtc(),
        proposal: PlanProposal(
          changeLabel:
              'Soggiorno ricalcolato: $nightsLabel · '
              '${formatEuroCents(totalCents)}',
          snapshot: candidate,
        ),
      ),
    );
    _persistNewMessages(thread);
    notifyListeners();
    return true;
  }

  TripSnapshot _planSnapshot(String conversationId) {
    final snapshot = conversationOf(conversationId).snapshot;
    if (snapshot == null) {
      throw StateError('Conversation $conversationId has no plan snapshot.');
    }
    return snapshot;
  }

  /// Whether the conversation currently has [optionId] selected for [kind].
  bool _hasSelection(
    String conversationId,
    ExternalPurchaseKind kind,
    String optionId,
  ) {
    final snapshot = conversationOf(conversationId).snapshot;
    if (snapshot == null) return false;
    return switch (kind) {
      ExternalPurchaseKind.travel =>
        snapshot.travelSelection?.option.id == optionId,
      ExternalPurchaseKind.stay =>
        snapshot.staySelection?.option.id == optionId,
    };
  }

  /// Marks the selection as `purchaseOpened` right after a successful external
  /// launch. Only the authorized selection fields change; the rest of the
  /// snapshot stays intact.
  void _markPurchaseOpened(
    String conversationId,
    ExternalPurchaseKind kind,
    String optionId,
  ) {
    final next = _selectionWithState(
      conversationId: conversationId,
      kind: kind,
      optionId: optionId,
      state: PurchaseState.purchaseOpened,
      label: 'Acquisto avviato',
    );
    if (next == null) return;
    _commitPlanRevision(
      conversationId: conversationId,
      before: _planSnapshot(conversationId),
      after: next,
    );
  }

  /// Builds a revision that changes ONLY the selection's purchase state (and
  /// the plan revision/timestamp), preserving provider label, option id, price
  /// and alternatives. Returns null when the conversation has no such
  /// selection, leaving the snapshot untouched.
  TripSnapshot? _selectionWithState({
    required String conversationId,
    required ExternalPurchaseKind kind,
    required String optionId,
    required PurchaseState state,
    required String label,
  }) {
    final current = _planSnapshot(conversationId);
    final revision = current.revision + 1;
    return switch (kind) {
      ExternalPurchaseKind.travel => _travelSelectionWithState(
        current: current,
        conversationId: conversationId,
        optionId: optionId,
        state: state,
        revision: revision,
        label: label,
      ),
      ExternalPurchaseKind.stay => _staySelectionWithState(
        current: current,
        conversationId: conversationId,
        optionId: optionId,
        state: state,
        revision: revision,
        label: label,
      ),
    };
  }

  TripSnapshot? _travelSelectionWithState({
    required TripSnapshot current,
    required String conversationId,
    required String optionId,
    required PurchaseState state,
    required int revision,
    required String label,
  }) {
    final selection = current.travelSelection;
    if (selection == null || selection.option.id != optionId) return null;
    return current.copyWith(
      travelSelection: TravelPlanSelection(
        option: TravelOption(
          id: selection.option.id,
          label: selection.option.label,
          priceCents: selection.option.priceCents,
          purchaseState: state,
        ),
        alternatives: selection.alternatives,
      ),
      revision: revision,
      revisionMetadata: _selectionMetadata(conversationId, revision, label),
    );
  }

  TripSnapshot? _staySelectionWithState({
    required TripSnapshot current,
    required String conversationId,
    required String optionId,
    required PurchaseState state,
    required int revision,
    required String label,
  }) {
    final selection = current.staySelection;
    if (selection == null || selection.option.id != optionId) return null;
    return current.copyWith(
      staySelection: StayPlanSelection(
        option: StayOption(
          id: selection.option.id,
          label: selection.option.label,
          priceCents: selection.option.priceCents,
          purchaseState: state,
        ),
        alternatives: selection.alternatives,
      ),
      revision: revision,
      revisionMetadata: _selectionMetadata(conversationId, revision, label),
    );
  }

  void _clearPurchaseReturn(String conversationId) {
    _purchaseReturns.remove(conversationId);
    _purchaseLaunchSucceeded.remove(conversationId);
    _purchasePromptConsumed.remove(conversationId);
    _purchaseAwaitingResume.remove(conversationId);
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
    final inspirationId = _inspirationProposalIds.remove(message.id);
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
          origin: inspirationId == null
              ? PlanChangeOrigin.chat
              : PlanChangeOrigin.share,
          label: proposal.changeLabel,
        ),
      );
      _commitPlanRevision(
        conversationId: conversationId,
        before: before,
        after: accepted,
      );
      if (inspirationId != null) {
        final index = _savedInspirations.indexWhere(
          (inspiration) => inspiration.id == inspirationId,
        );
        if (index >= 0) {
          _savedInspirations[index] = _savedInspirations[index].copyWith(
            attachedToPlan: true,
          );
        }
      }
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
    notifyListeners();

    if (aiService != null && aiService!.config.usesSupabase) {
      aiService!
          .generatePlan(
            operation: 'suggest_destination',
            message: traveledText,
            destination: thread.summary.title,
          )
          .then((aiResult) {
            if (aiResult.isSuccess && aiResult.destinationName != null) {
              final destName = aiResult.destinationName!;
              final destCountry = aiResult.destinationCountry ?? '';
              final destWhy =
                  (aiResult.destinationWhy != null &&
                      aiResult.destinationWhy!.isNotEmpty)
                  ? aiResult.destinationWhy!
                  : 'Ho selezionato i luoghi ideali per i tuoi ritmi.';
              final dynamicSnapshot = TripSnapshot(
                destinationTitle: destName,
                country: destCountry,
                durationLabel: '3-5 giorni',
                statusLabel: 'In pianificazione',
                dates: 'giorni da definire',
                transport: 'da definire',
                stay: 'da definire',
                placeLabels: aiResult.places.map((p) => p.title).toList(),
                days: aiResult.days,
              );
              thread.summary = thread.summary.copyWith(
                title: destName,
                snapshot: dynamicSnapshot,
              );
              thread.messages.add(
                ChatMessage(
                  id: '${thread.summary.id}-m${thread.messages.length + 1}',
                  role: ChatRole.assistant,
                  kind: ChatMessageKind.text,
                  text:
                      '$destWhy\n\nHo impostato una prima rotta per $destName. Apri il piano per esplorarla!',
                  sentAt: _now().toUtc(),
                ),
              );
            } else {
              if (!thread.advance()) {
                thread.messages.add(ChatFirstDemoData.closingReply());
              }
            }
            _persistNewMessages(thread);
            notifyListeners();
          })
          .catchError((_) {
            if (!thread.advance()) {
              thread.messages.add(ChatFirstDemoData.closingReply());
            }
            _persistNewMessages(thread);
            notifyListeners();
          });
    } else {
      if (!thread.advance()) {
        thread.messages.add(ChatFirstDemoData.closingReply());
      }
      _persistNewMessages(thread);
      notifyListeners();
    }
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
  /// words, and the destination is pinned mid-conversation. While the existing
  /// free talk is still in progress it is reopened (idempotent for the same
  /// session); once it is concluded — script fully consumed — a brand new
  /// thread with a deterministic unique id lets the traveler redo the demo.
  ChatThread startFreeTalk() {
    final existing = _reusableFreeTalk();
    if (existing != null) {
      openConversation(existing.summary.id);
      return existing;
    }
    final thread = ChatFirstDemoData.freeTalkThread(
      trendJourneys,
      conversationId: _nextFreeTalkId(),
    );
    _threads.insert(0, thread);
    _activeThreadId = thread.summary.id;
    notifyListeners();
    _persistNewMessages(thread);
    return thread;
  }

  /// The free-talk thread still in progress, so repeat entries stay
  /// idempotent within the same session. A concluded thread is skipped: it is
  /// the demo being redone, so a fresh one is created instead.
  ChatThread? _reusableFreeTalk() {
    for (final thread in _threads) {
      if (_isFreeTalk(thread) && !_isFreeTalkConcluded(thread)) return thread;
    }
    return null;
  }

  static bool _isFreeTalk(ChatThread thread) =>
      thread.summary.id == kFreeTalkConversationId ||
      thread.summary.id.startsWith('$kFreeTalkConversationId-');

  /// Concluded when no script beat is left to emit. An open proposal or an
  /// unanswered question keeps the thread in progress.
  static bool _isFreeTalkConcluded(ChatThread thread) =>
      thread.scriptIndex >= thread.script.length;

  /// Deterministic unique id for a fresh free talk, derived from the existing
  /// threads so repeated instances (or process reloads) never collide: the
  /// stable base id when none exists yet, then `c-free-talk-2`, `c-free-talk-3`
  /// after every existing free talk.
  String _nextFreeTalkId() {
    var maxSuffix = 0;
    for (final thread in _threads) {
      final id = thread.summary.id;
      if (id == kFreeTalkConversationId) {
        if (maxSuffix < 1) maxSuffix = 1;
      } else if (id.startsWith('$kFreeTalkConversationId-')) {
        final suffix = int.tryParse(
          id.substring(kFreeTalkConversationId.length + 1),
        );
        if (suffix != null && suffix > maxSuffix) maxSuffix = suffix;
      }
    }
    return maxSuffix == 0
        ? kFreeTalkConversationId
        : '$kFreeTalkConversationId-${maxSuffix + 1}';
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
          _reusableFreeTalk() ??
          ChatFirstDemoData.freeTalkThread(
            trendJourneys,
            conversationId: _nextFreeTalkId(),
          );
      if (!_threads.contains(thread)) {
        _threads.insert(0, thread);
      }
      _activeThreadId = thread.summary.id;
      thread.travelerMessage(intent);
      if (aiService != null && aiService!.config.usesSupabase) {
        try {
          final aiResult = await aiService!.generatePlan(
            operation: 'suggest_destination',
            message: intent,
          );
          if (aiResult.isSuccess && aiResult.destinationName != null) {
            final destName = aiResult.destinationName!;
            final destCountry = aiResult.destinationCountry ?? '';
            final destWhy =
                aiResult.destinationWhy ?? 'Una meta adatta ai tuoi desideri.';
            final dynamicSnapshot = TripSnapshot(
              destinationTitle: destName,
              country: destCountry,
              durationLabel: '3 giorni',
              statusLabel: 'In pianificazione',
              dates: 'giorni da definire',
              transport: 'da definire',
              stay: 'da definire',
              placeLabels: const <String>[],
              days: aiResult.days.isEmpty
                  ? const <TripDaySnapshot>[]
                  : aiResult.days,
            );
            thread.summary = thread.summary.copyWith(
              title: destName,
              snapshot: dynamicSnapshot,
            );
            thread.messages.add(
              ChatMessage(
                id: '${thread.summary.id}-m${thread.messages.length + 1}',
                role: ChatRole.assistant,
                kind: ChatMessageKind.text,
                text:
                    '$destWhy\n\nHo impostato una prima rotta per $destName. Apri il piano per esplorarla!',
                sentAt: _now().toUtc(),
              ),
            );
          } else {
            if (!thread.advance()) {
              thread.messages.add(ChatFirstDemoData.closingReply());
            }
          }
        } catch (_) {
          if (!thread.advance()) {
            thread.messages.add(ChatFirstDemoData.closingReply());
          }
        }
      } else {
        if (!thread.advance()) {
          thread.messages.add(ChatFirstDemoData.closingReply());
        }
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
