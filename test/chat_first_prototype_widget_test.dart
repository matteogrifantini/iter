import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_list_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/chat_first_profile_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
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

  testWidgets('home mostra riga Riprendi e apre la conversazione', (tester) async {
    final controller = ChatFirstPrototypeController();
    ChatThread? resumed;
    var chatsOpened = false;
    await tester.pumpWidget(wrap(ChatFirstHomeScreen(
      journeys: const [],
      resumable: controller.threads.take(2).toList(growable: false),
      onStartChat: (_) {},
      onResume: (thread) => resumed = thread,
      onOpenChats: () => chatsOpened = true,
      unread: 0,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Riprendi'), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('Porto'), findsOneWidget);

    await tester.tap(find.text('Roma'));
    await tester.pump();
    expect(resumed?.summary.title, 'Roma');

    await tester.tap(find.text('Tutte'));
    await tester.pump();
    expect(chatsOpened, isTrue);
  });

  testWidgets('lista chat mostra conversazioni e badge non letti', (tester) async {
    final controller = ChatFirstPrototypeController();
    String? opened;
    await tester.pumpWidget(wrap(ChatFirstListScreen(
      controller: controller,
      onOpenThread: (thread) => opened = thread.summary.id,
    )));

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('Porto'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Roma'));
    await tester.pump();
    expect(opened, isNotNull);
    expect(controller.unread, 0);
  });

  testWidgets('thread mostra bolle, scelte e avanza su tap', (tester) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: roma.summary.id,
      onOpenSnapshot: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Rallenta la mattina'), findsOneWidget);
    final before = controller.threadOf(roma.summary.id).messages.length;
    await tester.tap(find.text('Rallenta la mattina'));
    await tester.pumpAndSettle();
    expect(controller.threadOf(roma.summary.id).messages.length, before + 2);
  });

  testWidgets('proposta di piano: Accetta applica, Annulla mantiene', (tester) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: roma.summary.id,
      onOpenSnapshot: (_) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rallenta la mattina'));
    await tester.pumpAndSettle();
    expect(find.text('Accetta'), findsOneWidget);
    expect(find.text('Annulla'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(
      controller.threadOf(roma.summary.id).summary.snapshot?.days.first.items.first.time,
      '09:30',
    );
    expect(find.text('Modifica annullata'), findsOneWidget);
    expect(find.text('Accetta'), findsNothing);
  });

  testWidgets('proposta accettata aggiorna il piano della conversazione', (tester) async {
    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: roma.summary.id,
      onOpenSnapshot: (_) {},
    )));
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

  testWidgets('intake: domande, proposta e accettazione nel thread', (tester) async {
    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: thread.summary.id,
      onOpenSnapshot: (_) {},
    )));
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

  testWidgets('curation F5: card luogo con scelte Passa/Salva/Irrinunciabile',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: thread.summary.id,
      onOpenSnapshot: (_) {},
    )));
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

  testWidgets('flusso F5 completo: curation, trasporto, zona e itinerario',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final journey = controller.trendJourneys.first;
    final thread = controller.startFromJourney(journey);
    final id = thread.summary.id;
    await tester.pumpWidget(wrap(ChatFirstThreadScreen(
      controller: controller,
      conversationId: id,
      onOpenSnapshot: (_) {},
    )));
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

    final zoneName = controller.threadOf(id).messages
        .lastWhere((m) => m.kind == ChatMessageKind.stayZone)
        .stayZone!
        .name;
    expect(find.textContaining('Mappa demo'), findsOneWidget);
    await tapLast(tester, zoneName);

    await tapLast(tester, 'Accetta');

    final snapshot = controller.threadOf(id).summary.snapshot!;
    expect(snapshot.transport, 'Aereo diretto · 1h 30m');
    expect(snapshot.stay, zoneName);
    expect(
      snapshot.days.last.items.last.title,
      'Passeggiata finale',
    );
    expect(find.text('Modifica applicata'), findsWidgets);
  });

  testWidgets('profilo mostra memoria appresa e privacy', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(ChatFirstProfileScreen(
      themeMode: ThemeMode.light,
      onThemeChanged: (_) {},
      onOpenChats: () {},
    )));

    expect(find.text('Memoria appresa'), findsOneWidget);
    expect(find.text('Aspetto'), findsOneWidget);

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

  testWidgets('profilo: SegmentedButton senza overflow a 320x640 e testo 1.5', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: wrap(ChatFirstProfileScreen(
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
          onOpenChats: () {},
        )),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Sistema'), 200, scrollable: scrollable);
    expect(find.text('Sistema'), findsOneWidget);
  });

  testWidgets('snapshot read-only mostra dati e giorni', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    final snapshot = roma.summary.snapshot!;
    await tester.pumpWidget(wrap(TripSnapshotScreen(snapshot: snapshot)));

    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('In viaggio'), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Foro Romano'), findsNWidgets(2));
    expect(find.textContaining('Modifiche solo tramite chat'), findsOneWidget);
  });

  testWidgets('home con viaggi mostra Ispirazioni per te e non Classifica', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    await tester.pumpWidget(wrapIter(ChatFirstHomeScreen(
      journeys: controller.trendJourneys,
      resumable: controller.threads.take(2).toList(growable: false),
      onStartChat: (_) {},
      onResume: (_) {},
      onOpenChats: () {},
      unread: 0,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Ispirazioni per te'), findsOneWidget);
    expect(find.text('Classifica'), findsNothing);
    expect(find.text('Idee brevi'), findsNothing);
  });

  testWidgets('snapshot non mostra il bottone di condivisione demo', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ChatFirstPrototypeController();
    final roma = controller.threads.firstWhere(
      (t) => t.summary.title.contains('Roma'),
    );
    await tester.pumpWidget(wrap(TripSnapshotScreen(snapshot: roma.summary.snapshot!)));
    await tester.pump();

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });
}