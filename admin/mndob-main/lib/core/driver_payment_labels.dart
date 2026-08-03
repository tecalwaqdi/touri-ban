import '/backend/schema/enums/enums.dart';

/// تسميات طريقة الدفع للمندوب (نقدي / إلكتروني).
abstract final class DriverPaymentLabels {
  DriverPaymentLabels._();

  static String label(PaymentMethod? method, {String? fallbackRaw}) {
    switch (method) {
      case PaymentMethod.Cash:
        return 'نقدي';
      case PaymentMethod.OnlinePayment:
        return 'دفع إلكتروني';
      case PaymentMethod.Accepted:
      case PaymentMethod.Completed:
      case null:
        break;
    }
    final raw = (fallbackRaw ?? '').toLowerCase();
    if (raw.contains('cash') || raw.contains('نقد')) return 'نقدي';
    if (raw.contains('online') ||
        raw.contains('electronic') ||
        raw.contains('الكترون')) {
      return 'دفع إلكتروني';
    }
    return 'دفع إلكتروني';
  }

  static bool isCash(PaymentMethod? method) =>
      method == PaymentMethod.Cash ||
      label(method).contains('نقد');
}
