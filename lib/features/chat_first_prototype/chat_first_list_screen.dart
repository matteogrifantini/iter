import 'package:flutter/material.dart';

import '../../models/trip_models.dart' show JourneyRoute;
import '../../widgets/journey_media.dart';
import 'chat_first_controller.dart';
import 'chat_first_data.dart';

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
    threads.sort(
      (a, b) => b.summary.timestamp.compareTo(a.summary.timestamp),
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: threads.isEmpty
            ? _EmptyChats(onStart: () => _showNewChat(context))
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: threads.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 82),
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return _ConversationTile(
                    thread: thread,
                    onTap: () {
                      controller.openConversation(thread.summary.id);
                      onOpenThread(thread);
                    },
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNewChat(context),
          tooltip: 'Nuova chat',
          elevation: 0,
          child: const Icon(Icons.chat_outlined),
        ),
      ),
    );
  }

  Future<void> _showNewChat(BuildContext context) async {
    final journey = await showModalBottomSheet<JourneyRoute>(
      context: context,
      builder: (context) {
        final trends = controller.trendJourneys;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Con chi vuoi parlare?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final item in trends)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(
                      DemoMedia.postersForDestination(
                        item.destinationIds.first,
                      ).first,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.durationLabel),
                  onTap: () => Navigator.of(context).pop(item),
                ),
            ],
          ),
        );
      },
    );
    if (journey == null) return;
    final thread = controller.startFromJourney(journey);
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/travel/rail_coast.jpg',
                width: 240,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nessuna conversazione ancora',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Parla con Iter di una destinazione: qui ritrovi i piani '
                  'in corso e i promemoria.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Inizia una nuova chat'),
            ),
          ],
        ),
      ),
    );
  }
}