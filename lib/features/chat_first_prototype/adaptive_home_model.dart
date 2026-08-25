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

AdaptiveHomeModel resolveAdaptiveHome(
  List<ChatThread> threads, {
  String? focusedThreadId,
}) {
  if (focusedThreadId == null) return const AdaptiveHomeModel.empty();

  ChatThread? focused;
  for (final thread in threads) {
    if (thread.summary.id == focusedThreadId) {
      focused = thread;
      break;
    }
  }
  if (focused == null) return const AdaptiveHomeModel.empty();
  if (focused.summary.snapshot?.statusLabel == 'In viaggio') {
    return AdaptiveHomeModel.active(thread: focused);
  }
  return AdaptiveHomeModel.planning(thread: focused);
}
