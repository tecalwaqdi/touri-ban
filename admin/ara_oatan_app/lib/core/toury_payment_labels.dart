import 'package:easy_localization/easy_localization.dart';

/// قيم داخلية لطريقة الدفع (لا تُعرض للمستخدم مباشرة).
abstract final class TouryPaymentKeys {
  static const unset = 'TOURY_PAY_UNSET';
  static const cash = 'TOURY_PAY_CASH';
  static const online = 'TOURY_PAY_NGENIUS';

  static const legacyUnset = 'حدد طريقة الدفع';
  static const legacyCash = 'نقدآ';
  static const legacyCashAlt = 'نقدي';
}

bool touryIsUnsetPaymentValue(String payth) {
  final p = payth.trim();
  return p.isEmpty ||
      p == TouryPaymentKeys.unset ||
      p == TouryPaymentKeys.legacyUnset;
}

bool touryIsCashPaymentValue(String payth) {
  final p = payth.trim();
  return p == TouryPaymentKeys.cash ||
      p == TouryPaymentKeys.legacyCash ||
      p == TouryPaymentKeys.legacyCashAlt;
}

bool touryIsOnlinePaymentValue(String payth) {
  return payth.trim() == TouryPaymentKeys.online;
}

/// النص المعروض للمستخدم حسب اللغة الحالية.
String touryPaymentDisplayLabel(String payth) {
  if (touryIsUnsetPaymentValue(payth)) {
    return 'ux_choose_payment_method'.tr();
  }
  if (touryIsCashPaymentValue(payth)) {
    return 'ux_cash_on_delivery'.tr();
  }
  if (touryIsOnlinePaymentValue(payth)) {
    return 'ux_card_payment_network'.tr();
  }
  return 'ux_choose_payment_method'.tr();
}
