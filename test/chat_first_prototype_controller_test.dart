import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/mock_data_source.dart';
import 'package:iter/models/trip_models.dart' show JourneyRoute;

void main() {
  group('ChatFirstPrototypeController', () {
    test('seed espone due conversazioni con unread', () {
      final controller = ChatFirstPrototypeController();
      expect(controller.threads.length, 2);
      expect(controller.unread, 2);
      expect(
        controller.threads.any((t) => t.summary.title.contains('Roma')),
        isTrue,
      );
    });

    test('openConversation azzera i non letti', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      expect(roma.summary.unread, 2);
      controller.openConversation(roma.summary.id);
      expect(controller.unread, 0);
      expect(
        controller.threadOf(roma.summary.id).summary.unread,
        0,
      );
    });

    test('sendText avanza lo script e aggiunge messaggio viaggiatore', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      controller.openConversation(roma.summary.id);
      final before = controller.activeThread!.messages.length;
      controller.sendText('Rallenta la mattina');
      final thread = controller.threadOf(roma.summary.id);
      expect(thread.messages.length, before + 2);
      expect(thread.messages[before].role, ChatRole.traveler);
      expect(
        thread.messages[before + 1].kind,
        ChatMessageKind.planProposal,
      );
    });

    test('choose confermante prosegue, non confermante non crea messaggi', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      controller.openConversation(roma.summary.id);
      final thread = controller.threadOf(roma.summary.id);
      final before = thread.messages.length;

      controller.choose(
        const ChatChoice(label: 'Solo ispirazione', confirm: false),
        conversationId: roma.summary.id,
      );
      expect(thread.messages.length, before);

      controller.choose(
        const ChatChoice(label: 'Rallenta la mattina'),
        conversationId: roma.summary.id,
      );
      expect(thread.messages.length, before + 2);
    });

    test('sendAudio aggiunge un vocale viaggiatore + risposta', () {
      final controller = ChatFirstPrototypeController();
      final porto = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Porto'),
      );
      controller.openConversation(porto.summary.id);
      final before = controller.threadOf(porto.summary.id).messages.length;
      controller.sendAudio();
      final thread = controller.threadOf(porto.summary.id);
      expect(thread.messages.length, before + 2);
      expect(thread.messages[before].kind, ChatMessageKind.audio);
      expect(thread.messages[before].role, ChatRole.traveler);
    });

    test('sendMedia aggiunge un allegato immagine + risposta scriptata', () {
      final controller = ChatFirstPrototypeController();
      final porto = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Porto'),
      );
      controller.openConversation(porto.summary.id);
      final before = controller.threadOf(porto.summary.id).messages.length;
      controller.sendMedia(asset: 'assets/images/travel/porto_river.jpg', isVideo: false);
      final thread = controller.threadOf(porto.summary.id);
      expect(thread.messages[before].kind, ChatMessageKind.media);
      expect(thread.messages[before].media?.isVideo, isFalse);
      expect(thread.messages.length, before + 2);
    });

    test('script esaurito produce la risposta di chiusura', () {
      final controller = ChatFirstPrototypeController();
      final porto = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Porto'),
      );
      controller.openConversation(porto.summary.id);
      while (controller.threadOf(porto.summary.id).messages.length < 50) {
        controller.sendText('Continua');
      }
      final thread = controller.threadOf(porto.summary.id);
      expect(thread.scriptIndex, greaterThanOrEqualTo(thread.script.length));
    });

    test('startFromJourney crea un nuovo piano e riusa esistente', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final created = controller.startFromJourney(journey);
      expect(created.summary.isTrending, isTrue);
      expect(controller.threads.length, 3);

      final reused = controller.startFromJourney(journey);
      expect(reused.summary.id, created.summary.id);
      expect(controller.threads.length, 3);
    });

    test('acceptProposal aggiorna lo snapshot della conversazione', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);
      final original = thread.summary.snapshot!;
      expect(original.days.first.theme, 'Centro storico');
      expect(original.days.first.items.first.time, '09:30');

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      expect(proposal.proposal?.outcome, isNull);

      controller.acceptProposal(roma.summary.id, proposal.id);
      final updated = controller.threadOf(roma.summary.id).summary.snapshot!;
      expect(updated.days.first.theme, 'Mattina più lenta');
      expect(updated.days.first.items.first.time, '10:30');
      expect(proposal.proposal?.outcome, PlanProposalOutcome.accepted);
      expect(proposal.proposal?.snapshot, same(updated));
    });

    test('rejectProposal mantiene lo snapshot e chiude la proposta', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);
      final original = thread.summary.snapshot!;

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);

      controller.rejectProposal(roma.summary.id, proposal.id);
      expect(
        controller.threadOf(roma.summary.id).summary.snapshot,
        same(original),
      );
      expect(proposal.proposal?.outcome, PlanProposalOutcome.rejected);
    });

    test('la proposta risolta ignora ulteriori tentativi', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      final beforeAccept = thread.messages.length;
      controller.acceptProposal(roma.summary.id, proposal.id);
      final afterAccept = thread.messages.length;
      expect(afterAccept, beforeAccept + 2);

      controller.acceptProposal(roma.summary.id, proposal.id);
      expect(thread.messages.length, afterAccept);
      expect(proposal.proposal?.outcome, PlanProposalOutcome.accepted);
    });

    test('dopo la decisione il riepilogo riflette lo snapshot corrente', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      controller.acceptProposal(roma.summary.id, proposal.id);

      final summaries = thread.messages
          .where((m) => m.kind == ChatMessageKind.tripSummary);
      final lastSummary = summaries.last;
      expect(lastSummary.summary?.days.first.theme, 'Mattina più lenta');
      expect(lastSummary.summary?.days.first.items.first.time, '10:30');
    });

    test('poisFor ritorna i punti della prima destinazione (mock)', () async {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.firstWhere(
        (j) => j.destinationIds.contains('porto'),
      );
      final pois = await controller.poisFor(journey);
      expect(pois, isNotEmpty);
      expect(pois.first.name, isNotEmpty);
      expect(pois.first.whyFits, isNotEmpty);
    });

    test('poisFor ritorna lista vuota senza destinazioni', () async {
      final controller = ChatFirstPrototypeController();
      const empty = JourneyRoute(
        id: 'x',
        title: 'X',
        summary: '',
        durationLabel: '',
        stops: <String>[],
        destinationIds: <String>[],
        whyItFits: '',
        season: '',
        travelMode: '',
        videoAssets: <String>[],
        matchScore: 0,
      );
      expect(await controller.poisFor(empty), isEmpty);
    });
  });

  group('MockDataSource pois', () {
    test('fetchPois ritorna i punti di una destinazione conosciuta', () async {
      final source = MockDataSource();
      final pois = await source.fetchPois('porto');
      expect(pois, isNotEmpty);
      expect(pois.first.name, isNotEmpty);
      expect(pois.first.emoji, isNotEmpty);
      expect(pois.first.whyFits, isNotEmpty);
    });

    test('fetchPois ritorna lista vuota per slug sconosciuto', () async {
      final source = MockDataSource();
      expect(await source.fetchPois('atlantide'), isEmpty);
    });
  });

  group('Persistenza mock (F2a)', () {
    test('fetchConversations e fetchMessages sono vuoti', () async {
      final source = MockDataSource();
      expect(await source.fetchConversations(), isEmpty);
      expect(await source.fetchMessages('c-roma-active'), isEmpty);
    });

    test('le operazioni di scrittura sono no-op', () async {
      final source = MockDataSource();
      await source.insertMessage('c-roma-active', ChatMessage(
        id: 'm-1',
        role: ChatRole.traveler,
        kind: ChatMessageKind.text,
        text: 'Ciao',
        sentAt: DateTime(2026, 10, 16, 10, 30),
      ));
      await source.setConversationRead('c-roma-active');
      await source.incrementUnread('c-roma-active');
      expect(await source.fetchConversations(), isEmpty);
      expect(await source.fetchMessages('c-roma-active'), isEmpty);
    });

    test('createConversation su mock non crea nulla', () async {
      final source = MockDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final row = await source.createConversation(thread.summary);
      expect(row, isNull);
    });

    test('restoreConversations su mock non altera i seed', () async {
      final controller = ChatFirstPrototypeController(dataSource: MockDataSource());
      await controller.restoreConversations();
      expect(controller.threads.length, 2);
      expect(controller.unread, 2);
    });
  });

  group('Persistenza piano (F2b)', () {
    test('acceptProposal salva una versione del piano aggiornata', () async {
      final source = _TripSpyDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      controller.acceptProposal(roma.summary.id, proposal.id);

      await Future<void>.delayed(Duration.zero);
      expect(source.savedVersions.length, 1);
      final saved = source.savedVersions.single;
      expect(saved.snapshot.days.first.theme, 'Mattina più lenta');
      expect(saved.snapshot.days.first.items.first.time, '10:30');
      expect(saved.title, 'Roma');
    });

    test('rejectProposal non salva alcuna versione', () async {
      final source = _TripSpyDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      controller.rejectProposal(roma.summary.id, proposal.id);

      await Future<void>.delayed(Duration.zero);
      expect(source.savedVersions, isEmpty);
    });

    test('proposta già risolta non genera una seconda versione', () async {
      final source = _TripSpyDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);

      controller.openConversation(roma.summary.id);
      controller.sendText('Rallenta la mattina');
      final proposal = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
      controller.acceptProposal(roma.summary.id, proposal.id);
      controller.acceptProposal(roma.summary.id, proposal.id);

      await Future<void>.delayed(Duration.zero);
      expect(source.savedVersions.length, 1);
    });

    test('saveTripVersion su mock è un no-op sicuro', () async {
      final source = MockDataSource();
      final snapshot = ChatFirstPrototypeController()
          .threadOf('c-roma-active')
          .summary
          .snapshot!;
      await source.saveTripVersion(
        conversationId: 'aaa-bbb',
        title: 'Roma',
        snapshot: snapshot,
      );
    });
  });

  group('Profilo e memoria (F3)', () {
    test('fetchProfile su mock è nullo e upsertProfile è no-op', () async {
      final source = MockDataSource();
      expect(await source.fetchProfile(), isNull);
      await source.upsertProfile(themeMode: ThemeMode.dark);
      await source.upsertProfile(memoryTags: const <String>['Ritmo lento']);
      expect(await source.fetchProfile(), isNull);
    });

    test('loadProfile su mock mantiene tema chiaro e tag demo', () async {
      final controller = ChatFirstPrototypeController(dataSource: MockDataSource());
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.memoryTags, isNotEmpty);
      await controller.loadProfile();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.memoryTags, isNotEmpty);
    });

    test('setThemeMode aggiorna lo stato e persiste via spy', () async {
      final source = _ProfileSpyDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      expect(controller.themeMode, ThemeMode.light);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(source.upserts.length, 1);
      expect(source.upserts.single.themeMode, ThemeMode.dark);
      expect(source.upserts.single.memoryTags, isNull);
    });

    test('setThemeMode su stesso valore non persiste di nuovo', () async {
      final source = _ProfileSpyDataSource();
      final controller = ChatFirstPrototypeController(dataSource: source);
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setThemeMode(ThemeMode.dark);
      expect(source.upserts.length, 1);
    });

    test('loadProfile valorizza tema e tag letti dallo spy', () async {
      final source = _ProfileSpyDataSource(
        profile: const ProfileRow(
          themeMode: ThemeMode.dark,
          memoryTags: <String>['Ama i borghi'],
        ),
      );
      final controller = ChatFirstPrototypeController(dataSource: source);
      await controller.loadProfile();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.memoryTags, <String>['Ama i borghi']);
    });
  });

  group('Serializzazione (F2a)', () {
    test('Conversation round-trip conserva campi e snapshot', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final json = roma.summary.toJson();
      final restored = Conversation.fromJson(json);
      expect(restored.id, roma.summary.id);
      expect(restored.title, 'Roma');
      expect(restored.unread, 2);
      expect(restored.avatar.asset, roma.summary.avatar.asset);
      expect(restored.snapshot?.destinationTitle, 'Roma');
      expect(restored.snapshot?.days.first.theme, 'Centro storico');
    });

    test('ChatMessage round-trip conserva media, choices e audio', () {
      final original = ChatMessage(
        id: 'm-1',
        role: ChatRole.traveler,
        kind: ChatMessageKind.media,
        text: '',
        sentAt: DateTime(2026, 10, 16, 10, 32),
        media: const ChatMedia(asset: 'a.jpg', isVideo: false),
        choices: const <ChatChoice>[ChatChoice(label: 'Sì')],
      );
      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.id, 'm-1');
      expect(restored.role, ChatRole.traveler);
      expect(restored.kind, ChatMessageKind.media);
      expect(restored.media?.asset, 'a.jpg');
      expect(restored.choices.single.label, 'Sì');
    });

    test('PlanProposal round-trip conserva snapshot e outcome', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final thread = controller.threadOf(roma.summary.id);
      final message = ChatMessage(
        id: 'p-1',
        role: ChatRole.assistant,
        kind: ChatMessageKind.planProposal,
        text: '',
        sentAt: DateTime(2026, 10, 16, 10, 32),
        proposal: PlanProposal(
          changeLabel: 'Foro Romano alle 10:30',
          snapshot: thread.summary.snapshot!,
        ),
      );
      final restored = ChatMessage.fromJson(message.toJson());
      expect(restored.proposal?.changeLabel, 'Foro Romano alle 10:30');
      expect(restored.proposal?.snapshot.destinationTitle, 'Roma');
      expect(restored.proposal?.outcome, isNull);

      message.proposal!.outcome = PlanProposalOutcome.accepted;
      final settled = ChatMessage.fromJson(message.toJson());
      expect(settled.proposal?.outcome, PlanProposalOutcome.accepted);
    });

    test('ConversationRow.fromDbRow usa unread e updated_at dal DB', () {
      final row = <String, dynamic>{
        'id': 'aaa-bbb',
        'title': 'Roma',
        'avatar_asset': 'rome.jpg',
        'unread': 4,
        'updated_at': '2026-10-16T10:30:00.000Z',
        'summary': <String, dynamic>{},
      };
      final parsed = ConversationRow.fromDbRow(row);
      expect(parsed.id, 'aaa-bbb');
      expect(parsed.title, 'Roma');
      expect(parsed.unread, 4);
      expect(parsed.avatarAsset, 'rome.jpg');
      expect(parsed.updatedAt, DateTime.parse('2026-10-16T10:30:00.000Z'));
    });

    test('ConversationRow.fromDbRow recupera da summary jsonb completo', () {
      final controller = ChatFirstPrototypeController();
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      final row = <String, dynamic>{
        'id': 'aaa-bbb',
        'title': 'Roma',
        'avatar_asset': 'rome.jpg',
        'unread': 2,
        'updated_at': '2026-10-16T10:30:00.000Z',
        'summary': roma.summary.toJson(),
      };
      final parsed = ConversationRow.fromDbRow(row);
      expect(parsed.title, 'Roma');
      expect(parsed.unread, 2);
      expect(parsed.snapshot?.destinationTitle, 'Roma');
    });

    test('ChatMessage.fromJson tollera campi mancanti', () {
      final restored = ChatMessage.fromJson(const <String, dynamic>{});
      expect(restored.id, '');
      expect(restored.kind, ChatMessageKind.text);
      expect(restored.text, '');
    });
  });
}

/// Records `saveTripVersion` calls so tests can assert what the controller
/// persists after a proposal decision without touching a real database.
class _TripSpyDataSource extends MockDataSource {
  final List<({String conversationId, String title, TripSnapshot snapshot})>
      savedVersions = <({String conversationId, String title, TripSnapshot snapshot})>[];

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'conv-1',
        conversation: summary,
        updatedAt: DateTime(2026, 10, 16, 10, 30),
      );

  @override
  Future<void> saveTripVersion({
    required String conversationId,
    required String title,
    required TripSnapshot snapshot,
  }) async {
    savedVersions.add((conversationId: conversationId, title: title, snapshot: snapshot));
  }
}

/// Serves a configurable `fetchProfile` result and records `upsertProfile`
/// calls so tests can assert profile loading and theme persistence without a
/// real database.
class _ProfileSpyDataSource extends MockDataSource {
  _ProfileSpyDataSource({this.profile});

  final ProfileRow? profile;

  final List<({ThemeMode? themeMode, List<String>? memoryTags})> upserts =
      <({ThemeMode? themeMode, List<String>? memoryTags})>[];

  @override
  Future<ProfileRow?> fetchProfile() async => profile;

  @override
  Future<void> upsertProfile({ThemeMode? themeMode, List<String>? memoryTags}) async {
    upserts.add((themeMode: themeMode, memoryTags: memoryTags));
  }
}