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
const _driverReviewChannelId = 'admin_driver_reviews';
const _driverReviewChannelName = 'مراجعات المناديب';

@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push notifications for admin: bookings + driver registration reviews.
class AdminPushService {
  AdminPushService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String? _pendingOrderId;
  static String? _pendingDriverId;
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
        final payload = response.payload ?? '';
        if (payload.startsWith('driver:')) {
          _pendingDriverId = payload.substring('driver:'.length);
          _tryOpenPending();
          return;
        }
        if (payload.isNotEmpty) {
          _pendingOrderId = payload;
          _tryOpenPending();
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
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _driverReviewChannelId,
        _driverReviewChannelName,
        description: 'إشعارات طلبات تسجيل المناديب',
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
    if (doc == null) return;
    final canReceiveDriverReviewPush =
        AdminRoleService.isSuperAdminUser(doc) ||
            AdminRoleService.isCountryAgent ||
            AdminRoleService.isSuperAdmin;
    if (!canReceiveDriverReviewPush) return;

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
    final isCountryAdmin = data['isagent'] == true ||
        data['Isagent'] == true ||
        AdminRoleService.isCountryAgent;
    if (!isSuperAdmin && !isCountryAdmin) return;

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
    final driverId = _pendingDriverId;
    if (driverId != null && driverId.isNotEmpty) {
      _pendingDriverId = null;
      _openDriverReview(context, driverId);
      return;
    }
    final orderId = _pendingOrderId;
    if (orderId == null || orderId.isEmpty) return;
    _pendingOrderId = null;
    _openBookingDetails(context, orderId);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString();
    final driverId = _extractDriverId(message);
    final orderId = _extractOrderId(message);
    final title = message.notification?.title ??
        (driverId != null ? 'طلب مندوب' : 'حجز جديد');
    final body = message.notification?.body ??
        (driverId != null
            ? 'طلب تسجيل مندوب بانتظار المراجعة'
            : 'يوجد حجز جديد بانتظار المراجعة والموافقة');

    _showLocalNotification(
      title: title,
      body: body,
      payload: driverId != null
          ? 'driver:$driverId'
          : (orderId ?? ''),
      channelId: type.contains('driver_application')
          ? _driverReviewChannelId
          : _bookingChannelId,
      channelName: type.contains('driver_application')
          ? _driverReviewChannelName
          : _bookingChannelName,
    );
  }

  static void _onNotificationOpened(RemoteMessage message) {
    _storePendingFromMessage(message);
    _tryOpenPending();
  }

  static void _storePendingFromMessage(RemoteMessage message) {
    final driverId = _extractDriverId(message);
    if (driverId != null && driverId.isNotEmpty) {
      _pendingDriverId = driverId;
      return;
    }
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

  static String? _extractDriverId(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    if (!type.startsWith('driver_application') &&
        data['target']?.toString() != 'driver_review') {
      // Still allow explicit driverId + DriverActivation page.
      if ((data['initialPageName'] ?? '') != 'DriverActivation') {
        return null;
      }
    }
    final id = data['driverId']?.toString().trim();
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    String channelId = _bookingChannelId,
    String channelName = _bookingChannelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'إشعارات لوحة الإدارة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      payload.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _tryOpenPending() {
    final context = appNavigatorKey.currentContext;
    if (context == null || !loggedIn) return;

    final doc = currentUserDocument;
    if (doc == null) return;
    final ok = AdminRoleService.isSuperAdminUser(doc) ||
        AdminRoleService.isCountryAgent ||
        AdminRoleService.isSuperAdmin;
    if (!ok) return;

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

  static void _openDriverReview(BuildContext context, String driverId) {
    final ref = FirebaseFirestore.instance.collection('user').doc(driverId);
    context.pushNamed(
      DriverActivationWidget.routeName,
      queryParameters: {
        'dre': serializeParam(ref, ParamType.DocumentReference),
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
