import '/app_state.dart';

/// Immutable checkout quote. All calculations use halalas to avoid floating
/// point drift in payment-critical values.
class TouryPriceQuote {
  const TouryPriceQuote({
    required this.hourlyRateHalalas,
    required this.bookingHours,
    required this.baseFareHalalas,
    required this.driverNetHalalas,
    required this.appFeeHalalas,
    required this.vatHalalas,
    required this.discountHalalas,
    required this.customerTotalHalalas,
  });

  final int hourlyRateHalalas;
  final int bookingHours;
  final int baseFareHalalas;
  final int driverNetHalalas;
  final int appFeeHalalas;
  final int vatHalalas;
  final int discountHalalas;
  final int customerTotalHalalas;

  double get driverNetSar => driverNetHalalas / 100;
  double get appFeeSar => appFeeHalalas / 100;
  double get vatSar => vatHalalas / 100;
  double get discountSar => discountHalalas / 100;
  double get customerTotalSar => customerTotalHalalas / 100;

  bool get isConsistent =>
      driverNetHalalas + appFeeHalalas + vatHalalas - discountHalalas ==
      customerTotalHalalas;
}

int _percentOf(int amountHalalas, double percent) {
  if (amountHalalas <= 0 || !percent.isFinite || percent <= 0) return 0;
  return (amountHalalas * percent / 100).round();
}

TouryPriceQuote touryCalculatePriceQuote({
  required int hourlyRateSar,
  required int bookingHours,
  required int additionalHours,
  double appFeePercent = 15,
  bool vatEnabled = false,
  double vatPercent = 0,
  double additionalHoursDiscountPercent = 0,
  int additionalHoursDiscountCapSar = 0,
}) {
  final safeRateSar = hourlyRateSar.clamp(0, 1000000).toInt();
  final safeHours = bookingHours.clamp(0, 24 * 30).toInt();
  final safeAdditionalHours = additionalHours.clamp(0, safeHours).toInt();
  final hourlyRateHalalas = safeRateSar * 100;
  final baseFareHalalas = hourlyRateHalalas * safeHours;

  final appFeeHalalas = _percentOf(baseFareHalalas, appFeePercent);
  final vatHalalas = vatEnabled ? _percentOf(baseFareHalalas, vatPercent) : 0;

  final rawDiscountHalalas = _percentOf(
    hourlyRateHalalas * safeAdditionalHours,
    additionalHoursDiscountPercent,
  );
  final discountCapHalalas =
      additionalHoursDiscountCapSar.clamp(0, 100000000).toInt() * 100;
  final discountHalalas = discountCapHalalas <= 0
      ? 0
      : rawDiscountHalalas.clamp(0, discountCapHalalas).toInt();

  final driverNetHalalas = (baseFareHalalas - appFeeHalalas - vatHalalas)
      .clamp(0, baseFareHalalas)
      .toInt();
  final customerTotalHalalas =
      (baseFareHalalas - discountHalalas).clamp(0, baseFareHalalas).toInt();

  return TouryPriceQuote(
    hourlyRateHalalas: hourlyRateHalalas,
    bookingHours: safeHours,
    baseFareHalalas: baseFareHalalas,
    driverNetHalalas: driverNetHalalas,
    appFeeHalalas: appFeeHalalas,
    vatHalalas: vatHalalas,
    discountHalalas: discountHalalas,
    customerTotalHalalas: customerTotalHalalas,
  );
}

/// Recalculates every legacy checkout field from one quote so stale values can
/// no longer leak into the summary or the N-Genius amount.
TouryPriceQuote touryRecalculateCheckoutPrice([FFAppState? state]) {
  final app = state ?? FFAppState();
  final quote = touryCalculatePriceQuote(
    hourlyRateSar: app.srtypecar,
    bookingHours: app.totalsaat,
    additionalHours: app.addhors,
    vatEnabled: app.isVat,
    vatPercent: app.VatDolh.toDouble(),
    additionalHoursDiscountPercent: app.NsbhKsm,
    additionalHoursDiscountCapSar: app.UbKsm,
  );

  app.update(() {
    app.TOTALmndob2 = (quote.baseFareHalalas / 100).round();
    app.totalapp2 = (quote.appFeeHalalas / 100).round();
    app.vat2 = (quote.vatHalalas / 100).round();
    app.totalKsm2 = quote.discountSar;
    app.totalmndob3 = quote.driverNetSar;
    app.totalAllNow2 = (quote.customerTotalHalalas / 100).round();
    app.totalAllnow3 = quote.customerTotalSar;
  });
  return quote;
}
