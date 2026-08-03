import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/internationalization.dart';

const Locale touryFallbackLocale = Locale('en');

/// Production UI languages only. French and other locales are archived and
/// must not appear in the language picker until fully reviewed.
const Set<String> touryProductionLanguageCodes = {
  'ar',
  'en',
  'ru',
  'ky',
};

const List<Locale> touryProductionLocales = [
  Locale('en'),
  Locale('ar'),
  Locale('ru'),
  Locale('ky'),
];

/// Discovers translation assets, then keeps only production locales.
Future<List<Locale>> touryDiscoverSupportedLocales([
  AssetBundle? bundle,
]) async {
  final manifest =
      await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
  final discovered = manifest
      .listAssets()
      .where((asset) =>
          asset.startsWith('assets/langs/') &&
          !asset.contains('langs_archive') &&
          asset.endsWith('.json'))
      .map((asset) => asset.split('/').last.replaceAll('.json', ''))
      .map(_localeFromAssetName)
      .where((locale) =>
          touryProductionLanguageCodes.contains(locale.languageCode))
      .toSet()
      .toList();

  final locales = <Locale>[
    for (final locale in touryProductionLocales)
      if (discovered.any((d) => d.languageCode == locale.languageCode)) locale,
  ];

  if (locales.isEmpty) {
    throw FlutterError(
      'No production translation files found in assets/langs '
      '(expected ar/en/ru/ky).',
    );
  }
  return List.unmodifiable(locales);
}

/// Migrates a stored/legacy locale (e.g. fr) onto a production locale.
Locale touryMigrateLegacyLocale(Locale? stored) {
  if (stored == null) return touryFallbackLocale;
  final matched = _matchSupportedLocale(stored, touryProductionLocales);
  return matched ?? touryFallbackLocale;
}

Locale _localeFromAssetName(String name) {
  final normalized = name.replaceAll('_', '-');
  final parts = normalized.split('-');
  if (parts.length == 1) return Locale(parts.first);
  final second = parts[1];
  if (second.length == 4) {
    return Locale.fromSubtags(
      languageCode: parts.first,
      scriptCode: second,
    );
  }
  return Locale.fromSubtags(
    languageCode: parts.first,
    countryCode: second,
  );
}

/// يطابق لغة الجهاز مع لغة مدعومة، أو يعيد الإنجليزية.
Locale touryResolveDeviceLocale(
  List<Locale> supported, {
  List<Locale>? deviceLocales,
}) {
  final locales =
      deviceLocales ?? WidgetsBinding.instance.platformDispatcher.locales;
  for (final device in locales) {
    final matched = _matchSupportedLocale(device, supported);
    if (matched != null) {
      return matched;
    }
  }
  return touryFallbackLocale;
}

/// لغة البدء: تفضيل المستخدم المحفوظة، وإلا لغة الجهاز، وإلا الإنجليزية.
/// اللغات غير الإنتاجية (مثل fr) تُرحَّل إلى اللغة الافتراضية.
Locale touryResolveStartupLocale(List<Locale> supported) {
  final stored = FFLocalizations.getStoredLocale();
  if (stored != null) {
    final migrated = touryMigrateLegacyLocale(stored);
    final matched = _matchSupportedLocale(migrated, supported);
    if (matched != null) {
      if (touryLocaleStorageKey(stored) != touryLocaleStorageKey(matched)) {
        FFLocalizations.storeLocale(touryLocaleStorageKey(matched));
      }
      return matched;
    }
    return touryFallbackLocale;
  }
  return touryResolveDeviceLocale(supported);
}

/// مفتاح التخزين لـ FFLocalizations من [Locale].
String touryLocaleStorageKey(Locale locale) {
  if (locale.scriptCode != null && locale.scriptCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.scriptCode}';
  }
  return locale.languageCode;
}

Locale? _matchSupportedLocale(Locale device, List<Locale> supported) {
  for (final candidate in supported) {
    if (candidate.languageCode != device.languageCode) {
      continue;
    }
    final deviceScript = device.scriptCode;
    final candidateScript = candidate.scriptCode;
    if (candidateScript != null && candidateScript.isNotEmpty) {
      if (deviceScript == candidateScript) {
        return candidate;
      }
      continue;
    }
    if (deviceScript == null ||
        deviceScript.isEmpty ||
        candidateScript == null ||
        candidateScript.isEmpty) {
      return candidate;
    }
  }
  return null;
}
