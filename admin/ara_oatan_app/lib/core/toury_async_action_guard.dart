import 'package:flutter/foundation.dart';

/// Lightweight in-flight guard for high-impact user actions.
///
/// Prevents re-entrant taps while an async operation with the same [actionKey]
/// is running. Call [tryStart] synchronously before any `await`.
class TouryAsyncActionGuard {
  TouryAsyncActionGuard._();

  static final Set<String> _running = <String>{};

  /// Returns true if this call acquired the lock and may proceed.
  static bool tryStart(String actionKey) {
    final key = actionKey.trim();
    if (key.isEmpty) return false;
    if (_running.contains(key)) {
      if (kDebugMode) {
        debugPrint('TouryAsyncActionGuard blocked re-entry key=$key');
      }
      return false;
    }
    _running.add(key);
    return true;
  }

  static bool isRunning(String actionKey) =>
      _running.contains(actionKey.trim());

  static void finish(String actionKey) {
    _running.remove(actionKey.trim());
  }

  /// Test-only.
  @visibleForTesting
  static void debugReset() => _running.clear();

  @visibleForTesting
  static int get debugRunningCount => _running.length;
}
