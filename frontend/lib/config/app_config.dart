// lib/config/app_config.dart

/// Centralized ZeroMile Go Application Configuration
/// Handles environment variables from .env files, dart-define, or runtime configuration.
class AppConfig {
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String defaultOneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );
  static const bool defaultIsDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  static String _supabaseUrl = defaultSupabaseUrl;
  static String _supabaseAnonKey = defaultSupabaseAnonKey;
  static String _oneSignalAppId = defaultOneSignalAppId;
  static bool _isDemoMode = defaultIsDemoMode;

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get oneSignalAppId => _oneSignalAppId;
  static bool get isDemoMode => _isDemoMode;

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
    if (envMap.containsKey('DEMO_MODE')) {
      _isDemoMode = envMap['DEMO_MODE']!.toLowerCase() == 'true';
    }
  }

  /// Override configuration manually (useful for testing or runtime environment switches)
  static void override({
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? oneSignalAppId,
    bool? isDemoMode,
  }) {
    if (supabaseUrl != null && supabaseUrl.isNotEmpty) _supabaseUrl = supabaseUrl;
    if (supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) _supabaseAnonKey = supabaseAnonKey;
    if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) _oneSignalAppId = oneSignalAppId;
    if (isDemoMode != null) _isDemoMode = isDemoMode;
  }
}
