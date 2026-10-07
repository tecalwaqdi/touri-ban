import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '/app_state.dart';
import '/backend/schema/countries_record.dart';
import '/backend/schema/order_record.dart';
import '/core/toury_currency.dart';

/// Official Saudi Riyal symbol asset (SAMA design) — same asset as Driver app.
const kTourySaudiRiyalSymbolAsset = 'assets/currency/saudi_riyal_symbol.svg';

/// Single currency formatter for Customer surfaces touched by localization work.
///
/// - Currency *code* follows the selected country (SAR for SA, etc.).
/// - SAR *presentation* follows UI locale: official glyph in ar/ur, Latin
///   "SAR" in all other languages so scripts never mix.
/// - Other codes: registry/session symbol + locale-aware number.
abstract final class TouryMoneyFormat {
  TouryMoneyFormat._();

  static String resolveCurrencyCode({
    String? currencyCode,
    CountriesRecord? country,
    OrderRecord? order,
  }) {
    final fromArg = (currencyCode ?? '').trim();
    if (fromArg == TouryCurrency.officialRiyalSign ||
        fromArg == 'ر.س' ||
        fromArg.toUpperCase() == 'SAR' ||
        fromArg.toUpperCase() == 'RS' ||
        fromArg.toUpperCase() == 'SR') {
      return 'SAR';
    }
    final fromArgUpper = fromArg.toUpperCase();
    if (fromArgUpper.length == 3 &&
        RegExp(r'^[A-Z]{3}$').hasMatch(fromArgUpper)) {
      return fromArgUpper;
    }
    if (order != null) {
      final stored = (order.snapshotData['currency_code'] ??
              order.snapshotData['currency'] ??
              '')
          .toString()
          .trim()
          .toUpperCase();
      if (stored == 'SAR' || stored == 'ر.س' || stored == 'RS' || stored == 'SR') {
        return 'SAR';
      }
      if (stored.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(stored)) {
        return stored;
      }
    }
    final fromCountry = TouryCurrency.codeFromCountry(country);
    if (fromCountry.isNotEmpty) return fromCountry;
    final session = FFAppState().RMZCurrency.trim();
    if (session == TouryCurrency.officialRiyalSign ||
        session == 'ر.س' ||
        session.toUpperCase() == 'SAR' ||
        session.toUpperCase() == 'RS' ||
        session.toUpperCase() == 'SR') {
      return 'SAR';
    }
    final sessionUpper = session.toUpperCase();
    if (sessionUpper.length == 3 &&
        RegExp(r'^[A-Z]{3}$').hasMatch(sessionUpper)) {
      return sessionUpper;
    }
    return 'SAR';
  }

  static bool isSaudiRiyal({
    String? currencyCode,
    CountriesRecord? country,
    OrderRecord? order,
  }) =>
      resolveCurrencyCode(
        currencyCode: currencyCode,
        country: country,
        order: order,
      ) ==
      'SAR';

  /// Locale-aware amount body without currency symbol.
  static String formatAmount(
    num amount, {
    required Locale locale,
    int? fractionDigits,
  }) {
    final value = amount.toDouble();
    final digits = fractionDigits ??
        (value == value.roundToDouble() ? 0 : 2);
    try {
      return NumberFormat.decimalPattern(locale.toString())
          .format(double.parse(value.toStringAsFixed(digits)));
    } catch (_) {
      return value.toStringAsFixed(digits);
    }
  }

  /// Plain-text money for SnackBars / CTA strings that cannot host a Widget.
  /// SAR: U+20C1 in ar/ur; Latin "SAR" in every other UI language.
  static String formatPlain(
    num amount, {
    required Locale locale,
    String? currencyCode,
    CountriesRecord? country,
    OrderRecord? order,
  }) {
    final code = resolveCurrencyCode(
      currencyCode: currencyCode,
      country: country,
      order: order,
    );
    final body = formatAmount(amount, locale: locale);
    if (code == 'SAR') {
      return '$body ${TouryCurrency.symbolForCode('SAR', locale: locale)}';
    }
    final symbol = TouryCurrency.symbolForCode(
      code,
      override: country?.currencySymbol,
      locale: locale,
    );
    if (symbol.isEmpty) return '$body $code';
    return '$body $symbol';
  }
}

/// Renders a money amount; SAR uses the official glyph only in ar/ur UI.
class TouryMoneyText extends StatelessWidget {
  const TouryMoneyText({
    super.key,
    required this.amount,
    this.currencyCode,
    this.country,
    this.order,
    this.style,
    this.color,
    this.symbolSize,
    this.fractionDigits,
    this.maxLines = 1,
  });

  final num amount;
  final String? currencyCode;
  final CountriesRecord? country;
  final OrderRecord? order;
  final TextStyle? style;
  final Color? color;
  final double? symbolSize;
  final int? fractionDigits;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final code = TouryMoneyFormat.resolveCurrencyCode(
      currencyCode: currencyCode,
      country: country,
      order: order,
    );
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(color: color ?? style?.color);
    final fontSize = effectiveStyle.fontSize ?? 16;
    final numberColor =
        color ?? effectiveStyle.color ?? Theme.of(context).colorScheme.onSurface;
    final number = TouryMoneyFormat.formatAmount(
      amount,
      locale: locale,
      fractionDigits: fractionDigits,
    );

    if (code == 'SAR' && TouryCurrency.prefersOfficialRiyalGlyph(locale)) {
      final iconSize = symbolSize ?? (fontSize * 0.95);
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            kTourySaudiRiyalSymbolAsset,
            width: iconSize,
            height: iconSize * (1256.39 / 1124.14),
            colorFilter: ColorFilter.mode(numberColor, BlendMode.srcIn),
            semanticsLabel: 'Saudi Riyal',
          ),
          SizedBox(width: fontSize * 0.28),
          Flexible(
            child: Text(
              number,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              softWrap: maxLines > 1,
              style: effectiveStyle.copyWith(color: numberColor),
            ),
          ),
        ],
      );
    }

    final symbol = TouryCurrency.symbolForCode(
      code,
      override: country?.currencySymbol,
      locale: locale,
    );
    final label = symbol.isNotEmpty ? '$number $symbol' : '$number $code';
    return Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
      style: effectiveStyle.copyWith(color: numberColor),
    );
  }
}
