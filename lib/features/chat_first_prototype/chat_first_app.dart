import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/iter_theme.dart';
import 'chat_first_controller.dart';
import 'chat_first_shell.dart';
import 'data_source.dart';

const _themeModeKey = 'appearance:theme-mode:v1';

/// Top-level app for the chat-first prototype. It reuses Iter's visual theme
/// and theme persistence while keeping its own isolated controller.
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
    _loadTheme();
    _controller.loadTrendJourneys();
    _controller.restoreConversations();
  }

  Future<void> _loadTheme() async {
    try {
      final preferences = SharedPreferencesAsync();
      final saved = await preferences.getString(_themeModeKey);
      if (!mounted || saved == null) return;
      setState(() {
        _themeMode = switch (saved) {
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => ThemeMode.light,
        };
      });
    } catch (_) {
      // Unsupportable host keeps the light default.
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      final preferences = SharedPreferencesAsync();
      await preferences.setString(
        _themeModeKey,
        switch (mode) {
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
          ThemeMode.light => 'light',
        },
      );
    } catch (_) {
      // The visual preference still applies for this session.
    }
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