import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '/auth/firebase_auth/google_auth.dart';
import '/backend/backend.dart';
import '/core/app_design_system.dart';
import '/core/toury_google_auth_errors.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';

/// Whether Google quick sign-in is enabled (Settings/islogenGoogle).
bool touryIsGoogleSignInEnabled(SettingsRecord? settings) {
  if (settings == null) return true;
  final raw = settings.snapshotData['islogenGoogle'];
  if (raw == null) return true;
  return raw == true;
}

/// يعرض ورقة اختيار حساب Google ثم يُرجع بيانات الاعتماد لـ Firebase.
Future<UserCredential?> touryPickGoogleAccountAndSignIn(
  BuildContext context,
) async {
  if (kIsWeb) {
    return googleSignInWithAccount(forceAccountPicker: true);
  }

  // Quick path: one-tap when a Google account is already on this device.
  // If silent auth fails (common SHA/config issues), fall through to picker.
  try {
    final silent = await touryGoogleSignIn.signInSilently();
    if (silent != null) {
      try {
        final credential = await firebaseSignInWithGoogleAccount(silent);
        if (credential != null) return credential;
      } catch (e) {
        debugPrint('touryPickGoogleAccountAndSignIn silent firebase: $e');
        if (touryGoogleAuthWasCancelled(e)) return null;
      }
    }
  } catch (e) {
    debugPrint('touryPickGoogleAccountAndSignIn silent: $e');
  }

  if (!context.mounted) return null;

  final account = await showModalBottomSheet<GoogleSignInAccount>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _TouryGoogleAccountPickerSheet(),
  );

  if (account == null || !context.mounted) {
    return null;
  }

  return firebaseSignInWithGoogleAccount(account);
}

/// Google sign-in button gated by Settings/islogenGoogle (on by default).
Widget touryGoogleSignInButtonFromSettings({
  required BuildContext context,
  required SettingsRecord? settings,
  required bool loading,
  required VoidCallback onPressed,
  String? label,
}) {
  if (!touryIsGoogleSignInEnabled(settings)) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
    child: TouryGoogleSignInButton(
      label: label,
      loading: loading,
      onPressed: onPressed,
    ),
  );
}

/// زر تسجيل الدخول عبر Google — تصميم موحّد لشاشة الدخول.
class TouryGoogleSignInButton extends StatelessWidget {
  const TouryGoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label,
    this.loading = false,
    this.expanded = true,
  });

  final VoidCallback? onPressed;
  final String? label;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final text = label ?? 'Login with Google'.tr();

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: DsRadius.small,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: DsRadius.small,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.primary,
                    ),
                  )
                else
                  const _GoogleGlyph(),
                const SizedBox(width: DsSpacing.sm),
                Flexible(
                  child: TouryText(
                    text,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.textPrimary,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TouryGoogleAccountPickerSheet extends StatefulWidget {
  const _TouryGoogleAccountPickerSheet();

  @override
  State<_TouryGoogleAccountPickerSheet> createState() =>
      _TouryGoogleAccountPickerSheetState();
}

class _TouryGoogleAccountPickerSheetState
    extends State<_TouryGoogleAccountPickerSheet> {
  GoogleSignInAccount? _recentAccount;
  bool _loadingRecent = true;
  bool _openingPicker = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentAccount();
  }

  Future<void> _loadRecentAccount() async {
    try {
      final account = await touryGoogleSignIn.signInSilently();
      if (!mounted) return;
      setState(() {
        _recentAccount = account;
        _loadingRecent = false;
      });
      if (account == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_openingPicker) {
            _pickWithSystemChooser(forcePicker: true);
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecent = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_openingPicker) {
          _pickWithSystemChooser(forcePicker: true);
        }
      });
    }
  }

  Future<void> _pickWithSystemChooser({bool forcePicker = false}) async {
    setState(() {
      _openingPicker = true;
      _error = null;
    });

    try {
      final account = await pickGoogleAccount(forcePicker: forcePicker);
      if (!mounted) return;
      if (account != null) {
        Navigator.of(context).pop(account);
        return;
      }
      setState(() {
        _openingPicker = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (touryGoogleAuthWasCancelled(e)) {
        setState(() => _openingPicker = false);
        return;
      }
      setState(() {
        _openingPicker = false;
        _error = touryGoogleAuthErrorMessage(e, context);
      });
    }
  }

  Future<void> _useRecentAccount() async {
    final recent = _recentAccount;
    if (recent == null) {
      await _pickWithSystemChooser(forcePicker: true);
      return;
    }

    setState(() {
      _openingPicker = true;
      _error = null;
    });

    try {
      final auth = await recent.authentication;
      if (auth.idToken == null && auth.accessToken == null) {
        await _pickWithSystemChooser(forcePicker: true);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(recent);
    } catch (_) {
      await _pickWithSystemChooser(forcePicker: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const _GoogleGlyph(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TouryText(
                            'auth_google_pick_title'.tr(),
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: colors.textPrimary,
                          ),
                          const SizedBox(height: 4),
                          TouryText(
                            'auth_google_pick_sub'.tr(),
                            fontSize: 13,
                            color: colors.textSecondary,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_loadingRecent)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                  )
                else ...[
                  if (_recentAccount != null)
                    _AccountTile(
                      account: _recentAccount!,
                      subtitle: 'auth_google_recent_account'.tr(),
                      onTap: _openingPicker ? null : _useRecentAccount,
                    ),
                  if (_recentAccount != null) const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        _openingPicker ? null : () => _pickWithSystemChooser(
                              forcePicker: true,
                            ),
                    icon: _openingPicker
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : const Icon(Icons.account_circle_outlined),
                    label: Text(
                      _recentAccount == null
                          ? 'auth_google_show_accounts'.tr()
                          : 'auth_google_other_account'.tr(),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: colors.primary),
                      foregroundColor: colors.primaryStrong,
                      shape: RoundedRectangleBorder(
                        borderRadius: DsRadius.small,
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  TouryText(
                    _error!,
                    textAlign: TextAlign.center,
                    color: colors.error,
                    fontSize: 13,
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openingPicker
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('dialog_cancel'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.subtitle,
    required this.onTap,
  });

  final GoogleSignInAccount account;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return Material(
      color: colors.primarySoft,
      borderRadius: DsRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.surface,
                backgroundImage: account.photoUrl != null
                    ? NetworkImage(account.photoUrl!)
                    : null,
                child: account.photoUrl == null
                    ? Icon(Icons.person, color: colors.textSecondary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TouryText(
                      account.displayName ?? account.email,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    TouryText(
                      account.email,
                      fontSize: 12,
                      color: colors.textSecondary,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    TouryText(
                      subtitle,
                      fontSize: 11,
                      color: colors.primaryStrong,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
