import '/backend/admin_role_service.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_region_picker.dart';
import '/core/admin_driver_profile_view.dart';
import '/core/admin_driver_review_actions.dart';
import '/core/admin_driver_route_params.dart';
import '/core/admin_type_car_label.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'driver_activation_model.dart';
import 'driver_registration_review_body.dart';
export 'driver_activation_model.dart';

import '/backend/admin_audit_log.dart';
import '/backend/backend.dart';
import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';

enum _ReviewLoadPhase {
  loading,
  invalidParam,
  notFound,
  error,
  ready,
}

/// Driver Activation Page: There is a field for ID number, a field for name,
/// a field for work city, a field for car type, and an activation
/// confirmation button.
class DriverActivationWidget extends StatefulWidget {
  const DriverActivationWidget({
    super.key,
    required this.dre,
  });

  final DocumentReference? dre;

  static String routeName = 'DriverActivation';
  static String routePath = '/driverActivation';

  @override
  State<DriverActivationWidget> createState() => _DriverActivationWidgetState();
}

class _DriverActivationWidgetState extends State<DriverActivationWidget> {
  late DriverActivationModel _model;
  bool _busy = false;
  bool _seeded = false;

  _ReviewLoadPhase _phase = _ReviewLoadPhase.loading;
  UserRecord? _user;
  DocumentReference? _resolvedRef;
  Object? _error;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _seedFromUser(UserRecord user) async {
    if (_seeded) return;
    _seeded = true;
    if (_model.naimTextController!.text.trim().isEmpty &&
        user.displayName.trim().isNotEmpty) {
      _model.naimTextController!.text = user.displayName;
    }
    if (_model.textController3!.text.trim().isEmpty &&
        user.mndobVillText.trim().isNotEmpty) {
      _model.textController3!.text = user.mndobVillText;
      FFAppState().workciteText = user.mndobVillText;
    }
    if (_model.textFieldtypTextController!.text.trim().isEmpty) {
      final legacy = user.textTypeCarMndob.trim().isNotEmpty
          ? user.textTypeCarMndob
          : (user.snapshotData['mdenh_aml']?.toString() ?? '');
      final carLabel = await AdminTypeCarLabel.resolve(
        context: context,
        typeCarRef: user.mndobTypeCar,
        legacy: legacy,
      );
      if (!mounted) return;
      if (carLabel.trim().isNotEmpty) {
        _model.textFieldtypTextController!.text = carLabel;
        FFAppState().typeCarText = carLabel;
        FFAppState().RefTepeCar = user.mndobTypeCar;
      }
    }
  }

  String? _rawDre() {
    try {
      return GoRouterState.of(context).uri.queryParameters['dre'];
    } catch (_) {
      return null;
    }
  }

  DocumentReference? _resolveRef() {
    return AdminDriverRouteParams.resolveUserRef(
      rawQuery: _rawDre(),
      deserialized: widget.dre,
    );
  }

  Future<void> _load() async {
    final ref = _resolveRef();
    if (!mounted) return;

    if (ref == null) {
      setState(() {
        _phase = _ReviewLoadPhase.invalidParam;
        _user = null;
        _resolvedRef = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _phase = _ReviewLoadPhase.loading;
      _resolvedRef = ref;
      _error = null;
      _seeded = false;
    });

    try {
      final snap = await ref.get();
      if (!mounted) return;
      if (!snap.exists) {
        setState(() {
          _phase = _ReviewLoadPhase.notFound;
          _user = null;
        });
        return;
      }

      final user = UserRecord.fromSnapshot(snap);
      await _seedFromUser(user);
      if (!mounted) return;
      setState(() {
        _phase = _ReviewLoadPhase.ready;
        _user = user;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ReviewLoadPhase.error;
        _error = e;
        _user = null;
      });
    }
  }

  Future<void> _exceptionalApprove() async {
    final ref = _resolvedRef ?? _resolveRef();
    if (_busy || ref == null || !AdminRoleService.isSuperAdmin) return;
    final snap = await ref.get();
    final data = Map<String, dynamic>.from(
      snap.data() as Map<String, dynamic>? ?? {},
    );
    final reason = await showDriverExceptionalApproveDialog(
      context: context,
      data: data,
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final workCityRef = FFAppState().workcite;
      final carTypeRef = FFAppState().RefTepeCar;
      final adminProfile = <String, dynamic>{
        if (_model.naimTextController.text.trim().isNotEmpty)
          'displayName': _model.naimTextController.text.trim(),
        if (workCityRef != null) 'mndob_vill': workCityRef.path,
        if (carTypeRef != null) 'mndob_type_car': carTypeRef.path,
        if ((FFAppState().workciteText).trim().isNotEmpty)
          'mndob_vill_text': FFAppState().workciteText.trim(),
      };

      await CloudFunctionsClient.reviewDriver(
        action: 'approve',
        driverId: ref.id,
        useRegistrationV2: true,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
        override: true,
        overrideReason: reason,
        alsoActivate: true,
        adminProfile: adminProfile.isEmpty ? null : adminProfile,
      );
      await AdminAuditLog.record(
        action: 'driver_override_approve',
        targetType: 'user',
        targetId: ref.id,
        targetLabel: _model.naimTextController.text,
        metadata: {'override_reason': reason},
      );
      AdminListRefresh.notify(AdminListScope.representatives);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uiTr(context, 'تم الاعتماد والتفعيل الاستثنائي')),
        ),
      );
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final ref = _resolvedRef ?? _resolveRef();
    if (_busy || ref == null) return;
    setState(() => _busy = true);
    try {
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final reviewData = Map<String, dynamic>.from(data);
      final workCityRef = FFAppState().workcite;
      final carTypeRef = FFAppState().RefTepeCar;
      if (workCityRef != null) reviewData['mndob_vill'] = workCityRef;
      if (carTypeRef != null) {
        reviewData['mndob_type_car'] = carTypeRef;
      }
      final blockers =
          AdminDriverReviewActions.approvalBlockingReasons(reviewData)
              .map((key) => appTr(context, key))
              .where((text) => text.trim().isNotEmpty)
              .toList();
      if (blockers.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(blockers.join('\n'))),
        );
        return;
      }

      final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(appTr(context, 'adm_drv_approve_confirm_title')),
          content: Text(
            [
              '${appTr(context, 'adm_drv_driver')}: ${_model.naimTextController.text}',
              '${appTr(context, 'adm_drv_vehicle')}: ${data['text_type_car_mndob'] ?? data['mdenh_aml'] ?? ''}',
              'Email verified (Auth): server-checked',
              'Phone provided: profile field (no OTP)',
              'Documents: ${isV2 ? 'V2 required' : 'legacy'}',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(appTr(context, 'adm_cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(appTr(context, 'adm_confirm')),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final adminProfile = <String, dynamic>{
        if (_model.naimTextController.text.trim().isNotEmpty)
          'displayName': _model.naimTextController.text.trim(),
        if (workCityRef != null) 'mndob_vill': workCityRef.path,
        if (carTypeRef != null) 'mndob_type_car': carTypeRef.path,
        if ((FFAppState().workciteText).trim().isNotEmpty)
          'mndob_vill_text': FFAppState().workciteText.trim(),
      };

      await CloudFunctionsClient.reviewDriver(
        action: 'approved',
        driverId: ref.id,
        useRegistrationV2: isV2,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
        adminProfile: adminProfile.isEmpty ? null : adminProfile,
      );
      await AdminAuditLog.record(
        action: 'driver_approve',
        targetType: 'user',
        targetId: ref.id,
        targetLabel: _model.naimTextController.text,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return AlertDialog(
            title: Text(appTr(context, 'adm_drv_activated_title')),
            content: Text(appTr(context, 'adm_drv_activated_body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(alertDialogContext),
                child: Text(appTr(context, 'adm_ok')),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final ref = _resolvedRef ?? _resolveRef();
    if (_busy || ref == null) return;
    final reason = await showDriverRejectDialog(context: context);
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
      await CloudFunctionsClient.reviewDriver(
        action: 'rejected',
        driverId: ref.id,
        reason: reason,
        useRegistrationV2: isV2,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
      );
      await AdminAuditLog.record(
        action: 'driver_reject',
        targetType: 'user',
        targetId: ref.id,
        targetLabel: _model.naimTextController.text,
        metadata: {'reason': reason},
      );
      if (!mounted) return;
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestChanges() async {
    final ref = _resolvedRef ?? _resolveRef();
    if (_busy || ref == null) return;
    final payload = await showDriverNeedsChangesDialog(context: context);
    if (payload == null) return;
    setState(() => _busy = true);
    try {
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
      await CloudFunctionsClient.reviewDriver(
        action: 'changes_requested',
        driverId: ref.id,
        reason: payload.reason,
        useRegistrationV2: isV2,
        fieldsToFix: payload.fields,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
      );
      await AdminAuditLog.record(
        action: 'driver_request_changes',
        targetType: 'user',
        targetId: ref.id,
        targetLabel: _model.naimTextController!.text,
        metadata: {
          'reason': payload.reason,
          'fieldsToFix': payload.fields,
        },
      );
      if (!mounted) return;
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverActivationModel());

    _model.textFieldFocusNode1 ??= FocusNode();

    _model.naimTextController ??= TextEditingController();
    _model.naimFocusNode ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textFieldtypTextController ??=
        TextEditingController(text: FFAppState().typeCarText);
    _model.textFieldtypFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant DriverActivationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dre?.path != widget.dre?.path) {
      _load();
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    switch (_phase) {
      case _ReviewLoadPhase.loading:
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'مراجعة طلب المندوب'),
          isLoading: true,
          loadingMessage: uiTr(context, 'جاري تحميل بيانات المندوب...'),
          body: const SizedBox.shrink(),
        );
      case _ReviewLoadPhase.invalidParam:
        return AdminMissingDocumentScaffold(
          title: uiTr(context, 'مراجعة طلب المندوب'),
          message: uiTr(context, 'معرّف المندوب غير صالح'),
        );
      case _ReviewLoadPhase.notFound:
        return AdminMissingDocumentScaffold(
          title: uiTr(context, 'مراجعة طلب المندوب'),
          message: uiTr(context, 'تعذر العثور على بيانات المندوب'),
        );
      case _ReviewLoadPhase.error:
        return AdminDriverModuleScaffold(
          title: uiTr(context, 'مراجعة طلب المندوب'),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AdminUserFacingErrors.from(
                      context,
                      _error ?? Exception('load_failed'),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(uiTr(context, 'إعادة المحاولة')),
                  ),
                ],
              ),
            ),
          ),
        );
      case _ReviewLoadPhase.ready:
        final user = _user!;
        final row = AdminDriverRow.fromUser(user);
        final awaiting = row.review == AdminDriverReviewBucket.pendingReview ||
            row.review == AdminDriverReviewBucket.needsChanges;

        return Semantics(
          identifier: 'qa-driver-review',
          label: 'qa-driver-review',
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AdminDriverModuleScaffold(
              title: uiTr(context, 'مراجعة طلب المندوب'),
              subtitle: row.displayName,
              body: DriverRegistrationReviewBody(
                user: user,
                nameController: _model.naimTextController!,
                cityController: _model.textController3!,
                carTypeController: _model.textFieldtypTextController!,
                busy: _busy,
                awaitingReview: awaiting,
                onPickCity: () async {
                  await showAdminPickerSheet(
                    context: context,
                    child: const AdminWorkCityPickerSheet(),
                  );
                  safeSetState(() {
                    _model.textController3?.text = FFAppState().workciteText;
                  });
                },
                onPickCarType: () async {
                  await showAdminPickerSheet(
                    context: context,
                    child: const AdminTypeCarPickerSheet(),
                  );
                  safeSetState(() {
                    _model.textFieldtypTextController?.text =
                        FFAppState().typeCarText;
                  });
                },
                onApprove: awaiting ? _approve : null,
                onExceptionalApprove: awaiting ? _exceptionalApprove : null,
                onReject: awaiting ? _reject : null,
                onRequestChanges: awaiting ? _requestChanges : null,
              ),
            ),
          ),
        );
    }
  }
}
