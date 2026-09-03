import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';

const _conversationId = 'c-snapshot-glass';

void main() {
  test('sheet radius piano è 28', () {
    final glass = IterTheme.light().extension<IterGlassRoles>()!;
    expect(glass.sheetRadius, 28.0);
  });

  testWidgets('snapshot hero edge-to-edge con scrim e action bar in vetro', (
    tester,
  ) async {
    final controller = _controllerFor(
      ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
    );
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: TripSnapshotScreen(
          controller: controller,
          conversationId: _conversationId,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('plan-destination-hero')), findsOneWidget);
    expect(find.byType(IterHeroScrim), findsOneWidget);
    expect(find.byKey(const Key('iter-glass-bar')), findsOneWidget);
    expect(find.byKey(const Key('plan-global-actions')), findsOneWidget);
    expect(find.byKey(const Key('plan-map')), findsNothing);
    expect(find.text('Giorno 1'), findsOneWidget);
    expect(find.text('Aggiungi luogo'), findsOneWidget);
    expect(find.text('Chiedi'), findsOneWidget);
    expect(find.text('Costi'), findsOneWidget);
  });
}

ChatFirstPrototypeController _controllerFor(TripSnapshot snapshot) {
  final thread = ChatThread(
    summary: Conversation(
      id: _conversationId,
      title: snapshot.destinationTitle,
      subtitle: snapshot.statusLabel,
      avatar: const ChatAvatar(
        'assets/images/travel/porto_livraria_lello.jpg',
        label: 'Porto',
      ),
      timestamp: DateTime.utc(2026, 8, 11),
      lastPreview: 'Piano operativo',
      snapshot: snapshot,
    ),
    script: const <ScriptedBeat>[],
  );
  return ChatFirstPrototypeController(seed: <ChatThread>[thread]);
}
