import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_country_location_resolver.dart';
import '/backend/admin_gps_location_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'edet_agent_model.dart';
export 'edet_agent_model.dart';

class EdetAgentWidget extends StatefulWidget {
  const EdetAgentWidget({
    super.key,
    required this.agentRef,
  });

  final DocumentReference? agentRef;

  static String routeName = 'EdetAgent';
  static String routePath = '/edetAgent';

  @override
  State<EdetAgentWidget> createState() => _EdetAgentWidgetState();
}

class _EdetAgentWidgetState extends State<EdetAgentWidget> {
  late EdetAgentModel _model;

  static const double _kAgentVatPercent = 15.0;

  UserRecord? _agent;

  bool _detectingCountryFromGps = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetAgentModel());
    _loadAgent();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await queryListCacheFirst(
        CountriesRecord.collection,
        CountriesRecord.fromSnapshot,
        queryBuilder: (q) => q.orderBy('naim'),
        limit: kAdminPickerLimit,
      );
      if (!mounted) return;
      setState(() {
        _model.countries = countries;
        _model.countriesLoading = false;
        _syncSelectedCountry();
      });
    } catch (_) {
      if (mounted) setState(() => _model.countriesLoading = false);
    }
  }

  void _syncSelectedCountry() {
    final ref = _agent?.revDlohAgent;
    if (ref == null || _model.countries.isEmpty) return;
    for (final country in _model.countries) {
      if (country.reference.path == ref.path) {
        _model.selectedCountry = country;
        return;
      }
    }
  }

  Future<void> _loadAgent() async {
    final ref = widget.agentRef;
    if (ref == null) {
      if (mounted) setState(() => _model.isLoading = false);
      return;
    }

    try {
      final agent = await UserRecord.getDocumentOnce(ref);
      if (!mounted) return;

      if (!agent.isagent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'هذا الحساب ليس وكيلاً'))),
        );
        context.safePop();
        return;
      }

      _agent = agent;
      _model.nameTextController = TextEditingController(text: agent.displayName);
      _model.phoneTextController = TextEditingController(text: agent.phoneNumber);
      _model.emailTextController = TextEditingController(text: agent.email);
      _model.vatPercentTextController =
          TextEditingController(text: _kAgentVatPercent.toStringAsFixed(0));
      _model.appCommissionTextController = TextEditingController(
        text: agent.hasAppCommissionPercent()
            ? agent.appCommissionPercent.toString()
            : '',
      );
      _model.agentCommissionTextController = TextEditingController(
        text: agent.hasAgentTotal() ? agent.agentTotal.toString() : '',
      );
      _model.agentStartDate = agent.agentDateReg;
      _model.agentEndDate = agent.agentDateEnd;
      _model.activeValue = agent.actevUser;
      _syncSelectedCountry();

      setState(() => _model.isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _model.isLoading = false);
    }
  }

  String? _percentValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return '${uiTr(context, 'يرجى إدخال')} $label';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 100) {
      return uiTr(context, 'أدخل نسبة صحيحة بين 0 و 100');
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AdminUi.fieldFill(context, muted: readOnly),
        suffixIcon: const Icon(Icons.percent),
        helperText: readOnly ? uiTr(context, 'نسبة ثابتة') : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
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
      helpText: isStart ? uiTr(context, 'تاريخ بداية التسجيل') : uiTr(context, 'تاريخ انتهاء التسجيل'),
      cancelText: uiTr(context, 'إلغاء'),
      confirmText: uiTr(context, 'تأكيد'),
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
    if (date == null) return uiTr(context, 'اضغط لاختيار التاريخ');
    return dateTimeFormat(
      'yMMMd',
      date,
      locale: FFLocalizations.of(context).languageCode,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminUi.fieldFill(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: theme.secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: theme.primaryText),
              ),
            ),
            Text(
              _formatDate(date),
              style: TextStyle(
                color: theme.primaryText,
                fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
              ),
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
                uiTr(context, 'تعذّر قراءة الموقع — فعّل GPS واسمح للتطبيق بالوصول إلى الموقع'),
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
                uiTr(context, 'لم نتمكن من تحديد الدولة من موقعك. تأكد أن الدولة مسجّلة بحدود جغرافية في قسم الدول'),
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
            '${uiTr(context, 'تم تحديد الدولة')}: ${selected.naim}',
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
    if (_model.countriesLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_model.countries.isEmpty) {
      return Text(uiTr(context, 'لا توجد دول مسجلة. أضف دولاً من قسم الدول أولاً.'),
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CountriesRecord>(
          value: _model.selectedCountry,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: uiTr(context, 'البلد'),
            filled: true,
            fillColor: AdminUi.fieldFill(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          validator: (value) => value == null ? uiTr(context, 'اختر البلد') : null,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _detectingCountryFromGps ? null : _detectCountryFromGps,
          icon: _detectingCountryFromGps
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(uiTr(context, 'تحديد الدولة من الموقع الحالي')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: AdminUi.brandTeal.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!AdminSuperAdminGate.isAllowed) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    if (_model.agentStartDate == null || _model.agentEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار تاريخ البداية والانتهاء'))),
      );
      return;
    }

    if (_model.selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار البلد'))),
      );
      return;
    }

    final ref = widget.agentRef;
    if (ref == null) return;

    setState(() => _model.isSubmitting = true);
    try {
      final appPercent =
          double.tryParse(_model.appCommissionTextController!.text.trim()) ?? 0;
      final agentPercent =
          double.tryParse(_model.agentCommissionTextController!.text.trim()) ??
              0;

      await CloudFunctionsClient.updateCountryAgentAssignment(
        agentId: ref.id,
        countryPath: _model.selectedCountry!.reference.path,
        displayName: _model.nameTextController!.text.trim(),
        phoneNumber: _model.phoneTextController!.text.trim(),
        actevUser: _model.activeValue,
        dolhAgent: _model.selectedCountry!.naim,
        agentTotal: agentPercent,
        vatPercent: _kAgentVatPercent,
        appCommissionPercent: appPercent,
        agentDateReg: _model.agentStartDate,
        agentDateEnd: _model.agentEndDate,
        reason: 'edet_agent_save',
      );

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تحديث بيانات الوكيل'),
        refreshScope: AdminListScope.agents,
        popPage: true,
        deferHeavyWork: false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is FirebaseFunctionsException
          ? AdminUserCreation.authErrorMessage(e)
          : AdminCrudFeedback.saveFailed(context, e);
      AdminCrudFeedback.error(context, msg);
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (!AdminSuperAdminGate.isAllowed) return;
    final ref = widget.agentRef;
    if (ref == null || _agent == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(context, 'حذف الوكيل')),
        content: Text(appTrFormat(context, 'adm_delete_agent_body', _agent!.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isSubmitting = true);
    try {
      await AdminFirestoreDelete.deleteDocument(ref);
      await AdminAuditLog.recordDelete(
        targetType: 'agent',
        targetId: ref.id,
        targetLabel: _agent!.displayName,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف الوكيل'),
        refreshScope: AdminListScope.agents,
        removedDocumentId: ref.id,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: appTr(context, 'scr_edit_agent'),
      );
    }

    if (_model.isLoading) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_agent'),
        isLoading: true,
        child: const SizedBox.shrink(),
      );
    }

    if (_agent == null) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_agent'),
        child: AdminContentCard(
          child: Text(uiTr(context, 'تعذر تحميل بيانات الوكيل'), textAlign: TextAlign.center),
        ),
      );
    }

    return AdminEditScaffold(
      title: appTr(context, 'scr_edit_agent'),
      subtitle: _agent!.dolhAgent.isNotEmpty
          ? '${uiTr(context, 'الدولة')}: ${_agent!.dolhAgent}'
          : null,
      isLoading: _model.isSubmitting,
      floatingAction: AdminPrimaryButton(
        label: uiTr(context, 'حفظ التعديلات'),
        icon: Icons.save_rounded,
        isLoading: _model.isSubmitting,
        onPressed: _model.isSubmitting ? null : _save,
      ),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'بيانات الوكيل'),
              children: [
                TextFormField(
                  controller: _model.nameTextController,
                  focusNode: _model.nameFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'الاسم الكامل')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? uiTr(context, 'مطلوب') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model.phoneTextController,
                  focusNode: _model.phoneFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'رقم الجوال')),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model.emailTextController,
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'البريد الإلكتروني'),
                    helperText: appTr(context, 'adm_email_readonly_hint'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'تواريخ التسجيل'),
              children: [
                _buildDateTile(
                  label: uiTr(context, 'تاريخ البداية'),
                  date: _model.agentStartDate,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 12),
                _buildDateTile(
                  label: uiTr(context, 'تاريخ الانتهاء'),
                  date: _model.agentEndDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'النسب والموقع'),
              children: [
                _buildPercentField(
                  controller: _model.vatPercentTextController!,
                  label: uiTr(context, 'نسبة الضريبة'),
                  hint: '15',
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _buildPercentField(
                  controller: _model.appCommissionTextController!,
                  focusNode: _model.appCommissionFocusNode,
                  label: uiTr(context, 'نسبة التطبيق'),
                  hint: uiTr(context, 'مثال: 10'),
                  validator: (v) =>
                      _percentValidator(v, label: uiTr(context, 'نسبة التطبيق')),
                ),
                const SizedBox(height: 12),
                _buildPercentField(
                  controller: _model.agentCommissionTextController!,
                  focusNode: _model.agentCommissionFocusNode,
                  label: uiTr(context, 'نسبة الوكيل'),
                  hint: uiTr(context, 'مثال: 5'),
                  validator: (v) => _percentValidator(v, label: uiTr(context, 'نسبة الوكيل')),
                ),
                const SizedBox(height: 12),
                _buildCountrySelector(),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'حالة الوكيل'),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(uiTr(context, 'تفعيل الوكيل')),
                  value: _model.activeValue,
                  onChanged: _model.isSubmitting
                      ? null
                      : (v) => setState(() => _model.activeValue = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _model.isSubmitting ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              label: Text(uiTr(context, 'حذف الوكيل'),
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
