// lib/services/push_notification_service.dart

import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static const String defaultOneSignalAppId = '00000000-0000-0000-0000-000000000000';

  static Future<void> initialize({
    String appId = defaultOneSignalAppId,
    void Function(Map<String, dynamic> data)? onNotificationClicked,
  }) async {
    try {
      // 1. Set Log Level
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // 2. Initialize OneSignal
      OneSignal.initialize(appId);

      // 3. Request Notification Permission
      OneSignal.Notifications.requestPermission(true);

      // 4. Set Notification Click Listener
      OneSignal.Notifications.addClickListener((event) {
        final additionalData = event.notification.additionalData;
        if (additionalData != null && onNotificationClicked != null) {
          onNotificationClicked(Map<String, dynamic>.from(additionalData));
        }
      });
    } catch (_) {
      // Graceful fallback for headless environments or unsupported platforms
    }
  }

  /// Map Supabase User ID and set topic tags
  static Future<void> syncUserContext({
    required String userId,
    required String domainId,
    String? activeGroupId,
    String role = 'PARTICIPANT', // SUPERADMIN, GROUP_LEADER, PARTICIPANT
  }) async {
    try {
      // 1. Identify User in OneSignal
      await OneSignal.login(userId);

      // 2. Set Domain & Group Tags
      await OneSignal.User.addTags({
        'domain_id': domainId,
        if (activeGroupId != null) 'active_group_id': activeGroupId,
        'role': role,
      });
    } catch (_) {
      // Fallback
    }
  }

  /// Remove tags when exiting or concluding event
  static Future<void> clearUserTags() async {
    try {
      await OneSignal.User.removeTags(['domain_id', 'active_group_id', 'role']);
    } catch (_) {
      // Fallback
    }
  }
}
