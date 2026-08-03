import 'package:cloud_firestore/cloud_firestore.dart';

/// إعدادات كاش التطبيق — ميزانية إجمالية مستهدفة ~500 ميجا.
abstract final class TouryCacheConfig {
  TouryCacheConfig._();

  /// الميزانية الكلية المستهدفة (ميجابايت).
  static const int targetBudgetMb = 500;

  /// Firestore: القيمة الحرفية 500MB غير مدعومة من SDK (الحد الصريح 100MB).
  /// `CACHE_SIZE_UNLIMITED` يسمح بأكبر كاش محلي ممكن على الجوال.
  static const int firestoreCacheBytes = Settings.CACHE_SIZE_UNLIMITED;

  /// صور الشبكة: ~500 ميجا قرص (تقريباً 2500 صورة × 200KB).
  static const int imageDiskBudgetMb = targetBudgetMb;
  static const int imageMaxCacheObjects = 2500;
}
