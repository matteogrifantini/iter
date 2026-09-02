import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  testWidgets('hero scrim mantiene leggibilità', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterHeroScrim(child: Text('Porto'))),
      ),
    );
    expect(find.text('Porto'), findsOneWidget);
  });

  testWidgets('home attiva: hero edge-to-edge con scrim e composer in vetro', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    addTearDown(controller.dispose);
    final active = controller.threads.firstWhere(
      (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: Scaffold(
          body: ChatFirstHomeScreen(
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

    // Hero full-bleed: semantics 'hero', scrim sopra l'immagine, testi sopra.
    expect(find.bySemanticsLabel(RegExp('hero')), findsWidgets);
    expect(find.byType(IterHeroScrim), findsOneWidget);
    expect(find.byKey(const Key('home-destination-stage')), findsOneWidget);

    // Composer oggetto principale in vetro.
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-composer')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('home-composer')), findsOneWidget);
    expect(find.byKey(const Key('iter-glass-bar')), findsWidgets);

    // Riga operativa breve + 'Vedi il piano completo' una sola volta.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Vedi il piano completo'), findsOneWidget);

    // Timeline invariata nei dati.
    expect(active.summary.snapshot!.days.first.items.first.time, '09:30');
    expect(find.text('Foro Romano'), findsOneWidget);
  });
}
