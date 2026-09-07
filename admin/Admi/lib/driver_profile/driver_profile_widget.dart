import '/backend/admin_resource_guard.dart';
import '/backend/backend.dart';
import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/components/admin_edit_shell.dart';
import '/core/admin_driver_route_params.dart';
import '/core/admin_user_facing_errors.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'driver_profile_body.dart';
import 'driver_profile_model.dart';
export 'driver_profile_model.dart';

enum _ProfileLoadPhase { loading, invalidParam, notFound, error, denied, ready }

class DriverProfileWidget extends StatefulWidget {
  const DriverProfileWidget({super.key, required this.iduser});

  final DocumentReference? iduser;

  static String routeName = 'DriverProfile';
  static String routePath = '/driverProfile';

  @override
  State<DriverProfileWidget> createState() => _DriverProfileWidgetState();
}

class _DriverProfileWidgetState extends State<DriverProfileWidget> {
  late DriverProfileModel _model;

  _ProfileLoadPhase _phase = _ProfileLoadPhase.loading;
  UserRecord? _user;
  DocumentReference? _resolvedRef;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverProfileModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant DriverProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRaw = _rawIduser(oldWidget);
    final newRaw = _rawIduser(widget);
    if (oldRaw != newRaw || oldWidget.iduser?.path != widget.iduser?.path) {
      _load();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String? _rawIduser([DriverProfileWidget? w]) {
    try {
      return GoRouterState.of(context).uri.queryParameters['iduser'];
    } catch (_) {
      return null;
    }
  }

  DocumentReference? _resolveRef() {
    return AdminDriverRouteParams.resolveUserRef(
      rawQuery: _rawIduser(),
      deserialized: widget.iduser,
    );
  }

  Future<void> _load() async {
    final ref = _resolveRef();
    if (!mounted) return;

    if (ref == null) {
      setState(() {
        _phase = _ProfileLoadPhase.invalidParam;
        _user = null;
        _resolvedRef = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _phase = _ProfileLoadPhase.loading;
      _resolvedRef = ref;
      _error = null;
    });

    try {
      final snap = await ref.get();
      if (!mounted) return;
      if (!snap.exists) {
        setState(() {
          _phase = _ProfileLoadPhase.notFound;
          _user = null;
        });
        return;
      }

      final user = UserRecord.fromSnapshot(snap);
      final allowed = await AdminResourceGuard.canEditDriver(user);
      if (!mounted) return;

      if (!allowed) {
        setState(() {
          _phase = _ProfileLoadPhase.denied;
          _user = user;
        });
        return;
      }

      setState(() {
        _phase = _ProfileLoadPhase.ready;
        _user = user;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ProfileLoadPhase.error;
        _error = e;
        _user = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _ProfileLoadPhase.loading:
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'ملف المندوب'),
          isLoading: true,
          body: const SizedBox.shrink(),
        );
      case _ProfileLoadPhase.invalidParam:
        return AdminMissingDocumentScaffold(
          title: uiTr(context, 'ملف المندوب'),
          message: uiTr(context, 'معرّف المندوب غير صالح'),
        );
      case _ProfileLoadPhase.notFound:
        return AdminMissingDocumentScaffold(
          title: uiTr(context, 'ملف المندوب'),
          message: uiTr(context, 'تعذر العثور على بيانات المندوب'),
        );
      case _ProfileLoadPhase.error:
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'ملف المندوب'),
          body: _ErrorRetryBody(
            message: AdminUserFacingErrors.from(
              context,
              _error ?? Exception('load_failed'),
            ),
            onRetry: _load,
          ),
        );
      case _ProfileLoadPhase.denied:
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'ملف المندوب'),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                uiTr(context, 'لا تملك صلاحية عرض ملف هذا السائق'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case _ProfileLoadPhase.ready:
        final user = _user!;
        final ref = _resolvedRef ?? user.reference;
        final row = AdminDriverRow.fromUser(user);
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'ملف المندوب'),
          subtitle: row.displayName,
          body: DriverProfileBody(user: user, userRef: ref, onChanged: _load),
        );
    }
  }
}

class _ErrorRetryBody extends StatelessWidget {
  const _ErrorRetryBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(uiTr(context, 'إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}
