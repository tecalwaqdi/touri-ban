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

Stream<UserTokenInfo> getFcmTokenStream(String userPath) =>
    Stream.value(!kIsWeb && (Platform.isIOS || Platform.isAndroid))
        .where((shouldGetToken) => shouldGetToken)
        .asyncMap<String?>(
            (_) => FirebaseMessaging.instance.requestPermission().then(
                  (settings) => settings.authorizationStatus ==
                          AuthorizationStatus.authorized
                      ? FirebaseMessaging.instance.getToken()
                      : null,
                ))
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

final fcmTokenUserStream = authenticatedUserStream
    .where((user) => user != null)
    .map((user) => user!.reference.path)
    .distinct()
    .switchMap(getFcmTokenStream)
    .asyncMap((userTokenInfo) async {
      final deviceType = Platform.isIOS ? 'iOS' : 'Android';
      final result = await makeCloudCall(
        'addFcmToken',
        {
          'userDocPath': userTokenInfo.userPath,
          'fcmToken': userTokenInfo.fcmToken,
          'deviceType': deviceType,
        },
      );
      if (result.containsKey('error') || result.containsKey('code')) {
        try {
          await persistFcmTokenToFirestore(
            userPath: userTokenInfo.userPath,
            fcmToken: userTokenInfo.fcmToken,
            deviceType: deviceType,
          );
        } catch (e) {
          debugPrint('persistFcmTokenToFirestore failed: $e');
        }
      }
      return result;
    });

void triggerPushNotification({
  required String? notificationTitle,
  required String? notificationText,
  String? notificationImageUrl,
  DateTime? scheduledTime,
  String? notificationSound,
  required List<DocumentReference> userRefs,
  required String initialPageName,
  required Map<String, dynamic> parameterData,
}) {
  if ((notificationTitle ?? '').isEmpty || (notificationText ?? '').isEmpty) {
    return;
  }
  final serializedParameterData = serializeParameterData(parameterData);
  final pushNotificationData = {
    'notification_title': notificationTitle,
    'notification_text': notificationText,
    if (notificationImageUrl != null)
      'notification_image_url': notificationImageUrl,
    if (scheduledTime != null) 'scheduled_time': scheduledTime,
    if (notificationSound != null) 'notification_sound': notificationSound,
    'user_refs': userRefs.map((u) => u.path).join(','),
    'initial_page_name': initialPageName,
    'parameter_data': serializedParameterData,
    'sender': currentUserReference,
    'timestamp': DateTime.now(),
  };
  FirebaseFirestore.instance
      .collection(kUserPushNotificationsCollectionName)
      .doc()
      .set(pushNotificationData);
}
