import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
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
      expect(controller.threadOf(roma.summary.id).summary.unread, 0);
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
      expect(thread.messages[before + 1].kind, ChatMessageKind.planProposal);
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
      controller.sendMedia(
        asset: 'assets/images/travel/porto_river.jpg',
        isVideo: false,
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );

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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      controller.acceptProposal(roma.summary.id, proposal.id);

      final summaries = thread.messages.where(
        (m) => m.kind == ChatMessageKind.tripSummary,
      );
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

  group('Intake guidato (F4a)', () {
    test('startFromJourney apre un thread di intake con domande a scelta', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);

      expect(thread, isA<IntakeThread>());
      expect(thread.summary.isTrending, isTrue);
      expect(thread.summary.title, journey.stops.first);
      expect(thread.messages, isNotEmpty);
      expect(thread.messages.first.choices, isNotEmpty);
    });

    test('rispondere a tutte le domande produce la proposta finale', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;

      _answerIntake(controller, id);

      final proposalMessage = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      final snapshot = proposalMessage.proposal!.snapshot;
      expect(proposalMessage.proposal?.outcome, isNull);
      expect(snapshot.destinationTitle, journey.stops.first);
      expect(snapshot.transport, isNotEmpty);
      expect(snapshot.stay, isNotEmpty);
      expect(snapshot.placeLabels, isNotEmpty);
      expect(snapshot.days, isNotEmpty);
      expect(
        proposalMessage.proposal?.changeLabel,
        contains(journey.stops.first),
      );
    });

    test('il ritmo scelto cambia il numero di tappe al giorno', () {
      final relaxed = ChatFirstPrototypeController();
      final busy = ChatFirstPrototypeController();
      final journey = relaxed.trendJourneys.first;

      final relaxedThread = relaxed.startFromJourney(journey);
      final busyThread = busy.startFromJourney(journey);
      _answerIntake(
        relaxed,
        relaxedThread.summary.id,
        pace: 'Rilassato: un paio di tappe al giorno',
      );
      _answerIntake(
        busy,
        busyThread.summary.id,
        pace: 'Pieno, ma con pause vere',
      );

      final relaxedProposal = relaxedThread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      final busyProposal = busyThread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      expect(
        relaxedProposal.proposal!.snapshot.days.first.items.length,
        lessThan(busyProposal.proposal!.snapshot.days.first.items.length),
      );
    });

    test(
      'accettare la proposta aggiorna lo snapshot e persiste il piano',
      () async {
        final source = _TripSpyDataSource();
        final controller = ChatFirstPrototypeController(dataSource: source);
        final journey = controller.trendJourneys.first;
        final thread = controller.startFromJourney(journey);
        final id = thread.summary.id;

        _answerIntake(controller, id, duration: 'Un weekend, 3 giorni');
        final proposal = thread.messages.lastWhere(
          (m) => m.kind == ChatMessageKind.planProposal,
        );
        controller.acceptProposal(id, proposal.id);

        await Future<void>.delayed(Duration.zero);
        expect(thread.summary.snapshot?.destinationTitle, journey.stops.first);
        expect(thread.summary.snapshot?.durationLabel, '3 giorni');
        expect(proposal.proposal?.outcome, PlanProposalOutcome.accepted);
        expect(source.savedVersions.length, 1);
        expect(source.savedVersions.single.snapshot.durationLabel, '3 giorni');
      },
    );

    test('il riepilogo dopo l’accettazione riflette il piano accettato', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;

      _answerIntake(controller, id);
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      controller.acceptProposal(id, proposal.id);

      final summaries = thread.messages.where(
        (m) => m.kind == ChatMessageKind.tripSummary,
      );
      final lastSummary = summaries.last;
      expect(lastSummary.summary?.destinationTitle, journey.stops.first);
      expect(lastSummary.summary?.placeLabels, isNotEmpty);
    });
  });

  group('Moduli F5 (curation, trasporto, zona, itinerario)', () {
    test(
      'accettata l’intake il thread avanza da solo alla prima card luogo',
      () {
        final controller = ChatFirstPrototypeController();
        final journey = controller.trendJourneys.first;
        final thread = controller.startFromJourney(journey);
        final id = thread.summary.id;
        _startF5(controller, id);

        final summary = thread.messages.lastWhere(
          (m) => m.kind == ChatMessageKind.tripSummary,
        );
        expect(summary.summary?.destinationTitle, journey.stops.first);
        expect(
          thread.messages.any(
            (m) =>
                m.kind == ChatMessageKind.operational &&
                m.text.contains('salvato'),
          ),
          isTrue,
        );
        expect(thread.messages.last.kind, ChatMessageKind.placeCard);
        expect(thread.messages.last.placeCard, isNotNull);
        expect(thread.messages.last.choices.map((c) => c.label), <String>[
          'Passa',
          'Salva',
          'Irrinunciabile',
        ]);
      },
    );

    test('Salva porta il luogo in placeLabels e giorni dello snapshot', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      final place = thread.messages.last.placeCard!;

      _tapChoice(controller, id, 'Salva');

      final snapshot = thread.summary.snapshot!;
      expect(snapshot.placeLabels, <String>[place.name]);
      expect(snapshot.days, isNotEmpty);
      expect(
        snapshot.days.expand((d) => d.items).any((i) => i.title == place.name),
        isTrue,
      );
    });

    test('Irrinunciabile blocca il luogo nei giorni', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      final place = thread.messages.last.placeCard!;

      _tapChoice(controller, id, 'Irrinunciabile');

      final snapshot = thread.summary.snapshot!;
      final item = snapshot.days
          .expand((d) => d.items)
          .firstWhere((i) => i.title == place.name);
      expect(item.locked, isTrue);
    });

    test('Passa non tocca lo snapshot', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      final before = thread.summary.snapshot!;

      _tapChoice(controller, id, 'Passa');

      expect(thread.summary.snapshot, same(before));
    });

    test('la scelta del trasporto aggiorna snapshot.transport', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      for (var i = 0; i < 6; i++) {
        _tapChoice(controller, id, 'Passa');
      }
      expect(thread.messages.last.kind, ChatMessageKind.transport);

      _tapChoice(controller, id, 'Aereo diretto');

      expect(thread.summary.snapshot!.transport, 'Aereo diretto · 1h 30m');
    });

    test('la scelta della zona aggiorna snapshot.stay', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      for (var i = 0; i < 6; i++) {
        _tapChoice(controller, id, 'Passa');
      }
      _tapChoice(controller, id, 'Aereo diretto');
      final stayMessage = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.stayZone,
      );
      final zoneName = stayMessage.stayZone!.name;

      _tapChoice(controller, id, zoneName);

      expect(thread.summary.snapshot!.stay, zoneName);
    });

    test('il riepilogo itinerario riflette il piano raffinato', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      _tapChoice(controller, id, 'Salva');
      _tapChoice(controller, id, 'Salva');
      for (var i = 0; i < 4; i++) {
        _tapChoice(controller, id, 'Passa');
      }
      _tapChoice(controller, id, 'Aereo diretto');
      final zoneName = thread.messages
          .lastWhere((m) => m.kind == ChatMessageKind.stayZone)
          .stayZone!
          .name;
      _tapChoice(controller, id, zoneName);

      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
      final snapshot = proposal.proposal!.snapshot;
      expect(snapshot.placeLabels.length, 2);
      expect(snapshot.transport, 'Aereo diretto · 1h 30m');
      expect(snapshot.stay, zoneName);
    });

    test(
      'accettare la proposta itinerario persiste una seconda versione',
      () async {
        final source = _TripSpyDataSource();
        final controller = ChatFirstPrototypeController(dataSource: source);
        final journey = controller.trendJourneys.first;
        final thread = controller.startFromJourney(journey);
        final id = thread.summary.id;
        _startF5(controller, id);
        for (var i = 0; i < 6; i++) {
          _tapChoice(controller, id, 'Passa');
        }
        _tapChoice(controller, id, 'Aereo diretto');
        final zoneName = thread.messages
            .lastWhere((m) => m.kind == ChatMessageKind.stayZone)
            .stayZone!
            .name;
        _tapChoice(controller, id, zoneName);

        final proposal = thread.messages.lastWhere(
          (m) => m.kind == ChatMessageKind.planProposal,
        );
        expect(
          proposal.proposal!.snapshot.days.last.items.last.title,
          'Passeggiata finale',
        );
        controller.acceptProposal(id, proposal.id);

        await Future<void>.delayed(Duration.zero);
        expect(source.savedVersions.length, 2);
        expect(
          source.savedVersions.last.snapshot.days.last.items.last.title,
          'Passeggiata finale',
        );
      },
    );

    test(
      'annullare la proposta itinerario non persiste e non modifica',
      () async {
        final source = _TripSpyDataSource();
        final controller = ChatFirstPrototypeController(dataSource: source);
        final journey = controller.trendJourneys.first;
        final thread = controller.startFromJourney(journey);
        final id = thread.summary.id;
        _startF5(controller, id);
        for (var i = 0; i < 6; i++) {
          _tapChoice(controller, id, 'Passa');
        }
        _tapChoice(controller, id, 'In auto');
        final zoneName = thread.messages
            .lastWhere((m) => m.kind == ChatMessageKind.stayZone)
            .stayZone!
            .name;
        _tapChoice(controller, id, zoneName);

        final proposal = thread.messages.lastWhere(
          (m) => m.kind == ChatMessageKind.planProposal,
        );
        controller.rejectProposal(id, proposal.id);

        await Future<void>.delayed(Duration.zero);
        expect(source.savedVersions.length, 1);
        expect(
          thread.summary.snapshot!.days.last.items.last.title,
          isNot('Passeggiata finale'),
        );
      },
    );

    test('un testo libero non riconosciuto su una card luogo chiarisce e non '
        'avanza', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      final before = thread.messages.length;
      final snapshotBefore = thread.summary.snapshot!;

      controller.sendText('quello bello');

      expect(thread.messages.length, before + 2);
      final clarification = thread.messages.last;
      expect(clarification.role, ChatRole.assistant);
      expect(clarification.text, contains('Passa, Salva o Irrinunciabile'));
      expect(clarification.choices, isNotEmpty);
      expect(thread.summary.snapshot, same(snapshotBefore));
    });

    test('decisioni doppie sulla curation non duplicano il luogo', () {
      final controller = ChatFirstPrototypeController();
      final journey = controller.trendJourneys.first;
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      _startF5(controller, id);
      final place = thread.messages.last.placeCard!;

      _tapChoice(controller, id, 'Salva');
      final cardMessage = thread.messages.firstWhere(
        (m) =>
            m.kind == ChatMessageKind.placeCard && m.placeCard!.id == place.id,
      );
      controller.choose(
        cardMessage.choices.firstWhere((c) => c.label == 'Salva'),
        conversationId: id,
        messageId: cardMessage.id,
      );

      expect(
        thread.summary.snapshot!.placeLabels.where((l) => l == place.name),
        hasLength(1),
      );
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
      await source.insertMessage(
        'c-roma-active',
        ChatMessage(
          id: 'm-1',
          role: ChatRole.traveler,
          kind: ChatMessageKind.text,
          text: 'Ciao',
          sentAt: DateTime(2026, 10, 16, 10, 30),
        ),
      );
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
      final controller = ChatFirstPrototypeController(
        dataSource: MockDataSource(),
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
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
      final proposal = thread.messages.lastWhere(
        (m) => m.kind == ChatMessageKind.planProposal,
      );
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
      final controller = ChatFirstPrototypeController(
        dataSource: MockDataSource(),
      );
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

    test('ChatMessage round-trip conserva card luoghi, trasporto e zona', () {
      final original = ChatMessage(
        id: 'm-f5',
        role: ChatRole.assistant,
        kind: ChatMessageKind.placeCard,
        text: '',
        sentAt: DateTime(2026, 10, 16, 10, 30),
        placeCard: const PlaceCard(
          id: 'p-1',
          name: 'Perdersi in Alfama',
          category: 'Quartiere',
          neighborhood: 'Alfama',
          durationMinutes: 100,
          whyFits: 'Strade senza meta',
          bestMoment: 'Mattina presto',
        ),
        transport: const TransportCompare(
          options: <TransportOptionView>[
            TransportOptionView(
              label: 'Aereo diretto',
              priceLabel: 'da 89 €',
              durationLabel: '1h 30m',
              isRecommended: true,
            ),
          ],
        ),
        stayZone: const StayZoneInfo(
          name: 'Chiado',
          summary: 'Centrale e ben collegata.',
          whyFits: 'Riduce salite.',
          averageWalkMinutes: 13,
        ),
      );

      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.placeCard?.name, 'Perdersi in Alfama');
      expect(restored.placeCard?.durationMinutes, 100);
      expect(restored.transport?.options.single.isRecommended, isTrue);
      expect(restored.transport?.options.single.durationLabel, '1h 30m');
      expect(restored.stayZone?.averageWalkMinutes, 13);
      expect(restored.stayZone?.name, 'Chiado');
    });
  });

  group('Free talk (nuovo viaggio parlando)', () {
    test('startFreeTalk crea il thread libero e riusa quello esistente', () {
      final controller = ChatFirstPrototypeController();
      final created = controller.startFreeTalk();
      expect(created.summary.id, kFreeTalkConversationId);
      expect(created.summary.isTrending, isFalse);
      expect(created.summary.lastPreview, contains('Parlane'));
      expect(controller.threads.length, 3);

      final reused = controller.startFreeTalk();
      expect(reused.summary.id, kFreeTalkConversationId);
      expect(controller.threads.length, 3);
    });

    test('free talk reflects clues before naming any destination', () {
      final controller = ChatFirstPrototypeController();
      final thread = controller.startFreeTalk();
      controller.openConversation(thread.summary.id);
      final freeTalk = controller.threadOf(thread.summary.id) as FreeTalkThread;
      const forbiddenDestinations = <String>{'Lisbona', 'Porto', 'Roma'};
      expect(
        controller.trendJourneys.map(journeyCity).toSet(),
        containsAll(forbiddenDestinations),
      );

      controller.sendText(
        'Vorrei quattro giorni lenti a fine settembre, tipo Lisbona, con cibo',
      );
      final ack = freeTalk.messages.lastWhere((m) => m.id == kFreeTalkAckId);
      expect(ack.kind, ChatMessageKind.text);
      expect(ack.text, contains('quattro giorni lenti'));

      controller.sendText('Il budget è intorno a 500 euro.');
      expect(
        _assistantTexts(
          freeTalk,
        ).where((text) => forbiddenDestinations.any(text.contains)),
        isEmpty,
      );
    });

    test(
      'free talk preserves ordinary words containing a destination label',
      () {
        final controller = ChatFirstPrototypeController();
        final thread = controller.startFreeTalk();
        controller.openConversation(thread.summary.id);

        controller.sendText('Vorrei un weekend romantico a Roma.');

        final ack = controller
            .threadOf(thread.summary.id)
            .messages
            .lastWhere((message) => message.id == kFreeTalkAckId);
        expect(ack.text, contains('weekend romantico'));
        expect(ack.text, isNot(contains('Roma')));
      },
    );

    test(
      'free talk first reply emits acknowledgement then one missing question',
      () {
        final controller = ChatFirstPrototypeController();
        final thread = controller.startFreeTalk();
        controller.openConversation(thread.summary.id);
        final freeTalk =
            controller.threadOf(thread.summary.id) as FreeTalkThread;

        controller.sendText('Vorrei un weekend con calma.');

        final assistant = freeTalk.messages
            .where((message) => message.role == ChatRole.assistant)
            .toList(growable: false);
        expect(
          assistant.map((message) => message.id),
          containsAllInOrder(<String>[kFreeTalkAckId, kFreeTalkMissingId]),
        );
        expect(freeTalk.messages.last.id, kFreeTalkMissingId);
        expect(
          freeTalk.messages.where(
            (message) =>
                message.role == ChatRole.assistant &&
                message.choices.isNotEmpty,
          ),
          isEmpty,
        );
      },
    );

    test(
      'free talk correction revises the same thread and emits one proposal',
      () {
        final controller = ChatFirstPrototypeController();
        final thread = controller.startFreeTalk();
        controller.openConversation(thread.summary.id);

        controller.sendText('Vorrei quattro giorni lenti e buon cibo.');
        controller.sendText('A fine settembre.');
        _tapChoice(controller, thread.summary.id, 'Correggi');
        controller.sendText('Meglio ottobre e 500 euro.');
        final revised = controller
            .threadOf(thread.summary.id)
            .messages
            .lastWhere((message) => message.id == 'free-talk-summary-revised');
        expect(revised.text, contains('Meglio ottobre e 500 euro.'));

        _tapChoice(controller, thread.summary.id, 'Conferma');
        final messages = controller.threadOf(thread.summary.id).messages;
        expect(
          messages.where((message) => message.id == kFreeTalkProposalId),
          hasLength(1),
        );
        expect(controller.threadOf(thread.summary.id), same(thread));
      },
    );

    test(
      'home intent retries the same persisted batch without duplicate beats',
      () async {
        final source = _RetryingPersistenceDataSource();
        final controller = ChatFirstPrototypeController(dataSource: source);

        await expectLater(
          controller.submitHomeIntent('Vorrei partire piano.'),
          throwsStateError,
        );
        final failed = controller.threadOf(kFreeTalkConversationId);
        expect(
          failed.messages.where((m) => m.role == ChatRole.traveler),
          hasLength(1),
        );
        expect(
          failed.messages.where((m) => m.id == kFreeTalkMissingId),
          hasLength(1),
        );

        final thread = await controller.submitHomeIntent(
          'Vorrei partire piano.',
        );
        expect(thread, same(failed));
        expect(
          thread.messages.where((m) => m.role == ChatRole.traveler),
          hasLength(1),
        );
        expect(
          thread.messages.where((m) => m.id == kFreeTalkAckId),
          hasLength(1),
        );
        expect(
          thread.messages.where((m) => m.id == kFreeTalkMissingId),
          hasLength(1),
        );
      },
    );

    test('free talk names a destination only after summary confirmation', () {
      final controller = ChatFirstPrototypeController();
      final thread = controller.startFreeTalk();
      controller.openConversation(thread.summary.id);
      final freeTalk = controller.threadOf(thread.summary.id) as FreeTalkThread;
      const forbiddenDestinations = <String>{'Lisbona', 'Porto', 'Roma'};

      controller.sendText('Vorrei quattro giorni lenti, con buon cibo.');
      controller.sendText('A fine settembre.');

      final summary = freeTalk.messages.lastWhere(
        (message) => message.id == kFreeTalkSummaryId,
      );
      expect(summary.choices.map((choice) => choice.label), <String>[
        'Conferma',
        'Correggi',
      ]);
      expect(
        _assistantTexts(
          freeTalk,
        ).where((text) => forbiddenDestinations.any(text.contains)),
        isEmpty,
      );

      controller.choose(
        summary.choices.first,
        conversationId: thread.summary.id,
        messageId: summary.id,
      );
      final proposal = freeTalk.messages.lastWhere(
        (message) => message.id == kFreeTalkProposalId,
      );
      expect(proposal.kind, ChatMessageKind.planProposal);
      expect(forbiddenDestinations.any(proposal.text.contains), isTrue);
    });

    test('free talk keeps typed input when persistence fails', () async {
      final controller = ChatFirstPrototypeController(
        dataSource: _FailingPersistenceDataSource(),
      );
      final thread = controller.startFreeTalk();
      controller.openConversation(thread.summary.id);

      controller.sendText('Vorrei partire senza correre.');
      await Future<void>.delayed(Duration.zero);

      expect(
        controller
            .threadOf(thread.summary.id)
            .messages
            .any(
              (message) =>
                  message.role == ChatRole.traveler &&
                  message.text == 'Vorrei partire senza correre.',
            ),
        isTrue,
      );
    });

    test(
      'accepting a proposal keeps the in-memory plan when save fails',
      () async {
        final controller = ChatFirstPrototypeController(
          dataSource: _FailingTripVersionDataSource(),
        );
        final roma = controller.threads.firstWhere(
          (thread) => thread.summary.title.contains('Roma'),
        );
        controller.openConversation(roma.summary.id);
        controller.sendText('Rallenta la mattina');
        final proposal = controller
            .threadOf(roma.summary.id)
            .messages
            .lastWhere(
              (message) => message.kind == ChatMessageKind.planProposal,
            );

        controller.acceptProposal(roma.summary.id, proposal.id);
        await Future<void>.delayed(Duration.zero);

        expect(proposal.proposal?.outcome, PlanProposalOutcome.accepted);
        expect(
          controller
              .threadOf(roma.summary.id)
              .summary
              .snapshot
              ?.days
              .first
              .theme,
          'Mattina più lenta',
        );
      },
    );
  });
}

Iterable<String> _assistantTexts(ChatThread thread) => thread.messages
    .where((message) => message.role == ChatRole.assistant)
    .expand(
      (message) => <String>[
        message.text,
        ...message.choices.map((choice) => choice.label),
      ],
    );

/// Records `saveTripVersion` calls so tests can assert what the controller
/// persists after a proposal decision without touching a real database.
class _TripSpyDataSource extends MockDataSource {
  final List<({String conversationId, String title, TripSnapshot snapshot})>
  savedVersions =
      <({String conversationId, String title, TripSnapshot snapshot})>[];

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
    savedVersions.add((
      conversationId: conversationId,
      title: title,
      snapshot: snapshot,
    ));
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
  Future<void> upsertProfile({
    ThemeMode? themeMode,
    List<String>? memoryTags,
  }) async {
    upserts.add((themeMode: themeMode, memoryTags: memoryTags));
  }
}

/// Fully inherits the mock boundary and fails only message persistence.
class _FailingPersistenceDataSource extends MockDataSource {
  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'failing-conversation',
        conversation: summary,
        updatedAt: DateTime(2026, 10, 16, 10, 30),
      );

  @override
  Future<void> insertMessage(String conversationId, ChatMessage message) async {
    throw StateError('persistence unavailable');
  }
}

class _RetryingPersistenceDataSource extends MockDataSource {
  final _fail = <bool>[true];

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'retrying-conversation',
        conversation: summary,
        updatedAt: DateTime(2026, 10, 16, 10, 30),
      );

  @override
  Future<void> insertMessage(String conversationId, ChatMessage message) async {
    if (_fail.single) {
      _fail[0] = false;
      throw StateError('persistence unavailable');
    }
  }
}

/// Fully inherits the mock boundary and fails only accepted-plan persistence.
class _FailingTripVersionDataSource extends MockDataSource {
  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'failing-trip-version',
        conversation: summary,
        updatedAt: DateTime(2026, 10, 16, 10, 30),
      );

  @override
  Future<void> saveTripVersion({
    required String conversationId,
    required String title,
    required TripSnapshot snapshot,
  }) async {
    throw StateError('trip version persistence unavailable');
  }
}

/// Answers every guided intake question by tapping the choice with [label].
/// Defaults pick the balanced option of each question.
void _answerIntake(
  ChatFirstPrototypeController controller,
  String conversationId, {
  String duration = '4–5 giorni, senza fretta',
  String pace = 'Bilanciato: cultura e pause',
  String base = 'Centro, per spostarmi a piedi',
  String transport = 'Treno o metro + passi',
  String budget = 'Moderato: qualche tavola bella',
}) {
  for (final label in <String>[duration, pace, base, transport, budget]) {
    final thread = controller.threadOf(conversationId);
    final choice = thread.messages
        .expand((m) => m.choices)
        .firstWhere((c) => c.label == label);
    controller.choose(choice, conversationId: conversationId);
  }
}

/// Answers the intake, accepts its proposal, then lets the thread auto-advance
/// through the transition tail, landing on the first F5 curation place card.
void _startF5(ChatFirstPrototypeController controller, String conversationId) {
  _answerIntake(controller, conversationId);
  final proposal = controller
      .threadOf(conversationId)
      .messages
      .lastWhere((m) => m.kind == ChatMessageKind.planProposal);
  controller.acceptProposal(conversationId, proposal.id);
}

/// Chooses [label] on the most recent message that offers it, advancing the
/// thread one beat.
void _tapChoice(
  ChatFirstPrototypeController controller,
  String conversationId,
  String label,
) {
  final thread = controller.threadOf(conversationId);
  final message = thread.messages.lastWhere(
    (m) => m.choices.any((c) => c.label == label),
  );
  final choice = message.choices.firstWhere((c) => c.label == label);
  controller.choose(choice, conversationId: conversationId);
}
