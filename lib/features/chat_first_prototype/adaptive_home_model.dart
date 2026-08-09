import 'package:flutter/foundation.dart';

import 'chat_first_data.dart';

enum AdaptiveHomeKind { empty, planning, active }

@immutable
class AdaptiveHomeModel {
  const AdaptiveHomeModel.empty() : this._(kind: AdaptiveHomeKind.empty);

  const AdaptiveHomeModel.planning({required ChatThread thread})
      : this._(kind: AdaptiveHomeKind.planning, thread: thread);

  const AdaptiveHomeModel.active({required ChatThread thread})
      : this._(kind: AdaptiveHomeKind.active, thread: thread);

  const AdaptiveHomeModel._({required this.kind, this.thread});

  final AdaptiveHomeKind kind;
  final ChatThread? thread;
}

AdaptiveHomeModel resolveAdaptiveHome(List<ChatThread> threads) {
  for (final thread in threads) {
    if (thread.summary.snapshot?.statusLabel == 'In viaggio') {
      return AdaptiveHomeModel.active(thread: thread);
    }
  }

  ChatThread? newestPlanning;
  for (final thread in threads) {
    if (thread.summary.snapshot?.statusLabel != 'In pianificazione') continue;
    if (newestPlanning == null ||
        thread.summary.timestamp.isAfter(newestPlanning.summary.timestamp)) {
      newestPlanning = thread;
    }
  }

  if (newestPlanning != null) {
    return AdaptiveHomeModel.planning(thread: newestPlanning);
  }
  return const AdaptiveHomeModel.empty();
}
