/// Configuration passed at build time with `--dart-define`.
///
/// The mobile client deliberately never knows provider keys such as Gemini or
/// openrouteservice. Those stay in a Supabase Edge Function.
class AppConfig {
  const AppConfig({
    required this.backend,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.geminiModel = 'gemini-2.5-flash',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      backend: String.fromEnvironment('ITER_BACKEND', defaultValue: 'mock'),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      geminiModel: String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: 'gemini-2.5-flash',
      ),
    );
  }


  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');


  final String backend;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String geminiModel;

  bool get usesSupabase =>
      backend == 'supabase' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
