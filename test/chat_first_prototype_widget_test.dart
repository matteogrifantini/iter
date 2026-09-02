import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';
import 'package:iter/data/mock_data.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_app.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_list_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/chat_first_profile_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_shell.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/iter_ui_primitives.dart';
import 'package:iter/features/chat_first_prototype/plan_external_launcher.dart';
import 'package:iter/features/chat_first_prototype/profile_models.dart';
import 'package:iter/features/chat_first_prototype/rotta_viva_mark.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';
import 'package:iter/models/trip_models.dart' show JourneyRoute;

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(body: child),
    );
  }

  Widget wrapIter(Widget child) {
    return MaterialApp(
      theme: IterTheme.light(),
      home: Scaffold(body: child),
    );
  }

  Future<void> tapLast(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('home vuota espone manifesto e segnali senza catalogo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final submitted = <String>[];
    String? selectedPhoto;
    await tester.pumpWidget(
      wrap(
        ChatFirstHomeScreen(
          model: const AdaptiveHomeModel.empty(),
          onSubmitIntent: submitted.add,
          onVoiceIntent: () {},
          onPhotoIntent: (path) => selectedPhoto = path,
          onOpenThread: (_) {},
          onOpenTrips: () {},
          unread: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Composer per raccontare il viaggio'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.bySemanticsLabel('Composer per raccontare il viaggio'),
      findsOneWidget,
    );
    expect(find.text('Dove vorresti andare?'), findsOneWidget);
    semantics.dispose();
    expect(find.byType(ListView), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('🌊 Mare e pause'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('🌊 Mare e pause'));
    await tester.pump();
    expect(submitted, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mare e pause',
    );

    await tester.scrollUntilVisible(
      find.byTooltip('Invia il desiderio'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pump();
    expect(submitted, <String>['Mare e pause']);

    await tester.scrollUntilVisible(
      find.byTooltip('Aggiungi una foto'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Aggiungi una foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finestrino sul mare'));
    await tester.pumpAndSettle();
    expect(selectedPhoto, 'assets/images/travel/rail_window.jpg');
  });

  testWidgets('home non duplica il percorso Viaggi nella barra superiore', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: const AdaptiveHomeModel.empty(),
          unread: 2,
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Viaggi'), findsNothing);
  });

  testWidgets('home vuota conserva il testo se l handoff sincrono fallisce', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: const AdaptiveHomeModel.empty(),
          unread: 0,
          onSubmitIntent: (_) => throw StateError('demo failure'),
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(TextField),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Vorrei rallentare');
    await tester.scrollUntilVisible(
      find.byTooltip('Invia il desiderio'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Vorrei rallentare',
    );
  });

  testWidgets('home conserva input e segnali, espone retry dopo errore async', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: const AdaptiveHomeModel.empty(),
          unread: 0,
          onSubmitIntent: (_) async {
            attempts++;
            if (attempts == 1) throw StateError('offline');
          },
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('🌊 Mare e pause'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('🌊 Mare e pause'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byTooltip('Invia il desiderio'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pumpAndSettle();

    expect(
      find.text('Non riesco a iniziare il viaggio. Riprova.'),
      findsOneWidget,
    );
    expect(find.text('Riprova'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mare e pause',
    );
    await tester.scrollUntilVisible(
      find.text('Riprova'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('lista chat mostra conversazioni e badge non letti', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    String? opened;
    await tester.pumpWidget(
      wrap(
        ChatFirstListScreen(
          controller: controller,
          onOpenThread: (thread) => opened = thread.summary.id,
        ),
      ),
    );

    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('Porto'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Roma'));
    await tester.pump();
    expect(opened, isNotNull);
    expect(controller.unread, 0);
  });

  testWidgets('FAB e empty state avviano la chat libera senza popup scelta', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    String? opened;
    await tester.pumpWidget(
      wrap(
        ChatFirstListScreen(
          controller: controller,
          onOpenThread: (thread) => opened = thread.summary.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Nuova chat'), findsOneWidget);
    await tester.tap(find.byTooltip('Nuova chat'));
    await tester.pumpAndSettle();
    expect(opened, kFreeTalkConversationId);
    expect(find.text('Con chi vuoi parlare?'), findsNothing);
    expect(controller.threadOf(kFreeTalkConversationId), isA<FreeTalkThread>());
  });

  testWidgets('Nuova chat dopo una libera conclusa apre un nuovo thread', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    String? opened;

    // Una chat libera gia conclusa (script consumato) nel controller di partenza.
    final concluded = controller.startFreeTalk();
    final concludedThread =
        controller.threadOf(concluded.summary.id) as FreeTalkThread;
    concludedThread.scriptIndex = concludedThread.script.length;
    await tester.pumpWidget(
      wrap(
        ChatFirstListScreen(
          controller: controller,
          onOpenThread: (thread) => opened = thread.summary.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuova chat'));
    await tester.pumpAndSettle();

    expect(opened, isNot(kFreeTalkConversationId));
    expect(opened, startsWith('$kFreeTalkConversationId-'));
    expect(controller.threadOf(opened!), isA<FreeTalkThread>());
    // La conclusa resta al suo posto, la nuova e separata e puo rifare la demo.
    expect(controller.threadOf(kFreeTalkConversationId), same(concludedThread));
  });

  testWidgets('thread mostra bolle, scelte e avanza su tap', (tester) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: roma.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rallenta la mattina'), findsOneWidget);
    final before = controller.threadOf(roma.summary.id).messages.length;
    await tester.tap(find.text('Rallenta la mattina'));
    await tester.pumpAndSettle();
    expect(controller.threadOf(roma.summary.id).messages.length, before + 2);
  });

  testWidgets('proposta di piano: Accetta applica, Annulla mantiene', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: roma.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rallenta la mattina'));
    await tester.pumpAndSettle();
    expect(find.text('Accetta'), findsOneWidget);
    expect(find.text('Annulla'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(
      controller
          .threadOf(roma.summary.id)
          .summary
          .snapshot
          ?.days
          .first
          .items
          .first
          .time,
      '09:30',
    );
    expect(find.text('Modifica annullata'), findsOneWidget);
    expect(find.text('Accetta'), findsNothing);
  });

  testWidgets('proposta accettata aggiorna il piano della conversazione', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: roma.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rallenta la mattina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accetta'));
    await tester.pumpAndSettle();

    final updated = controller.threadOf(roma.summary.id).summary.snapshot!;
    expect(updated.days.first.items.first.time, '10:30');
    expect(find.text('Modifica applicata'), findsOneWidget);
    expect(find.text('Annulla'), findsNothing);
  });

  testWidgets(
    'proposta chat mostra solo la modifica e apre il piano completo',
    (tester) async {
      final controller = ChatFirstPrototypeController();
      addTearDown(controller.dispose);
      final roma = controller.threads.firstWhere(
        (t) => t.summary.title.contains('Roma'),
      );
      TripSnapshot? openedSnapshot;
      await tester.pumpWidget(
        wrap(
          ChatFirstThreadScreen(
            controller: controller,
            conversationId: roma.summary.id,
            onOpenSnapshot: (snapshot) => openedSnapshot = snapshot,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rallenta la mattina'));
      await tester.pumpAndSettle();

      expect(
        find.text('Foro Romano alle 10:30, passeggiata ai Fori alle 14:00.'),
        findsOneWidget,
      );
      expect(find.text('2 giorni · In viaggio'), findsNothing);
      expect(find.byKey(const Key('chat-proposal-open-plan')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-proposal-open-plan')));
      expect(openedSnapshot?.destinationTitle, 'Roma');
    },
  );

  testWidgets('intake: domande, proposta e accettazione nel thread', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: thread.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('quanti giorni'), findsOneWidget);

    const labels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    for (final label in labels) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(find.text('Accetta'), findsOneWidget);
    await tester.tap(find.text('Accetta'));
    await tester.pumpAndSettle();

    final snapshot = controller.threadOf(thread.summary.id).summary.snapshot!;
    expect(snapshot.destinationTitle, journey.stops.first);
    expect(snapshot.durationLabel, '4–5 giorni');
    expect(snapshot.days, isNotEmpty);
    expect(
      controller
          .threadOf(thread.summary.id)
          .messages
          .lastWhere((m) => m.kind == ChatMessageKind.planProposal)
          .proposal!
          .outcome,
      PlanProposalOutcome.accepted,
    );
    expect(
      controller.threadOf(thread.summary.id).messages.last.kind,
      ChatMessageKind.placeCard,
    );
  });

  testWidgets('curation F5: card luogo con scelte Passa/Salva/Irrinunciabile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: thread.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    const intakeLabels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    for (final label in intakeLabels) {
      await tapLast(tester, label);
    }
    await tapLast(tester, 'Accetta');

    final place = thread.messages
        .lastWhere((m) => m.kind == ChatMessageKind.placeCard)
        .placeCard!;
    expect(find.text(place.name), findsWidgets);
    expect(find.text('Passa'), findsWidgets);
    expect(find.text('Salva'), findsWidgets);
    expect(find.text('Irrinunciabile'), findsWidgets);
    expect(find.textContaining('Mappa demo'), findsNothing);
  });

  testWidgets('flusso F5 completo: curation, trasporto, zona e itinerario', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    final id = thread.summary.id;
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    const intakeLabels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    for (final label in intakeLabels) {
      await tapLast(tester, label);
    }
    await tapLast(tester, 'Accetta');

    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Irrinunciabile');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Aereo diretto');

    final zoneName = controller
        .threadOf(id)
        .messages
        .lastWhere((m) => m.kind == ChatMessageKind.stayZone)
        .stayZone!
        .name;
    expect(find.textContaining('Mappa demo'), findsOneWidget);
    await tapLast(tester, zoneName);

    await tapLast(tester, 'Accetta');

    final snapshot = controller.threadOf(id).summary.snapshot!;
    expect(snapshot.transport, 'Aereo diretto · 1h 30m');
    expect(snapshot.stay, zoneName);
    expect(snapshot.days.last.items.last.title, 'Passeggiata finale');
    expect(find.text('Modifica applicata'), findsWidgets);
  });

  testWidgets('moduli rich volo e hotel compaiono in una meta operativa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    // porto-slow gia esiste come thread di pianificazione seed: costruiamo un
    // journey guidato con id diverso per attraversare il flusso intake/F5.
    final seeded = MockData.journeyById('porto-slow');
    final journey = JourneyRoute(
      id: 'porto-guided',
      title: seeded.title,
      summary: seeded.summary,
      durationLabel: seeded.durationLabel,
      stops: const <String>['Porto'],
      destinationIds: const <String>['porto'],
      whyItFits: seeded.whyItFits,
      season: seeded.season,
      travelMode: seeded.travelMode,
      videoAssets: seeded.videoAssets,
      matchScore: seeded.matchScore,
    );
    final thread = controller.startFromJourney(journey);
    final id = thread.summary.id;
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    const intakeLabels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    for (final label in intakeLabels) {
      await tapLast(tester, label);
    }
    await tapLast(tester, 'Accetta');

    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Irrinunciabile');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');

    final transport = controller
        .threadOf(id)
        .messages
        .lastWhere((message) => message.kind == ChatMessageKind.transport);
    expect(transport.flightCompare, isNotNull);
    expect(transport.flightCompare!.options, hasLength(4));
    expect(find.text('Consigliato'), findsOneWidget);
    expect(find.text('TAP Air Portugal'), findsNWidgets(3));
    expect(find.text('189 €'), findsNWidgets(2));
    expect(find.text('Giorno migliore del piano'), findsOneWidget);
    expect(find.text('Sabato 17 ottobre 2026'), findsOneWidget);
    expect(find.text('Confronto rapido'), findsOneWidget);
    expect(find.text('Orari'), findsOneWidget);
    expect(find.text('Scali'), findsOneWidget);
    expect(
      find.textContaining('4 alternative · da 119 € a 189 €'),
      findsOneWidget,
    );
    expect(find.text('Perché questa scelta'), findsOneWidget);
    expect(find.textContaining('FCO→OPO'), findsNWidgets(4));
    expect(find.textContaining('07:15'), findsNWidgets(2));
    expect(find.textContaining('3h 05m'), findsNWidgets(4));
    expect(find.textContaining('Diretto'), findsNWidgets(7));
    expect(find.text('Bagaglio a mano 10 kg'), findsNWidgets(3));
    expect(
      find.text('Diretto e comodo, ma non il più economico.'),
      findsOneWidget,
    );
    expect(find.textContaining('scalo'), findsNWidgets(5));
    expect(find.textContaining('quotazione 11/08/2026'), findsWidgets);

    await tester.tap(find.text('Scegli').first);
    await tester.pumpAndSettle();
    var snapshot = controller.threadOf(id).summary.snapshot!;
    expect(snapshot.travelSelection?.option.id, 'porto-flight-tap-direct');
    expect(snapshot.revision, 3);

    await tapLast(tester, 'Aereo diretto');

    final stay = controller
        .threadOf(id)
        .messages
        .lastWhere((message) => message.kind == ChatMessageKind.stayZone);
    expect(stay.stayCompare, isNotNull);
    expect(stay.stayCompare!.options, hasLength(4));
    expect(find.text('Torel Avantgarde'), findsNWidgets(3));
    expect(find.text('Cedofeita · 1 notte'), findsOneWidget);
    expect(find.text('Date del soggiorno'), findsOneWidget);
    expect(find.text('17–18 ottobre 2026 · 1 notte'), findsOneWidget);
    expect(find.text('Confronto rapido'), findsNWidgets(2));
    expect(find.text('Zona'), findsOneWidget);
    expect(find.text('Distanza'), findsOneWidget);
    expect(
      find.textContaining('4 strutture · da 236 € a 482 €'),
      findsOneWidget,
    );
    expect(find.text('Perché questa scelta'), findsNWidgets(2));

    final proposalsBefore = controller
        .threadOf(id)
        .messages
        .where((message) => message.kind == ChatMessageKind.planProposal)
        .length;
    await tester.tap(find.byTooltip('Aggiungi notti'));
    await tester.pumpAndSettle();
    final proposals = controller
        .threadOf(id)
        .messages
        .where((message) => message.kind == ChatMessageKind.planProposal)
        .toList(growable: false);
    expect(proposals.length, proposalsBefore + 1);
    expect(proposals.last.proposal?.changeLabel, contains('2 notti'));
    expect(
      proposals.last.proposal?.snapshot.staySelection?.option.priceCents,
      96400,
    );
  });

  testWidgets(
    'free talk convergente su Porto completa la coda F5 con moduli rich',
    (tester) async {
      tester.view.physicalSize = const Size(800, 9000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = ChatFirstPrototypeController();
      final thread = controller.startFreeTalk();
      final id = thread.summary.id;
      await tester.pumpWidget(
        wrap(
          ChatFirstThreadScreen(
            controller: controller,
            conversationId: id,
            onOpenSnapshot: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Vorrei quattro giorni lenti, con buon cibo.',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Invia'));
      await tester.pumpAndSettle();
      // Destination question offers the trend metas; pick Porto so the rich
      // flight and hotel fixture is available for this focused test.
      await tapLast(tester, 'Porto');

      const intakeLabels = <String>[
        '4–5 giorni, senza fretta',
        'Bilanciato: cultura e pause',
        'Centro, per spostarmi a piedi',
        'Treno o metro + passi',
        'Moderato: qualche tavola bella',
      ];
      for (final label in intakeLabels) {
        await tapLast(tester, label);
      }
      await tapLast(tester, 'Accetta');

      // Porto curation cards, then the transport beat with rich flights.
      await tapLast(tester, 'Salva');
      await tapLast(tester, 'Salva');
      await tapLast(tester, 'Irrinunciabile');
      await tapLast(tester, 'Passa');
      await tapLast(tester, 'Passa');
      await tapLast(tester, 'Passa');

      final transport = controller
          .threadOf(id)
          .messages
          .lastWhere((message) => message.kind == ChatMessageKind.transport);
      expect(transport.flightCompare, isNotNull);
      expect(transport.flightCompare!.options, hasLength(4));
      expect(find.text('TAP Air Portugal'), findsNWidgets(3));
      expect(find.textContaining('FCO→OPO'), findsNWidgets(4));
    },
  );

  testWidgets(
    'moduli rich: totale stepper e proposta allineati sull hotel selezionato',
    (tester) async {
      tester.view.physicalSize = const Size(800, 11000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = ChatFirstPrototypeController();
      final seeded = MockData.journeyById('porto-slow');
      final journey = JourneyRoute(
        id: 'porto-guided-2',
        title: seeded.title,
        summary: seeded.summary,
        durationLabel: seeded.durationLabel,
        stops: const <String>['Porto'],
        destinationIds: const <String>['porto'],
        whyItFits: seeded.whyItFits,
        season: seeded.season,
        travelMode: seeded.travelMode,
        videoAssets: seeded.videoAssets,
        matchScore: seeded.matchScore,
      );
      final thread = controller.startFromJourney(journey);
      final id = thread.summary.id;
      await tester.pumpWidget(
        wrap(
          ChatFirstThreadScreen(
            controller: controller,
            conversationId: id,
            onOpenSnapshot: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      const intakeLabels = <String>[
        '4–5 giorni, senza fretta',
        'Bilanciato: cultura e pause',
        'Centro, per spostarmi a piedi',
        'Treno o metro + passi',
        'Moderato: qualche tavola bella',
      ];
      for (final label in intakeLabels) {
        await tapLast(tester, label);
      }
      await tapLast(tester, 'Accetta');
      await tapLast(tester, 'Salva');
      await tapLast(tester, 'Salva');
      await tapLast(tester, 'Irrinunciabile');
      await tapLast(tester, 'Passa');
      await tapLast(tester, 'Passa');
      await tapLast(tester, 'Passa');
      await tapLast(tester, 'Aereo diretto');

      expect(find.text('1 notte · 482 €'), findsOneWidget);

      final moovButton = find.descendant(
        of: find.byKey(
          const ValueKey<String>('stay-option-porto-hotel-moov-centro'),
        ),
        matching: find.bySubtype<FilledButton>(),
      );
      expect(moovButton, findsOneWidget);
      await tester.tap(moovButton);
      await tester.pumpAndSettle();

      final snapshot = controller.threadOf(id).summary.snapshot!;
      expect(snapshot.staySelection?.option.id, 'porto-hotel-moov-centro');
      // L'header passa alla tariffa dell'hotel selezionato (236 €/notte).
      expect(find.text('1 notte · 236 €'), findsOneWidget);
      // Il bottone Scegli dell'opzione scelta si disabilita.
      expect(tester.widget<FilledButton>(moovButton).onPressed, isNull);

      await tester.tap(find.byTooltip('Aggiungi notti'));
      await tester.pumpAndSettle();
      expect(find.text('2 notti · 472 €'), findsOneWidget);
      final proposals = controller
          .threadOf(id)
          .messages
          .where((message) => message.kind == ChatMessageKind.planProposal)
          .toList(growable: false);
      final proposal = proposals.last.proposal!;
      expect(proposal.changeLabel, contains('2 notti · 472 €'));
      expect(
        proposal.snapshot.staySelection?.option.id,
        'porto-hotel-moov-centro',
      );
      expect(proposal.snapshot.staySelection?.option.priceCents, 47200);
      expect(proposal.snapshot.stay, contains('2 notti · 472 €'));
    },
  );

  testWidgets('moduli rich a 320 px con testo 1.5 non traboccano', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 30000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final seeded = MockData.journeyById('porto-slow');
    final journey = JourneyRoute(
      id: 'porto-guided-3',
      title: seeded.title,
      summary: seeded.summary,
      durationLabel: seeded.durationLabel,
      stops: const <String>['Porto'],
      destinationIds: const <String>['porto'],
      whyItFits: seeded.whyItFits,
      season: seeded.season,
      travelMode: seeded.travelMode,
      videoAssets: seeded.videoAssets,
      matchScore: seeded.matchScore,
    );
    final thread = controller.startFromJourney(journey);
    final id = thread.summary.id;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: wrap(
          ChatFirstThreadScreen(
            controller: controller,
            conversationId: id,
            onOpenSnapshot: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const intakeLabels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    // Fino alla remata operativa il flusso è guidato dal controller: a 320 px
    // con testo 1.5 il centro dei chip può cadere fuori dal target hit-test,
    // ma la verifica è sull'overflow e sui moduli rich, non sul tap preciso.
    Future<void> choose(String label) async {
      final message = controller
          .threadOf(id)
          .messages
          .lastWhere((m) => m.choices.any((c) => c.label == label));
      controller.choose(
        message.choices.firstWhere((c) => c.label == label),
        conversationId: id,
        messageId: message.id,
      );
      await tester.pumpAndSettle();
    }

    for (final label in intakeLabels) {
      await choose(label);
    }
    controller.acceptProposal(id, 'intake-proposal');
    await tester.pumpAndSettle();
    await choose('Salva');
    await choose('Salva');
    await choose('Irrinunciabile');
    await choose('Passa');
    await choose('Passa');
    await choose('Passa');
    await choose('Aereo diretto');

    expect(tester.takeException(), isNull);
    expect(find.text('Consigliato'), findsWidgets);
    final addNights = find.byTooltip('Aggiungi notti');
    await tester.ensureVisible(addNights);
    await tester.pumpAndSettle();
    await tester.tap(addNights, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      controller
          .threadOf(id)
          .messages
          .where((message) => message.kind == ChatMessageKind.planProposal),
      isNotEmpty,
    );
  });

  testWidgets('flusso non operativo (Lisbona) non mostra i moduli rich', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    expect(journeyCity(journey), 'Lisbona');
    final thread = controller.startFromJourney(journey);
    final id = thread.summary.id;
    await tester.pumpWidget(
      wrap(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    const intakeLabels = <String>[
      '4–5 giorni, senza fretta',
      'Bilanciato: cultura e pause',
      'Centro, per spostarmi a piedi',
      'Treno o metro + passi',
      'Moderato: qualche tavola bella',
    ];
    for (final label in intakeLabels) {
      await tapLast(tester, label);
    }
    await tapLast(tester, 'Accetta');

    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Salva');
    await tapLast(tester, 'Irrinunciabile');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Passa');
    await tapLast(tester, 'Aereo diretto');

    final transport = controller
        .threadOf(id)
        .messages
        .lastWhere((message) => message.kind == ChatMessageKind.transport);
    expect(transport.flightCompare, isNull);
    final stay = controller
        .threadOf(id)
        .messages
        .lastWhere((message) => message.kind == ChatMessageKind.stayZone);
    expect(stay.stayCompare, isNull);
    expect(find.text('Scegli'), findsNothing);
    expect(find.text('TAP Air Portugal'), findsNothing);
    expect(find.textContaining('FCO→OPO'), findsNothing);
  });

  testWidgets('profilo mostra memoria appresa e privacy', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        ChatFirstProfileScreen(
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
          onOpenChats: () {},
        ),
      ),
    );

    expect(find.text('Memoria appresa'), findsOneWidget);
    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    expect(find.byKey(const Key('profile-stats')), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Privacy'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Solo ispirazione, per ora'), findsNothing);
  });

  testWidgets('profilo: SegmentedButton senza overflow a 320x640 e testo 1.5', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: wrap(
          ChatFirstProfileScreen(
            themeMode: ThemeMode.light,
            onThemeChanged: (_) {},
            onOpenChats: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Sistema'),
      200,
      scrollable: scrollable,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
  });

  testWidgets('profilo apre la gestione disponibilità in un foglio dedicato', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        ChatFirstProfileScreen(
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
          onOpenChats: () {},
          availability: const <AvailabilityEntry>[],
          stats: const TravelStats(
            completedTrips: 3,
            visitedPlaces: 18,
            estimatedKilometers: 1240,
          ),
          onAddAvailability: (_) {},
          onRemoveAvailability: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Disponibilità'), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Aggiungi disponibilità'),
      240,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi disponibilità'));
    await tester.pumpAndSettle();

    expect(find.text('Nuova disponibilità'), findsOneWidget);
    expect(find.text('Libero'), findsOneWidget);
    expect(find.text('Turno'), findsOneWidget);
    expect(find.text('Salva disponibilità'), findsOneWidget);
  });

  testWidgets('viaggi usa una lista lineare con nuova chat esplicita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(
      wrapIter(
        ChatFirstListScreen(controller: controller, onOpenThread: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trips-heading')), findsOneWidget);
    expect(find.byKey(const Key('trips-new-chat')), findsOneWidget);
    expect(find.text('Nuova chat'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('snapshot read-only mostra dati e giorni', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(
      wrap(
        TripSnapshotScreen(
          controller: controller,
          conversationId: roma.summary.id,
        ),
      ),
    );

    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('In viaggio'), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Foro Romano'), findsOneWidget);
    expect(find.text('Aggiungi luogo'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('plan-global-actions'))).width,
      lessThanOrEqualTo(560),
    );
  });

  testWidgets('chat mantiene un composer grande e flottante', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final active = controller.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );
    await tester.pumpWidget(
      wrapIter(
        ChatFirstThreadScreen(
          controller: controller,
          conversationId: active.summary.id,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-composer')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('chat-composer'))).height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('home pianificazione promuove una scelta e continua il thread', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    var startedAnother = false;
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: AdaptiveHomeModel.planning(
            thread: controller.threads.firstWhere(
              (thread) =>
                  thread.summary.snapshot?.statusLabel == 'In pianificazione',
            ),
          ),
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
          onStartAnotherJourney: () async => startedAnother = true,
          unread: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prossima scelta'), findsOneWidget);
    expect(find.text('Decidiamo il ritmo del viaggio'), findsOneWidget);
    expect(find.text('Continua il viaggio'), findsOneWidget);
    expect(find.text('Inizia un altro viaggio'), findsOneWidget);
    await tester.tap(find.text('Inizia un altro viaggio'));
    await tester.pump();
    expect(startedAnother, isTrue);
    expect(find.text('Ispirazioni per te'), findsNothing);
  });

  testWidgets('home pianificazione usa superficie neutra per la card scelta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: AdaptiveHomeModel.planning(
            thread: controller.threads.firstWhere(
              (thread) =>
                  thread.summary.snapshot?.statusLabel == 'In pianificazione',
            ),
          ),
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
          unread: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final colors = IterTheme.light().colorScheme;
    final surface = tester.widget<IterMaterialSurface>(
      find.byKey(const Key('planning-next-choice')),
    );
    expect(surface.translucent, isFalse);
    expect(surface.borderRadius, BorderRadius.circular(24));
    expect(colors.surfaceContainerLow, isNot(colors.primaryContainer));
  });

  testWidgets('home segue una nuova chat anche prima della prima proposta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller = ChatFirstPrototypeController();
    addTearDown(controller.dispose);
    final thread = controller.startFreeTalk();

    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: AdaptiveHomeModel.planning(thread: thread),
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
          unread: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('La tua idea prende forma'), findsOneWidget);
    expect(find.text('Riprendi la chat'), findsOneWidget);
  });

  testWidgets('home attiva apre il thread senza mutare il piano', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    final active = controller.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );
    final snapshot = active.summary.snapshot!;
    ChatThread? opened;
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: AdaptiveHomeModel.active(thread: active),
          unread: 2,
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (thread) => opened = thread,
          onOpenTrips: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roma · Oggi'), findsOneWidget);
    expect(find.text('Foro Romano'), findsOneWidget);
    expect(find.text('Aggiornamento da confermare'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vedi il piano completo'));
    await tester.pump();
    expect(opened, same(active));
    expect(snapshot.days.first.items.first.time, '09:30');
  });

  testWidgets('home attiva mette la destinazione prima della timeline', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    final active = controller.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );
    await tester.pumpWidget(
      wrapIter(
        ChatFirstHomeScreen(
          model: AdaptiveHomeModel.active(thread: active),
          unread: 0,
          onSubmitIntent: (_) {},
          onVoiceIntent: () {},
          onPhotoIntent: (_) {},
          onOpenThread: (_) {},
          onOpenTrips: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-destination-stage')), findsOneWidget);
    expect(find.byKey(const Key('home-route')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-composer')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('home-composer')), findsOneWidget);
  });

  testWidgets('home resta leggibile a 320x640, testo 1.5 e moto ridotto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.5),
          disableAnimations: true,
        ),
        child: wrapIter(
          ChatFirstHomeScreen(
            model: const AdaptiveHomeModel.empty(),
            unread: 3,
            onSubmitIntent: (_) {},
            onVoiceIntent: () {},
            onPhotoIntent: (_) {},
            onOpenThread: (_) {},
            onOpenTrips: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('🌊 Mare e pause'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('shell usa Oggi Viaggi Tu con dock flottante e Home pulita senza chat box', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: controller,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('shell-floating-dock'))).width,
      lessThanOrEqualTo(360),
    );

    // Home pulita: zero TextField chat sulla home
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Organizza un nuovo viaggio'), findsOneWidget);

    // Tap su Organizza un nuovo viaggio -> apre chat dedicata a tutto schermo
    await tester.tap(find.text('Organizza un nuovo viaggio'));
    await tester.pumpAndSettle();

    expect(find.text('Organizzazione viaggio'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shell naviga su Viaggi e mostra lista con pulsante Nuovo viaggio', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: controller,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viaggi').last);
    await tester.pumpAndSettle();

    expect(find.text('I tuoi viaggi'), findsOneWidget);
    expect(find.text('Nuovo viaggio'), findsOneWidget);
  });

  testWidgets('shell naviga su Tu e mostra profilo', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: controller,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tu').last);
    await tester.pumpAndSettle();

    expect(find.text('Il tuo profilo'), findsOneWidget);
    expect(find.text('Preferenze di Viaggio'), findsOneWidget);
    expect(find.text('Configurazione IA (Fase Demo)'), findsOneWidget);
  });


  testWidgets('home active evita overflow a 320 con testo 1.5', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller = ChatFirstPrototypeController();
    final active = controller.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: wrapIter(
          ChatFirstHomeScreen(
            model: AdaptiveHomeModel.active(thread: active),
            unread: 0,
            onSubmitIntent: (_) {},
            onVoiceIntent: () {},
            onPhotoIntent: (_) {},
            onOpenThread: (_) {},
            onOpenTrips: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rotta trace distingue gli stati e annulla il moto ridotto', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Row(
            children: <Widget>[
              RottaVivaRouteTrace(state: RottaVivaRouteState.empty),
              RottaVivaRouteTrace(state: RottaVivaRouteState.planning),
              RottaVivaRouteTrace(state: RottaVivaRouteState.active),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Rotta vuota, pronta a raccogliere un desiderio'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rotta in pianificazione, una scelta alla volta'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rotta attiva, piano di oggi'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('composer usa vetro con pill radius in chiaro e scuro', (
    tester,
  ) async {
    for (final theme in <ThemeData>[IterTheme.light(), IterTheme.dark()]) {
      final colors = theme.colorScheme;
      final foreground = colors.onSurface;
      final glass = theme.extension<IterGlassRoles>()!;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ChatFirstHomeScreen(
              model: const AdaptiveHomeModel.empty(),
              unread: 0,
              onSubmitIntent: (_) {},
              onVoiceIntent: () {},
              onPhotoIntent: (_) {},
              onOpenThread: (_) {},
              onOpenTrips: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(TextField),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final composer = tester.widget<IterMaterialSurface>(
        find.byKey(const Key('iter-glass-bar')),
      );

      expect(composer.borderRadius, BorderRadius.circular(glass.pillRadius));
      expect(composer.translucent, isTrue);
      expect(decorator.decoration.filled, isFalse);
      expect(field.style?.color, foreground);
      expect(field.decoration?.labelStyle?.color, foreground);
      expect(
        field.decoration?.hintStyle?.color,
        foreground.withValues(alpha: .72),
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Aggiungi una foto'),
                matching: find.byType(IconButton),
              ),
            )
            .color,
        foreground,
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Invia un messaggio vocale'),
                matching: find.byType(IconButton),
              ),
            )
            .color,
        foreground,
      );
    }
  });

  testWidgets('snapshot non mostra il bottone di condivisione demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(
      wrap(
        TripSnapshotScreen(
          controller: controller,
          conversationId: roma.summary.id,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  group('Acquisti esterni e lifecycle UI', () {
    final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
    final flight = fixture.flights[0];
    final launcher = PlanExternalLauncher(
      launchExternal: (_) async => true,
      launchBrowser: (_) async => false,
    );

    String planningPortoId(ChatFirstPrototypeController controller) =>
        controller.threads
            .firstWhere(
              (thread) =>
                  thread.summary.snapshot?.statusLabel == 'In pianificazione',
            )
            .summary
            .id;

    Future<void> openPortoPurchase(
      ChatFirstPrototypeController controller,
    ) async {
      final id = planningPortoId(controller);
      controller.selectTravelOption(conversationId: id, optionId: flight.id);
      expect(
        await controller.openExternalPurchase(
          conversationId: id,
          kind: ExternalPurchaseKind.travel,
          optionId: flight.id,
          uri: flight.providerUrl,
          launcher: launcher,
        ),
        isTrue,
      );
    }

    testWidgets(
      'app osserva WidgetsBinding e il resume apre il dialog una volta sola',
      (tester) async {
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        await openPortoPurchase(controller);

        await tester.pumpWidget(ChatFirstPrototypeApp(controller: controller));
        await tester.pumpAndSettle();

        expect(
          find.text('Sei tornato dal sito di prenotazione.'),
          findsNothing,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Sei tornato dal sito di prenotazione.'),
          findsOneWidget,
        );
        expect(find.text('Sì, aggiorna'), findsOneWidget);
        expect(find.text('Non ancora'), findsOneWidget);

        // The prompt is consumed: a second resume stays silent.
        await tester.tap(find.text('Non ancora'));
        await tester.pumpAndSettle();
        expect(
          find.text('Sei tornato dal sito di prenotazione.'),
          findsNothing,
        );
        final id = planningPortoId(controller);
        expect(
          controller
              .conversationOf(id)
              .snapshot!
              .travelSelection!
              .option
              .purchaseState,
          PurchaseState.selected,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Sei tornato dal sito di prenotazione.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'resume senza ritorno atteso o senza launch riuscito non mostra dialog',
      (tester) async {
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: ChatFirstShell(
              controller: controller,
              themeMode: ThemeMode.light,
              onThemeChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.handleAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'dialog Sì aggiorna porta solo i campi autorizzati a acquistato',
      (tester) async {
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: ChatFirstShell(
              controller: controller,
              themeMode: ThemeMode.light,
              onThemeChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openPortoPurchase(controller);
        final id = planningPortoId(controller);
        final opened = controller.conversationOf(id).snapshot!;
        final openedOption = opened.travelSelection!.option;
        final openedAlternatives = opened.travelSelection!.alternatives;

        controller.handleAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(
          find.text('Sei tornato dal sito di prenotazione.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Sì, aggiorna'));
        await tester.pumpAndSettle();
        final confirmed = controller.conversationOf(id).snapshot!;
        final option = confirmed.travelSelection!.option;
        expect(option.purchaseState, PurchaseState.purchased);
        expect(option.id, openedOption.id);
        expect(option.label, openedOption.label);
        expect(option.priceCents, openedOption.priceCents);
        expect(
          confirmed.travelSelection!.alternatives.map((item) => item.id),
          openedAlternatives.map((item) => item.id),
        );
        expect(
          confirmed.days.map((day) => day.toJson()).toList(),
          opened.days.map((day) => day.toJson()).toList(),
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'dialog in italiano e senza dati sensibili annuncia solo la voce',
      (tester) async {
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: ChatFirstShell(
              controller: controller,
              themeMode: ThemeMode.light,
              onThemeChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openPortoPurchase(controller);

        controller.handleAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        final title = (dialog.title! as Text).data!;
        final content = (dialog.content! as Text).data!;
        expect(title, contains('sito di prenotazione'));
        expect(content, contains(flight.provider));
        expect(content, isNot(contains('FCO')));
        expect(content, isNot(contains('€')));
        await tester.tap(find.text('Non ancora'));
        await tester.pumpAndSettle();
      },
    );
  });
}
