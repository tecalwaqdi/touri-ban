import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// UI guard for screens restricted to super admin (`isAdminRule == 1` or `IsAdmin`).
class AdminSuperAdminGate {
  AdminSuperAdminGate._();

  static bool get isProfileLoading =>
      loggedIn && currentUserDocument == null;

  static bool get isAllowed {
    if (isProfileLoading) return false;
    return AdminRoleService.isSuperAdmin;
  }

  static Widget profileLoadingLayout({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required dynamic menu2Model,
    required VoidCallback updateCallback,
    required String title,
  }) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: menu2Model,
      updateCallback: updateCallback,
      title: title,
      child: AdminPageBody(
        title: uiTr(context, 'جاري التحميل'),
        subtitle: uiTr(context, 'يتم تحميل بيانات حسابك'),
        child: AdminContentCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget deniedLayout({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required dynamic menu2Model,
    required VoidCallback updateCallback,
    required String title,
    String feature = 'هذه الصفحة',
  }) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: menu2Model,
      updateCallback: updateCallback,
      title: title,
      child: AdminPageBody(
        title: uiTr(context, 'غير مصرّح'),
        subtitle: uiTr(context, 'متاح لسوبر الأدمن فقط'),
        child: AdminContentCard(
          child: Text(
            'لا تملك صلاحية الوصول إلى $feature.',
            style: theme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  static Widget deniedEditScaffold({
    required BuildContext context,
    required String title,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا تملك صلاحية الوصول. هذه الميزة متاحة لسوبر الأدمن فقط.',
            style: theme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Returns a blocking widget, or null when the super admin may proceed.
  static Widget? guardLayout({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required dynamic menu2Model,
    required VoidCallback updateCallback,
    required String title,
    String feature = 'هذه الصفحة',
  }) {
    if (isProfileLoading) {
      return profileLoadingLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: menu2Model,
        updateCallback: updateCallback,
        title: title,
      );
    }
    if (!isAllowed) {
      return deniedLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: menu2Model,
        updateCallback: updateCallback,
        title: title,
        feature: feature,
      );
    }
    return null;
  }
}
