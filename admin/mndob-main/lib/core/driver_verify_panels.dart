import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/core/driver_email_verification_service.dart';
import '/design_system/design_system.dart';

/// Full-screen gate: verify email via Firebase Auth email **link**, then continue.
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

class _DriverEmailVerifyPanelState extends State<DriverEmailVerifyPanel>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _sending = false;
  String? _message;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkVerified(silent: true));
    }
  }

  Future<void> _bootstrap() async {
    if (await DriverEmailVerificationService.reloadAndCheckVerified()) {
      widget.onVerified();
      return;
    }
    await _sendLink();
  }

  Future<void> _sendLink() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await DriverEmailVerificationService.sendVerificationEmail();
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        widget.onVerified();
        return;
      }
        setState(
          () => _message = widget.t('Verification link sent. Check your inbox.'),
        );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _message = widget.t(_mapAuthError(e.code)));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _message = widget.t(_mapError(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = widget.t('Network error'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_busy) return;
    if (!silent) {
      setState(() => _busy = true);
    }
    try {
      final ok = await DriverEmailVerificationService.reloadAndCheckVerified();
      if (!mounted) return;
      if (ok) {
        setState(() => _message = widget.t('Email verified successfully'));
        widget.onVerified();
      } else if (!silent) {
        setState(
          () => _message = widget.t(
            'Email not verified yet. Open the link in your inbox, then try again.',
          ),
        );
      }
    } catch (_) {
      if (!mounted || silent) return;
      setState(() => _message = widget.t('Network error'));
    } finally {
      if (mounted && !silent) setState(() => _busy = false);
    }
  }

  String _mapError(String? message) {
    switch (message) {
      case 'RESEND_COOLDOWN':
        return 'Resend cooldown';
      default:
        return 'Network error';
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'too-many-requests':
        return 'Too many attempts';
      case 'requires-recent-login':
        return 'Please sign in again';
      default:
        return 'Network error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final cooldown = DriverEmailVerificationService.remainingCooldown;
    final cooldownLabel = cooldown == null ? null : '${cooldown.inSeconds}s';
    final masked = DriverEmailVerificationService.maskEmail(widget.email);

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
                .replaceAll('{email}', masked),
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          DsSpacing.gapMd,
          if (_message != null) ...[
            Text(
              _message!,
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            DsSpacing.gapMd,
          ],
          const Spacer(),
          DsButton.outlined(
            label: cooldownLabel == null
                ? widget.t('Resend verification link')
                : '${widget.t('Resend in')} $cooldownLabel',
            expanded: true,
            enabled: !_busy && !_sending && cooldownLabel == null,
            onPressed: _sendLink,
          ),
          DsSpacing.gapSm,
          DsButton.primary(
            label: widget.t('I verified my email'),
            expanded: true,
            loading: _busy,
            enabled: !_busy && !_sending,
            onPressed: () => _checkVerified(silent: false),
          ),
        ],
      ),
    );
  }
}
