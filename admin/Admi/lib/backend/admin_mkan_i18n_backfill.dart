import '/backend/admin_i18n_backfill.dart';

export 'admin_i18n_backfill.dart'
    show AdminI18nBackfill, I18nBackfillResult, I18nBackfillProgress;

/// للتوافق مع الاستدعاءات القديمة — يعيد عدد المعالم فقط.
Future<int> touryBackfillMkanI18n({
  int batchSize = 400,
  void Function(String message)? onProgress,
}) async {
  final result = await AdminI18nBackfill.run(
    batchSize: batchSize,
    onProgress: onProgress,
  );
  if (!result.success) {
    throw Exception(result.error ?? 'backfill failed');
  }
  return result.landmarks;
}
