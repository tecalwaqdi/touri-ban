import '/backend/admin_audit_log.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_review_actions.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'driver_activation_model.dart';
export 'driver_activation_model.dart';

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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<String?> _askReason(String title) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: appTr(context, 'adm_drv_reason_hint'),
          ),
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
    final reason = controller.text.trim();
    controller.dispose();
    if (ok != true || reason.isEmpty) return null;
    return reason;
  }

  Future<void> _approve() async {
    if (_busy || widget.dre == null) return;
    setState(() => _busy = true);
    try {
      final snap = await widget.dre!.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      // Merge in-form city/type so prerequisites see intended values.
      data['mndob_vill'] = FFAppState().workcite ?? data['mndob_vill'];
      data['mndob_type_car'] =
          FFAppState().RefTepeCar ?? data['mndob_type_car'];
      final blockers = AdminDriverReviewActions.approvalBlockingReasons(data)
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

      await widget.dre!.update({
        ...createUserRecordData(
          displayName: _model.naimTextController.text,
          mndobVill: FFAppState().workcite,
          mndobTypeCar: FFAppState().RefTepeCar,
          mndobVillText: FFAppState().workciteText,
        ),
      });
      await CloudFunctionsClient.reviewDriver(
        action: 'approved',
        driverId: widget.dre!.id,
        useRegistrationV2: isV2,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
      );
      await AdminAuditLog.record(
        action: 'driver_approve',
        targetType: 'user',
        targetId: widget.dre!.id,
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
    if (_busy || widget.dre == null) return;
    final reason = await _askReason(appTr(context, 'adm_drv_reject_title'));
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      final snap = await widget.dre!.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
      await CloudFunctionsClient.reviewDriver(
        action: 'rejected',
        driverId: widget.dre!.id,
        reason: reason,
        useRegistrationV2: isV2,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
      );
      await AdminAuditLog.record(
        action: 'driver_reject',
        targetType: 'user',
        targetId: widget.dre!.id,
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

  Future<List<String>?> _askFieldsToFix() async {
    final selected = <String>{
      AdminDriverReviewActions.fieldsToFixAllowlist.first,
    };
    final labels = <String, String>{
      'personal_info': uiTr(context, 'البيانات الشخصية'),
      'vehicle': uiTr(context, 'بيانات المركبة'),
      'national_id': uiTr(context, 'الهوية'),
      'vehicle_registration': uiTr(context, 'استمارة المركبة'),
      'driver_license': uiTr(context, 'رخصة القيادة'),
      'plate': uiTr(context, 'رقم اللوحة'),
      'other': uiTr(context, 'أخرى'),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(uiTr(context, 'الحقول المطلوب تعديلها')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final code
                        in AdminDriverReviewActions.fieldsToFixAllowlist)
                      CheckboxListTile(
                        dense: true,
                        value: selected.contains(code),
                        title: Text(labels[code] ?? code),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              selected.add(code);
                            } else {
                              selected.remove(code);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(appTr(context, 'adm_cancel')),
                ),
                TextButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: Text(appTr(context, 'adm_confirm')),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || selected.isEmpty) return null;
    return selected.toList();
  }

  Future<void> _requestChanges() async {
    if (_busy || widget.dre == null) return;
    final fields = await _askFieldsToFix();
    if (fields == null) return;
    final reason =
        await _askReason(appTr(context, 'adm_drv_request_changes_title'));
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      final snap = await widget.dre!.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
      await CloudFunctionsClient.reviewDriver(
        action: 'changes_requested',
        driverId: widget.dre!.id,
        reason: reason,
        useRegistrationV2: isV2,
        fieldsToFix: fields,
        reviewVersion: (data['reviewVersion'] as num?)?.toInt(),
      );
      await AdminAuditLog.record(
        action: 'driver_request_changes',
        targetType: 'user',
        targetId: widget.dre!.id,
        targetLabel: _model.naimTextController.text,
        metadata: {'reason': reason, 'fieldsToFix': fields},
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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    if (widget.dre == null) {
      return AdminMissingDocumentScaffold(
        title: uiTr(context, 'تفعيل المندوب'),
        message: uiTr(context, 'تعذر تحميل بيانات المندوب'),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(widget.dre!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 55.0,
                height: 55.0,
                child: SpinKitThreeBounce(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 55.0,
                ),
              ),
            ),
          );
        }

        final driverActivationUserRecord = snapshot.data!;

        return Semantics(
          identifier: 'qa-driver-review',
          label: 'qa-driver-review',
          child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: false,
              title: Text(
                FFLocalizations.of(context).getText(
                  'fk1pfxmz' /* Driver Activation */,
                ),
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: FlutterFlowTheme.of(context).titleLargeFamily,
                      color: FlutterFlowTheme.of(context).info,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      useGoogleFonts:
                          !FlutterFlowTheme.of(context).titleLargeIsCustom,
                    ),
              ),
              actions: [],
              centerTitle: true,
              elevation: 0.0,
            ),
            resizeToAvoidBottomInset: true,
            body: AdminSafeScrollBody(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4.0,
                              color: Color(0x19000000),
                              offset: Offset(
                                0.0,
                                2.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  'yla09x6x' /* Complete Your Profile */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .headlineSmallFamily,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .headlineSmallIsCustom,
                                    ),
                              ),
                              Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.textController1 ??=
                                      TextEditingController(
                                    text: driverActivationUserRecord.driverid,
                                  ),
                                  focusNode: _model.textFieldFocusNode1,
                                  autofocus: true,
                                  textInputAction: TextInputAction.next,
                                  readOnly: true,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText:
                                        FFLocalizations.of(context).getText(
                                      'vty1juz4' /* ID Number */,
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyMediumIsCustom,
                                      ),
                                  keyboardType: TextInputType.number,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model.textController1Validator
                                      .asValidator(context),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.naimTextController,
                                  focusNode: _model.naimFocusNode,
                                  autofocus: false,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText:
                                        FFLocalizations.of(context).getText(
                                      'y4j3dmds' /* Full Name */,
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyMediumIsCustom,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model.naimTextControllerValidator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.words),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.textController3,
                                  focusNode: _model.textFieldFocusNode2,
                                  readOnly: true,
                                  onTap: () async {
                                    await showAdminPickerSheet(
                                      context: context,
                                      child: const AdminWorkCityPickerSheet(),
                                    );
                                    safeSetState(() {
                                      _model.textController3?.text =
                                          FFAppState().workciteText;
                                    });
                                  },
                                  autofocus: false,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: valueOrDefault<String>(
                                      FFAppState().workciteText,
                                      appTr(context, 'adm_drv_select_work_city'),
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    prefixIcon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyMediumIsCustom,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model.textController3Validator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.words),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.textFieldtypTextController,
                                  focusNode: _model.textFieldtypFocusNode,
                                  readOnly: true,
                                  onTap: () async {
                                    await showAdminPickerSheet(
                                      context: context,
                                      child: const AdminTypeCarPickerSheet(),
                                    );
                                    safeSetState(() {
                                      _model.textFieldtypTextController?.text =
                                          FFAppState().typeCarText;
                                    });
                                  },
                                  autofocus: false,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: valueOrDefault<String>(
                                      FFAppState().typeCarText,
                                      appTr(context, 'adm_drv_select_car_type'),
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    prefixIcon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyMediumIsCustom,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model
                                      .textFieldtypTextControllerValidator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.words),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                              if ((FFAppState().RefTepeCar != null) &&
                                  (FFAppState().workcite != null))
                                Semantics(
                                  identifier: 'qa-driver-approve',
                                  label: 'qa-driver-approve',
                                  button: true,
                                  child: FFButtonWidget(
                                  onPressed: _busy ? null : _approve,
                                  text: FFLocalizations.of(context).getText(
                                    'nzykcws9' /* Activate Driver Account */,
                                  ),
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 50.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmallFamily,
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .titleSmallIsCustom,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                ),
                              Semantics(
                                identifier: 'qa-driver-request-changes',
                                label: 'qa-driver-request-changes',
                                button: true,
                                child: OutlinedButton(
                                onPressed: _busy ? null : _requestChanges,
                                child: Text(
                                  appTr(context, 'adm_drv_request_changes_btn'),
                                ),
                              ),
                              ),
                              Semantics(
                                identifier: 'qa-driver-reject',
                                label: 'qa-driver-reject',
                                button: true,
                                child: OutlinedButton(
                                onPressed: _busy ? null : _reject,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(
                                  appTr(context, 'adm_drv_reject_btn'),
                                ),
                              ),
                              ),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'u5dafqzc' /* By activating your account, yo... */,
                                ),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodySmallFamily,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodySmallIsCustom,
                                    ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
        );
      },
    );
  }
}
