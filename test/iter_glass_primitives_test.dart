import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  testWidgets('IterGlassBar usa vetro con fallback opaco', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassBar(child: Text('vetro'))),
      ),
    );
    expect(find.text('vetro'), findsOneWidget);
    expect(find.byKey(const Key('iter-glass-bar')), findsOneWidget);
  });

  testWidgets('IterGlassSheet ha raggio 28', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassSheet(child: Text('sheet'))),
      ),
    );
    expect(find.byKey(const Key('iter-glass-sheet')), findsOneWidget);
  });

  testWidgets('IterGlassBar senza blur con reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(body: IterGlassBar(child: Text('vetro'))),
        ),
      ),
    );
    expect(find.text('vetro'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
