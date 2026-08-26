/// Mirrors Customer `touryCalculatePriceQuote` for Admin preview only.
/// Keep math identical — do not invent a second pricing model.
class AdminVehiclePricePreview {
  const AdminVehiclePricePreview({
    required this.customerTotalSar,
    required this.baseFareSar,
    required this.discountSar,
  });

  final int customerTotalSar;
  final int baseFareSar;
  final int discountSar;
}

int _percentOf(int amount, double percent) {
  if (amount <= 0 || percent <= 0) return 0;
  return ((amount * percent) / 100).round();
}

AdminVehiclePricePreview adminVehiclePricePreview({
  required int hourlyRateSar,
  required int bookingHours,
  required int additionalHours,
  double additionalHoursDiscountPercent = 0,
  int additionalHoursDiscountCapSar = 0,
}) {
  final safeRate = hourlyRateSar < 0 ? 0 : hourlyRateSar;
  final safeHours = bookingHours.clamp(0, 720);
  final safeExtra = additionalHours.clamp(0, 720);
  final baseFareHalalas = safeRate * 100 * safeHours;

  var discountHalalas = 0;
  if (safeExtra > 0 && additionalHoursDiscountPercent > 0) {
    discountHalalas = _percentOf(
      safeRate * 100 * safeExtra,
      additionalHoursDiscountPercent,
    );
    final cap = additionalHoursDiscountCapSar < 0
        ? 0
        : additionalHoursDiscountCapSar * 100;
    if (cap > 0 && discountHalalas > cap) {
      discountHalalas = cap;
    }
  }

  final customerTotalHalalas =
      (baseFareHalalas - discountHalalas).clamp(0, baseFareHalalas).toInt();

  return AdminVehiclePricePreview(
    customerTotalSar: (customerTotalHalalas / 100).round(),
    baseFareSar: (baseFareHalalas / 100).round(),
    discountSar: (discountHalalas / 100).round(),
  );
}
