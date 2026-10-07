import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_approved_profile_policy.dart';
import '/core/driver_data_change_request_form.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_secure_account_update_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Contact edits (phone/email/password) + Request Data Change for approved drivers.
class DriverAccountSecurityWidget extends StatefulWidget {
  const DriverAccountSecurityWidget({super.key});

  static String routeName = 'DriverAccountSecurity';
  static String routePath = '/driverAccountSecurity';

  @override
  State<DriverAccountSecurityWidget> createState() =>
      _DriverAccountSecurityWidgetState();
}

class _DriverAccountSecurityWidgetState
    extends State<DriverAccountSecurityWidget> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final doc = currentUserDocument;
    _phoneCtrl.text = doc?.phoneNumber ?? '';
    _emailCtrl.text = doc?.email ?? currentUserEmail;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  String t(String key) => driverTr(context, key);

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final err = await action();
      if (!mounted) return;
      if (err != null) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(err),
          type: DriverMessageType.error,
        );
      } else {
        await DriverDialogs.showAlert(
          context,
          title: t('Success'),
          message: t('Data updated successfully'),
          type: DriverMessageType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onChangeRequestSubmitted() {
    final doc = currentUserDocument;
    if (doc != null &&
        DriverApprovedProfilePolicy.hasOpenCorrectionRequest(doc)) {
      context.pushNamed(DriverPendingApprovalWidget.routeName);
      return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final doc = currentUserDocument;
    final approved = DriverApprovedProfilePolicy.isApprovedOrActive(doc);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(t('Account security')),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DsSpacing.md),
        children: [
          Text(
            t('Contact details'),
            style: typography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: DsSpacing.sm),
          TextField(
            controller: _phoneCtrl,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t('Phone number')),
          ),
          const SizedBox(height: DsSpacing.sm),
          TextField(
            controller: _currentPasswordCtrl,
            enabled: !_busy,
            obscureText: true,
            decoration: InputDecoration(
              labelText: t('Current password'),
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => DriverSecureAccountUpdateService.updatePhoneNumber(
                        rawPhone: _phoneCtrl.text,
                        currentPassword: _currentPasswordCtrl.text,
                      ),
                    ),
            child: Text(t('Update phone number')),
          ),
          const SizedBox(height: DsSpacing.lg),
          TextField(
            controller: _emailCtrl,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: t('Email')),
          ),
          const SizedBox(height: DsSpacing.sm),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => DriverSecureAccountUpdateService.updateEmail(
                        currentPassword: _currentPasswordCtrl.text,
                        newEmail: _emailCtrl.text,
                      ),
                    ),
            child: Text(t('Update email')),
          ),
          const SizedBox(height: DsSpacing.lg),
          TextField(
            controller: _newPasswordCtrl,
            enabled: !_busy,
            obscureText: true,
            decoration: InputDecoration(labelText: t('New password')),
          ),
          const SizedBox(height: DsSpacing.sm),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => DriverSecureAccountUpdateService.updatePassword(
                        currentPassword: _currentPasswordCtrl.text,
                        newPassword: _newPasswordCtrl.text,
                      ),
                    ),
            child: Text(t('Update password')),
          ),
          if (approved && doc != null) ...[
            const SizedBox(height: DsSpacing.xl),
            DriverDataChangeRequestForm(
              driver: doc,
              enabled: !_busy,
              onSubmitted: _onChangeRequestSubmitted,
            ),
          ],
        ],
      ),
    );
  }
}
