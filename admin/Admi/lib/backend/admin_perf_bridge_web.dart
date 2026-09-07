import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '/core/finance/admin_finance_repository.dart';

bool _clearHookInstalled = false;

/// Web: expose latest P4B trace on `globalThis.__TOURI_PERF_P4B__`.
void publishPerfP4b(Map<String, Object?> payload) {
  try {
    final json = jsonEncode(payload);
    globalContext.setProperty('__TOURI_PERF_P4B__'.toJS, json.toJS);
    _ensureClearHook();
  } catch (_) {
    // ignore bridge failures in preview
  }
}

void _ensureClearHook() {
  if (_clearHookInstalled) return;
  _clearHookInstalled = true;
  // PERF-P4C probe: allow Playwright to drop P3 session cache between warm runs.
  globalContext.setProperty(
    '__TOURI_CLEAR_FINANCE_CACHE__'.toJS,
    (() {
      AdminFinanceRepository.instance.clearSession();
    }).toJS,
  );
}
