import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_country_landmark_filter.dart';
import '/backend/admin_panel_session.dart';
import '/backend/admin_prefetch.dart';
import '/backend/admin_role_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Finishes sign-in: syncs auth globals, loads profile, opens panel home.
Future<AdminLoginResult> completePanelSignIn(
  BaseAuthUser authUser,
) async {
  currentUser = authUser;
  AppStateNotifier.instance.updateSilently(authUser);

  final profile = await ensureCurrentUserDocument(forceRefresh: true);
  if (profile == null) {
    AppStateNotifier.instance.updateNotifyOnAuthChange(true);
    return AdminLoginResult.profileLoadFailed;
  }

  await refreshAuthClaims();
  if (!AdminRoleService.hasPanelAccess) {
    AppStateNotifier.instance.updateNotifyOnAuthChange(true);
    return AdminLoginResult.unauthorized;
  }

  await AdminPanelSession.ensureScopeReady(force: true);

  AppStateNotifier.instance.stopShowingSplashImage();
  AppStateNotifier.instance.updateNotifyOnAuthChange(true);
  AppStateNotifier.instance.update(authUser, forceNotify: true);
  AppStateNotifier.instance.notifyProfileReady();

  syncPanelHomeUrl();

  unawaited(_warmListsInBackground());

  return AdminLoginResult.success;
}

Future<void> _warmListsInBackground() async {
  try {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!loggedIn) return;
    await AdminPrefetch.warmAfterLogin();
    if (AdminRoleService.isCountryAgent) {
      AdminCountryLandmarkFilter.scheduleWarmCache();
    }
  } catch (_) {}
}

enum AdminLoginResult {
  success,
  profileLoadFailed,
  unauthorized,
  navigationFailed,
}

String messageForLoginResult(BuildContext context, AdminLoginResult result) {
  switch (result) {
    case AdminLoginResult.success:
      return '';
    case AdminLoginResult.profileLoadFailed:
      return FFLocalizations.of(context).getText('adm_login_profile_failed');
    case AdminLoginResult.unauthorized:
      return FFLocalizations.of(context).getText('adm_login_unauthorized');
    case AdminLoginResult.navigationFailed:
      return FFLocalizations.of(context).getText('adm_login_nav_failed');
  }
}
