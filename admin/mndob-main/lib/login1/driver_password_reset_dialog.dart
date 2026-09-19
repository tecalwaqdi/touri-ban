import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '/core/driver_auth_errors.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_password_reset_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// OTP + new password after [DriverPasswordResetService.requestOtp].
Future<bool> showDriverPasswordResetDialog({
  required BuildContext context,
  required String email,
  required String emailMasked,
}) async {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  var obscure = true;
  var loading = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !loading,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> submit() async {
            if (loading) return;
            final pwd = passwordController.text;
            final confirm = confirmController.text;
            if (pwd != confirm) {
              await DriverDialogs.showAlert(
                ctx,
                title: driverTr(ctx, 'Error'),
                message: driverTr(ctx, 'Passwords do not match'),
                type: DriverMessageType.warning,
              );
              return;
            }
            setLocal(() => loading = true);
            try {
              await DriverPasswordResetService.confirmReset(
                code: codeController.text,
                newPassword: pwd,
              );
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            } on FirebaseFunctionsException catch (e) {
              DriverAuthErrors.logSafely(e);
              if (ctx.mounted) {
                await DriverDialogs.showAlert(
                  ctx,
                  title: driverTr(ctx, 'Error'),
                  message: _resetErrorMessage(ctx, e.message ?? ''),
                  type: DriverMessageType.warning,
                );
              }
            } catch (e) {
              DriverAuthErrors.logSafely(e);
              if (ctx.mounted) {
                await DriverDialogs.showAlert(
                  ctx,
                  title: driverTr(ctx, 'Error'),
                  message: driverTr(
                    ctx,
                    'Something went wrong. Please try again.',
                  ),
                  type: DriverMessageType.warning,
                );
              }
            } finally {
              if (ctx.mounted) setLocal(() => loading = false);
            }
          }

          return AlertDialog(
            title: Text(driverTr(ctx, 'Reset password')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    driverTrNamed(
                      ctx,
                      'Enter the 6-digit verification code sent to {email}',
                      {'email': emailMasked},
                    ),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DsSpacing.md),
                  DsTextField(
                    controller: codeController,
                    label: driverTr(ctx, 'Verification code'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  DsTextField.password(
                    controller: passwordController,
                    label: driverTr(ctx, 'New password'),
                    obscureText: obscure,
                    suffixIcon: DsIconButton(
                      icon: obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: DsIcons.md,
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  DsTextField.password(
                    controller: confirmController,
                    label: driverTr(ctx, 'Confirm Password'),
                    obscureText: obscure,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
                child: Text(driverTr(ctx, 'Cancel')),
              ),
              FilledButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(driverTr(ctx, 'Save new password')),
              ),
            ],
          );
        },
      );
    },
  );

  codeController.dispose();
  passwordController.dispose();
  confirmController.dispose();
  return result == true;
}

String _resetErrorMessage(BuildContext context, String code) {
  const map = {
    'OTP_INVALID': 'Invalid verification code.',
    'OTP_EXPIRED': 'Verification code expired. Request a new one.',
    'OTP_TOO_MANY_ATTEMPTS': 'Too many attempts. Please try again later.',
    'OTP_CONSUMED': 'Verification code expired. Request a new one.',
    'WEAK_PASSWORD': 'Password must be at least 6 characters',
    'SEND_RATE_LIMITED': 'Too many attempts. Please try again later.',
    'RESEND_PROVIDER_ERROR': 'Something went wrong. Please try again.',
    'OTP_SEND_FAILED': 'Something went wrong. Please try again.',
  };
  final key = map[code.trim()] ?? DriverAuthErrors.messageKeyForCode(code);
  return driverTr(context, key);
}
