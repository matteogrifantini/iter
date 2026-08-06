import 'package:flutter/material.dart';

import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_home_screen.dart';
import 'chat_first_list_screen.dart';
import 'chat_first_models.dart';
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
                journeys: controller.trendJourneys,
                resumable: controller.threads.take(2).toList(growable: false),
                onStartChat: (journey) => _startFromJourney(context, journey),
                onResume: (thread) => _openThread(context, thread),
                onOpenChats: () => setState(() => _tabIndex = 1),
                unread: controller.unread,
                poisLoader: controller.poisFor,
              ),
              ChatFirstListScreen(
                controller: controller,
                onOpenThread: (thread) => _openThread(context, thread),
              ),
              ChatFirstProfileScreen(
                themeMode: widget.themeMode,
                onThemeChanged: widget.onThemeChanged,
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

  void _startFromJourney(BuildContext context, JourneyRoute journey) {
    final thread = widget.controller.startFromJourney(journey);
    _openThread(context, thread);
  }

  void _openThread(BuildContext context, ChatThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatFirstThreadScreen(
          controller: widget.controller,
          conversationId: thread.summary.id,
          onOpenSnapshot: (summary) => _openSnapshot(context, summary),
        ),
      ),
    );
  }

  void _openSnapshot(BuildContext context, TripSnapshot snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripSnapshotScreen(snapshot: snapshot),
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
          label: 'Chat',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profilo',
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
    return child;
  }
}