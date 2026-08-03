import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

const _bookingChannelId = 'admin_bookings';
const _bookingChannelName = 'حجوزات جديدة';

@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push notifications for admin users when a new booking is created.
class AdminPushService {
  AdminPushService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String? _pendingOrderId;
  static StreamSubscription<User?>? _authSub;
  static StreamSubscription<UserRecord?>? _userDocSub;
  static Timer? _syncDebounce;
  static bool _syncInFlight = false;
  static String? _lastSyncedToken;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(
      adminFirebaseMessagingBackgroundHandler,
    );

    await _initLocalNotifications();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
    _messaging.onTokenRefresh.listen(_saveTokenForAdmin);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _storePendingFromMessage(initial);
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _userDocSub?.cancel();
      _userDocSub = null;
      _lastSyncedToken = null;
      if (user != null) {
        scheduleTokenSync();
        return;
      }
      await clearTokenForCurrentUser();
    });

    scheduleTokenSync();
  }

  /// Debounced FCM token sync — avoids Firestore write loops on profile stream.
  static void scheduleTokenSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 3), () {
      unawaited(syncTokenForCurrentUser());
    });
  }

  static Future<void> dispose() async {
    _syncDebounce?.cancel();
    await _userDocSub?.cancel();
    await _authSub?.cancel();
    _userDocSub = null;
    _authSub = null;
    _syncInFlight = false;
    _lastSyncedToken = null;
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        if (orderId != null && orderId.isNotEmpty) {
          _pendingOrderId = orderId;
          _tryOpenPendingBooking();
        }
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _bookingChannelId,
        _bookingChannelName,
        description: 'إشعارات الحجوزات الجديدة لمدير التطبيق',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> syncTokenForCurrentUser() async {
    if (kIsWeb || !loggedIn || _syncInFlight) return;

    var doc = currentUserDocument;
    if (doc == null && currentUserReference != null) {
      try {
        final snap = await currentUserReference!.get();
        if (snap.exists) {
          doc = UserRecord.fromSnapshot(snap);
        }
      } catch (_) {}
    }
    if (doc == null || !AdminRoleService.isSuperAdminUser(doc)) return;

    _syncInFlight = true;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _lastSyncedToken) return;
      await _saveTokenForAdmin(token);
      _lastSyncedToken = token;
    } finally {
      _syncInFlight = false;
    }
  }

  static Future<void> _saveTokenForAdmin(String token) async {
    final ref = currentUserReference;
    if (ref == null) return;

    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>? ?? {};
    final isSuperAdmin = data['IsAdmin'] == true ||
        data['isAdmin'] == true ||
        _firestoreAdminRule(data['isAdminRule']) == 1 ||
        _firestoreAdminRule(data['IsAdminRule']) == 1;
    if (!isSuperAdmin) return;

    final existing = List<String>.from(
      (data['fcm_tokens'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty),
    );
    final priorToken = data['fcm_token']?.toString();
    final needsTokenAdd = !existing.contains(token);
    if (!needsTokenAdd && priorToken == token) {
      return;
    }
    if (needsTokenAdd) {
      existing.add(token);
    }
    while (existing.length > 5) {
      existing.removeAt(0);
    }

    await ref.update({
      'fcm_token': token,
      'fcm_tokens': existing,
      'fcm_token_updated': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> clearTokenForCurrentUser() async {
    if (kIsWeb) return;

    final ref = currentUserReference;
    final token = await _messaging.getToken();
    if (ref == null || token == null || token.isEmpty) return;

    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final existing = List<String>.from(
        (data['fcm_tokens'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty && e != token),
      );

      await ref.update({
        'fcm_token': FieldValue.delete(),
        'fcm_tokens': existing,
      });
    } catch (_) {}
  }

  static void flushPendingNavigation(BuildContext context) {
    final orderId = _pendingOrderId;
    if (orderId == null || orderId.isEmpty) return;
    _pendingOrderId = null;
    _openBookingDetails(context, orderId);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final orderId = _extractOrderId(message);
    final title = message.notification?.title ?? 'حجز جديد';
    final body = message.notification?.body ??
        'يوجد حجز جديد بانتظار المراجعة والموافقة';

    _showLocalNotification(
      title: title,
      body: body,
      orderId: orderId,
    );
  }

  static void _onNotificationOpened(RemoteMessage message) {
    _storePendingFromMessage(message);
    _tryOpenPendingBooking();
  }

  static void _storePendingFromMessage(RemoteMessage message) {
    final orderId = _extractOrderId(message);
    if (orderId != null && orderId.isNotEmpty) {
      _pendingOrderId = orderId;
    }
  }

  static String? _extractOrderId(RemoteMessage message) {
    final data = message.data;
    return data['orderId']?.toString().trim().isNotEmpty == true
        ? data['orderId'].toString()
        : data['order_id']?.toString();
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? orderId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _bookingChannelId,
      _bookingChannelName,
      channelDescription: 'إشعارات الحجوزات الجديدة لمدير التطبيق',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      orderId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
      payload: orderId,
    );
  }

  static void _tryOpenPendingBooking() {
    final context = appNavigatorKey.currentContext;
    if (context == null || !loggedIn) return;

    final doc = currentUserDocument;
    if (doc == null || !AdminRoleService.isSuperAdminUser(doc)) return;

    flushPendingNavigation(context);
  }

  static void _openBookingDetails(BuildContext context, String orderId) {
    final ref = FirebaseFirestore.instance.collection('order').doc(orderId);
    context.pushNamed(
      AdminBookingDetailsWidget.routeName,
      queryParameters: {
        'idbokeng': serializeParam(
          ref,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  static int? _firestoreAdminRule(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
