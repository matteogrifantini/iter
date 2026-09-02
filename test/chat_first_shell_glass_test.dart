import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_shell.dart';

Finder dockHeightBox(double height) => find.descendant(
  of: find.byKey(const Key('shell-floating-dock')),
  matching: find.byWidgetPredicate(
    // AnimatedContainer folds width:/height: into constraints
    // (SDK implicit_animations.dart: tighten/tightFor), so height: 52
    // surfaces as constraints.maxHeight == 52. OR covers both spellings.
    (widget) =>
        widget is AnimatedContainer &&
        (widget.constraints?.maxHeight == height ||
            widget.constraints?.minHeight == height),
  ),
);

Future<void> pumpShell(
  WidgetTester tester, {
  bool disableAnimations = false,
  ThemeMode themeMode = ThemeMode.light,
  Size? surfaceSize,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = surfaceSize ?? const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final controller = ChatFirstPrototypeController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: IterTheme.light(),
      darkTheme: IterTheme.dark(),
      themeMode: themeMode,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            highContrast: highContrast,
          ),
          child: ChatFirstShell(
            controller: controller,
            themeMode: themeMode,
            onThemeChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dock resta flottante in vetro con 3 destinazioni', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
  });

  testWidgets('dock si restringe oltre 80px di scroll e si riespande', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(dockHeightBox(52.0), findsOneWidget);

    final dockBox = tester.widget<AnimatedContainer>(dockHeightBox(52.0));
    expect(
      dockBox.duration,
      const Duration(milliseconds: 180),
      reason: 'shrink animato 180ms',
    );
    expect(dockBox.curve, Curves.easeOut);

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(dockHeightBox(44.0), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(dockHeightBox(52.0), findsOneWidget);
  });

  testWidgets('shrink senza animazione con reduced motion', (tester) async {
    await pumpShell(tester, disableAnimations: true);
    expect(dockHeightBox(52.0), findsOneWidget);
    expect(
      tester.widget<AnimatedContainer>(dockHeightBox(52.0)).duration,
      Duration.zero,
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(dockHeightBox(44.0), findsOneWidget);
  });

  testWidgets('dock visibile in dark theme', (tester) async {
    await pumpShell(tester, themeMode: ThemeMode.dark);
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(dockHeightBox(52.0), findsOneWidget);
  });

  testWidgets('dock visibile a 320dp di larghezza', (tester) async {
    await pumpShell(tester, surfaceSize: const Size(320, 700));
    // La home page può andare in overflow a 320dp (pre-esistente,
    // home_hero_banner.dart) — lo si drena: il dock Task-3 resta trovato.
    tester.takeException();
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
  });

  testWidgets('dock senza eccezioni con highContrast', (tester) async {
    await pumpShell(tester, highContrast: true);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(dockHeightBox(52.0), findsOneWidget);
  });
}
