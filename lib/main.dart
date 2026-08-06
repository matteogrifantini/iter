import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_config.dart';
import 'app/iter_app.dart';
import 'features/chat_first_prototype/chat_first_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  if (config.usesSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }

  runApp(
    config.chatFirstPrototype
        ? const ChatFirstPrototypeApp()
        : IterApp(config: config),
  );
}
