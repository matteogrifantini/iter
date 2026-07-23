import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/app_config.dart';
import 'package:iter/app/iter_app.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_models.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_proposals.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_screen.dart';
import 'package:iter/features/new_trip_lab/new_trip_origin_resolver.dart';
import 'package:iter/widgets/trip_card.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    expect(finder, findsAtLeastNWidgets(1));
    final target = finder.first;
    await Scrollable.ensureVisible(
      target.evaluate().first,
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Widget newTripLabApp({
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(390, 844),
    double textScale = 1,
    OriginResolver? originResolver,
    List<DateTime> savedFreeDays = const <DateTime>[],
    PrototypeProposalSource proposalSource =
        const DeterministicPrototypeProposalSource(),
    bool? disableAnimations,
    List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
  }) => MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      locale: const Locale('it'),
      supportedLocales: const <Locale>[Locale('it')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: IterTheme.light(),
      darkTheme: IterTheme.dark(),
      themeMode: themeMode,
      navigatorObservers: navigatorObservers,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations:
                disableAnimations ?? mediaQuery.disableAnimations,
          ),
          child: child!,
        );
      },
      home: NewTripLabScreen(
        savedFreeDays: savedFreeDays,
        originResolver:
            originResolver ?? FixedOriginResolver.resolved('Firenze'),
        proposalSource: proposalSource,
        autoAdvanceDelay: Duration.zero,
        searchStageDelay: Duration.zero,
        clock: () => DateTime(2026, 7, 16),
      ),
    ),
  );

  Future<void> driveOpenQuestions(WidgetTester tester) async {
    await tapVisible(tester, find.text('Non lo so ancora'));
    await tapVisible(tester, find.text('Indifferente'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    await tapVisible(tester, find.text('Solo'));
    expect(find.text('Continua'), findsNothing);
    await tapVisible(tester, find.text('Qualsiasi, se conviene'));
    await tapVisible(tester, find.text('€500'));
    await tapVisible(tester, find.text('Cultura'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    await tapVisible(tester, find.text('Equilibrato'));
    await tapVisible(tester, find.text('Il giusto'));
  }

  Future<void> driveAccessibleQuestions(
    WidgetTester tester, {
    bool customDurationAndFriends = false,
  }) async {
    void expectNoLayoutError(String stage) {
      expect(tester.takeException(), isNull, reason: '$stage layout');
    }

    expectNoLayoutError('date modes');
    await tapVisible(tester, find.text('Non lo so ancora'));
    expectNoLayoutError('open date controls');
    if (customDurationAndFriends) {
      await tapVisible(tester, find.text('Personalizza'));
      expect(find.text('Minimo'), findsOneWidget);
      expect(find.text('Massimo'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Aumenta Minimo'));
    } else {
      await tapVisible(tester, find.text('Indifferente'));
    }
    expectNoLayoutError('dates');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );

    if (customDurationAndFriends) {
      await tapVisible(tester, find.text('Con amici'));
      expect(find.text('Adulti'), findsOneWidget);
      expect(find.text('Bambini'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Aumenta Adulti'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('new-trip-contextual-action')),
      );
    } else {
      await tapVisible(tester, find.text('Solo'));
    }
    expectNoLayoutError('company');

    await tapVisible(tester, find.text('Qualsiasi, se conviene'));
    expectNoLayoutError('transport');
    await tapVisible(tester, find.text('€500'));
    expectNoLayoutError('budget');
    await tapVisible(tester, find.text('Cultura'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    expectNoLayoutError('travel style');
    await tapVisible(tester, find.text('Equilibrato'));
    expectNoLayoutError('pace');
    await tapVisible(tester, find.text('Il giusto'));
    expectNoLayoutError('walking');
    expect(find.text('Il viaggio che stiamo cercando'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  Future<void> reachSelection(WidgetTester tester) async {
    await tester.pumpWidget(newTripLabApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Parti da Firenze'), findsOneWidget);

    await driveOpenQuestions(tester);
    expect(tester.takeException(), isNull, reason: 'question flow overflow');
    expect(find.text('Il viaggio che stiamo cercando'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('new-trip-search')));
    expect(tester.takeException(), isNull, reason: 'results overflow');
    expect(find.text('6 viaggi, già confrontabili'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^€\d+–€\d+ gruppo$').hasMatch(widget.data ?? ''),
      ),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('Tieni almeno due proposte'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('new-trip-compare')))
          .onPressed,
      isNull,
    );

    await tapVisible(tester, find.text('Tieni per il confronto'));
    await tapVisible(tester, find.text('Tieni per il confronto'));
    await tapVisible(tester, find.byKey(const ValueKey('new-trip-compare')));
    expect(tester.takeException(), isNull, reason: 'comparison overflow');
    expect(find.textContaining('criterio per criterio'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quale portiamo avanti?'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'comparison choice overflow',
    );
    await tapVisible(tester, find.textContaining('Scegli '));
    expect(tester.takeException(), isNull, reason: 'selection overflow');
    expect(find.text('Hai scelto'), findsOneWidget);
    expect(find.textContaining('prezzo non è bloccato'), findsOneWidget);
  }

  testWidgets('Lab Home opens the single Semplice flow directly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const IterApp(
        config: AppConfig(
          backend: 'mock',
          supabaseUrl: '',
          supabaseAnonKey: '',
          newTripLab: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('new-trip-lab')));

    expect(find.text('Da dove vuoi partire?'), findsOneWidget);
    expect(
      find.text('Tre modi di iniziare. Uno diventerà Iter.'),
      findsNothing,
    );
    expect(find.text('Semplice'), findsNothing);
  });

  testWidgets('normal Home keeps the existing product entry', (tester) async {
    await tester.pumpWidget(
      const IterApp(
        config: AppConfig(
          backend: 'mock',
          supabaseUrl: '',
          supabaseAnonKey: '',
          newTripLab: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-trip')), findsOneWidget);
    expect(find.byKey(const Key('new-trip-lab')), findsNothing);
  });

  testWidgets('opening and closing the lab never creates a trip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const IterApp(
        config: AppConfig(
          backend: 'mock',
          supabaseUrl: '',
          supabaseAnonKey: '',
          newTripLab: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigation = find.byType(NavigationBar);
    await tapVisible(
      tester,
      find.descendant(of: navigation, matching: find.text('Viaggi')),
    );
    final tripCountBefore = find.byType(TripCard).evaluate().length;
    await tapVisible(
      tester,
      find.descendant(of: navigation, matching: find.text('Oggi')),
    );

    await tapVisible(tester, find.byKey(const Key('new-trip-lab')));
    await tester.pumpAndSettle();
    if (find
        .byKey(const ValueKey('new-trip-origin-field'))
        .evaluate()
        .isNotEmpty) {
      await tester.enterText(
        find.byKey(const ValueKey('new-trip-origin-field')),
        'Firenze',
      );
      await tester.pump();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('new-trip-origin-confirm')),
      );
    }
    await tapVisible(tester, find.byTooltip('Chiudi anteprima'));

    await tapVisible(
      tester,
      find.descendant(of: navigation, matching: find.text('Viaggi')),
    );
    expect(find.byType(TripCard), findsNWidgets(tripCountBefore));
  });

  testWidgets('failed location falls back to a manual editable origin', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      newTripLabApp(
        originResolver: FixedOriginResolver.failed(
          PrototypeOriginFailure.permissionDenied,
        ),
        textScale: 1.5,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-trip-origin-field')), findsOneWidget);
    expect(find.text('Milano'), findsNothing);
    expect(find.text('Roma'), findsNothing);
    expect(find.text('Bologna'), findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-trip-origin-field')),
      'Firenze Santa Maria Novella',
    );
    await tester.pump();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-origin-confirm')),
    );

    expect(
      find.textContaining('Parti da Firenze Santa Maria Novella'),
      findsOneWidget,
    );
    expect(find.text('Quando potresti partire?'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'manual origin overflow');
  });

  testWidgets('locating origin is readable with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(
        originResolver: _PendingOriginResolver(),
        textScale: 1.5,
        disableAnimations: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Cerchiamo la tua città'), findsOneWidget);
  });

  testWidgets('option semantics expose one button label without emoji noise', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(newTripLabApp(disableAnimations: true));
      await tester.pumpAndSettle();

      final option = find.byKey(
        const ValueKey('new-trip-option-Ho già le date'),
      );
      final node = tester.getSemantics(option);
      final flags = node.flagsCollection;
      expect(node.label, 'Ho già le date. Partenza e ritorno precisi.');
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isTrue);
      expect(flags.isSelected, Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled saved free days option remains a semantic button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(newTripLabApp(disableAnimations: true));
      await tester.pumpAndSettle();

      final option = find.byKey(
        const ValueKey('new-trip-option-Usa i miei giorni liberi'),
      );
      final node = tester.getSemantics(option);
      final flags = node.flagsCollection;
      expect(
        node.label,
        'Usa i miei giorni liberi. Parti dalle disponibilità che hai già registrato. Aggiungi prima dei giorni liberi.',
      );
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isFalse);
      expect(flags.isSelected, Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('origin editor has no route transition with reduced motion', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      newTripLabApp(
        disableAnimations: true,
        navigatorObservers: <NavigatorObserver>[observer],
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-origin-pill')),
    );

    final route = observer.lastPushedRoute;
    expect(route, isA<ModalBottomSheetRoute<String>>());
    final bottomSheetRoute = route! as ModalBottomSheetRoute<String>;
    expect(bottomSheetRoute.transitionDuration, Duration.zero);
    expect(bottomSheetRoute.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('origin changes immediately when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      newTripLabApp(
        originResolver: FixedOriginResolver.failed(
          PrototypeOriginFailure.permissionDenied,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('new-trip-origin-field')),
      'Firenze Santa Maria Novella',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('origin-help')), findsNothing);
    expect(find.byKey(const ValueKey('origin-result')), findsOneWidget);
    expect(find.text('Usa “Firenze Santa Maria Novella”'), findsOneWidget);
  });

  testWidgets('Semplice intake renders in dark theme at large text', (
    tester,
  ) async {
    const size = Size(320, 720);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(
        themeMode: ThemeMode.dark,
        size: size,
        textScale: 1.5,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(
          find.byKey(const ValueKey('new-trip-option-Ho già le date')),
        ),
      ).brightness,
      Brightness.dark,
    );
    await tapVisible(tester, find.text('Non lo so ancora'));
    expect(tester.takeException(), isNull, reason: 'dark intake overflow');
  });

  testWidgets('Semplice reaches results, compare and final selection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await reachSelection(tester);
  });

  testWidgets('isolated flexible departure dates enable confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(newTripLabApp());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Ho più possibilità'));
    expect(find.byType(CalendarDatePicker2), findsOneWidget);
    await tapVisible(tester, find.text('18'));
    await tapVisible(tester, find.text('27'));
    await tapVisible(tester, find.text('3–4'));

    expect(find.textContaining('2 partenze possibili'), findsOneWidget);
    final action = tester.widget<FilledButton>(
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    expect(action.onPressed, isNotNull);
  });

  testWidgets('Semplice keeps date choices in two columns above progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(
        originResolver: FixedOriginResolver.resolved('Firenze'),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    final fixedDates = find.byKey(
      const ValueKey('new-trip-option-Ho già le date'),
    );
    final flexibleDates = find.byKey(
      const ValueKey('new-trip-option-Ho più possibilità'),
    );
    expect(fixedDates, findsOneWidget);
    expect(flexibleDates, findsOneWidget);
    expect(
      tester.getTopLeft(fixedDates).dy,
      equals(tester.getTopLeft(flexibleDates).dy),
    );
    expect(
      tester.getTopLeft(fixedDates).dx,
      isNot(equals(tester.getTopLeft(flexibleDates).dx)),
    );
    expect(
      tester.getSize(fixedDates).width,
      tester.getSize(flexibleDates).width,
    );
    expect(
      tester.getTopLeft(flexibleDates).dx - tester.getTopRight(fixedDates).dx,
      10,
    );
    expect(find.text('📅'), findsAtLeastNWidgets(1));

    final progress = find.byKey(const ValueKey('new-trip-simple-progress'));
    expect(progress, findsOneWidget);
    expect(
      tester.getTopLeft(progress).dy,
      greaterThan(tester.getBottomLeft(fixedDates).dy),
    );
    expect(tester.takeException(), isNull, reason: 'Semplice date layout');
  });

  testWidgets('progress follows the options inside scrollable content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(newTripLabApp(disableAnimations: true));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Non lo so ancora'));
    await tapVisible(tester, find.text('Indifferente'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    await tapVisible(tester, find.text('Solo'));
    await tapVisible(tester, find.text('Qualsiasi, se conviene'));
    await tapVisible(tester, find.text('€500'));
    await tapVisible(tester, find.text('Cultura'));

    final option = find.byKey(const ValueKey('new-trip-option-Cibo'));
    final progress = find.byKey(const ValueKey('new-trip-simple-progress'));
    final action = find.byKey(const ValueKey('new-trip-contextual-action'));
    final bottomNavigation = find.byKey(
      const ValueKey('new-trip-simple-bottom-navigation'),
    );

    await Scrollable.ensureVisible(
      progress.evaluate().first,
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();

    expect(option, findsOneWidget);
    expect(progress, findsOneWidget);
    expect(action, findsOneWidget);
    expect(
      tester.getTopLeft(option).dy,
      lessThan(tester.getTopLeft(progress).dy),
    );
    expect(
      tester.getTopLeft(progress).dy,
      lessThan(tester.getTopLeft(action).dy),
    );
    expect(
      find.ancestor(of: progress, matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
    expect(bottomNavigation, findsOneWidget);
    expect(
      find.descendant(of: bottomNavigation, matching: progress),
      findsNothing,
    );
  });

  testWidgets('progress announces current question and remaining effort', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(newTripLabApp(disableAnimations: true));
      await tester.pumpAndSettle();

      final progress = find.bySemanticsLabel('Avanzamento del nuovo viaggio');
      expect(progress, findsOneWidget);
      expect(
        tester.getSemantics(progress).value,
        '1 di 7, Quando, 6 domande ancora',
      );

      await tapVisible(tester, find.text('Non lo so ancora'));
      await tapVisible(tester, find.text('Indifferente'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('new-trip-contextual-action')),
      );
      await tapVisible(tester, find.text('Solo'));
      await tapVisible(tester, find.text('Qualsiasi, se conviene'));
      await tapVisible(tester, find.text('€500'));
      await tapVisible(tester, find.text('Cultura'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('new-trip-contextual-action')),
      );

      expect(
        tester.getSemantics(progress).value,
        '6 di 7, Ritmo, 1 domanda ancora',
      );
      await tapVisible(tester, find.text('Equilibrato'));

      expect(
        tester.getSemantics(progress).value,
        '7 di 7, Camminate, Ultima domanda',
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final scenario in <({Size size, double scale, int columns})>[
    (size: const Size(360, 800), scale: 1, columns: 1),
    (size: const Size(390, 844), scale: 1, columns: 2),
    (size: const Size(320, 720), scale: 1.5, columns: 1),
  ]) {
    testWidgets('option grid uses ${scenario.columns} column(s) at '
        '${scenario.size.width}dp and ${scenario.scale}x text', (tester) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        newTripLabApp(
          size: scenario.size,
          textScale: scenario.scale,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final fixedDates = find.byKey(
        const ValueKey('new-trip-option-Ho già le date'),
      );
      final flexibleDates = find.byKey(
        const ValueKey('new-trip-option-Ho più possibilità'),
      );
      expect(fixedDates, findsOneWidget);
      expect(flexibleDates, findsOneWidget);

      final fixedTopLeft = tester.getTopLeft(fixedDates);
      final flexibleTopLeft = tester.getTopLeft(flexibleDates);
      if (scenario.columns == 1) {
        expect(flexibleTopLeft.dx, fixedTopLeft.dx);
        expect(flexibleTopLeft.dy, greaterThan(fixedTopLeft.dy));
      } else {
        expect(flexibleTopLeft.dy, fixedTopLeft.dy);
        expect(flexibleTopLeft.dx, greaterThan(fixedTopLeft.dx));
      }
      expect(tester.takeException(), isNull, reason: 'option grid overflow');
    });
  }

  testWidgets('option qualifiers are visible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(newTripLabApp(disableAnimations: true));
    await tester.pumpAndSettle();

    expect(find.text('Partenza e ritorno precisi.'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'option qualifier overflow');
  });

  testWidgets('saved free days keep consecutive-window validation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(
        savedFreeDays: <DateTime>[
          DateTime(2026, 8, 2),
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 4),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Usa i miei giorni liberi'));
    await tapVisible(tester, find.text('3–4'));
    expect(
      find.byKey(const ValueKey('new-trip-calendar-saved')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Calendario dei giorni liberi salvati, sola lettura. Usa le finestre salvate qui sotto per includere o escludere i giorni.',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('new-trip-calendar-saved')),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 finestre dai giorni liberi'), findsOneWidget);
    final savedWindowChip = find.byType(FilterChip).first;
    expect(tester.widget<FilterChip>(savedWindowChip).selected, isTrue);
    await tapVisible(tester, savedWindowChip);
    expect(tester.widget<FilterChip>(savedWindowChip).selected, isFalse);
    await tapVisible(tester, savedWindowChip);
    expect(tester.widget<FilterChip>(savedWindowChip).selected, isTrue);
    final action = tester.widget<FilledButton>(
      find.byKey(const ValueKey('new-trip-contextual-action')),
    );
    expect(action.onPressed, isNotNull);
  });

  testWidgets('no-results proposes one relaxation at a time', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(proposalSource: const EmptyPrototypeProposalSource()),
    );
    await tester.pumpAndSettle();

    await driveOpenQuestions(tester);
    await tapVisible(tester, find.byKey(const ValueKey('new-trip-search')));

    expect(find.text('+1 giorno'), findsOneWidget);
    expect(find.text('Aeroporto vicino'), findsNothing);
    expect(find.text('+€100'), findsNothing);

    await tapVisible(tester, find.text('Mostra un’altra modifica'));
    expect(find.text('+1 giorno'), findsNothing);
    expect(find.text('Aeroporto vicino'), findsOneWidget);
    expect(find.text('+€100'), findsNothing);
  });

  testWidgets('Semplice reaches summary at 320x640 with text scale 1.5', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      newTripLabApp(textScale: 1.5, disableAnimations: true),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Parti da Firenze'), findsOneWidget);
    await driveAccessibleQuestions(tester);
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRoute = route;
    super.didPush(route, previousRoute);
  }
}

class _PendingOriginResolver implements OriginResolver {
  final Completer<PrototypeOriginResolution> _completer =
      Completer<PrototypeOriginResolution>();

  @override
  Future<PrototypeOriginResolution> resolve() => _completer.future;
}
