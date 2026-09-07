import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';

/// Session/local Demo Mode for controlled Admin finance fixtures.
///
/// Default OFF. Never a server-global flag. Does not change finance semantics.
abstract final class AdminFinanceDemoMode {
  AdminFinanceDemoMode._();

  static const seedGroup = 'TOURI_ADMIN_FINANCE_DEMO';
  static const seedVersion = 'finance_ui_v1';
  static const demoAccountantEmail = 'accountant.demo@touri-taxi.com';

  static const _prefsKey = 'admin_finance_demo_mode_v1';

  static final ValueNotifier<bool> enabledListenable = ValueNotifier<bool>(false);

  static bool get enabled => enabledListenable.value;

  /// Super Admin or the dedicated demo Accountant email only.
  static bool get canToggle {
    if (AdminRoleService.isSuperAdmin) return true;
    final email = currentUserEmail.trim().toLowerCase();
    return AdminRoleService.isAccountant && email == demoAccountantEmail;
  }

  static Future<void> hydrateFromLocal() async {
    if (!canToggle) {
      if (enabledListenable.value) enabledListenable.value = false;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      enabledListenable.value = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      enabledListenable.value = false;
    }
  }

  static Future<void> setEnabled(bool value) async {
    if (!canToggle) {
      enabledListenable.value = false;
      return;
    }
    enabledListenable.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // Session value still applied via listenable.
    }
  }

  /// Test hook — does not touch SharedPreferences.
  @visibleForTesting
  static void debugSetEnabled(bool value) {
    enabledListenable.value = value;
  }

  @visibleForTesting
  static void debugReset() {
    enabledListenable.value = false;
  }
}
