import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  testWidgets('cost sheet in vetro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassSheet(child: Text('Totali'))),
      ),
    );
    expect(find.text('Totali'), findsOneWidget);
  });
}
