import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_dashboard_invalidate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum AdminCrudAction { add, edit, delete }

/// Identifiers for list pages that should reload after CRUD.
abstract final class AdminListScope {
  static const landmarks = 'landmarks';
  static const agents = 'agents';
  static const partners = 'partners';
  static const countries = 'countries';
  static const regions = 'regions';
  static const cities = 'cities';
  static const users = 'users';
  static const drivers = 'drivers';
  static const representatives = 'representatives';
  static const transportCompanies = 'transport_companies';
  static const support = 'support';
  static const bookings = 'bookings';
  static const superAdmins = 'super_admins';
  static const typeCars = 'type_cars';
  static const auditLog = 'audit_log';
}

/// Notifies registered [AdminFirestoreList] instances to reload.
class AdminListRefresh {
  AdminListRefresh._();

  static final Map<String, Set<VoidCallback>> _listeners = {};
  static final Map<String, Set<Future<void> Function()>> _asyncListeners = {};
  static final Map<String, Set<void Function(String docId)>> _removeListeners =
      {};

  static void register(String scope, VoidCallback listener) {
    _listeners.putIfAbsent(scope, () => {}).add(listener);
  }

  static void registerAsync(String scope, Future<void> Function() listener) {
    _asyncListeners.putIfAbsent(scope, () => {}).add(listener);
  }

  static void unregister(String scope, VoidCallback listener) {
    _listeners[scope]?.remove(listener);
  }

  static void unregisterAsync(String scope, Future<void> Function() listener) {
    _asyncListeners[scope]?.remove(listener);
  }

  static void registerRemove(
    String scope,
    void Function(String docId) listener,
  ) {
    _removeListeners.putIfAbsent(scope, () => {}).add(listener);
  }

  static void unregisterRemove(
    String scope,
    void Function(String docId) listener,
  ) {
    _removeListeners[scope]?.remove(listener);
  }

  static void removeItem(String scope, String docId) {
    final listeners = _removeListeners[scope];
    if (listeners == null || listeners.isEmpty) return;
    for (final listener in List<void Function(String)>.from(listeners)) {
      listener(docId);
    }
  }

  static void notify(String scope, {bool immediate = false}) {
    final listeners = _listeners[scope];
    if (listeners == null || listeners.isEmpty) return;

    void run() {
      final current = _listeners[scope];
      if (current == null) return;
      for (final listener in List<VoidCallback>.from(current)) {
        listener();
      }
    }

    if (immediate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => run());
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 200), run);
    });
  }

  /// Waits until all async list reloads finish (used after delete/edit).
  static Future<void> notifyAwait(Iterable<String> scopes) async {
    final jobs = <Future<void>>[];
    for (final scope in scopes) {
      final async = _asyncListeners[scope];
      if (async != null) {
        for (final listener in List<Future<void> Function()>.from(async)) {
          jobs.add(listener());
        }
      }
      final sync = _listeners[scope];
      if (sync != null) {
        for (final listener in List<VoidCallback>.from(sync)) {
          listener();
        }
      }
    }
    if (jobs.isEmpty) return;
    await Future.wait(jobs);
  }

  static void notifyAll({bool immediate = false}) {
    for (final scope in _listeners.keys.toList()) {
      notify(scope, immediate: immediate);
    }
  }
}

/// Unified popup feedback + list refresh after add / edit / delete.
abstract final class AdminCrudFeedback {
  AdminCrudFeedback._();

  static String deleteSuccessMessage(BuildContext context) =>
      FFLocalizations.of(context).getText('adm_deleted_success');

  static String defaultMessage(BuildContext context, AdminCrudAction action) {
    final l10n = FFLocalizations.of(context);
    switch (action) {
      case AdminCrudAction.add:
        return l10n.getText('adm_added_success');
      case AdminCrudAction.edit:
        return l10n.getText('adm_saved_success');
      case AdminCrudAction.delete:
        return l10n.getText('adm_deleted_success');
    }
  }

  static String saveFailed(BuildContext context, Object error) =>
      '${FFLocalizations.of(context).getText('adm_save_failed')}: $error';

  static String deleteFailed(BuildContext context, Object error) =>
      '${FFLocalizations.of(context).getText('adm_delete_failed')}: $error';

  static String updateFailed(BuildContext context, Object error) =>
      '${FFLocalizations.of(context).getText('adm_update_failed')}: $error';

  static String uploadFailed(BuildContext context, Object error) =>
      '${FFLocalizations.of(context).getText('adm_upload_failed')}: $error';

  static IconData _icon(AdminCrudAction action) {
    switch (action) {
      case AdminCrudAction.add:
        return Icons.add_circle_outline_rounded;
      case AdminCrudAction.edit:
        return Icons.edit_note_rounded;
      case AdminCrudAction.delete:
        return Icons.delete_outline_rounded;
    }
  }

  static void _showSnackSuccess(
    BuildContext context, {
    required AdminCrudAction action,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminUi.brandTeal,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: duration,
        content: Row(
          children: [
            Icon(_icon(action), color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Blocking success popup — shown immediately on root navigator.
  static Future<void> _showDeleteSuccessDialog(String message) async {
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    await showDialog<void>(
      context: navContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        Future<void>.delayed(const Duration(milliseconds: 2400), () {
          if (dialogCtx.mounted) {
            Navigator.of(dialogCtx, rootNavigator: true).pop();
          }
        });
        return PopScope(
          canPop: true,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminUi.radiusMd),
            ),
            elevation: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AdminUi.brandTeal,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> success(
    BuildContext context, {
    required AdminCrudAction action,
    String? message,
    String? refreshScope,
    Iterable<String>? refreshScopes,
    String? removedDocumentId,
    Future<void> Function()? refresh,
    bool invalidateStats = true,
    bool popPage = false,
    bool? deferHeavyWork,
  }) async {
    if (!context.mounted) return;

    final text = message ?? defaultMessage(context, action);
    final isDelete = action == AdminCrudAction.delete;
    final deleteMessage =
        isDelete ? (message ?? deleteSuccessMessage(context)) : text;
    final shouldDefer = deferHeavyWork ?? !isDelete;

    final scopes = <String>{
      ...?refreshScopes,
      if (refreshScope != null) refreshScope,
    };

    void refreshLists({required bool immediate, bool removeRow = false}) {
      if (removeRow && removedDocumentId != null) {
        for (final scope in scopes) {
          AdminListRefresh.removeItem(scope, removedDocumentId);
        }
      }
      for (final scope in scopes) {
        AdminListRefresh.notify(scope, immediate: immediate);
      }
      if (refresh != null) {
        unawaited(refresh());
      }
    }

    if (isDelete) {
      if (removedDocumentId != null) {
        for (final scope in scopes) {
          AdminListRefresh.removeItem(scope, removedDocumentId);
        }
      }

      if (refresh != null) {
        await refresh();
      }
      await AdminListRefresh.notifyAwait(scopes);

      // 2) Popup + snackbar only after DB delete + server refresh succeeded.
      if (context.mounted) {
        _showSnackSuccess(
          context,
          action: AdminCrudAction.delete,
          message: deleteMessage,
          duration: const Duration(seconds: 4),
        );
      }
      unawaited(_showDeleteSuccessDialog(deleteMessage));

      if (invalidateStats) {
        refreshDashboardStatsAfterDelete(
          refreshScope: refreshScope,
          refreshScopes: refreshScopes,
        );
      }

      if (popPage && context.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (context.mounted) context.safePop();
      }
      return;
    }

    _showSnackSuccess(context, action: action, message: text);
    if (refresh != null) {
      await refresh();
    }
    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(
          const Duration(milliseconds: 200),
          () => refreshLists(immediate: false),
        );
      });
    } else {
      await AdminListRefresh.notifyAwait(scopes);
      refreshLists(immediate: true);
    }

    if (invalidateStats) {
      if (!shouldDefer) {
        invalidateAdminDashboardStats();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future<void>.delayed(
            const Duration(milliseconds: 200),
            invalidateAdminDashboardStats,
          );
        });
      }
    }

    if (popPage && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (context.mounted) context.safePop();
    }
  }

  static void error(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC62828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void validation(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF6C00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Text(message),
      ),
    );
  }
}
