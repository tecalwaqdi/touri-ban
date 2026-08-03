import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Connectivity probe + stream (no secrets; uses generate_204).
abstract final class DriverConnectivityService {
  DriverConnectivityService._();

  static final _controller = StreamController<bool>.broadcast();
  static Timer? _timer;
  static bool? _last;
  static bool _started = false;

  static Stream<bool> get onChanged => _controller.stream;
  static bool get isOnline => _last ?? true;

  static Future<void> start({Duration interval = const Duration(seconds: 20)}) async {
    if (_started) return;
    _started = true;
    await probe();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(probe()));
  }

  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  static Future<bool> probe() async {
    var online = false;
    try {
      final res = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      online = res.statusCode == 204 || res.statusCode == 200;
    } catch (_) {
      online = false;
    }
    if (_last != online) {
      _last = online;
      if (!_controller.isClosed) _controller.add(online);
      DriverRuntimeDiagnostics.note('connectivity', online ? 'online' : 'offline');
    }
    return online;
  }
}

/// Safe diagnostics — never log secrets / docs / tokens.
abstract final class DriverRuntimeDiagnostics {
  DriverRuntimeDiagnostics._();

  static int activeTimers = 0;
  static int activeListeners = 0;
  static bool locationSyncActive = false;
  static String? currentOrderPath;
  static final List<String> _recent = [];

  static void note(String tag, String message) {
    if (!kDebugMode) return;
    final line = '${DateTime.now().toIso8601String()} [$tag] $message';
    _recent.add(line);
    if (_recent.length > 40) _recent.removeAt(0);
    debugPrint(line);
  }

  static List<String> snapshot() => List.unmodifiable(_recent);
}

enum DriverOfflineOpType {
  acceptOrder,
  driverArrived,
  startTrip,
  completeTrip,
  cancelTrip,
  cashConfirmation,
  setOnline,
  setOffline,
}

enum DriverOfflineOpStatus {
  queued,
  sending,
  confirmed,
  failed,
}

class DriverOfflineAction {
  DriverOfflineAction({
    required this.operationId,
    required this.type,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.orderPath,
    this.serverResult,
    this.payload = const {},
  });

  final String operationId;
  final DriverOfflineOpType type;
  DriverOfflineOpStatus status;
  int retryCount;
  final DateTime createdAt;
  DateTime? lastAttemptAt;
  final String? orderPath;
  String? serverResult;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'type': type.name,
        'status': status.name,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'orderPath': orderPath,
        'serverResult': serverResult,
        'payload': payload,
      };

  static DriverOfflineAction fromJson(Map<String, dynamic> j) =>
      DriverOfflineAction(
        operationId: (j['operationId'] ?? '').toString(),
        type: DriverOfflineOpType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => DriverOfflineOpType.setOffline,
        ),
        status: DriverOfflineOpStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => DriverOfflineOpStatus.queued,
        ),
        retryCount: (j['retryCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        lastAttemptAt: DateTime.tryParse((j['lastAttemptAt'] ?? '').toString()),
        orderPath: j['orderPath'] as String?,
        serverResult: j['serverResult'] as String?,
        payload: Map<String, dynamic>.from(j['payload'] as Map? ?? const {}),
      );
}

/// Persisted offline queue — never auto-replays without backend reconciliation.
abstract final class DriverOfflineActionQueue {
  DriverOfflineActionQueue._();

  static const _prefsKey = 'driver_offline_action_queue_v1';
  static const _maxRetries = 5;
  static final _rand = math.Random();
  static List<DriverOfflineAction> _cache = [];
  static bool _loaded = false;
  static bool _flushing = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
    } else {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _cache = list
            .whereType<Map>()
            .map((e) => DriverOfflineAction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_cache.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<DriverOfflineAction>> pending() async {
    await ensureLoaded();
    return List.unmodifiable(
      _cache.where((e) =>
          e.status == DriverOfflineOpStatus.queued ||
          e.status == DriverOfflineOpStatus.failed),
    );
  }

  /// Enqueue only when offline / transient failure. Returns operationId.
  static Future<String> enqueue({
    required DriverOfflineOpType type,
    String? orderPath,
    Map<String, dynamic> payload = const {},
  }) async {
    await ensureLoaded();
    final id =
        'op_${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 32)}';
    _cache.add(DriverOfflineAction(
      operationId: id,
      type: type,
      status: DriverOfflineOpStatus.queued,
      retryCount: 0,
      createdAt: DateTime.now(),
      orderPath: orderPath,
      payload: payload,
    ));
    await _persist();
    DriverRuntimeDiagnostics.note('offline_queue', 'enqueued ${type.name}');
    return id;
  }

  static Future<void> markConfirmed(String operationId, {String? result}) async {
    await ensureLoaded();
    final i = _cache.indexWhere((e) => e.operationId == operationId);
    if (i < 0) return;
    _cache[i].status = DriverOfflineOpStatus.confirmed;
    _cache[i].serverResult = result ?? 'ok';
    await _persist();
  }

  static Future<void> markFailed(String operationId, String reason) async {
    await ensureLoaded();
    final i = _cache.indexWhere((e) => e.operationId == operationId);
    if (i < 0) return;
    _cache[i].status = DriverOfflineOpStatus.failed;
    _cache[i].serverResult = reason;
    _cache[i].retryCount += 1;
    _cache[i].lastAttemptAt = DateTime.now();
    await _persist();
  }

  /// Clear confirmed / exhausted entries.
  static Future<void> prune() async {
    await ensureLoaded();
    _cache.removeWhere((e) =>
        e.status == DriverOfflineOpStatus.confirmed ||
        (e.status == DriverOfflineOpStatus.failed && e.retryCount >= _maxRetries));
    await _persist();
  }

  static bool get isFlushing => _flushing;

  /// Reconcile with backend before any replay. Caller supplies [reconcile].
  static Future<void> flush(
    Future<DriverOfflineReconcileResult> Function(DriverOfflineAction op)
        reconcile,
  ) async {
    if (_flushing) return;
    _flushing = true;
    try {
      await ensureLoaded();
      final open = _cache
          .where((e) =>
              e.status == DriverOfflineOpStatus.queued ||
              (e.status == DriverOfflineOpStatus.failed &&
                  e.retryCount < _maxRetries))
          .toList();
      for (final op in open) {
        op.status = DriverOfflineOpStatus.sending;
        op.lastAttemptAt = DateTime.now();
        await _persist();
        try {
          final result = await reconcile(op);
          if (result.alreadyDone || result.applied) {
            op.status = DriverOfflineOpStatus.confirmed;
            op.serverResult = result.message;
          } else if (result.requiresOnlineUi) {
            op.status = DriverOfflineOpStatus.failed;
            op.serverResult = result.message;
            op.retryCount += 1;
          } else {
            op.status = DriverOfflineOpStatus.failed;
            op.serverResult = result.message;
            op.retryCount += 1;
          }
        } catch (e) {
          op.status = DriverOfflineOpStatus.failed;
          op.serverResult = e.toString();
          op.retryCount += 1;
        }
        await _persist();
      }
      await prune();
    } finally {
      _flushing = false;
    }
  }
}

class DriverOfflineReconcileResult {
  const DriverOfflineReconcileResult({
    this.alreadyDone = false,
    this.applied = false,
    this.requiresOnlineUi = false,
    this.message = '',
  });

  final bool alreadyDone;
  final bool applied;
  final bool requiresOnlineUi;
  final String message;
}
