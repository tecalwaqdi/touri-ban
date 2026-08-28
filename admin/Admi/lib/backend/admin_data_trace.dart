import 'package:flutter/foundation.dart';

/// QA-only Firestore/query timing trace (no document payloads, no tokens).
abstract final class AdminDataTrace {
  static const enabled = kDebugMode;

  static void log({
    required String route,
    required String queryName,
    required String collection,
    String? scope,
    int? filterCount,
    int? docsReturned,
    int? durationMs,
    String? source,
    String? errorCategory,
  }) {
    if (!enabled) return;
    debugPrint(
      '[AdminDataTrace] route=$route query=$queryName collection=$collection '
      'scope=${scope ?? '-'} filters=${filterCount ?? '-'} '
      'docs=${docsReturned ?? '-'} ms=${durationMs ?? '-'} '
      'source=${source ?? '-'} err=${errorCategory ?? '-'}',
    );
  }
}
