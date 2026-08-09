import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';

void main() {
  test('returns empty when no thread has a trip snapshot', () {
    final freeTalk = _thread(
      id: 'free-talk',
      timestamp: DateTime.utc(2026, 8, 9, 9),
    );

    final result = resolveAdaptiveHome(<ChatThread>[freeTalk]);

    expect(result.kind, AdaptiveHomeKind.empty);
    expect(result.thread, isNull);
  });

  test('prefers an active trip over a planning trip', () {
    final planning = _thread(
      id: 'planning',
      timestamp: DateTime.utc(2026, 8, 10),
      snapshot: _snapshot('In pianificazione'),
    );
    final active = _thread(
      id: 'active',
      timestamp: DateTime.utc(2026, 8, 9),
      snapshot: _snapshot('In viaggio'),
    );

    final result = resolveAdaptiveHome(<ChatThread>[planning, active]);

    expect(result.kind, AdaptiveHomeKind.active);
    expect(result.thread, same(active));
  });

  test('returns the newest planning trip when none is active', () {
    final olderPlanning = _thread(
      id: 'older-planning',
      timestamp: DateTime.utc(2026, 8, 8),
      snapshot: _snapshot('In pianificazione'),
    );
    final newerPlanning = _thread(
      id: 'newer-planning',
      timestamp: DateTime.utc(2026, 8, 11),
      snapshot: _snapshot('In pianificazione'),
    );
    final originalOrder = <ChatThread>[newerPlanning, olderPlanning];

    final result = resolveAdaptiveHome(originalOrder);

    expect(result.kind, AdaptiveHomeKind.planning);
    expect(result.thread, same(newerPlanning));
    expect(originalOrder, orderedEquals(<ChatThread>[newerPlanning, olderPlanning]));
  });
}

ChatThread _thread({
  required String id,
  required DateTime timestamp,
  TripSnapshot? snapshot,
}) {
  return ChatThread(
    summary: Conversation(
      id: id,
      title: id,
      subtitle: 'Test',
      avatar: const ChatAvatar('assets/images/travel/test.jpg'),
      timestamp: timestamp,
      lastPreview: 'Test fixture',
      snapshot: snapshot,
    ),
    script: const <ScriptedBeat>[],
  );
}

TripSnapshot _snapshot(String statusLabel) {
  return TripSnapshot(
    destinationTitle: 'Roma',
    country: 'Italia',
    durationLabel: '3 giorni',
    statusLabel: statusLabel,
    dates: '10–12 agosto',
    transport: 'Treno',
    stay: 'Centro',
    placeLabels: const <String>['Foro Romano'],
    days: const <TripDaySnapshot>[],
  );
}
