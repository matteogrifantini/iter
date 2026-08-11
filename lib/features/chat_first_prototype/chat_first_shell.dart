import 'package:flutter/material.dart';

import 'adaptive_home_model.dart';
import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_home_screen.dart';
import 'chat_first_list_screen.dart';
import 'chat_first_profile_screen.dart';
import 'chat_first_thread_screen.dart';
import 'trip_snapshot_screen.dart';

/// Bottom navigation with WhatsApp-style chat grammar and Iter's identity.
class ChatFirstShell extends StatefulWidget {
  const ChatFirstShell({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ChatFirstPrototypeController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<ChatFirstShell> createState() => _ChatFirstShellState();
}

class _ChatFirstShellState extends State<ChatFirstShell> {
  var _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          body: IndexedStack(
            index: _tabIndex,
            children: <Widget>[
              ChatFirstHomeScreen(
                model: resolveAdaptiveHome(controller.threads),
                onSubmitIntent: (intent) =>
                    _startFreeTalkWithText(context, intent),
                onVoiceIntent: () => _startFreeTalkWithVoice(context),
                onPhotoIntent: (asset) =>
                    _startFreeTalkWithPhoto(context, asset),
                onOpenThread: (thread) => _openThread(context, thread),
                onOpenTrips: () => setState(() => _tabIndex = 1),
                onStartAnotherJourney: () => _startAnotherFreeTalk(context),
                unread: controller.unread,
              ),
              ChatFirstListScreen(
                controller: controller,
                onOpenThread: (thread) => _openThread(context, thread),
              ),
              ChatFirstProfileScreen(
                themeMode: widget.themeMode,
                onThemeChanged: widget.onThemeChanged,
                memoryTags: widget.controller.memoryTags,
                onOpenChats: () => setState(() => _tabIndex = 1),
              ),
            ],
          ),
          bottomNavigationBar: _ChatBottomNavigation(
            currentIndex: _tabIndex,
            unread: widget.controller.unread,
            onChanged: (index) => setState(() => _tabIndex = index),
          ),
        );
      },
    );
  }

  Future<void> _startFreeTalkWithText(
    BuildContext context,
    String intent,
  ) async {
    final thread = await widget.controller.submitHomeIntent(intent);
    if (context.mounted) _openThread(context, thread);
  }

  Future<void> _startAnotherFreeTalk(BuildContext context) async {
    final thread = widget.controller.startFreeTalk();
    if (context.mounted) _openThread(context, thread);
  }

  void _startFreeTalkWithVoice(BuildContext context) {
    final thread = widget.controller.startFreeTalk();
    _openThread(context, thread);
    widget.controller.sendAudio();
  }

  void _startFreeTalkWithPhoto(BuildContext context, String asset) {
    final thread = widget.controller.startFreeTalk();
    _openThread(context, thread);
    widget.controller.sendMedia(asset: asset, isVideo: false);
  }

  void _openThread(BuildContext context, ChatThread thread) {
    widget.controller.openConversation(thread.summary.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatFirstThreadScreen(
          controller: widget.controller,
          conversationId: thread.summary.id,
          onOpenSnapshot: (_) => _openSnapshot(context, thread.summary.id),
        ),
      ),
    );
  }

  void _openSnapshot(BuildContext context, String conversationId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripSnapshotScreen(
          controller: widget.controller,
          conversationId: conversationId,
        ),
      ),
    );
  }
}

class _ChatBottomNavigation extends StatelessWidget {
  const _ChatBottomNavigation({
    required this.currentIndex,
    required this.unread,
    required this.onChanged,
  });

  final int currentIndex;
  final int unread;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      destinations: <NavigationDestination>[
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Oggi',
        ),
        NavigationDestination(
          icon: _UnreadIcon(unread: unread, icon: Icons.chat_bubble_outline),
          selectedIcon: _UnreadIcon(unread: unread, icon: Icons.chat_bubble),
          label: 'Viaggi',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Tu',
        ),
      ],
    );
  }
}

class _UnreadIcon extends StatelessWidget {
  const _UnreadIcon({required this.unread, required this.icon});

  final int unread;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget child = Icon(icon);
    if (unread > 0) {
      child = Badge.count(
        count: unread,
        backgroundColor: colors.primary,
        textColor: colors.onPrimary,
        child: child,
      );
    }
    return Semantics(
      label: unread > 0 ? 'Viaggi, $unread messaggi non letti' : 'Viaggi',
      child: child,
    );
  }
}
