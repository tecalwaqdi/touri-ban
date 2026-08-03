import '/backend/admin_performance.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_country_location_resolver.dart';
import '/backend/admin_gps_location_service.dart';
import '/components/admin_crud_feedback.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_add_agent_model.dart';
export 'admin_add_agent_model.dart';

/// Add Agent Page
///
/// This page allows administrators to add a new agent to the system,
/// providing all necessary fields to gather the required information.
///
/// The layout ensures that all essential data is captured clearly and
/// efficiently.
///
/// 1. Agent Information Section:
///
/// Agent Name: A text input field for entering the full name of the agent.
/// Mobile Number: A field for entering the agent’s mobile number.
/// Address: A text area for entering the agent's physical address.
/// Email Address: A field for entering the agent's email address.
/// Password: A secure field for setting the agent's password.
/// Confirm Password: A field to confirm the entered password, ensuring both
/// match.
/// 2. Registration Details Section:
///
/// Registration Start Date: A date picker to set the start date of the
/// agent’s registration.
/// Expiration Date: A date picker to set the expiration date of the agent’s
/// registration.
/// 3. Commission and Location Section:
///
/// Commission Percentage: A field to enter the percentage commission that the
/// agent will receive from bookings.
/// Country: A dropdown menu to select the country where the agent is
/// operating.
/// 4. Activation Section:
///
/// Activate Agent: A toggle or checkbox to activate the agent, making them
/// live and able to perform actions within the system.
/// 5. Submission Button:
///
/// A clearly labeled button (e.g., "Add Agent") at the bottom of the page to
/// save the new agent's details.
class AdminAddAgentWidget extends StatefulWidget {
  const AdminAddAgentWidget({super.key});

  static String routeName = 'AdminAddAgent';
  static String routePath = '/adminAddAgent';

  @override
  State<AdminAddAgentWidget> createState() => _AdminAddAgentWidgetState();
}

class _AdminAddAgentWidgetState extends State<AdminAddAgentWidget> {
  late AdminAddAgentModel _model;

  static const double _kAgentVatPercent = 15.0;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _detectingCountryFromGps = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAddAgentModel());

    _model.naimfullTextController ??= TextEditingController();
    _model.naimfullFocusNode ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.passTextController ??= TextEditingController();
    _model.passFocusNode ??= FocusNode();

    _model.cPassTextController ??= TextEditingController();
    _model.cPassFocusNode ??= FocusNode();

    _model.textController7 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.appCommissionTextController ??= TextEditingController();
    _model.appCommissionFocusNode ??= FocusNode();

    _model.vatPercentTextController ??=
        TextEditingController(text: _kAgentVatPercent.toStringAsFixed(0));

    _model.switchValue = true;
    _loadCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await queryCountriesRecordOnce(
        queryBuilder: (q) => q.orderBy('naim'),
        limit: kAdminPickerLimit,
      );
      if (mounted) {
        setState(() {
          _model.countries = countries;
          _model.countriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _model.countriesLoading = false);
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_model.agentStartDate ?? now)
        : (_model.agentEndDate ??
            _model.agentStartDate ??
            now.add(const Duration(days: 365)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'تاريخ بداية التسجيل' : 'تاريخ انتهاء التسجيل',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _model.agentStartDate = picked;
          if (_model.agentEndDate != null &&
              _model.agentEndDate!.isBefore(picked)) {
            _model.agentEndDate = picked.add(const Duration(days: 365));
          }
        } else {
          _model.agentEndDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اضغط لاختيار التاريخ';
    return dateTimeFormat(
      'yMMMd',
      date,
      locale: FFLocalizations.of(context).languageCode,
    );
  }

  Future<void> _submitAgent() async {
    if (!(_model.formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى تصحيح الحقول المحددة بالأحمر'))),
      );
      return;
    }

    if (_model.agentStartDate == null || _model.agentEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار تاريخ البداية وتاريخ الانتهاء'))),
      );
      return;
    }

    if (_model.selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار البلد'))),
      );
      return;
    }

    final password = _model.passTextController!.text;
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'))),
      );
      return;
    }

    if (password != _model.cPassTextController!.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'كلمتا المرور غير متطابقتين'))),
      );
      return;
    }

    setState(() => _model.isSubmitting = true);

    try {
      final email = _model.emailTextController!.text.trim();
      final agentPercent = _parsePercent(_model.textController7!.text) ?? 0.0;
      final appPercent =
          _parsePercent(_model.appCommissionTextController!.text) ?? 0.0;
      final vatPercent =
          _parsePercent(_model.vatPercentTextController!.text) ??
              _kAgentVatPercent;

      await AdminUserCreation.createEmailUser(
        email: email,
        password: password,
        userData: {
          'display_name': _model.naimfullTextController!.text.trim(),
          'phone_number': _model.textController2!.text.trim(),
          'actev_user': _model.switchValue ?? true,
          'Isagent': true,
          'isAdminRule': AdminRoleService.ruleCountryAgent,
          'dolh_agent': _model.selectedCountry!.naim,
          'Rev_dloh_agent': _model.selectedCountry!.reference.path,
          'Agent_total': agentPercent,
          'vat_percent': vatPercent,
          'app_commission_percent': appPercent,
          if (_model.agentStartDate != null)
            'agent_date_reg': _model.agentStartDate!.toIso8601String(),
          if (_model.agentEndDate != null)
            'agent_date_end': _model.agentEndDate!.toIso8601String(),
        },
      );

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.add,
        message: uiTr(context, 'تم إضافة الوكيل بنجاح'),
        refreshScope: AdminListScope.agents,
        popPage: true,
        deferHeavyWork: false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? AdminUserCreation.authErrorMessage(e)
          : e.toString().replaceFirst('Exception: ', '');
      AdminCrudFeedback.error(context, 'تعذر إضافة الوكيل: $msg');
    } finally {
      if (mounted) {
        setState(() => _model.isSubmitting = false);
      }
    }
  }

  double? _parsePercent(String? raw) {
    if (raw == null) return null;
    var value = raw.trim().replaceAll(',', '.');
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < arabic.length; i++) {
      value = value.replaceAll(arabic[i], '$i');
    }
    return double.tryParse(value);
  }

  String? _percentValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $label';
    }
    final parsed = _parsePercent(value);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return 'أدخل نسبة صحيحة بين 0 و 100';
    }
    return null;
  }

  Widget _buildPercentField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hint,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: !readOnly,
      autofocus: false,
      obscureText: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
              letterSpacing: 0.0,
              useGoogleFonts:
                  !FlutterFlowTheme.of(context).bodyMediumIsCustom,
            ),
        hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
              letterSpacing: 0.0,
              useGoogleFonts:
                  !FlutterFlowTheme.of(context).bodyMediumIsCustom,
            ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x00000000), width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x00000000), width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x00000000), width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
        suffixIcon: const Icon(Icons.percent),
        helperText: readOnly ? 'نسبة ثابتة' : null,
      ),
      style: FlutterFlowTheme.of(context).bodyLarge.override(
            fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
            letterSpacing: 0.0,
            useGoogleFonts: !FlutterFlowTheme.of(context).bodyLargeIsCustom,
          ),
      minLines: 1,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator != null ? (v) => validator(v) : null,
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      color: date == null ? theme.secondaryText : theme.primaryText,
                      fontWeight:
                          date == null ? FontWeight.normal : FontWeight.w600,
                      useGoogleFonts: !theme.bodyMediumIsCustom,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detectCountryFromGps() async {
    if (_model.countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'لا توجد دول مسجلة'))),
      );
      return;
    }

    setState(() => _detectingCountryFromGps = true);

    try {
      final position = await AdminGpsLocationService.currentPosition();
      if (!mounted) return;

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uiTr(
                context,
                'تعذّر قراءة الموقع — فعّل GPS واسمح للتطبيق بالوصول إلى الموقع',
              ),
            ),
          ),
        );
        return;
      }

      final resolved = await AdminCountryLocationResolver.resolveCountry(
        position,
        countries: _model.countries,
      );
      if (!mounted) return;

      if (resolved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uiTr(
                context,
                'لم نتمكن من تحديد الدولة من موقعك. تأكد أن الدولة مسجّلة بحدود جغرافية في قسم الدول',
              ),
            ),
          ),
        );
        return;
      }

      CountriesRecord? match;
      for (final country in _model.countries) {
        if (country.reference.path == resolved.reference.path) {
          match = country;
          break;
        }
      }

      final selected = match ?? resolved;
      setState(() => _model.selectedCountry = selected);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(context, 'تم تحديد الدولة: ${selected.naim}'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _detectingCountryFromGps = false);
      }
    }
  }

  Widget _buildCountrySelector() {
    final theme = FlutterFlowTheme.of(context);

    if (_model.countriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_model.countries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          'لا توجد دول مسجلة. أضف دولاً من قسم الدول أولاً.',
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            color: theme.error,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CountriesRecord>(
          value: _model.selectedCountry,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: FFLocalizations.of(context).getText('2jwojhmw'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          hint: Text(uiTr(context, 'اختر البلد')),
          items: _model.countries
              .map(
                (country) => DropdownMenuItem(
                  value: country,
                  child: Text(country.naim.isNotEmpty ? country.naim : '—'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _model.selectedCountry = value),
          validator: (value) => value == null ? 'اختر البلد' : null,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _detectingCountryFromGps ? null : _detectCountryFromGps,
          icon: _detectingCountryFromGps
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                )
              : Icon(Icons.my_location, color: theme.primary),
          label: Text(
            uiTr(context, 'تحديد الدولة من الموقع الحالي'),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: AdminUi.brandTeal.withValues(alpha: 0.5)),
          ),
        ),
        Text(
          uiTr(
            context,
            'يستخدم موقعك الحالي لمطابقة الدولة المسجّلة في النظام (يتطلب حدوداً جغرافية للدولة)',
          ),
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdminSuperAdminGate.isProfileLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(appTr(context, 'scr_add_agent'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: appTr(context, 'scr_add_agent'),
      );
    }

    return GestureDetector(
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
          leading: FlutterFlowIconButton(
            buttonSize: 48.0,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).info,
              size: 24.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'ipx4fx9n' /* Add New Agent */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: FlutterFlowTheme.of(context).info,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).headlineMediumIsCustom,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        resizeToAvoidBottomInset: true,
        body: AdminSafeScrollBody(
            child: Form(
              key: _model.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 24.0, 24.0, 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'tj87gvh2' /* Agent Information */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            TextFormField(
                              controller: _model.naimfullTextController,
                              focusNode: _model.naimfullFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  'ojqsv76w' /* Full Name */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                            TextFormField(
                              controller: _model.textController2,
                              focusNode: _model.textFieldFocusNode1,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  'f27mzn49' /* Mobile Number */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              keyboardType: TextInputType.phone,
                              validator: _model.textController2Validator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.emailTextController,
                              focusNode: _model.emailFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  'yp7qzd6p' /* Email Address */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'مطلوب';
                                }
                                if (!v.contains('@')) {
                                  return 'بريد غير صالح';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _model.textController4,
                              focusNode: _model.textFieldFocusNode2,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  '0w6ldlhl' /* Address */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              maxLines: 6,
                              minLines: 3,
                              validator: _model.textController4Validator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.passTextController,
                              focusNode: _model.passFocusNode,
                              autofocus: false,
                              obscureText: !_model.passVisibility,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  'r7lgjz82' /* Password */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                                suffixIcon: InkWell(
                                  onTap: () => safeSetState(
                                    () => _model.passVisibility =
                                        !_model.passVisibility,
                                  ),
                                  focusNode: FocusNode(skipTraversal: true),
                                  child: Icon(
                                    _model.passVisibility
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 22,
                                  ),
                                ),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return '6 أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _model.cPassTextController,
                              focusNode: _model.cPassFocusNode,
                              autofocus: false,
                              obscureText: !_model.cPassVisibility,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  'qocblr67' /* Confirm Password */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
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
                                fillColor: Colors.white,
                                suffixIcon: InkWell(
                                  onTap: () => safeSetState(
                                    () => _model.cPassVisibility =
                                        !_model.cPassVisibility,
                                  ),
                                  focusNode: FocusNode(skipTraversal: true),
                                  child: Icon(
                                    _model.cPassVisibility
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 22,
                                  ),
                                ),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              validator: _model.cPassTextControllerValidator
                                  .asValidator(context),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 24.0, 24.0, 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'yi5ujlmp' /* Registration Details */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTile(
                                    label: FFLocalizations.of(context).getText(
                                      'n9r83k1l' /* Start Date */,
                                    ),
                                    date: _model.agentStartDate,
                                    onTap: () => _pickDate(isStart: true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateTile(
                                    label: FFLocalizations.of(context).getText(
                                      'tkf9k1mb' /* Expiration Date */,
                                    ),
                                    date: _model.agentEndDate,
                                    onTap: () => _pickDate(isStart: false),
                                  ),
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 24.0, 24.0, 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'النسب والموقع',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            _buildPercentField(
                              controller: _model.vatPercentTextController!,
                              label: uiTr(context, 'نسبة الضريبة'),
                              hint: '15',
                              validator: (v) => _percentValidator(
                                v,
                                label: uiTr(context, 'نسبة الضريبة'),
                              ),
                            ),
                            _buildPercentField(
                              controller: _model.appCommissionTextController!,
                              focusNode: _model.appCommissionFocusNode,
                              label: uiTr(context, 'نسبة التطبيق'),
                              hint: 'مثال: 10',
                              validator: (v) => _percentValidator(
                                v,
                                label: uiTr(context, 'نسبة التطبيق'),
                              ),
                            ),
                            _buildPercentField(
                              controller: _model.textController7!,
                              focusNode: _model.textFieldFocusNode3,
                              label: uiTr(context, 'نسبة الوكيل'),
                              hint: 'مثال: 5',
                              validator: (v) => _percentValidator(
                                v,
                                label: uiTr(context, 'نسبة الوكيل'),
                              ),
                            ),
                            _buildCountrySelector(),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 24.0, 24.0, 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '2qtpgmnk' /* Agent Status */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'nnyz649d' /* Activate Agent */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyLargeIsCustom,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchValue!,
                                  onChanged: (newValue) async {
                                    safeSetState(
                                        () => _model.switchValue = newValue);
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  FFButtonWidget(
                    onPressed: _model.isSubmitting ? null : _submitAgent,
                    text: FFLocalizations.of(context).getText(
                      '6pmr3p9h' /* Add Agent */,
                    ),
                    options: FFButtonOptions(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 56.0,
                      padding: EdgeInsets.all(8.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: FlutterFlowTheme.of(context)
                          .titleMedium
                          .override(
                            fontFamily:
                                FlutterFlowTheme.of(context).titleMediumFamily,
                            color: FlutterFlowTheme.of(context).info,
                            letterSpacing: 0.0,
                            useGoogleFonts: !FlutterFlowTheme.of(context)
                                .titleMediumIsCustom,
                          ),
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
            ),
        ),
      ),
    );
  }
}
