import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/core/driver_i18n.dart';

/// Payment method labels for the driver app (Cash / Online payment).
abstract final class DriverPaymentLabels {
  DriverPaymentLabels._();

  static const cashKey = 'Cash';
  static const onlineKey = 'Online payment';

  /// English phrase key for EasyLocalization (never Arabic).
  static String labelKey(PaymentMethod? method, {String? fallbackRaw}) {
    switch (method) {
      case PaymentMethod.Cash:
        return cashKey;
      case PaymentMethod.OnlinePayment:
        return onlineKey;
      case PaymentMethod.Accepted:
      case PaymentMethod.Completed:
      case null:
        break;
    }
    final raw = (fallbackRaw ?? '').toLowerCase();
    if (raw.contains('cash') || raw.contains('نقد')) return cashKey;
    if (raw.contains('online') ||
        raw.contains('electronic') ||
        raw.contains('الكترون') ||
        raw.contains('электрон')) {
      return onlineKey;
    }
    return onlineKey;
  }

  static String label(
    PaymentMethod? method, {
    String? fallbackRaw,
    BuildContext? context,
  }) {
    final key = labelKey(method, fallbackRaw: fallbackRaw);
    if (context != null) return driverTr(context, key);
    return key;
  }

  static bool isCash(PaymentMethod? method, {String? fallbackRaw}) {
    if (method == PaymentMethod.Cash) return true;
    if (method == PaymentMethod.OnlinePayment) return false;
    final raw = (fallbackRaw ?? '').toLowerCase();
    return raw.contains('cash') || raw.contains('نقد');
  }
}
