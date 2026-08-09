import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_list_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/chat_first_profile_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_shell.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';

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

  Finder semanticsLabel(String label) => find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
    description: 'Semantics label $label',
  );

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

    expect(find.text('Dimmi che viaggio hai in mente'), findsOneWidget);
    expect(semanticsLabel('Iter, la rotta che prende forma'), findsWidgets);
    expect(
      semanticsLabel('Scrivi il viaggio che hai in mente'),
      findsOneWidget,
    );
    expect(semanticsLabel('Aggiungi una foto'), findsOneWidget);
    expect(semanticsLabel('Invia un messaggio vocale'), findsOneWidget);
    expect(find.text('🌊 Mare e pause'), findsOneWidget);
    expect(find.text('Roma'), findsNothing);
    expect(find.text('Porto'), findsNothing);
    expect(find.text('Ispirazioni per te'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);

    await tester.tap(find.text('🌊 Mare e pause'));
    await tester.pump();
    expect(submitted, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mare e pause',
    );
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pump();
    expect(submitted, <String>['Mare e pause']);

    await tester.tap(find.byTooltip('Aggiungi una foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finestrino sul mare'));
    await tester.pumpAndSettle();
    expect(selectedPhoto, 'assets/images/travel/rail_window.jpg');
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
    await tester.enterText(find.byType(TextField), 'Vorrei rallentare');
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Vorrei rallentare',
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
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Sistema'),
      200,
      scrollable: scrollable,
    );
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

  testWidgets('home pianificazione promuove una scelta e continua il thread', (
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

    expect(find.text('Prossima scelta'), findsOneWidget);
    expect(find.text('Decidiamo il ritmo del viaggio'), findsOneWidget);
    expect(find.text('Continua il viaggio'), findsOneWidget);
    expect(find.text('Ispirazioni per te'), findsNothing);
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
    expect(find.text('Aggiornamento da confermare'), findsOneWidget);
    expect(semanticsLabel('Timeline di oggi, 2 tappe'), findsOneWidget);
    await tester.tap(find.text('Apri il piano di oggi'));
    await tester.pump();
    expect(opened, same(active));
    expect(snapshot.days.first.items.first.time, '09:30');
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
    expect(semanticsLabel('Viaggi, 3 messaggi non letti'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('🌊 Mare e pause'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(semanticsLabel('Segnale: mare e pause'), findsWidgets);
  });

  testWidgets('shell usa Oggi Viaggi Tu e apre il FreeTalk dopo invio', (
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

    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byType(TextField),
      'Quattro giorni senza fretta',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Invia il desiderio'));
    await tester.pumpAndSettle();
    expect(controller.activeThread?.summary.id, kFreeTalkConversationId);
    expect(controller.activeThread?.messages.last.role, ChatRole.assistant);
  });

  testWidgets('shell lega planning e active al thread aperto dalla Home', (
    tester,
  ) async {
    final seeded = ChatFirstPrototypeController();
    final planning = seeded.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In pianificazione',
    );
    final planningController = ChatFirstPrototypeController(
      seed: <ChatThread>[planning],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: planningController,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Continua il viaggio'));
    await tester.pumpAndSettle();
    expect(planningController.activeThreadId, planning.summary.id);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final active = seeded.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );
    final activeController = ChatFirstPrototypeController(
      seed: <ChatThread>[active],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: activeController,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Apri il piano di oggi'));
    await tester.pumpAndSettle();
    expect(activeController.activeThreadId, active.summary.id);
  });

  testWidgets(
    'shell invia text voce e foto nel FreeTalk, non nel thread active',
    (tester) async {
      final controller = ChatFirstPrototypeController();
      final active = controller.threads.firstWhere(
        (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
      );
      controller.openConversation(active.summary.id);
      final activeMessages = active.messages.length;
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

      Future<void> returnToHome() async {
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(TextField),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      }

      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byType(TextField),
        'Vorrei fermarmi vicino al mare',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Invia il desiderio'));
      await tester.pumpAndSettle();
      await returnToHome();

      await tester.tap(find.byTooltip('Invia un messaggio vocale'));
      await tester.pumpAndSettle();
      await returnToHome();

      await tester.tap(find.byTooltip('Aggiungi una foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finestrino sul mare'));
      await tester.pumpAndSettle();

      final freeTalk = controller.threadOf(kFreeTalkConversationId);
      expect(
        freeTalk.messages
            .where((message) => message.role == ChatRole.traveler)
            .map((message) => message.kind),
        containsAll(<ChatMessageKind>[
          ChatMessageKind.text,
          ChatMessageKind.audio,
          ChatMessageKind.media,
        ]),
      );
      expect(active.messages.length, activeMessages);
    },
  );

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
    await tester.scrollUntilVisible(
      find.text('Aggiornamento da confermare'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer mantiene contrasto semantico in chiaro e scuro', (
    tester,
  ) async {
    for (final theme in <ThemeData>[IterTheme.light(), IterTheme.dark()]) {
      final colors = theme.colorScheme;
      final isDark = colors.brightness == Brightness.dark;
      final background = isDark ? colors.surface : colors.inverseSurface;
      final foreground = isDark ? colors.onSurface : colors.onInverseSurface;
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

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final composer = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = composer.decoration as BoxDecoration;

      expect(decoration.color, background);
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
      wrap(TripSnapshotScreen(snapshot: roma.summary.snapshot!)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });
}
