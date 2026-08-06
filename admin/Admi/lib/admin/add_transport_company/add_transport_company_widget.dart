import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_performance.dart';
import '/components/admin_crud_feedback.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'add_transport_company_model.dart';
export 'add_transport_company_model.dart';

class AddTransportCompanyWidget extends StatefulWidget {
  const AddTransportCompanyWidget({super.key});

  static String routeName = 'AddTransportCompany';
  static String routePath = '/addTransportCompany';

  @override
  State<AddTransportCompanyWidget> createState() =>
      _AddTransportCompanyWidgetState();
}

class _AddTransportCompanyWidgetState extends State<AddTransportCompanyWidget> {
  late AddTransportCompanyModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddTransportCompanyModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.licenseTextController ??= TextEditingController();
    _model.licenseFocusNode ??= FocusNode();
    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();

    AdminAgentCountryLock.applyToAppState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final country = AdminRoleService.scopedCountryRef;
      if (country != null) {
        final doc = await CountriesRecord.getDocumentOnce(country);
        if (mounted) {
          setState(() {
            _model.countries = [doc];
            _model.selectedCountry = doc;
            _model.countriesLoading = false;
          });
        }
        return;
      }

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
      if (mounted) setState(() => _model.countriesLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    final name = _model.nameTextController!.text.trim();
    final license = _model.licenseTextController!.text.trim();
    final phone = _model.phoneTextController!.text.trim();
    final email = _model.emailTextController!.text.trim();
    final password = _model.passwordTextController!.text;
    final confirm = _model.confirmPasswordTextController!.text;

    if (license.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى إدخال رقم ترخيص هيئة النقل'))),
      );
      return;
    }

    if (_model.selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار الدولة'))),
      );
      return;
    }

    if (email.isNotEmpty) {
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiTr(context, 'كلمة مرور مدير الشركة يجب أن تكون 6 أحرف على الأقل')),
          ),
        );
        return;
      }
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'كلمتا المرور غير متطابقتين'))),
        );
        return;
      }
    }

    setState(() => _model.isSubmitting = true);

    try {
      final companyRef = TransportCompanyRecord.collection.doc();
      DocumentReference? ownerRef;

      await companyRef.set(
        createTransportCompanyRecordData(
          naim: name,
          licenseNumber: license,
          revDolh: _model.selectedCountry!.reference,
          dolhText: _model.selectedCountry!.naim,
          phone: phone,
          email: email,
          actev: _model.activeValue,
          createdTime: getCurrentTimestamp,
        ),
      );

      if (email.isNotEmpty) {
        final uid = await AdminUserCreation.createEmailUser(
          email: email,
          password: password,
          userData: {
            'display_name': name,
            'phone_number': phone,
            'actev_user': true,
            'transport_company': companyRef.path,
            'transport_company_text': name,
            'isAdminRule': AdminRoleService.ruleTransportCompany,
          },
        );

        ownerRef = UserRecord.collection.doc(uid);
        await companyRef.update(
          createTransportCompanyRecordData(ownerUser: ownerRef),
        );
      }

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.add,
        message: uiTr(context, 'تم تسجيل شركة النقل بنجاح'),
        refreshScope: AdminListScope.transportCompanies,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.saveFailed(context, e));
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditScaffold(
      title: appTr(context, 'scr_register_transport'),
      subtitle:
          uiTr(context, 'شركة مرخّصة من هيئة النقل — أدخل بيانات الشركة ثم أضف سائقيها لاحقاً'),
      isLoading: _model.isSubmitting,
      floatingAction: AdminPrimaryButton(
        label: uiTr(context, 'حفظ الشركة'),
        icon: Icons.local_shipping_rounded,
        isLoading: _model.isSubmitting,
        onPressed: _model.isSubmitting ? null : _save,
      ),
      child: Form(
        key: _model.formKey,
        child: AdminEditFormCard(
          sectionTitle: uiTr(context, 'بيانات الشركة المرخّصة'),
          children: [
            TextFormField(
              controller: _model.nameTextController,
              focusNode: _model.nameFocusNode,
              decoration: InputDecoration(
                labelText: uiTr(context, 'اسم الشركة'),
                hintText: uiTr(context, 'مثال: شركة النقل الوطنية'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? uiTr(context, 'أدخل اسم الشركة') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model.licenseTextController,
              focusNode: _model.licenseFocusNode,
              decoration: InputDecoration(
                labelText: uiTr(context, 'رقم ترخيص هيئة النقل'),
                hintText: uiTr(context, 'الرقم الرسمي للترخيص'),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model.phoneTextController,
              focusNode: _model.phoneFocusNode,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: uiTr(context, 'جوال الشركة'),
                hintText: '05xxxxxxxx',
              ),
            ),
            const SizedBox(height: 14),
            _buildCountrySelector(),
            const SizedBox(height: 14),
            AdminEditSwitchRow(
              label: uiTr(context, 'تفعيل الشركة'),
              subtitle: uiTr(context, 'الشركة المفعّلة يمكن إضافة سائقيها للحجوزات'),
              value: _model.activeValue,
              onChanged: (v) => setState(() => _model.activeValue = v),
            ),
            const SizedBox(height: 20),
            Text(
              appTr(context, 'adm_company_manager_section'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _model.emailTextController,
              focusNode: _model.emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: uiTr(context, 'بريد مدير الشركة'),
                helperText: appTr(context, 'adm_company_manager_login_hint'),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model.passwordTextController,
              focusNode: _model.passwordFocusNode,
              obscureText: !_model.passwordVisibility,
              decoration: InputDecoration(
                labelText: uiTr(context, 'كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _model.passwordVisibility
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _model.passwordVisibility = !_model.passwordVisibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model.confirmPasswordTextController,
              focusNode: _model.confirmPasswordFocusNode,
              obscureText: !_model.confirmPasswordVisibility,
              decoration: InputDecoration(
                labelText: uiTr(context, 'تأكيد كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _model.confirmPasswordVisibility
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _model.confirmPasswordVisibility =
                        !_model.confirmPasswordVisibility,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    if (_model.countriesLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_model.countries.isEmpty) {
      return Text(uiTr(context, 'لا توجد دول مسجّلة'));
    }

    if (AdminRoleService.isCountryAgent && _model.selectedCountry != null) {
      return InputDecorator(
        decoration: InputDecoration(labelText: uiTr(context, 'الدولة')),
        child: Text(_model.selectedCountry!.naim),
      );
    }

    return DropdownButtonFormField<CountriesRecord>(
      value: _model.selectedCountry,
      isExpanded: true,
      decoration: InputDecoration(labelText: uiTr(context, 'الدولة')),
      items: _model.countries
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c.naim.isNotEmpty ? c.naim : '—'),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _model.selectedCountry = v),
      validator: (v) => v == null ? uiTr(context, 'اختر الدولة') : null,
    );
  }
}
