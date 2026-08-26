import 'package:firebase_messaging/firebase_messaging.dart';

/// OS-level notification permission state for Customer settings UI.
abstract final class TouryNotificationSettings {
  TouryNotificationSettings._();

  static bool isOsAuthorized(NotificationSettings settings) {
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static Future<NotificationSettings> readOsSettings() =>
      FirebaseMessaging.instance.getNotificationSettings();

  static Future<bool> osNotificationsEnabled() async {
    final settings = await readOsSettings();
    return isOsAuthorized(settings);
  }

  /// Requests iOS/Android notification permission when user opts in.
  static Future<bool> requestEnable() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return isOsAuthorized(settings);
  }
}
