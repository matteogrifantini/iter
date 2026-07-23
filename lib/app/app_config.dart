import 'package:flutter/foundation.dart';

/// Configuration passed at build time with `--dart-define`.
///
/// The mobile client deliberately never knows provider keys such as Gemini or
/// openrouteservice. Those stay in a Supabase Edge Function.
class AppConfig {
  const AppConfig({
    required this.backend,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.newTripLab = false,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      backend: String.fromEnvironment('ITER_BACKEND', defaultValue: 'mock'),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      newTripLab: bool.fromEnvironment(
        'ITER_NEW_TRIP_LAB',
        defaultValue: kDebugMode,
      ),
    );
  }

  final String backend;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool newTripLab;

  bool get usesSupabase =>
      backend == 'supabase' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
