import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '/core/email_otp_verification_service.dart';
import '/design_system/design_system.dart';

/// Full-screen gate: verify email via 6-digit Email OTP, then continue.
///
/// Phone OTP is intentionally not part of Registration V2.
class DriverEmailVerifyPanel extends StatefulWidget {
  const DriverEmailVerifyPanel({
    super.key,
    required this.email,
    required this.onVerified,
    required this.t,
  });

  final String email;
  final VoidCallback onVerified;
  final String Function(String) t;

  @override
  State<DriverEmailVerifyPanel> createState() => _DriverEmailVerifyPanelState();
}

class _DriverEmailVerifyPanelState extends State<DriverEmailVerifyPanel> {
  bool _busy = false;
  bool _sending = false;
  String _code = '';
  String? _message;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
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
      widget.onVerified();
      return;
    }
    await _request();
  }

  Future<void> _request() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      final res = await EmailOtpVerificationService.requestOtp();
      if (!mounted) return;
      if (res['alreadyVerified'] == true) {
        widget.onVerified();
        return;
      }
      setState(() => _message = widget.t('Code sent'));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _message = widget.t(_mapError(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = widget.t('Network error'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || _code.length != 6) return;
    setState(() => _busy = true);
    try {
      final ok = await EmailOtpVerificationService.verifyOtp(_code);
      if (!mounted) return;
      if (ok) {
        setState(() => _message = widget.t('Email verified successfully'));
        widget.onVerified();
      } else {
        setState(() => _message = widget.t('Invalid code'));
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _message = widget.t(_mapError(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = widget.t('Network error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(String? message) {
    switch (message) {
      case 'INVALID_CODE':
        return 'Invalid code';
      case 'OTP_EXPIRED':
        return 'Expired code';
      case 'TOO_MANY_ATTEMPTS':
        return 'Too many attempts';
      case 'RESEND_COOLDOWN':
        return 'Resend cooldown';
      default:
        return 'Network error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final cooldown = EmailOtpVerificationService.remainingCooldown;
    final cooldownLabel = cooldown == null ? null : '${cooldown.inSeconds}s';
    final masked = EmailOtpVerificationService.maskEmail(widget.email);

    return Padding(
      padding: DsSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.t('Verify your email'),
            style: typography.headlineSmall.copyWith(color: colors.textPrimary),
          ),
          DsSpacing.gapSm,
          Text(
            widget
                .t('Enter the 6-digit verification code sent to {email}')
                .replaceAll('{email}', masked),
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          DsSpacing.gapMd,
          DsOtpField(
            length: 6,
            enabled: !_busy && !_sending,
            onChanged: (v) => setState(() => _code = v),
          ),
          if (_message != null) ...[
            DsSpacing.gapMd,
            Text(
              _message!,
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
          const Spacer(),
          DsButton.outlined(
            label: cooldownLabel == null
                ? widget.t('Resend code')
                : '${widget.t('Resend in')} $cooldownLabel',
            expanded: true,
            enabled: !_busy && !_sending && cooldownLabel == null,
            onPressed: _request,
          ),
          DsSpacing.gapSm,
          DsButton.primary(
            label: widget.t('Verify'),
            expanded: true,
            loading: _busy,
            enabled: !_busy && !_sending && _code.length == 6,
            onPressed: _verify,
          ),
        ],
      ),
    );
  }
}
