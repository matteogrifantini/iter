import 'package:flutter/material.dart';

import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'iter_ui_primitives.dart';

class ChatFirstListScreen extends StatelessWidget {
  const ChatFirstListScreen({
    super.key,
    required this.controller,
    required this.onOpenThread,
  });

  final ChatFirstPrototypeController controller;
  final ValueChanged<ChatThread> onOpenThread;

  @override
  Widget build(BuildContext context) {
    final threads = List<ChatThread>.of(controller.threads);
    threads.sort((a, b) => b.summary.timestamp.compareTo(a.summary.timestamp));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 128),
        children: <Widget>[
          IterSectionHeading(
            key: const Key('trips-heading'),
            eyebrow: 'Le tue rotte',
            title: 'Viaggi',
            trailing: Tooltip(
              message: 'Nuova chat',
              child: TextButton.icon(
                key: const Key('trips-new-chat'),
                onPressed: () => _startNewChat(context),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Nuova chat'),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (threads.isEmpty)
            _EmptyChats(onStart: () => _startNewChat(context))
          else
            for (var index = 0; index < threads.length; index++) ...<Widget>[
              _ConversationTile(
                thread: threads[index],
                onTap: () {
                  controller.openConversation(threads[index].summary.id);
                  onOpenThread(threads[index]);
                },
              ),
              if (index != threads.length - 1)
                const Divider(height: 24, indent: 82),
            ],
        ],
      ),
    );
  }

  /// Opens the free-talk thread directly: no destination picker, the traveler
  /// starts with their own words. Mirrors [ChatFirstShell._startAnotherFreeTalk].
  void _startNewChat(BuildContext context) {
    final thread = controller.startFreeTalk();
    onOpenThread(thread);
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = thread.summary;
    final hasUnread = summary.unread > 0;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.primary, width: 2),
        ),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: colors.surfaceContainerHighest,
          backgroundImage: AssetImage(summary.avatar.asset),
        ),
      ),
      title: Text(
        summary.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          summary.lastPreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: hasUnread ? colors.onSurface : colors.onSurfaceVariant,
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _shortTime(summary.timestamp),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: hasUnread ? colors.primary : colors.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${summary.unread}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _shortTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/travel/rail_coast.jpg',
            width: double.infinity,
            height: 170,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Nessuna conversazione ancora',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Racconta a Iter una destinazione o un momento: da qui nasce '
          'il prossimo viaggio.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Inizia una nuova chat'),
        ),
      ],
    );
  }
}
