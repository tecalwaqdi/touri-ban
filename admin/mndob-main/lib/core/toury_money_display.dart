import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '/core/driver_country_service.dart';
import '/core/toury_country_registry.dart';

/// Official Saudi Riyal symbol asset (SAMA design).
const kSaudiRiyalSymbolAsset = 'assets/currency/saudi_riyal_symbol.svg';

/// Formats and renders money amounts for the driver app.
///
/// Currency *code* follows the driver's country. SAR *presentation* follows
/// UI locale: official glyph in ar/ur, Latin "SAR" elsewhere (no script mix).
class TouryMoneyAmount extends StatelessWidget {
  const TouryMoneyAmount({
    super.key,
    required this.amount,
    this.currencyCode,
    this.style,
    this.color,
    this.symbolSize,
    this.fractionDigits = 2,
    this.showPlusForPositive = false,
    this.compact = false,
    this.maxLines = 1,
  });

  final double amount;
  final String? currencyCode;
  final TextStyle? style;
  final Color? color;
  final double? symbolSize;
  final int fractionDigits;
  final bool showPlusForPositive;
  final bool compact;
  final int maxLines;

  static const officialRiyalSign = '\u20C1';

  static bool prefersOfficialRiyalGlyph(Locale locale) {
    final lang = locale.languageCode.toLowerCase();
    return lang == 'ar' || lang == 'ur';
  }

  static String resolveCurrencyCode(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed == officialRiyalSign ||
        trimmed == 'ر.س' ||
        trimmed.toUpperCase() == 'SAR' ||
        trimmed.toUpperCase() == 'RS' ||
        trimmed.toUpperCase() == 'SR') {
      return 'SAR';
    }
    final code = trimmed.toUpperCase();
    if (code.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return code;
    }
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencyForIso(iso);
  }

  static bool isSaudiRiyal(String? raw) => resolveCurrencyCode(raw) == 'SAR';

  static String formatNumber(
    double amount, {
    int fractionDigits = 2,
    bool showPlusForPositive = false,
    String? locale,
  }) {
    final abs = amount.abs();
    final fmt = NumberFormat.currency(
      locale: (locale ?? 'en_US'),
      symbol: '',
      decimalDigits: fractionDigits,
    );
    final body = fmt.format(abs).trim();
    if (amount < 0) return '-$body';
    if (showPlusForPositive && amount > 0) return '+$body';
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final code = resolveCurrencyCode(currencyCode);
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(color: color ?? style?.color);
    final fontSize = effectiveStyle.fontSize ?? 16;
    final iconSize = symbolSize ?? (fontSize * (compact ? 0.85 : 0.95));
    final number = formatNumber(
      amount,
      fractionDigits: fractionDigits,
      showPlusForPositive: showPlusForPositive,
      locale: locale.toString(),
    );
    final numberColor = color ?? effectiveStyle.color ??
        Theme.of(context).colorScheme.onSurface;

    if (code == 'SAR' && prefersOfficialRiyalGlyph(locale)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            kSaudiRiyalSymbolAsset,
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

    if (code == 'SAR') {
      return Text(
        'SAR $number',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: maxLines > 1,
        style: effectiveStyle.copyWith(color: numberColor),
      );
    }

    final symbol = TouryCountryRegistry.currencySymbol(
      DriverCountryService.currentIso2(),
      locale: locale,
    );
    // Prefer ISO-based symbol map when code is known and not SAR.
    final mapped = switch (code) {
      'KGS' => 'с',
      'RUB' => '₽',
      'UZS' => 'soʻm',
      'AED' => 'د.إ',
      _ => symbol,
    };

    return Text(
      '$mapped $number',
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
      style: effectiveStyle.copyWith(color: numberColor),
    );
  }
}
