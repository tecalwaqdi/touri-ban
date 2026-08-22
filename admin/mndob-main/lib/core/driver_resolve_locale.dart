import 'package:flutter/material.dart';

import '/flutter_flow/internationalization.dart';

/// اللغات المدعومة في تطبيق المندوب (EasyLocalization + FFLocalizations).
const List<Locale> driverSupportedLocales = [
  Locale('en'),
  Locale('ar'),
  Locale('ru'),
  Locale('ky'),
  Locale('fr'),
  Locale('ur'),
  Locale('pt'),
];

const Locale driverFallbackLocale = Locale('en');

Locale driverResolveDeviceLocale([
  List<Locale> supported = driverSupportedLocales,
]) {
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  for (final device in locales) {
    final matched = _matchSupportedLocale(device, supported);
    if (matched != null) {
      return matched;
    }
  }
  return driverFallbackLocale;
}

Locale driverResolveStartupLocale([
  List<Locale> supported = driverSupportedLocales,
]) {
  final stored = FFLocalizations.getStoredLocale();
  if (stored != null) {
    final matched = _matchSupportedLocale(stored, supported);
    if (matched != null) {
      if (driverLocaleStorageKey(stored) != driverLocaleStorageKey(matched)) {
        FFLocalizations.storeLocale(driverLocaleStorageKey(matched));
      }
      return matched;
    }
    return driverFallbackLocale;
  }
  return driverResolveDeviceLocale(supported);
}

String driverLocaleStorageKey(Locale locale) {
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

Locale driverLocaleOrDefault(Locale? locale) {
  if (locale == null) return driverFallbackLocale;
  final matched = _matchSupportedLocale(locale, driverSupportedLocales);
  return matched ?? driverFallbackLocale;
}
