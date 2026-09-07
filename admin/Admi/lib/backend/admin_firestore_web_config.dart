import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// PERF-P4C — explicit Admin Firestore Web transport / cache policy.
///
/// Settings must be applied once in [initFirebase] **before** any Firestore use.
/// Dart-defines (optional A/B):
/// - TOURI_FS_WEB_PERSISTENCE (default true — false regresses Settlements)
/// - TOURI_FS_AUTO_LONG_POLL (default false — only enable if measured faster)
/// - TOURI_FS_FORCE_LONG_POLL (default false — often slower)
abstract final class AdminFirestoreWebConfig {
  AdminFirestoreWebConfig._();

  /// Web IndexedDB persistence.
  ///
  /// P4C measured `false` (memory-only): Finance Hub improved (~1112 ms) but
  /// Settlements live first-paint regressed ~324 → ~1363 ms. Stop-rule Y:
  /// keep persistence **enabled** (P4B behavior). Session reuse still uses
  /// P3 repository TTL 180s. Override only for A/B:
  /// `--dart-define=TOURI_FS_WEB_PERSISTENCE=false`.
  static const bool webPersistenceEnabled = bool.fromEnvironment(
    'TOURI_FS_WEB_PERSISTENCE',
    defaultValue: true,
  );

  static const bool webAutoDetectLongPolling = bool.fromEnvironment(
    'TOURI_FS_AUTO_LONG_POLL',
    defaultValue: false,
  );

  static const bool webForceLongPolling = bool.fromEnvironment(
    'TOURI_FS_FORCE_LONG_POLL',
    defaultValue: false,
  );

  static int settingsApplyCount = 0;

  /// One-shot finance reads: prefer server so first-page does not wait on a
  /// cold/stale IndexedDB hit when P3 repository is cold. Live Settlements stay
  /// on snapshots().
  static const GetOptions financeOneShotGetOptions = GetOptions(
    source: Source.server,
  );

  static Settings buildSettings({required bool isWeb}) {
    if (!isWeb) {
      return const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
    return Settings(
      persistenceEnabled: webPersistenceEnabled,
      webExperimentalAutoDetectLongPolling:
          webAutoDetectLongPolling ? true : null,
      webExperimentalForceLongPolling: webForceLongPolling ? true : null,
    );
  }

  static void applyOnce({required bool isWeb}) {
    FirebaseFirestore.instance.settings = buildSettings(isWeb: isWeb);
    settingsApplyCount++;
  }

  static Map<String, Object?> describe() => <String, Object?>{
        'platform': kIsWeb ? 'web' : 'io',
        'webPersistenceEnabled': webPersistenceEnabled,
        'webAutoDetectLongPolling': webAutoDetectLongPolling,
        'webForceLongPolling': webForceLongPolling,
        'settingsApplyCount': settingsApplyCount,
        'financeOneShotSource': 'server',
      };
}
