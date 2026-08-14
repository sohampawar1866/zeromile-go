// lib/config/app_config.dart

/// Centralized ZeroMile Go Application Configuration
/// Handles environment variables from .env files, dart-define, or runtime configuration.
class AppConfig {
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lqfedsbgbxsniyzgcmvx.supabase.co',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZmVkc2JnYnhzbml5emdjbXZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MjA2NDYsImV4cCI6MjEwMjI5NjY0Nn0.nGw80aonCWz2mP2HhZQokkK2vbcb4Z2yhq8yne5AnCM',
  );
  static const String defaultOneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'your-onesignal-app-id-here',
  );

  static String _supabaseUrl = defaultSupabaseUrl;
  static String _supabaseAnonKey = defaultSupabaseAnonKey;
  static String _oneSignalAppId = defaultOneSignalAppId;

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get oneSignalAppId => _oneSignalAppId;

  /// Loads configuration from a provided Map (e.g. from flutter_dotenv or .env file)
  static void loadFromEnv(Map<String, String> envMap) {
    if (envMap.containsKey('SUPABASE_URL') && envMap['SUPABASE_URL']!.isNotEmpty) {
      _supabaseUrl = envMap['SUPABASE_URL']!;
    }
    if (envMap.containsKey('SUPABASE_ANON_KEY') && envMap['SUPABASE_ANON_KEY']!.isNotEmpty) {
      _supabaseAnonKey = envMap['SUPABASE_ANON_KEY']!;
    }
    if (envMap.containsKey('ONESIGNAL_APP_ID') && envMap['ONESIGNAL_APP_ID']!.isNotEmpty) {
      _oneSignalAppId = envMap['ONESIGNAL_APP_ID']!;
    }
  }

  /// Override configuration manually (useful for testing or runtime environment switches)
  static void override({
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? oneSignalAppId,
  }) {
    if (supabaseUrl != null && supabaseUrl.isNotEmpty) _supabaseUrl = supabaseUrl;
    if (supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) _supabaseAnonKey = supabaseAnonKey;
    if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) _oneSignalAppId = oneSignalAppId;
  }
}
