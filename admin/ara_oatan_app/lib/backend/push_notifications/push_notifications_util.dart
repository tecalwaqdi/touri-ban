import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'serialization_util.dart';
import '../../auth/firebase_auth/auth_util.dart';
import '../cloud_functions/cloud_functions.dart';

import 'package:flutter/foundation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

export 'push_notifications_handler.dart';
export 'serialization_util.dart';

const kUserPushNotificationsCollectionName = 'ff_user_push_notifications';

class UserTokenInfo {
  const UserTokenInfo(this.userPath, this.fcmToken);
  final String userPath;
  final String fcmToken;
}

/// Request permission, wait for APNs on iOS, then return an FCM token.
Future<String?> obtainFcmToken() async {
  if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return null;
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: true,
  );
  final status = settings.authorizationStatus;
  if (status != AuthorizationStatus.authorized &&
      status != AuthorizationStatus.provisional) {
    return null;
  }
  if (Platform.isIOS) {
    for (var i = 0; i < 8; i++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }
  return messaging.getToken();
}

Stream<UserTokenInfo> getFcmTokenStream(String userPath) =>
    Stream.value(!kIsWeb && (Platform.isIOS || Platform.isAndroid))
        .where((shouldGetToken) => shouldGetToken)
        .asyncMap<String?>((_) => obtainFcmToken())
        .switchMap((fcmToken) => Stream.value(fcmToken)
            .merge(FirebaseMessaging.instance.onTokenRefresh))
        .where((fcmToken) => fcmToken != null && fcmToken.isNotEmpty)
        .map((token) => UserTokenInfo(userPath, token!));

Future<void> persistFcmTokenToFirestore({
  required String userPath,
  required String fcmToken,
  required String deviceType,
}) async {
  if (userPath.split('/').length < 2 || fcmToken.isEmpty) {
    return;
  }
  final userRef = FirebaseFirestore.instance.doc(userPath);
  final tokenDocId = 'tok_${fcmToken.hashCode.abs().toRadixString(16)}';
  await userRef.collection('fcm_tokens').doc(tokenDocId).set({
    'fcm_token': fcmToken,
    'device_type': deviceType,
    'created_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

/// Register FCM token for the signed-in user (direct write + CF dedupe).
Future<void> registerFcmTokenForCurrentUser() async {
  final user = currentUserReference;
  if (user == null) return;
  final token = await obtainFcmToken();
  if (token == null || token.isEmpty) return;
  final deviceType = Platform.isIOS ? 'iOS' : 'Android';
  try {
    await persistFcmTokenToFirestore(
      userPath: user.path,
      fcmToken: token,
      deviceType: deviceType,
    );
  } catch (e) {
    debugPrint('persistFcmTokenToFirestore failed: $e');
  }
  await makeCloudCall(
    'addFcmToken',
    {
      'userDocPath': user.path,
      'fcmToken': token,
      'deviceType': deviceType,
    },
  );
}

final fcmTokenUserStream = authenticatedUserStream
    .where((user) => user != null)
    .map((user) => user!.reference.path)
    .distinct()
    .switchMap(getFcmTokenStream)
    .asyncMap((userTokenInfo) async {
      final deviceType = Platform.isIOS ? 'iOS' : 'Android';
      // Always write under the user doc (rules allow owner writes). CF is
      // best-effort dedupe across users for the same physical token.
      try {
        await persistFcmTokenToFirestore(
          userPath: userTokenInfo.userPath,
          fcmToken: userTokenInfo.fcmToken,
          deviceType: deviceType,
        );
      } catch (e) {
        debugPrint('persistFcmTokenToFirestore failed: $e');
      }
      return makeCloudCall(
        'addFcmToken',
        {
          'userDocPath': userTokenInfo.userPath,
          'fcmToken': userTokenInfo.fcmToken,
          'deviceType': deviceType,
        },
      );
    });

void triggerPushNotification({
  String? notificationTitle,
  String? notificationText,
  String? notificationType,
  Map<String, String>? notificationPayload,
  String? notificationImageUrl,
  DateTime? scheduledTime,
  String? notificationSound,
  required List<DocumentReference> userRefs,
  required String initialPageName,
  required Map<String, dynamic> parameterData,
}) {
  final type = (notificationType ?? '').trim();
  if (type.isEmpty &&
      ((notificationTitle ?? '').isEmpty ||
          (notificationText ?? '').isEmpty)) {
    return;
  }
  if (userRefs.isEmpty) return;
  final serializedParameterData = serializeParameterData(parameterData);
  // Client creates on ff_user_push_notifications are denied by rules;
  // enqueue via trusted callable so sendUserPushNotificationsTrigger runs.
  DocumentReference? orderRef;
  final rawOrder = parameterData['idorder'] ?? parameterData['id'];
  if (rawOrder is DocumentReference) {
    orderRef = rawOrder;
  }
  final payload = <String, dynamic>{
    if (type.isNotEmpty) 'notificationType': type,
    if (notificationPayload != null && notificationPayload.isNotEmpty)
      'notificationPayload': notificationPayload,
    if (type.isEmpty && (notificationTitle ?? '').isNotEmpty)
      'notificationTitle': notificationTitle,
    if (type.isEmpty && (notificationText ?? '').isNotEmpty)
      'notificationText': notificationText,
    if (notificationImageUrl != null)
      'notificationImageUrl': notificationImageUrl,
    if (notificationSound != null) 'notificationSound': notificationSound,
    'userRefs': userRefs.map((u) => u.path).toList(),
    'initialPageName': initialPageName,
    'parameterData': serializedParameterData,
    if (orderRef != null) 'orderPath': orderRef.path,
  };
  // Legacy scheduled_time path is unused for user pushes; ignore scheduledTime.
  // Fire-and-forget — never block chat / trip UI on push delivery.
  // ignore: unawaited_futures
  makeCloudCall('enqueueUserPushNotification', payload);
}
