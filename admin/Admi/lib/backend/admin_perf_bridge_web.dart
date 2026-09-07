import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web: expose latest P4B trace on `globalThis.__TOURI_PERF_P4B__`.
void publishPerfP4b(Map<String, Object?> payload) {
  try {
    final json = jsonEncode(payload);
    globalContext.setProperty('__TOURI_PERF_P4B__'.toJS, json.toJS);
  } catch (_) {
    // ignore bridge failures in preview
  }
}
