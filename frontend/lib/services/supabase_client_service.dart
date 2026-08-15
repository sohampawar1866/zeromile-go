// lib/services/supabase_client_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseClientService {
  static SupabaseClientService? _instance;
  late final SupabaseClient client;

  SupabaseClientService._internal(this.client);

  static SupabaseClientService get instance {
    if (_instance == null) {
      try {
        _instance = SupabaseClientService._internal(Supabase.instance.client);
      } catch (_) {
        final fallbackClient = SupabaseClient(
          AppConfig.supabaseUrl,
          AppConfig.supabaseAnonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        _instance = SupabaseClientService._internal(fallbackClient);
      }
    }
    return _instance!;
  }

  static Future<SupabaseClientService> initialize({
    String? url,
    String? anonKey,
  }) async {
    if (_instance != null) return _instance!;

    final targetUrl = url ?? AppConfig.supabaseUrl;
    final targetAnonKey = anonKey ?? AppConfig.supabaseAnonKey;

    try {
      await Supabase.initialize(
        url: targetUrl,
        // ignore: deprecated_member_use
        anonKey: targetAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 20,
        ),
      );
      _instance = SupabaseClientService._internal(Supabase.instance.client);
    } catch (_) {
      final fallbackClient = SupabaseClient(targetUrl, targetAnonKey);
      _instance = SupabaseClientService._internal(fallbackClient);
    }

    return _instance!;
  }

  /// Injects a custom or mock SupabaseClient (useful for unit & integration testing)
  static void setMockInstance(SupabaseClient customClient) {
    _instance = SupabaseClientService._internal(customClient);
  }

  /// Resets singleton state
  static void reset() {
    _instance = null;
  }
}
