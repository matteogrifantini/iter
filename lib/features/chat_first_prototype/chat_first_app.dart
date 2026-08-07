import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../app/iter_theme.dart';
import 'chat_first_controller.dart';
import 'chat_first_shell.dart';
import 'data_source.dart';

/// Top-level app for the chat-first prototype. It reuses Iter's visual theme
/// while keeping its own isolated controller; the theme now lives on the
/// controller (light default on mock, persisted `profiles.theme_mode` on
/// Supabase) instead of SharedPreferences.
class ChatFirstPrototypeApp extends StatefulWidget {
  const ChatFirstPrototypeApp({super.key});

  @override
  State<ChatFirstPrototypeApp> createState() => _ChatFirstPrototypeAppState();
}

class _ChatFirstPrototypeAppState extends State<ChatFirstPrototypeApp> {
  late final ChatFirstPrototypeController _controller;
  var _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _controller = ChatFirstPrototypeController(dataSource: resolveDataSource());
    _loadProfile();
    _controller.loadTrendJourneys();
    _controller.restoreConversations();
  }

  Future<void> _loadProfile() async {
    await _controller.loadProfile();
    if (!mounted) return;
    setState(() => _themeMode = _controller.themeMode);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await _controller.setThemeMode(mode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iter',
      debugShowCheckedModeBanner: false,
      theme: IterTheme.light(),
      darkTheme: IterTheme.dark(),
      themeMode: _themeMode,
      locale: const Locale('it'),
      supportedLocales: const <Locale>[Locale('it')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ChatFirstShell(
        controller: _controller,
        themeMode: _themeMode,
        onThemeChanged: _setTheme,
      ),
    );
  }
}