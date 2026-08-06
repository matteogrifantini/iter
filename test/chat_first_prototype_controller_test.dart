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
}