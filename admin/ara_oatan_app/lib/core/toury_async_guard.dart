import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/core/toury_dialogs.dart';

/// تنفيذ عملية غير متزامنة مع معالجة أخطاء موحّدة للمنتج النهائي.
Future<T?> touryRunGuarded<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? loadingMessage,
  String? successMessage,
  String? errorMessage,
  bool showErrorDialog = true,
}) async {
  if (loadingMessage != null && context.mounted) {
    TouryDialogs.showSnackBar(
      context,
      loadingMessage,
      type: TouryMessageType.info,
      loading: true,
    );
  }

  try {
    final result = await action();
    if (loadingMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    if (successMessage != null && context.mounted) {
      TouryDialogs.showSnackBar(
        context,
        successMessage,
        type: TouryMessageType.success,
      );
    }
    return result;
  } catch (e, st) {
    debugPrint('touryRunGuarded: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (showErrorDialog) {
        await TouryDialogs.showAlert(
          context,
          title: 'dialog_error_title'.tr(),
          message: errorMessage ?? 'generic_error_retry'.tr(),
          type: TouryMessageType.error,
        );
      } else {
        TouryDialogs.showSnackBar(
          context,
          errorMessage ?? 'generic_error_retry'.tr(),
          type: TouryMessageType.error,
        );
      }
    }
    return null;
  }
}

/// للعمليات بدون واجهة (تهيئة، كاش).
Future<T?> touryRunSilent<T>(
  Future<T> Function() action, {
  void Function(Object error, StackTrace stack)? onError,
}) async {
  try {
    return await action();
  } catch (e, st) {
    debugPrint('touryRunSilent: $e\n$st');
    onError?.call(e, st);
    return null;
  }
}
