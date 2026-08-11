import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart'
    show AppLifecycleState, ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'package:iter/app/app_config.dart';
import 'package:iter/data/mock_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/data_source.dart';
import 'package:iter/features/chat_first_prototype/mock_data_source.dart';
import 'package:iter/features/chat_first_prototype/plan_editor.dart';
import 'package:iter/features/chat_first_prototype/plan_external_launcher.dart';
import 'package:iter/features/chat_first_prototype/supabase_data_source.dart';
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
      expect(updated.revision, original.revision + 1);
      expect(updated.revisionMetadata?.origin, PlanChangeOrigin.chat);
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
      expect(saved.conversation.title, 'Roma');
      expect(saved.conversation.snapshot, same(saved.snapshot));
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

    test('saveTripVersion su mock restituisce successo', () async {
      final source = MockDataSource();
      final conversation = ChatFirstPrototypeController()
          .threadOf('c-roma-active')
          .summary;
      final result = await source.saveTripVersion(
        conversationId: 'aaa-bbb',
        conversation: conversation,
        snapshot: conversation.snapshot!,
      );
      expect(result.succeeded, isTrue);
      expect(result.errorCode, isNull);
    });

    test(
      'saveTripVersion invoca una sola RPC con il payload atomico completo',
      () async {
        final server = await _TripVersionPostgrestServer.start();
        addTearDown(server.close);
        final client = SupabaseClient(server.url, 'test-publishable-key');
        final source = SupabaseDataSource(
          config: AppConfig(
            backend: 'supabase',
            supabaseUrl: server.url,
            supabaseAnonKey: 'test-publishable-key',
          ),
          client: client,
        );
        final conversation = ChatFirstPrototypeController()
            .threadOf('c-roma-active')
            .summary;
        final snapshot = conversation.snapshot!.copyWith(revision: 7);
        final updatedConversation = conversation.copyWith(snapshot: snapshot);

        final result = await source.saveTripVersion(
          conversationId: 'conversation-db-id',
          conversation: updatedConversation,
          snapshot: snapshot,
        );

        expect(result.succeeded, isTrue);
        expect(server.requests, hasLength(1));
        final request = server.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/rest/v1/rpc/save_trip_revision');
        expect(request.body, <String, dynamic>{
          'p_conversation_id': 'conversation-db-id',
          'p_title': updatedConversation.title,
          'p_status': 'active',
          'p_snapshot': snapshot.toJson(),
          'p_summary': updatedConversation.toJson(),
          'p_revision': 7,
        });
      },
    );

    test(
      'saveTripVersion traduce un errore PostgREST in failure osservabile',
      () async {
        final server = await _TripVersionPostgrestServer.start(
          failRequests: true,
        );
        addTearDown(server.close);
        final source = SupabaseDataSource(
          config: AppConfig(
            backend: 'supabase',
            supabaseUrl: server.url,
            supabaseAnonKey: 'test-publishable-key',
          ),
          client: SupabaseClient(server.url, 'test-publishable-key'),
        );
        final conversation = ChatFirstPrototypeController()
            .threadOf('c-roma-active')
            .summary;

        final result = await source.saveTripVersion(
          conversationId: 'conversation-db-id',
          conversation: conversation,
          snapshot: conversation.snapshot!,
        );

        expect(result.succeeded, isFalse);
        expect(result.errorCode, 'XX000');
      },
    );

    test('migration crea trip_versions canonica prima dei grant', () async {
      final sql = await File(
        'supabase/migrations/'
        '20260810235146_add_trip_version_owner_policies.sql',
      ).readAsString();
      final normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      const tableDdl =
          'create table if not exists public.trip_versions ( '
          'id uuid primary key default gen_random_uuid(), '
          'trip_id uuid not null references public.trips (id) on delete cascade, '
          'version_number integer not null check (version_number > 0), '
          'draft jsonb not null, '
          'created_at timestamptz not null default now(), '
          'unique (trip_id, version_number) '
          ');';
      const indexDdl =
          'create index if not exists idx_trip_versions_trip '
          'on public.trip_versions (trip_id, created_at desc);';
      const rlsDdl =
          'alter table public.trip_versions enable row level security;';
      const grant =
          'grant select, insert on table public.trip_versions '
          'to authenticated;';

      expect(normalized, contains(tableDdl));
      expect(normalized, contains(indexDdl));
      expect(normalized, contains(rlsDdl));
      expect(normalized.indexOf(tableDdl), lessThan(normalized.indexOf(grant)));
      expect(normalized.indexOf(indexDdl), lessThan(normalized.indexOf(grant)));
      expect(normalized.indexOf(rlsDdl), lessThan(normalized.indexOf(grant)));
    });

    test('fresh SQL limita trip_versions agli utenti permanenti', () async {
      final schema = await File('supabase/schema.sql').readAsString();
      final migration = await File(
        'supabase/migrations/'
        '20260810235146_add_trip_version_owner_policies.sql',
      ).readAsString();

      _expectTripVersionLeastPrivilege('schema.sql', schema);
      _expectTripVersionLeastPrivilege('migration originale', migration);
    });

    test('follow-up migration restringe privilegi e policy live', () async {
      final migrations = Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('_tighten_trip_version_privileges.sql'),
          )
          .toList(growable: false);

      expect(migrations, hasLength(1));
      final sql = await migrations.single.readAsString();
      _expectTripVersionLeastPrivilege('migration follow-up', sql);
      final normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      expect(
        normalized,
        contains('revoke execute on function public.save_trip_revision'),
      );
      expect(normalized, contains('from public, anon'));
      expect(
        normalized,
        contains('grant execute on function public.save_trip_revision'),
      );
      expect(normalized, contains('to authenticated'));
    });

    test('migration rende RPC atomica, monotona e policy ripetibili', () async {
      final sql = await File(
        'supabase/migrations/'
        '20260810235146_add_trip_version_owner_policies.sql',
      ).readAsString();
      final normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final schema = await File('supabase/schema.sql').readAsString();
      final normalizedSchema = schema.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );

      expect(normalized, contains('security invoker'));
      expect(normalized, isNot(contains('security definer')));
      expect(normalized, contains("set search_path = ''"));
      expect(RegExp(r'for update').allMatches(normalized), hasLength(2));
      expect(normalized, contains('p_revision <= v_latest_revision'));
      expect(
        normalized,
        contains('on conflict (trip_id, version_number) do nothing'),
      );
      expect(
        normalized,
        contains('revoke execute on function public.save_trip_revision'),
      );
      expect(normalized, contains('from public, anon'));
      expect(
        normalized,
        contains('grant execute on function public.save_trip_revision'),
      );
      expect(normalized, contains('to authenticated'));
      expect(
        normalized,
        contains(
          'drop policy if exists "trip versions owner select" '
          'on public.trip_versions; create policy '
          '"trip versions owner select"',
        ),
      );
      expect(
        normalized,
        contains(
          'drop policy if exists "trip versions owner insert" '
          'on public.trip_versions; create policy '
          '"trip versions owner insert"',
        ),
      );
      expect(
        _saveTripRevisionContract(normalizedSchema),
        _saveTripRevisionContract(normalized),
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

  group('Controller Piano operativo', () {
    test('tutti i comandi producono anteprime senza mutare il piano', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';
      final before = controller.conversationOf(conversationId).snapshot!;

      final add = controller.previewAddPlace(
        conversationId: conversationId,
        item: const TripItemSnapshot(
          id: 'porto-new-stop',
          title: 'Casa da Musica',
          category: 'Musica',
          startTime: '11:00',
          durationMinutes: 60,
          locked: false,
        ),
        targetDayId: 'porto-day-1',
        targetIndex: 1,
      );
      final move = controller.previewMoveStop(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
        targetDayId: 'porto-day-2',
        targetIndex: 1,
      );
      final remove = controller.previewRemoveStop(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
      );
      final time = controller.previewChangeTime(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
        startTime: '08:30',
      );
      final lock = controller.previewToggleLock(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
      );

      expect(<PlanPatchKind>[
        add.kind,
        move.kind,
        remove.kind,
        time.kind,
        lock.kind,
      ], PlanPatchKind.values);
      expect(controller.conversationOf(conversationId).snapshot, same(before));
      expect(controller.pendingPlanPatch(conversationId), same(lock));
      expect(controller.pendingPlanPatch('c-plan-roma'), isNull);
    });

    test('conferma applica e persiste una sola volta', () async {
      final source = _PlanRecordingDataSource();
      final controller = _planController(dataSource: source);
      const conversationId = 'c-plan-porto';
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.previewChangeTime(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
        startTime: '08:30',
      );
      final applied = controller.confirmPlanPatch(conversationId);
      final duplicate = controller.confirmPlanPatch(conversationId);
      await source.savedCount(1);

      expect(applied?.status, PlanPatchStatus.applied);
      expect(duplicate, isNull);
      expect(controller.conversationOf(conversationId).snapshot?.revision, 2);
      expect(source.savedVersions, hasLength(1));
      expect(source.savedVersions.single.snapshot.revision, 2);
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test(
      'proposta chat accettata crea revisione, history e restore persistito',
      () async {
        final source = _RestoringPlanDataSource();
        final controller = _planController(dataSource: source);
        const conversationId = 'c-plan-porto';

        controller.previewToggleLock(
          conversationId: conversationId,
          itemId: 'porto-livraria-lello-stop',
        );
        controller.confirmPlanPatch(conversationId);
        await source.savedCount(1);
        final before = controller.conversationOf(conversationId).snapshot!;
        final proposal = ChatMessage(
          id: 'proposal-after-r2',
          role: ChatRole.assistant,
          kind: ChatMessageKind.planProposal,
          text: 'Rendo il piano piu lento.',
          sentAt: DateTime(2026, 8, 11, 12, 30),
          proposal: PlanProposal(
            changeLabel: 'Ritmo piu lento',
            snapshot: before.copyWith(statusLabel: 'Piu lento'),
          ),
        );
        controller.threadOf(conversationId).messages.add(proposal);

        controller.acceptProposal(conversationId, proposal.id);
        await source.savedCount(2);

        final accepted = controller.conversationOf(conversationId).snapshot!;
        expect(accepted.revision, before.revision + 1);
        expect(accepted.statusLabel, 'Piu lento');
        expect(accepted.revisionMetadata?.origin, PlanChangeOrigin.chat);
        expect(
          controller.planRevisionHistory(conversationId).last,
          isA<PlanRevisionRecord>()
              .having((record) => record.before.revision, 'before', 2)
              .having(
                (record) => record.after.revision,
                'after',
                before.revision + 1,
              ),
        );
        expect(source.savedVersions.last.snapshot.toJson(), accepted.toJson());
        expect(
          source.savedVersions.last.conversation.snapshot?.toJson(),
          accepted.toJson(),
        );

        final restored = ChatFirstPrototypeController(
          dataSource: source,
          seed: <ChatThread>[],
        );
        await restored.restoreConversations();
        expect(
          restored.conversationOf(conversationId).snapshot?.toJson(),
          accepted.toJson(),
        );
      },
    );

    test('conferma stale ricalcola e richiede una nuova conferma', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';
      final thread = controller.threadOf(conversationId);
      final current = thread.summary.snapshot!;
      controller.previewChangeTime(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
        startTime: '08:30',
      );
      thread.summary = thread.summary.copyWith(
        snapshot: current.copyWith(revision: current.revision + 1),
      );

      final rebased = controller.confirmPlanPatch(conversationId);
      expect(rebased?.baseRevision, 2);
      expect(rebased?.requiresConfirmation, isTrue);
      expect(controller.conversationOf(conversationId).snapshot?.revision, 2);

      final applied = controller.confirmPlanPatch(conversationId);
      expect(applied?.status, PlanPatchStatus.applied);
      expect(controller.conversationOf(conversationId).snapshot?.revision, 3);
    });

    test('annulla elimina solo la patch della conversazione richiesta', () {
      final controller = _planController();
      controller.previewToggleLock(
        conversationId: 'c-plan-porto',
        itemId: 'porto-livraria-lello-stop',
      );
      controller.previewToggleLock(
        conversationId: 'c-plan-roma',
        itemId: 'roma-foro-stop',
      );

      expect(controller.cancelPlanPatch('c-plan-porto'), isTrue);
      expect(controller.pendingPlanPatch('c-plan-porto'), isNull);
      expect(controller.pendingPlanPatch('c-plan-roma'), isNotNull);
      expect(controller.cancelPlanPatch('c-plan-porto'), isFalse);
    });

    test(
      'cronologia mantiene dieci before/after e undo crea una revisione',
      () {
        final controller = _planController();
        const conversationId = 'c-plan-porto';
        for (var index = 0; index < 11; index++) {
          controller.previewToggleLock(
            conversationId: conversationId,
            itemId: 'porto-livraria-lello-stop',
          );
          expect(controller.confirmPlanPatch(conversationId), isNotNull);
        }
        final beforeUndo = controller.conversationOf(conversationId).snapshot!;
        final history = controller.planRevisionHistory(conversationId);
        expect(history, hasLength(10));
        expect(history.last.before.revision, 11);
        expect(history.last.after.revision, 12);

        expect(controller.undoLastPlanRevision(conversationId), isTrue);
        final undone = controller.conversationOf(conversationId).snapshot!;
        expect(undone.revision, beforeUndo.revision + 1);
        expect(undone.days.first.items.first.locked, isFalse);
        expect(undone.revisionMetadata?.label, 'Annulla ultima modifica');
        expect(controller.planRevisionHistory(conversationId), hasLength(10));
      },
    );

    test(
      'fallimento espone errorCode e retry salva la revisione esatta',
      () async {
        final source = _RetryingPlanDataSource();
        final controller = _planController(dataSource: source);
        const conversationId = 'c-plan-porto';
        controller.previewToggleLock(
          conversationId: conversationId,
          itemId: 'porto-livraria-lello-stop',
        );
        controller.confirmPlanPatch(conversationId);
        await source.savedCount(1);
        await Future<void>.delayed(Duration.zero);

        expect(
          controller.planPersistenceState(conversationId).status,
          PlanPersistenceStatus.failed,
        );
        expect(
          controller.planPersistenceState(conversationId).errorCode,
          'plan_write_failed',
        );
        expect(controller.conversationOf(conversationId).snapshot?.revision, 2);

        expect(await controller.retryPlanPersistence(conversationId), isTrue);
        expect(
          source.savedVersions.map((call) => call.snapshot.revision),
          <int>[2, 2],
        );
        expect(
          source.savedVersions[1].snapshot,
          same(source.savedVersions[0].snapshot),
        );
        expect(
          source.savedVersions[1].conversation,
          same(source.savedVersions[0].conversation),
        );
        expect(
          controller.planPersistenceState(conversationId).status,
          PlanPersistenceStatus.saved,
        );
        expect(
          controller.planPersistenceState(conversationId).errorCode,
          isNull,
        );
      },
    );

    test(
      'failure stale non retrocede stato e non puo essere ritentato',
      () async {
        final source = _ControlledPlanDataSource();
        final controller = _planController(dataSource: source);
        const conversationId = 'c-plan-porto';

        controller.previewToggleLock(
          conversationId: conversationId,
          itemId: 'porto-livraria-lello-stop',
        );
        controller.confirmPlanPatch(conversationId);
        controller.previewToggleLock(
          conversationId: conversationId,
          itemId: 'porto-livraria-lello-stop',
        );
        controller.confirmPlanPatch(conversationId);
        await source.startedCount(1);
        expect(controller.planPersistenceState(conversationId).revision, 3);

        source.failNext('revision_2_failed');
        await source.startedCount(2);
        expect(
          controller.planPersistenceState(conversationId),
          isA<PlanPersistenceState>()
              .having(
                (state) => state.status,
                'status',
                PlanPersistenceStatus.saving,
              )
              .having((state) => state.revision, 'revision', 3)
              .having((state) => state.errorCode, 'errorCode', isNull),
        );
        expect(await controller.retryPlanPersistence(conversationId), isFalse);

        source.completeNext();
        await source.completedCount(2);
        expect(
          controller.planPersistenceState(conversationId),
          isA<PlanPersistenceState>()
              .having(
                (state) => state.status,
                'status',
                PlanPersistenceStatus.saved,
              )
              .having((state) => state.revision, 'revision', 3)
              .having((state) => state.errorCode, 'errorCode', isNull),
        );
      },
    );

    test('completion persistence dopo dispose non muta stato', () async {
      final source = _ControlledPlanDataSource();
      final controller = _planController(dataSource: source);
      const conversationId = 'c-plan-porto';
      controller.previewToggleLock(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
      );
      controller.confirmPlanPatch(conversationId);
      await source.startedCount(1);
      final beforeDispose = controller.planPersistenceState(conversationId);

      controller.dispose();
      source.completeNext();
      await source.completedCount(1);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.planPersistenceState(conversationId),
        same(beforeDispose),
      );
    });

    test('scritture della stessa conversazione restano serializzate', () async {
      final source = _ControlledPlanDataSource();
      final controller = _planController(dataSource: source);
      const conversationId = 'c-plan-porto';

      controller.previewToggleLock(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
      );
      controller.confirmPlanPatch(conversationId);
      controller.previewToggleLock(
        conversationId: conversationId,
        itemId: 'porto-livraria-lello-stop',
      );
      controller.confirmPlanPatch(conversationId);
      await source.startedCount(1);
      expect(source.startedRevisions, <int>[2]);

      source.completeNext();
      await source.startedCount(2);
      expect(source.startedRevisions, <int>[2, 3]);
      source.completeNext();
      await source.completedCount(2);
      expect(controller.planPersistenceState(conversationId).revision, 3);
    });

    test('conversazioni diverse persistono senza bloccarsi fra loro', () async {
      final source = _ControlledPlanDataSource();
      final controller = _planController(dataSource: source);
      controller.previewToggleLock(
        conversationId: 'c-plan-porto',
        itemId: 'porto-livraria-lello-stop',
      );
      controller.confirmPlanPatch('c-plan-porto');
      controller.previewToggleLock(
        conversationId: 'c-plan-roma',
        itemId: 'roma-foro-stop',
      );
      controller.confirmPlanPatch('c-plan-roma');

      await source.startedCount(2);
      expect(source.startedConversationIds.toSet(), <String>{
        'db-c-plan-porto',
        'db-c-plan-roma',
      });
      source.completeAll();
      await source.completedCount(2);
    });

    test('contesto luogo e removibile e si consuma solo al send valido', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';
      final beforePlan = controller.conversationOf(conversationId).snapshot!;
      final beforeMessages = controller
          .threadOf(conversationId)
          .messages
          .length;
      const place = PlanPlaceDetails(
        id: 'porto-livraria-lello',
        title: 'Livraria Lello',
        description: 'Libreria storica',
      );

      controller.setPlaceComposerContext(conversationId, place);
      expect(controller.placeComposerContext(conversationId), same(place));
      expect(
        controller.threadOf(conversationId).messages,
        hasLength(beforeMessages),
      );
      expect(
        controller.conversationOf(conversationId).snapshot,
        same(beforePlan),
      );
      controller.openConversation(conversationId);
      controller.sendText('   ');
      expect(controller.placeComposerContext(conversationId), same(place));
      controller.openConversation('c-plan-roma');
      controller.sendText('Raccontami questo posto');
      expect(controller.placeComposerContext(conversationId), same(place));
      controller.openConversation(conversationId);
      controller.sendText('Perche vale la pena?');
      expect(controller.placeComposerContext(conversationId), isNull);

      controller.setPlaceComposerContext(conversationId, place);
      expect(controller.clearPlaceComposerContext(conversationId), isTrue);
      expect(controller.clearPlaceComposerContext(conversationId), isFalse);
    });

    test('selezioni volo e hotel usano fixture e creano revisioni', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');

      expect(
        controller.selectTravelOption(
          conversationId: conversationId,
          optionId: fixture.flights[2].id,
        ),
        isTrue,
      );
      final flightSnapshot = controller
          .conversationOf(conversationId)
          .snapshot!;
      expect(flightSnapshot.revision, 2);
      expect(flightSnapshot.travelSelection?.option.id, fixture.flights[2].id);
      expect(
        flightSnapshot.travelSelection?.alternatives.map((option) => option.id),
        fixture.flights
            .where((option) => option.id != fixture.flights[2].id)
            .map((option) => option.id),
      );
      expect(
        flightSnapshot.travelSelection?.option.purchaseState,
        PurchaseState.selected,
      );
      expect(flightSnapshot.transport, contains(fixture.flights[2].provider));

      expect(
        controller.selectStayOption(
          conversationId: conversationId,
          optionId: fixture.hotels[1].id,
        ),
        isTrue,
      );
      final staySnapshot = controller.conversationOf(conversationId).snapshot!;
      expect(staySnapshot.revision, 3);
      expect(staySnapshot.staySelection?.option.id, fixture.hotels[1].id);
      expect(
        staySnapshot.staySelection?.alternatives.map((option) => option.id),
        fixture.hotels
            .where((option) => option.id != fixture.hotels[1].id)
            .map((option) => option.id),
      );
      expect(staySnapshot.stay, fixture.hotels[1].name);
      expect(
        controller.selectTravelOption(
          conversationId: conversationId,
          optionId: 'missing',
        ),
        isFalse,
      );
      expect(controller.conversationOf(conversationId).snapshot?.revision, 3);
    });

    test(
      'inventario chat conserva dettagli e tutte le alternative operative',
      () {
        final snapshot = ChatFirstDemoData.operationalFixtureFor(
          'porto',
        ).snapshot;
        final flights = ChatFirstDemoData.flightCompareFor(snapshot);
        final stays = ChatFirstDemoData.stayCompareFor(snapshot);

        expect(flights.options, hasLength(4));
        expect(flights.recommended.id, 'porto-flight-tap-direct');
        expect(flights.options[2].departureAirport, 'FCO');
        expect(flights.options[2].stops, 1);
        expect(flights.options[2].baggage, isNotEmpty);
        expect(flights.quotedAt, DateTime.utc(2026, 8, 11, 9));
        expect(stays.options, hasLength(4));
        expect(stays.recommended.zone, 'Cedofeita');
        expect(stays.options[1].conditions, isNotEmpty);
        expect(stays.options[1].averageWalkMinutes, 13);
      },
    );

    test(
      'proposeStayNightsChange propone notti senza applicare, accept le incorpora',
      () {
        final controller = _planController();
        const conversationId = 'c-plan-porto';
        final before = controller.conversationOf(conversationId).snapshot!;

        expect(
          controller.proposeStayNightsChange(
            conversationId: conversationId,
            nights: 2,
          ),
          isTrue,
        );
        final thread = controller.threadOf(conversationId);
        final proposalMessage = thread.messages.lastWhere(
          (message) => message.kind == ChatMessageKind.planProposal,
        );
        final proposal = proposalMessage.proposal!;
        expect(proposal.changeLabel, isNotEmpty);
        expect(proposal.changeLabel, contains('2 notti'));
        expect(proposal.snapshot.staySelection?.option.priceCents, 96400);
        expect(
          proposal.snapshot.staySelection?.option.purchaseState,
          PurchaseState.selected,
        );
        expect(proposal.snapshot.stay, contains('2 notti'));
        expect(proposal.snapshot.stay, contains('964 €'));
        expect(
          proposal.snapshot.revisionMetadata?.label,
          contains('Date ricalcolate'),
        );
        expect(
          controller.conversationOf(conversationId).snapshot,
          same(before),
        );

        controller.acceptProposal(conversationId, proposalMessage.id);
        final accepted = controller.conversationOf(conversationId).snapshot!;
        expect(accepted.revision, before.revision + 1);
        expect(accepted.staySelection?.option.priceCents, 96400);
        expect(
          accepted.staySelection?.option.id,
          'porto-hotel-torel-avantgarde',
        );
        expect(accepted.stay, contains('2 notti'));
        expect(accepted.revisionMetadata?.label, proposal.changeLabel);
      },
    );

    test('reject di una proposta notti lascia il piano invariato', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';
      final before = controller.conversationOf(conversationId).snapshot!;

      expect(
        controller.proposeStayNightsChange(
          conversationId: conversationId,
          nights: 3,
        ),
        isTrue,
      );
      final thread = controller.threadOf(conversationId);
      final proposalMessage = thread.messages.lastWhere(
        (message) => message.kind == ChatMessageKind.planProposal,
      );
      expect(controller.conversationOf(conversationId).snapshot, same(before));

      controller.rejectProposal(conversationId, proposalMessage.id);
      expect(controller.conversationOf(conversationId).snapshot, same(before));
      expect(controller.conversationOf(conversationId).snapshot?.revision, 1);
      expect(proposalMessage.proposal?.outcome, PlanProposalOutcome.rejected);
    });

    test(
      'proposeStayNightsChange rifiuta notti invalide o destinazioni non operative',
      () {
        final controller = _planController();
        const conversationId = 'c-plan-porto';
        expect(
          controller.proposeStayNightsChange(
            conversationId: conversationId,
            nights: 0,
          ),
          isFalse,
        );
        expect(
          controller.proposeStayNightsChange(
            conversationId: conversationId,
            nights: -2,
          ),
          isFalse,
        );

        final notOperational = ChatFirstPrototypeController(
          seed: <ChatThread>[
            _planThread(
              'c-plan-unknown',
              ChatFirstDemoData.operationalFixtureFor(
                'porto',
              ).snapshot.copyWith(destinationTitle: 'Lisbona'),
            ),
          ],
        );
        expect(
          notOperational.proposeStayNightsChange(
            conversationId: 'c-plan-unknown',
            nights: 2,
          ),
          isFalse,
        );
      },
    );

    test('proposte notti consecutive senza accept generano id univoci', () {
      final controller = _planController();
      const conversationId = 'c-plan-porto';

      expect(
        controller.proposeStayNightsChange(
          conversationId: conversationId,
          nights: 2,
        ),
        isTrue,
      );
      expect(
        controller.proposeStayNightsChange(
          conversationId: conversationId,
          nights: 3,
        ),
        isTrue,
      );

      final proposals = controller
          .threadOf(conversationId)
          .messages
          .where((message) => message.kind == ChatMessageKind.planProposal)
          .toList(growable: false);
      expect(proposals, hasLength(2));
      expect(proposals.first.id, isNot(proposals.last.id));
      // entrambe restano pendenti: la conferma raggiunge la proposta giusta.
      expect(proposals.first.proposal?.outcome, isNull);
      expect(proposals.last.proposal?.outcome, isNull);
      expect(controller.conversationOf(conversationId).snapshot?.revision, 1);
    });

    test('FlightCompare e StayCompare fanno round-trip JSON completo', () {
      final snapshot = ChatFirstDemoData.operationalFixtureFor(
        'porto',
      ).snapshot;
      final flights = ChatFirstDemoData.flightCompareFor(snapshot);
      final stays = ChatFirstDemoData.stayCompareFor(snapshot);

      final flightsBack = FlightCompare.fromJson(flights.toJson());
      expect(flightsBack.options, hasLength(flights.options.length));
      expect(flightsBack.recommendedId, flights.recommendedId);
      expect(flightsBack.quotedAt, flights.quotedAt);
      expect(flightsBack.recommended.id, flights.recommended.id);
      final flight = flightsBack.options[2];
      expect(flight.departureAirport, 'FCO');
      expect(flight.arrivalAirport, 'OPO');
      expect(flight.departureAt, flights.options[2].departureAt);
      expect(flight.durationMinutes, 275);
      expect(flight.stops, 1);
      expect(flight.baggage, isNotEmpty);
      expect(flight.priceCents, 15600);
      expect(flight.tradeoff, isNotEmpty);

      final staysBack = StayCompare.fromJson(stays.toJson());
      expect(staysBack.options, hasLength(stays.options.length));
      expect(staysBack.recommendedId, stays.recommendedId);
      expect(staysBack.recommended.name, 'Torel Avantgarde');
      final hotel = staysBack.options[1];
      expect(hotel.zone, 'Sé');
      expect(hotel.nights, 1);
      expect(hotel.priceCents, 23600);
      expect(hotel.averageWalkMinutes, 13);
      expect(hotel.conditions, isNotEmpty);
      expect(hotel.atmosphere, isNotEmpty);
      expect(hotel.tradeoff, isNotEmpty);
      expect(hotel.provider, isNotEmpty);
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

    test('free talk reflects clues and offers trend metas as explicit choices', () {
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
      // The echo strips destination names; the destination question offers the
      // trend metas as explicit clickable choices instead of naming them.
      expect(ack.text, isNot(contains('Lisbona')));

      final destination = freeTalk.messages.lastWhere(
        (m) => m.id == kFreeTalkDestinationId,
      );
      expect(destination.kind, ChatMessageKind.text);
      expect(destination.choices.map((c) => c.label), containsAll(<String>[
        'Lisbona',
        'Porto',
        'Roma',
        'Consigliami tu',
      ]));
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
      'free talk first reply emits acknowledgement then the destination choice',
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
          containsAllInOrder(<String>[kFreeTalkAckId, kFreeTalkDestinationId]),
        );
        expect(freeTalk.messages.last.id, kFreeTalkDestinationId);
        expect(
          freeTalk.messages.where(
            (message) =>
                message.role == ChatRole.assistant &&
                message.choices.isNotEmpty,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'free talk converges every meta choice on the Porto proposal',
      () {
        final controller = ChatFirstPrototypeController();
        final thread = controller.startFreeTalk();
        controller.openConversation(thread.summary.id);

        controller.sendText('Vorrei quattro giorni lenti e buon cibo.');
        _tapChoice(controller, thread.summary.id, 'Lisbona');
        _answerIntake(controller, thread.summary.id);
        final proposal = controller
            .threadOf(thread.summary.id)
            .messages
            .lastWhere((message) => message.kind == ChatMessageKind.planProposal);
        expect(proposal.proposal?.snapshot.destinationTitle, 'Porto');
        expect(proposal.text, contains('Porto'));
        // F1: the free talk honestly discloses the demo convergence on Porto.
        expect(proposal.text, contains('Per la demo convergo su Porto'));
        expect(proposal.text, contains('volo, hotel e mete sono reali'));
        expect(controller.threadOf(thread.summary.id).summary.title, 'Porto');
      },
    );

    test(
      'free talk "Consigliami tu" also converges on the Porto route',
      () {
        final controller = ChatFirstPrototypeController();
        final thread = controller.startFreeTalk();
        controller.openConversation(thread.summary.id);

        controller.sendText('Vorrei partire senza una meta fissa.');
        _tapChoice(controller, thread.summary.id, 'Consigliami tu');
        _answerIntake(controller, thread.summary.id);
        final proposal = controller
            .threadOf(thread.summary.id)
            .messages
            .lastWhere((message) => message.kind == ChatMessageKind.planProposal);
        expect(proposal.proposal?.snapshot.destinationTitle, 'Porto');
        expect(controller.threadOf(thread.summary.id).summary.title, 'Porto');
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
          failed.messages.where((m) => m.id == kFreeTalkDestinationId),
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
          thread.messages.where((m) => m.id == kFreeTalkDestinationId),
          hasLength(1),
        );
      },
    );

    test('free talk converges the F5 tail on Porto with rich modules', () {
      final controller = ChatFirstPrototypeController();
      final thread = controller.startFreeTalk();
      controller.openConversation(thread.summary.id);
      final freeTalk = controller.threadOf(thread.summary.id) as FreeTalkThread;

      controller.sendText('Vorrei quattro giorni lenti, con buon cibo.');
      _tapChoice(controller, thread.summary.id, 'Roma');
      _answerIntake(controller, thread.summary.id);

      // The proposal always assembles the operational Porto snapshot, so the
      // F5 tail activates FlightCompare/StayCompare for the porto fixture.
      final proposal = freeTalk.messages.lastWhere(
        (message) => message.id == kIntakeProposalId,
      );
      expect(proposal.kind, ChatMessageKind.planProposal);
      expect(proposal.proposal?.snapshot.destinationTitle, 'Porto');
      controller.acceptProposal(thread.summary.id, proposal.id);

      // Six porto curation cards, then the transport beat with rich flights.
      for (var i = 0; i < 6; i++) {
        _tapChoice(controller, thread.summary.id, 'Passa');
      }
      final transport = freeTalk.messages.lastWhere(
        (message) => message.kind == ChatMessageKind.transport,
      );
      expect(transport.flightCompare, isNotNull);
      expect(transport.flightCompare!.options, hasLength(4));
      _tapChoice(controller, thread.summary.id, 'Aereo diretto');

      final stay = freeTalk.messages.lastWhere(
        (message) => message.kind == ChatMessageKind.stayZone,
      );
      expect(stay.stayCompare, isNotNull);
      expect(stay.stayCompare!.options, hasLength(4));
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

    test('la disclosure demo appare solo nella proposta free talk', () {
      final guided = ChatFirstDemoData.intakeThreadFor(
        MockData.journeyById('porto-slow'),
      );
      final guidedProposal = guided.script.firstWhere(
        (beat) => beat.assistant.id == kIntakeProposalId,
      );
      expect(guidedProposal.assistant.text, isNot(contains('Per la demo')));

      final free = ChatFirstDemoData.freeTalkThread(
        ChatFirstDemoData.trendJourneys(),
      );
      final freeProposal = free.script.firstWhere(
        (beat) => beat.assistant.id == kIntakeProposalId,
      );
      expect(freeProposal.assistant.text, contains('Per la demo convergo su Porto'));
    });

    test('free talk fallback: convergenza robusta senza catalogo porto', () {
      final noPorto = ChatFirstDemoData.freeTalkThread(
        <JourneyRoute>[
          MockData.journeyById('atlantic-rail'),
          MockData.journeyById('paris-city'),
        ],
      );
      expect(noPorto.journey?.id, 'atlantic-rail');

      final empty = ChatFirstDemoData.freeTalkThread(const <JourneyRoute>[]);
      expect(empty.journey?.id, 'porto-slow');
    });

    test('startFreeTalk apre un nuovo thread dopo una chat libera conclusa', () {
      final controller = ChatFirstPrototypeController();
      final first = controller.startFreeTalk();
      controller.openConversation(first.summary.id);

      controller.sendText('Vorrei quattro giorni lenti, con buon cibo.');
      _tapChoice(controller, first.summary.id, 'Roma');
      _answerIntake(controller, first.summary.id);
      final proposal = controller
          .threadOf(first.summary.id)
          .messages
          .lastWhere((message) => message.id == kIntakeProposalId);
      controller.acceptProposal(first.summary.id, proposal.id);
      for (var i = 0; i < 6; i++) {
        _tapChoice(controller, first.summary.id, 'Passa');
      }
      _tapChoice(controller, first.summary.id, 'Aereo diretto');
      final stay = controller
          .threadOf(first.summary.id)
          .messages
          .lastWhere((message) => message.kind == ChatMessageKind.stayZone);
      _tapChoice(controller, first.summary.id, stay.stayZone!.name);
      final itinerary = controller
          .threadOf(first.summary.id)
          .messages
          .lastWhere((message) => message.id == kItineraryProposalId);
      controller.acceptProposal(first.summary.id, itinerary.id);

      final completed = controller.threadOf(first.summary.id);
      expect(
        completed.scriptIndex,
        completed.script.length,
        reason: 'la chat libera è conclusa: script consumato',
      );

      final second = controller.startFreeTalk();
      expect(second.summary.id, isNot(kFreeTalkConversationId));
      expect(second.summary.id, startsWith('$kFreeTalkConversationId-'));
      expect(second, isNot(same(first)));

      // Una chat in corso viene invece riaperta: idempotenza di sessione.
      final again = controller.startFreeTalk();
      expect(again.summary.id, second.summary.id);
    });
  });

  group('Acquisti esterni e lifecycle', () {
    const cid = 'c-plan-porto';
    PlanExternalLauncher succeedingLauncher() => PlanExternalLauncher(
      launchExternal: (_) async => true,
      launchBrowser: (_) async => false,
    );

    test(
      'openExternalPurchase registra il ritorno prima del launch e marca acquisto aperto',
      () async {
        final controller = _planController();
        addTearDown(controller.dispose);
        final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
        final flight = fixture.flights[0];
        expect(
          controller.selectTravelOption(
            conversationId: cid,
            optionId: flight.id,
          ),
          isTrue,
        );
        final revisionBefore = controller.conversationOf(cid).snapshot!.revision;

        final launchStarted = Completer<void>();
        final launchResult = Completer<bool>();
        final launcher = PlanExternalLauncher(
          launchExternal: (_) {
            launchStarted.complete();
            return launchResult.future;
          },
          launchBrowser: (_) async => false,
        );
        final opening = controller.openExternalPurchase(
          conversationId: cid,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
          uri: flight.providerUrl,
          launcher: launcher,
        );
        // While the launch is still in flight the expected return is already
        // registered, but the selection is NOT marked "purchase opened" yet.
        await launchStarted.future;
        expect(controller.hasExpectedPurchaseReturn(cid), isTrue);
        expect(
          controller
              .conversationOf(cid)
              .snapshot!
              .travelSelection!
              .option
              .purchaseState,
          PurchaseState.selected,
        );
        launchResult.complete(true);
        expect(await opening, isTrue);
        final snapshot = controller.conversationOf(cid).snapshot!;
        expect(
          snapshot.travelSelection!.option.purchaseState,
          PurchaseState.purchaseOpened,
        );
        expect(snapshot.revision, revisionBefore + 1);
        expect(snapshot.revisionMetadata?.label, 'Acquisto avviato');
        // The prompt stays pending until the app resumes.
        expect(controller.pendingPurchasePrompts, isEmpty);
      },
    );

    test('launch fallito non marca acquisto aperto e pulisce il ritorno', () async {
      final controller = _planController();
      addTearDown(controller.dispose);
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final flight = fixture.flights[0];
      controller.selectTravelOption(
        conversationId: cid,
        optionId: flight.id,
      );
      final revisionBefore = controller.conversationOf(cid).snapshot!.revision;
      final failing = PlanExternalLauncher(
        launchExternal: (_) async => false,
        launchBrowser: (_) async => false,
      );

      final opened = await controller.openExternalPurchase(
        conversationId: cid,
        kind: ExternalPurchaseKind.travel,
        optionId: flight.id,
        uri: flight.providerUrl,
        launcher: failing,
      );
      expect(opened, isFalse);
      final snapshot = controller.conversationOf(cid).snapshot!;
      expect(
        snapshot.travelSelection!.option.purchaseState,
        PurchaseState.selected,
      );
      expect(snapshot.revision, revisionBefore);
      expect(controller.hasExpectedPurchaseReturn(cid), isFalse);
      expect(controller.pendingPurchasePrompts, isEmpty);
      controller.handleAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.pendingPurchasePrompts, isEmpty);
    });

    test('resume atteso mostra il prompt una volta sola e lo consuma', () async {
      final controller = _planController();
      addTearDown(controller.dispose);
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final flight = fixture.flights[0];
      controller.selectTravelOption(
        conversationId: cid,
        optionId: flight.id,
      );
      expect(
        await controller.openExternalPurchase(
          conversationId: cid,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
          uri: flight.providerUrl,
          launcher: succeedingLauncher(),
        ),
        isTrue,
      );
      expect(controller.pendingPurchasePrompts, isEmpty);

      controller.handleAppLifecycleState(AppLifecycleState.resumed);
      var pending = controller.pendingPurchasePrompts;
      expect(pending, hasLength(1));
      expect(pending.single.conversationId, cid);
      expect(pending.single.kind, ExternalPurchaseKind.travel);
      expect(pending.single.optionId, flight.id);

      expect(controller.consumePurchasePrompt(cid), isTrue);
      expect(controller.pendingPurchasePrompts, isEmpty);
      // A second resume does not re-show the consumed prompt.
      controller.handleAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.pendingPurchasePrompts, isEmpty);
    });

    test('resume normale o cold start non genera prompt', () async {
      final controller = _planController();
      addTearDown(controller.dispose);
      expect(controller.pendingPurchasePrompts, isEmpty);
      controller.handleAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.pendingPurchasePrompts, isEmpty);

      final coldStart = ChatFirstPrototypeController();
      addTearDown(coldStart.dispose);
      expect(coldStart.pendingPurchasePrompts, isEmpty);
      coldStart.handleAppLifecycleState(AppLifecycleState.resumed);
      expect(coldStart.pendingPurchasePrompts, isEmpty);
    });

    test(
      'confirmExternalPurchase aggiorna solo provider, opzione, prezzo, timestamp e stato',
      () async {
        final controller = _planController();
        addTearDown(controller.dispose);
        final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
        final flight = fixture.flights[0];
        controller.selectTravelOption(
          conversationId: cid,
          optionId: flight.id,
        );
        await controller.openExternalPurchase(
          conversationId: cid,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
          uri: flight.providerUrl,
          launcher: succeedingLauncher(),
        );
        final opened = controller.conversationOf(cid).snapshot!;
        final openedOption = opened.travelSelection!.option;
        final openedAlternatives = opened.travelSelection!.alternatives;
        final openedRevision = opened.revision;

        controller.confirmExternalPurchase(
          conversationId: cid,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
        );
        final confirmed = controller.conversationOf(cid).snapshot!;
        final option = confirmed.travelSelection!.option;
        expect(option.purchaseState, PurchaseState.purchased);
        expect(option.id, openedOption.id);
        expect(option.label, openedOption.label);
        expect(option.priceCents, openedOption.priceCents);
        expect(
          confirmed.travelSelection!.alternatives.map((item) => item.id),
          openedAlternatives.map((item) => item.id),
        );
        expect(confirmed.revision, openedRevision + 1);
        expect(confirmed.revisionMetadata?.label, 'Acquisto confermato');
        expect(
          confirmed.revisionMetadata!.timestamp.isAfter(
            opened.revisionMetadata!.timestamp,
          ),
          isTrue,
        );
        // Nothing else in the plan changed.
        expect(
          confirmed.days.map((day) => day.toJson()).toList(),
          opened.days.map((day) => day.toJson()).toList(),
        );
        expect(confirmed.staySelection?.toJson(), opened.staySelection?.toJson());
        expect(confirmed.transport, opened.transport);
        expect(confirmed.stay, opened.stay);
        // The settled purchase no longer lingers as a prompt.
        expect(controller.pendingPurchasePrompts, isEmpty);
        expect(controller.hasExpectedPurchaseReturn(cid), isFalse);
      },
    );

    test('dismissExternalPurchasePrompt ripristina selezionato', () async {
      final controller = _planController();
      addTearDown(controller.dispose);
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final flight = fixture.flights[0];
      controller.selectTravelOption(
        conversationId: cid,
        optionId: flight.id,
      );
      await controller.openExternalPurchase(
        conversationId: cid,
        kind: ExternalPurchaseKind.travel,
        optionId: flight.id,
        uri: flight.providerUrl,
        launcher: succeedingLauncher(),
      );
      expect(
        controller.conversationOf(cid).snapshot!.travelSelection!.option
            .purchaseState,
        PurchaseState.purchaseOpened,
      );

      controller.dismissExternalPurchasePrompt(
        conversationId: cid,
        kind: ExternalPurchaseKind.travel,
        optionId: flight.id,
      );
      final snapshot = controller.conversationOf(cid).snapshot!;
      expect(
        snapshot.travelSelection!.option.purchaseState,
        PurchaseState.selected,
      );
      expect(
        snapshot.travelSelection!.option.purchaseState,
        isNot(PurchaseState.purchased),
      );
      expect(snapshot.revisionMetadata?.label, 'Acquisto non confermato');
      expect(controller.pendingPurchasePrompts, isEmpty);

      // A dismissal for a selection that never existed leaves the plan intact.
      final before = controller.conversationOf(cid).snapshot!.revision;
      controller.dismissExternalPurchasePrompt(
        conversationId: cid,
        kind: ExternalPurchaseKind.stay,
        optionId: 'missing',
      );
      expect(controller.conversationOf(cid).snapshot!.revision, before);
    });

    test('process death lascia acquisto aperto e nessun prompt', () async {
      final source = _RestoringPlanDataSource();
      final controllerA = _planController(dataSource: source);
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final flight = fixture.flights[0];
      controllerA.selectTravelOption(
        conversationId: cid,
        optionId: flight.id,
      );
      await source.savedCount(1);
      expect(
        await controllerA.openExternalPurchase(
          conversationId: cid,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
          uri: flight.providerUrl,
          launcher: succeedingLauncher(),
        ),
        isTrue,
      );
      await source.savedCount(2);
      expect(
        controllerA.conversationOf(cid).snapshot!.travelSelection!.option
            .purchaseState,
        PurchaseState.purchaseOpened,
      );
      controllerA.dispose();

      // New controller instance on the same persisted conversation: the
      // purchaseOpened selection survives, the session prompt state does not.
      final controllerB = ChatFirstPrototypeController(dataSource: source);
      addTearDown(controllerB.dispose);
      await controllerB.restoreConversations();
      expect(
        controllerB.conversationOf(cid).snapshot!.travelSelection!.option
            .purchaseState,
        PurchaseState.purchaseOpened,
      );
      expect(controllerB.pendingPurchasePrompts, isEmpty);
      controllerB.handleAppLifecycleState(AppLifecycleState.resumed);
      expect(controllerB.pendingPurchasePrompts, isEmpty);
    });
  });
}

ChatFirstPrototypeController _planController({IterDataSource? dataSource}) {
  final porto = ChatFirstDemoData.operationalFixtureFor('porto');
  final roma = ChatFirstDemoData.operationalFixtureFor('roma');
  return ChatFirstPrototypeController(
    dataSource: dataSource,
    seed: <ChatThread>[
      _planThread('c-plan-porto', porto.snapshot),
      _planThread('c-plan-roma', roma.snapshot),
    ],
  );
}

ChatThread _planThread(String id, TripSnapshot snapshot) => ChatThread(
  summary: Conversation(
    id: id,
    title: snapshot.destinationTitle,
    subtitle: 'Piano operativo',
    avatar: ChatAvatar('fixture.jpg', label: snapshot.destinationTitle),
    timestamp: DateTime(2026, 8, 11, 12),
    lastPreview: 'Piano pronto',
    snapshot: snapshot,
  ),
  script: <ScriptedBeat>[],
);

/// Records `saveTripVersion` calls so tests can assert what the controller
/// persists after a proposal decision without touching a real database.
class _TripSpyDataSource extends MockDataSource {
  final List<
    ({String conversationId, Conversation conversation, TripSnapshot snapshot})
  >
  savedVersions =
      <
        ({
          String conversationId,
          Conversation conversation,
          TripSnapshot snapshot,
        })
      >[];

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'conv-1',
        conversation: summary,
        updatedAt: DateTime(2026, 10, 16, 10, 30),
      );

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async {
    savedVersions.add((
      conversationId: conversationId,
      conversation: conversation,
      snapshot: snapshot,
    ));
    return const PlanSaveResult.success();
  }
}

class _PlanRecordingDataSource extends MockDataSource {
  final List<
    ({String conversationId, Conversation conversation, TripSnapshot snapshot})
  >
  savedVersions =
      <
        ({
          String conversationId,
          Conversation conversation,
          TripSnapshot snapshot,
        })
      >[];

  final StreamController<int> _saveCounts = StreamController<int>.broadcast();

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'db-${summary.id}',
        conversation: summary,
        updatedAt: DateTime(2026, 8, 11, 12),
      );

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async {
    savedVersions.add((
      conversationId: conversationId,
      conversation: conversation,
      snapshot: snapshot,
    ));
    _saveCounts.add(savedVersions.length);
    return const PlanSaveResult.success();
  }

  Future<void> savedCount(int count) async {
    if (savedVersions.length >= count) return;
    await _saveCounts.stream.firstWhere((current) => current >= count);
  }
}

class _RestoringPlanDataSource extends _PlanRecordingDataSource {
  @override
  Future<List<ConversationRow>> fetchConversations() async {
    if (savedVersions.isEmpty) return const <ConversationRow>[];
    final latest = savedVersions.last;
    return <ConversationRow>[
      ConversationRow(
        id: latest.conversationId,
        conversation: Conversation.fromJson(latest.conversation.toJson()),
        updatedAt: DateTime(2026, 8, 11, 12, 30),
      ),
    ];
  }
}

class _RetryingPlanDataSource extends _PlanRecordingDataSource {
  final List<int> _attempt = <int>[0];

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async {
    savedVersions.add((
      conversationId: conversationId,
      conversation: conversation,
      snapshot: snapshot,
    ));
    _saveCounts.add(savedVersions.length);
    _attempt[0]++;
    return _attempt.single == 1
        ? const PlanSaveResult.failure('plan_write_failed')
        : const PlanSaveResult.success();
  }
}

class _ControlledPlanDataSource extends MockDataSource {
  final List<int> startedRevisions = <int>[];
  final List<String> startedConversationIds = <String>[];
  final List<Completer<PlanSaveResult>> _pending =
      <Completer<PlanSaveResult>>[];
  final StreamController<int> _started = StreamController<int>.broadcast();
  final StreamController<int> _completed = StreamController<int>.broadcast();
  final List<int> _completedCount = <int>[0];

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async =>
      ConversationRow(
        id: 'db-${summary.id}',
        conversation: summary,
        updatedAt: DateTime(2026, 8, 11, 12),
      );

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) {
    startedRevisions.add(snapshot.revision);
    startedConversationIds.add(conversationId);
    final completer = Completer<PlanSaveResult>();
    _pending.add(completer);
    _started.add(startedRevisions.length);
    return completer.future.whenComplete(() {
      _completedCount[0]++;
      _completed.add(_completedCount.single);
    });
  }

  Future<void> startedCount(int count) async {
    if (startedRevisions.length >= count) return;
    await _started.stream.firstWhere((current) => current >= count);
  }

  Future<void> completedCount(int count) async {
    if (_completedCount.single >= count) return;
    await _completed.stream.firstWhere((current) => current >= count);
  }

  void completeNext() {
    final completer = _pending.firstWhere(
      (candidate) => !candidate.isCompleted,
    );
    completer.complete(const PlanSaveResult.success());
  }

  void failNext(String errorCode) {
    final completer = _pending.firstWhere(
      (candidate) => !candidate.isCompleted,
    );
    completer.complete(PlanSaveResult.failure(errorCode));
  }

  void completeAll() {
    for (final completer in _pending.where(
      (candidate) => !candidate.isCompleted,
    )) {
      completer.complete(const PlanSaveResult.success());
    }
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
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async => const PlanSaveResult.failure('persistence_unavailable');
}

String _saveTripRevisionContract(String normalizedSql) {
  const startMarker = 'create or replace function public.save_trip_revision(';
  const endMarker = ') to authenticated;';
  final start = normalizedSql.indexOf(startMarker);
  final end = normalizedSql.indexOf(endMarker, start);
  return normalizedSql.substring(start, end + endMarker.length);
}

void _expectTripVersionLeastPrivilege(String source, String sql) {
  final normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  const revoke =
      'revoke all privileges on table public.trip_versions '
      'from anon, authenticated;';
  const grant =
      'grant select, insert on table public.trip_versions to authenticated;';
  const permanentUser =
      "(select (auth.jwt()->>'is_anonymous')::boolean) is false";

  expect(
    normalized,
    contains(revoke),
    reason: '$source revoca i default grant',
  );
  expect(
    normalized,
    contains(grant),
    reason: '$source ripristina SELECT/INSERT',
  );
  expect(
    normalized.indexOf(revoke),
    lessThan(normalized.indexOf(grant)),
    reason: '$source revoca prima del grant minimo',
  );
  expect(
    RegExp(RegExp.escape(permanentUser)).allMatches(normalized),
    hasLength(2),
    reason: '$source protegge entrambe le policy dagli utenti anonimi',
  );
  expect(
    RegExp(r'grant [^;]* on table public\.trip_versions [^;]*;')
        .allMatches(normalized)
        .map((match) => match.group(0))
        .toList(growable: false),
    <String?>[grant],
    reason: '$source mantiene un solo grant minimo',
  );
  expect(
    RegExp(
      r'revoke [^;]* on table public\.trip_versions [^;]*service_role',
    ).hasMatch(normalized),
    isFalse,
    reason: '$source non revoca service_role',
  );
}

class _TripVersionPostgrestServer {
  _TripVersionPostgrestServer._(this._server, {required this.failRequests}) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  final bool failRequests;
  final List<({String method, String path, Map<String, dynamic> body})>
  requests = <({String method, String path, Map<String, dynamic> body})>[];

  String get url => 'http://${_server.address.address}:${_server.port}';

  static Future<_TripVersionPostgrestServer> start({
    bool failRequests = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _TripVersionPostgrestServer._(server, failRequests: failRequests);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final bodyText = await utf8.decoder.bind(request).join();
    final body = bodyText.isEmpty
        ? const <String, dynamic>{}
        : (jsonDecode(bodyText) as Map).cast<String, dynamic>();
    requests.add((method: request.method, path: request.uri.path, body: body));

    if (failRequests) {
      await _json(request, HttpStatus.internalServerError, <String, dynamic>{
        'code': 'XX000',
        'message': 'persistence unavailable',
        'details': null,
        'hint': null,
      });
      return;
    }

    if (request.method == 'POST' &&
        request.uri.path == '/rest/v1/rpc/save_trip_revision') {
      await _json(request, HttpStatus.ok, true);
      return;
    }

    await _json(request, HttpStatus.notFound, <String, dynamic>{
      'code': 'PGRST205',
      'message': 'unexpected test request',
      'details': '${request.method} ${request.uri}',
      'hint': null,
    });
  }

  Future<void> _json(HttpRequest request, int status, Object body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
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
