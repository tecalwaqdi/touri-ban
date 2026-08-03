import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';

/// Optional country filter when super-admin browses from التقارير الإدارية.
class AdminReportsCountryScope {
  AdminReportsCountryScope._();

  static DocumentReference? _countryRef;
  static String _countryLabel = 'جميع الدول';
  static void Function()? onChanged;

  static bool get isActive =>
      AdminRoleService.isSuperAdmin && _countryRef != null;

  static DocumentReference? get countryRef => _countryRef;

  static String get countryLabel =>
      _countryRef != null ? _countryLabel : 'جميع الدول';

  static void set({
    required DocumentReference countryRef,
    required String countryLabel,
  }) {
    if (!AdminRoleService.isSuperAdmin) return;
    final changed = _countryRef?.path != countryRef.path;
    _countryRef = countryRef;
    _countryLabel = countryLabel.isNotEmpty ? countryLabel : 'دولة';
    if (changed) {
      // Reports filter only — do not wipe landmark caches (causes OOM on mobile).
      AdminCountryScope.clearVillageCache();
    }
    onChanged?.call();
  }

  static void clear() {
    if (_countryRef == null) return;
    _countryRef = null;
    _countryLabel = 'جميع الدول';
    AdminCountryScope.clearVillageCache();
    onChanged?.call();
  }

  static void syncFrom({
    DocumentReference? countryRef,
    required String countryLabel,
  }) {
    if (countryRef == null) {
      clear();
      return;
    }
    set(countryRef: countryRef, countryLabel: countryLabel);
  }
}
