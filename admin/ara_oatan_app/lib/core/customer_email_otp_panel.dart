import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/core/email_otp_verification_service.dart';
import '/design_system/design_system.dart';

/// Customer email verification panel.
///
/// Release policy: Firebase Auth **email link** only (no 6-digit OTP UI).
/// SoT remains [User.emailVerified] after [User.reload].
class CustomerEmailOtpPanel extends StatefulWidget {
  const CustomerEmailOtpPanel({
    super.key,
    required this.email,
    this.onVerified,
  });

  final String email;
  final VoidCallback? onVerified;

  @override
  State<CustomerEmailOtpPanel> createState() => _CustomerEmailOtpPanelState();
}

class _CustomerEmailOtpPanelState extends State<CustomerEmailOtpPanel> {
  bool _sending = false;
  bool _checking = false;
  String? _message;
  String? _errorKey;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Force link mode for Customer release — OTP CF remains DORMANT.
    EmailOtpVerificationService.mode = EmailVerificationMode.emailLink;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (await EmailOtpVerificationService.reloadAndCheckVerified()) {
      widget.onVerified?.call();
      return;
    }
    await _request();
  }

  Future<void> _request() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _errorKey = null;
      _message = null;
    });
    try {
      final locale = context.locale.languageCode;
      final res = await EmailOtpVerificationService.requestOtp(locale: locale);
      if (!mounted) return;
      if (res['alreadyVerified'] == true) {
        widget.onVerified?.call();
        return;
      }
      setState(() => _message = 'email_link_sent'.tr());
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _mapError(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorKey = 'email_otp_network_error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _errorKey = null;
    });
    try {
      final ok = await EmailOtpVerificationService.reloadAndCheckVerified();
      if (!mounted) return;
      if (ok) {
        setState(() => _message = 'email_otp_verified_success'.tr());
        widget.onVerified?.call();
      } else {
        setState(() => _errorKey = 'email_link_not_verified_yet');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorKey = 'email_otp_network_error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _mapError(String? message) {
    switch (message) {
      case 'RESEND_COOLDOWN':
        return 'email_otp_resend_cooldown';
      case 'RATE_LIMITED':
        return 'email_otp_rate_limited';
      default:
        return 'email_otp_network_error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final cooldown = EmailOtpVerificationService.remainingCooldown;
    final cooldownLabel =
        cooldown == null ? null : '${cooldown.inSeconds}s';
    final masked = EmailOtpVerificationService.maskEmail(widget.email);

    return Semantics(
      identifier: 'qa-customer-email-link',
      label: 'qa-customer-email-link',
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'email_otp_verify_title'.tr(),
              style: typography.titleMedium.copyWith(color: colors.textPrimary),
            ),
            DsSpacing.gapXs,
            Text(
              'email_link_open_inbox'.tr(namedArgs: {'email': masked}),
              style: typography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            DsSpacing.gapMd,
            if (_message != null)
              Text(
                _message!,
                style: typography.bodySmall.copyWith(color: colors.success),
              ),
            if (_errorKey != null)
              Text(
                _errorKey!.tr(),
                style: typography.bodySmall.copyWith(color: colors.error),
              ),
            DsSpacing.gapSm,
            DsButton.primary(
              label: 'email_link_i_verified'.tr(),
              expanded: true,
              loading: _checking,
              onPressed: _checking ? null : _checkVerified,
            ),
            DsSpacing.gapXs,
            DsButton.text(
              label: cooldownLabel == null
                  ? 'email_link_resend'.tr()
                  : '${'email_otp_resend_in'.tr()} $cooldownLabel',
              onPressed: (_sending || cooldown != null) ? null : _request,
            ),
          ],
        ),
      ),
    );
  }
}
