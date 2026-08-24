import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/core/driver_email_verification_service.dart';
import '/design_system/design_system.dart';

/// Full-screen gate: verify email via Firebase Auth, then continue.
///
/// Phone OTP is intentionally not part of Registration V2 (Owner policy:
/// phone required as profile field only; emailVerified is the sole Auth gate).
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
  String? _message;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sendInitial());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _sendInitial() async {
    try {
      await DriverEmailVerificationService.sendVerificationEmail();
      if (mounted) {
        setState(() => _message = widget.t('Verification email sent'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString());
      }
    }
  }

  Future<void> _resend() async {
    if (!DriverEmailVerificationService.canResend || _busy) return;
    setState(() => _busy = true);
    try {
      await DriverEmailVerificationService.sendVerificationEmail();
      if (mounted) {
        setState(() => _message = widget.t('Verification email sent'));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _message = e.message ?? e.code);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await DriverEmailVerificationService.reloadAndCheckVerified();
      if (!mounted) return;
      if (ok) {
        widget.onVerified();
      } else {
        setState(() {
          _message = widget.t(
            'Email not verified yet. Open the link in your inbox, then try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final cooldown = DriverEmailVerificationService.remainingCooldown;
    final cooldownLabel = cooldown == null ? null : '${cooldown.inSeconds}s';

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
                .t(
                  'We sent a verification link to {email}. Open it, then tap I verified my email.',
                )
                .replaceAll('{email}', widget.email),
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
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
                ? widget.t('Resend')
                : '${widget.t('Resend')} ($cooldownLabel)',
            expanded: true,
            enabled: !_busy && cooldownLabel == null,
            onPressed: _resend,
          ),
          DsSpacing.gapSm,
          DsButton.primary(
            label: widget.t('I verified my email'),
            expanded: true,
            loading: _busy,
            onPressed: _check,
          ),
        ],
      ),
    );
  }
}
