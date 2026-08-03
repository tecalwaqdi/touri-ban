import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// إعدادات Firebase المركزية.
///
/// **Android / iOS:** يقرأ التطبيق من `google-services.json` و`GoogleService-Info.plist`.
/// لربط الإنتاج: استبدل هذين الملفين من [Firebase Console](https://console.firebase.google.com).
///
/// **Web:** تُستخدم القيم أدناه. يمكن تجاوزها عند البناء:
/// ```bash
/// flutter build web --dart-define=FIREBASE_PROJECT_ID=your-project-id \
///   --dart-define=FIREBASE_API_KEY=your-api-key \
///   --dart-define=FIREBASE_APP_ID=your-app-id \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
///   --dart-define=FIREBASE_STORAGE_BUCKET=your-bucket.firebasestorage.app
/// ```
abstract final class FirebaseAppOptions {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'tutorial-multi-language-70gx4j',
  );

  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY',
  );

  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:638010533068:web:cd138c3c2424cbef844e69',
  );

  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '638010533068',
  );

  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'tutorial-multi-language-70gx4j.firebasestorage.app',
  );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: apiKey,
        authDomain: '$projectId.firebaseapp.com',
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      );

  /// تحذير في الإصدار إذا بقي مشروع FlutterFlow التجريبي.
  static void warnIfTutorialProjectInRelease() {
    if (!kReleaseMode) return;
    if (projectId.contains('tutorial')) {
      debugPrint(
        '⚠️ Firebase: المشروع "$projectId" يبدو تجريبياً. '
        'استبدل google-services.json / GoogleService-Info.plist للإنتاج.',
      );
    }
  }
}
