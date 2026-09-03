import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../app/app_config.dart';
import '../../app/iter_theme.dart';
import 'chat_first_controller.dart';
import 'chat_first_shell.dart';
import 'data_source.dart';
import 'gemini_ai_service.dart';

/// Top-level app for the chat-first prototype. It reuses Iter's visual theme
/// while keeping its own isolated controller; the theme now lives on the
/// controller (light default on mock, persisted `profiles.theme_mode` on
/// Supabase) instead of SharedPreferences. It observes [WidgetsBinding] so a
/// resume after an external purchase can ask the traveler to settle it.
class ChatFirstPrototypeApp extends StatefulWidget {
  const ChatFirstPrototypeApp({super.key, this.controller});

  /// Optional injected controller for tests and hosting; a null value builds
  /// the isolated demo controller as before.
  final ChatFirstPrototypeController? controller;

  @override
  State<ChatFirstPrototypeApp> createState() => _ChatFirstPrototypeAppState();
}

class _ChatFirstPrototypeAppState extends State<ChatFirstPrototypeApp>
    with WidgetsBindingObserver {
  late final ChatFirstPrototypeController _controller;
  var _themeMode = ThemeMode.light;
  var _ownsController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
    } else {
      final config = AppConfig.fromEnvironment();
      final dataSource = resolveDataSource();
      final aiService = GeminiAiService(config: config);
      _controller = ChatFirstPrototypeController(
        dataSource: dataSource,
        aiService: aiService,
      );
      _ownsController = true;
    }
    _loadProfile();
    _controller.loadTrendJourneys();
    _controller.restoreConversations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.handleAppLifecycleState(state);
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
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) _controller.dispose();
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
