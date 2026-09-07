import 'dart:convert';

import 'package:flutter/scheduler.dart';

import '/backend/admin_perf_bridge.dart';
import '/backend/admin_firestore_web_config.dart';

/// PERF-P4B — one monotonic clock per finance route load.
///
/// Publish via console `P4B|...` lines + `window.__TOURI_PERF_P4B__` (web).
/// No PII. Safe in release preview when [enabled].
abstract final class AdminFinanceRouteTrace {
  AdminFinanceRouteTrace._();

  /// Force-on for P4B preview by default (disable with `--dart-define=TOURI_PERF_P4B=false`).
  static bool enabled =
      const bool.fromEnvironment('TOURI_PERF_P4B', defaultValue: true);

  static String? _traceId;
  static String? _route;
  static Stopwatch? _sw;
  static final Map<String, int> _marks = <String, int>{};
  static final List<Map<String, Object?>> _events = <Map<String, Object?>>[];
  static int _seq = 0;
  static bool _paintScheduled = false;
  static int firebaseInitCount = 0;
  static int firestoreSettingsApplyCount = 0;

  static String? get activeTraceId => _traceId;
  static Map<String, int> get marks => Map<String, int>.unmodifiable(_marks);

  static int? ms(String event) => _marks[event];

  static int? delta(String from, String to) {
    final a = _marks[from];
    final b = _marks[to];
    if (a == null || b == null) return null;
    return b - a;
  }

  static void begin(String route) {
    if (!enabled) return;
    _seq += 1;
    _traceId = 'p4b_${_seq}_${DateTime.now().millisecondsSinceEpoch}';
    _route = route;
    _sw = Stopwatch()..start();
    _marks.clear();
    _events.clear();
    _paintScheduled = false;
    mark('ROUTE_ENTER');
    _publish();
  }

  static void mark(String event, {Map<String, Object?>? extra}) {
    if (!enabled || _sw == null || _traceId == null) return;
    final ms = _sw!.elapsedMilliseconds;
    _marks[event] = ms;
    final row = <String, Object?>{
      'traceId': _traceId,
      'route': _route,
      'event': event,
      'ms': ms,
      if (extra != null) ...extra,
    };
    _events.add(row);
    // ignore: avoid_print
    print(
      'P4B|$_traceId|$_route|$event|$ms|${extra == null ? '' : jsonEncode(extra)}',
    );
    _publish();
  }

  /// Mark and schedule first-useful frame callback (once per trace).
  static void markStateEmitAndSchedulePaint({String stateEvent = 'STATE_EMIT'}) {
    if (!enabled) return;
    mark(stateEvent);
    if (_paintScheduled) return;
    _paintScheduled = true;
    mark('FRAME_SCHEDULED');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      mark('FIRST_USEFUL_FRAME_PAINTED');
    });
  }

  static Map<String, Object?> snapshot() {
    return <String, Object?>{
      'traceId': _traceId,
      'route': _route,
      'marks': Map<String, int>.from(_marks),
      'events': List<Map<String, Object?>>.from(_events),
      'firebaseInitCount': firebaseInitCount,
      'firestoreSettingsApplyCount': firestoreSettingsApplyCount,
      'firestoreWebConfig': AdminFirestoreWebConfig.describe(),
      'deltas': <String, int?>{
        'route_to_query_start': delta('ROUTE_ENTER', 'QUERY_START'),
        'route_to_query_requested': delta('ROUTE_ENTER', 'QUERY_REQUESTED'),
        'auth_token': delta('AUTH_TOKEN_REQUEST_START', 'AUTH_TOKEN_REQUEST_END'),
        'query_to_snapshot':
            delta('QUERY_START', 'FIRESTORE_FIRST_SNAPSHOT') ??
                delta('FIRESTORE_GET_START', 'FIRESTORE_FIRST_SNAPSHOT') ??
                delta('FIRESTORE_LISTEN_START', 'FIRESTORE_FIRST_SNAPSHOT'),
        'snapshot_to_model':
            delta('FIRESTORE_FIRST_SNAPSHOT', 'MODEL_BUILD_END') ??
                delta('FIRESTORE_FIRST_SNAPSHOT', 'REPOSITORY_COMPLETE'),
        'model_to_state':
            delta('MODEL_BUILD_END', 'STATE_EMIT') ??
                delta('REPOSITORY_COMPLETE', 'STATE_EMIT'),
        'state_to_paint': delta('STATE_EMIT', 'FIRST_USEFUL_FRAME_PAINTED'),
        'total_enter_to_paint':
            delta('ROUTE_ENTER', 'FIRST_USEFUL_FRAME_PAINTED'),
        'summary': delta('SUMMARY_START', 'SUMMARY_COMPLETE'),
      },
    };
  }

  static void _publish() {
    publishPerfP4b(snapshot());
  }

  static void noteFirebaseInit() {
    firebaseInitCount++;
  }

  static void noteFirestoreSettings() {
    firestoreSettingsApplyCount++;
  }
}
