/// حالات الرحلة النصية المستخدمة في مجموعة `order` (عرض / توافق قديم).
/// الكتابة الإنتاجية تعتمد `status_code` مع dual-write لهذه القيم.
abstract final class DriverTripHalh {
  DriverTripHalh._();

  static const waitingAccept = 'بإنتظار قبول المندوب';
  static const pendingHalhOrder = 'Pending';
  static const accepted = 'مقبول';
  static const driverArrived = 'وصل المندوب';
  static const inProgress = 'تم البدء في الرحلة';
  static const completed = 'مكتمل';
  static const completedAlias = 'مكتملة';
  static const cancelled = 'ملغي';

  static const Set<String> activeForDriver = {
    accepted,
    driverArrived,
    inProgress,
  };

  static bool isActiveTrip(String? halhText) =>
      activeForDriver.contains((halhText ?? '').trim());

  static bool isCompleted(String? halhText) {
    final h = (halhText ?? '').trim();
    return h == completed || h == completedAlias;
  }
}

/// حد أدنى لرصيد محفظة المندوب عند قبول طلبات الدفع النقدي.
abstract final class DriverWalletRules {
  DriverWalletRules._();

  static const double minCashWalletBalance = 200.0;
}
