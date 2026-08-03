import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/toury_locale_loader.dart';

/// مفاتيح رسائل Google — تُترجم عبر EasyLocalization مع احتياطي مضمّن لكل لغة.
abstract final class TouryGoogleAuthMessages {
  TouryGoogleAuthMessages._();

  static const failed = 'auth_google_failed';
  static const developerError = 'auth_google_developer_error';
  static const notEnabled = 'auth_google_not_enabled';
  static const accountConflict = 'auth_google_account_conflict';
  static const network = 'error_network_user';

  static const Map<String, Map<String, String>> _fallback = {
    failed: {
      'ar': 'تعذّر تسجيل الدخول عبر Google. حاول مرة أخرى.',
      'en': 'Google sign-in failed. Please try again.',
      'ru': 'Не удалось войти через Google. Попробуйте снова.',
      'ky': 'Google аркылуу кирүү ишке ашкан жок. Кайра аракет кылыңыз.',
    },
    developerError: {
      'ar':
          'إعداد Google غير مكتمل على هذا الجهاز. تأكد من تفعيل Google في Firebase وإضافة SHA-1، ثم أعد تثبيت التطبيق.',
      'en':
          'Google sign-in is not configured on this device. Enable Google in Firebase, add the Android SHA-1, then reinstall the app.',
      'ru':
          'Google не настроен на этом устройстве. Включите Google в Firebase, добавьте SHA-1 Android и переустановите приложение.',
      'ky':
          'Бул түзмөктө Google туура эмес орнотулган. Firebase\'де Google\'ду иштетип, SHA-1 кошуп, колдонмону кайра орнотуңуз.',
    },
    notEnabled: {
      'ar':
          'تسجيل الدخول عبر Google غير مفعّل في Firebase. فعّله من Authentication ← Sign-in method.',
      'en':
          'Google sign-in is disabled in Firebase. Enable it under Authentication → Sign-in method.',
      'ru':
          'Вход через Google не включён в Firebase. Включите его в Authentication → Sign-in method.',
      'ky':
          'Firebase\'де Google кирүү иштетилген эмес. Authentication → Sign-in method бөлүмүнөн иштетиңиз.',
    },
    accountConflict: {
      'ar':
          'هذا البريد مرتبط بطريقة دخول أخرى. استخدم البريد وكلمة المرور.',
      'en':
          'This email is linked to another sign-in method. Use email and password.',
      'ru':
          'Этот email привязан к другому способу входа. Используйте email и пароль.',
      'ky':
          'Бул почта башка кирүү ыкмасына байланышкан. Почта жана сырсөз колдонуңуз.',
    },
    network: {
      'ar': 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم حاول مرة أخرى.',
      'en': 'No internet connection. Check your network and try again.',
      'ru': 'Нет подключения к интернету. Проверьте сеть и попробуйте снова.',
      'ky': 'Интернет жок. Тармакты текшерип, кайра аракет кылыңыз.',
    },
  };

  /// يختار النص حسب لغة التطبيق الحالية — لا يعيد رسالة استثناء إنجليزية خام.
  static String localized(String key, [BuildContext? context]) {
    final lang = _resolveLang(context);
    final map = _fallback[key];

    final fromCache = TouryCachedAssetLoader.translate(key, Locale(lang));
    if (fromCache != null &&
        fromCache.isNotEmpty &&
        fromCache != key &&
        !_looksLikeRawException(fromCache)) {
      return fromCache;
    }

    try {
      final translated = key.tr();
      if (translated.isNotEmpty &&
          translated != key &&
          !_looksLikeRawException(translated)) {
        // إذا رجعت الترجمة الإنجليزية بينما لغة التطبيق مختلفة، استخدم الاحتياطي.
        if (map != null &&
            lang != 'en' &&
            translated == map['en'] &&
            (map[lang]?.isNotEmpty ?? false)) {
          return map[lang]!;
        }
        return translated;
      }
    } catch (_) {}

    if (map != null) {
      return map[lang] ?? map['en'] ?? key;
    }
    return key;
  }

  static String _resolveLang(BuildContext? context) {
    if (context != null && context.mounted) {
      try {
        final code = context.locale.languageCode.toLowerCase();
        if (_supported(code)) return code;
      } catch (_) {}
    }
    return 'en';
  }

  static bool _supported(String code) =>
      code == 'ar' || code == 'en' || code == 'ru' || code == 'ky';

  static bool _looksLikeRawException(String text) {
    final t = text.toLowerCase();
    return t.contains('exception') ||
        t.contains('apiexception') ||
        t.contains('platformexception') ||
        t.contains('firebase_auth/') ||
        t.contains('developer_error') ||
        t.contains('com.google') ||
        RegExp(r'^\[.*\]').hasMatch(text);
  }
}

/// يحوّل أخطاء Google Sign-In إلى رسالة مفهومة للمستخدم بكل اللغات.
String touryGoogleAuthErrorMessage(Object error, [BuildContext? context]) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'account-exists-with-different-credential' =>
        TouryGoogleAuthMessages.localized(
          TouryGoogleAuthMessages.accountConflict,
          context,
        ),
      'invalid-credential' || 'invalid-id-token' || 'missing-or-invalid-nonce' =>
        TouryGoogleAuthMessages.localized(
          TouryGoogleAuthMessages.developerError,
          context,
        ),
      'operation-not-allowed' => TouryGoogleAuthMessages.localized(
          TouryGoogleAuthMessages.notEnabled,
          context,
        ),
      'network-request-failed' => TouryGoogleAuthMessages.localized(
          TouryGoogleAuthMessages.network,
          context,
        ),
      _ => TouryGoogleAuthMessages.localized(
          TouryGoogleAuthMessages.failed,
          context,
        ),
    };
  }

  if (error is PlatformException) {
    final code = error.code;
    final message = error.message ?? '';
    if (_isUserCancelled(code, message)) {
      return '';
    }
    if (_isNetwork(code, message)) {
      return TouryGoogleAuthMessages.localized(
        TouryGoogleAuthMessages.network,
        context,
      );
    }
    if (_isDeveloperMisconfiguration(code, message)) {
      return TouryGoogleAuthMessages.localized(
        TouryGoogleAuthMessages.developerError,
        context,
      );
    }
  }

  final text = error.toString();
  if (_isUserCancelled('', text)) {
    return '';
  }
  if (_isNetwork('', text)) {
    return TouryGoogleAuthMessages.localized(
      TouryGoogleAuthMessages.network,
      context,
    );
  }
  if (text.contains('DEVELOPER_ERROR') ||
      text.contains('ApiException: 10') ||
      text.contains('sign_in_failed') ||
      text.contains('ID token missing') ||
      text.contains('SHA-1')) {
    return TouryGoogleAuthMessages.localized(
      TouryGoogleAuthMessages.developerError,
      context,
    );
  }

  return TouryGoogleAuthMessages.localized(
    TouryGoogleAuthMessages.failed,
    context,
  );
}

bool touryGoogleAuthWasCancelled(Object error) {
  if (error is PlatformException) {
    return _isUserCancelled(error.code, error.message ?? '');
  }
  return _isUserCancelled('', error.toString());
}

bool _isUserCancelled(String code, String message) {
  final m = message.toLowerCase();
  return code == 'sign_in_canceled' ||
      code == '12501' ||
      message.contains('12501') ||
      m.contains('canceled') ||
      m.contains('cancelled');
}

bool _isDeveloperMisconfiguration(String code, String message) {
  return code == 'sign_in_failed' ||
      code == '10' ||
      code == 'security_exception' ||
      message.contains('DEVELOPER_ERROR') ||
      message.contains('ApiException: 10') ||
      message.contains('ID token missing');
}

bool _isNetwork(String code, String message) {
  final m = message.toLowerCase();
  return code == 'network_error' ||
      code == '7' ||
      m.contains('network') ||
      m.contains('socket') ||
      m.contains('unreachable');
}
