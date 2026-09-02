import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  test('raggi chat rispettano token', () {
    final theme = IterTheme.light();
    final glass = theme.extension<IterGlassRoles>()!;
    expect(glass.pillRadius, 20.0);
    expect(glass.cardRadius, 24.0);
  });

  testWidgets('composer thread usa IterGlassBar con allegato e invio/mic',
      (tester) async {
    final controller = ChatFirstPrototypeController();
    final thread = controller.threads.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: Scaffold(
          body: ChatFirstThreadScreen(
            controller: controller,
            conversationId: thread.summary.id,
            onOpenSnapshot: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IterGlassBar), findsOneWidget);
    expect(find.byTooltip('Allegato'), findsOneWidget);
    // Empty composer shows mic, typed composer shows send.
    expect(find.byTooltip('Registra vocale (demo)'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 2);

    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.pump();
    expect(find.byTooltip('Invia'), findsOneWidget);
  });
}
