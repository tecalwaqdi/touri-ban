import 'package:flutter/material.dart';

import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';

/// تنفيذ عملية غير متزامنة مع معالجة أخطاء موحّدة.
Future<T?> driverRunGuarded<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? loadingMessage,
  String? successMessage,
  String? errorMessage,
  bool showErrorDialog = true,
}) async {
  if (loadingMessage != null && context.mounted) {
    DriverDialogs.showSnackBar(
      context,
      loadingMessage,
      type: DriverMessageType.info,
      loading: true,
    );
  }

  try {
    final result = await action();
    if (loadingMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    if (successMessage != null && context.mounted) {
      DriverDialogs.showSnackBar(
        context,
        successMessage,
        type: DriverMessageType.success,
      );
    }
    return result;
  } catch (e, st) {
    debugPrint('driverRunGuarded: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final msg = errorMessage ?? driverTr(context, 'Something went wrong. Please try again.');
      if (showErrorDialog) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Error'),
          message: msg,
          type: DriverMessageType.error,
        );
      } else {
        DriverDialogs.showSnackBar(
          context,
          msg,
          type: DriverMessageType.error,
        );
      }
    }
    return null;
  }
}
