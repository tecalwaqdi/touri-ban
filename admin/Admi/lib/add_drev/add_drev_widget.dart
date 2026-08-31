import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_country_sync.dart';
import '/backend/admin_resource_guard.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_drev_model.dart';
export 'add_drev_model.dart';

/// Form Name - Email - Car Type - Mobile Number - Personal Photo - Preferred
/// Work City - Plate Number - Password -
///
class AddDrevWidget extends StatefulWidget {
  const AddDrevWidget({
    super.key,
    this.editUserRef,
    this.companyRef,
  });

  final DocumentReference? editUserRef;
  final DocumentReference? companyRef;

  static String routeName = 'addDrev';
  static String routePath = '/addDrev';

  bool get isEditMode => editUserRef != null;

  @override
  State<AddDrevWidget> createState() => _AddDrevWidgetState();
}

class _AddDrevWidgetState extends State<AddDrevWidget> {
  late AddDrevModel _model;
  List<TransportCompanyRecord> _companies = [];
  TransportCompanyRecord? _selectedCompany;
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddDrevModel());

    AdminAgentCountryLock.applyToAppState();

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.mobilTextController ??= TextEditingController();
    _model.mobilFocusNode ??= FocusNode();

    _model.passTextController ??= TextEditingController();
    _model.passFocusNode ??= FocusNode();

    _model.cpassTextController ??= TextEditingController();
    _model.cpassFocusNode ??= FocusNode();

    _model.cartypeTextController ??= TextEditingController();
    _model.cartypeFocusNode ??= FocusNode();

    _model.platTextController ??= TextEditingController();
    _model.platFocusNode ??= FocusNode();

    _model.workcityTextController ??= TextEditingController();
    _model.workcityFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapForm();
      _model.nameTextControllerValidator = (context, val) {
        if (val == null || val.trim().isEmpty) return uiTr(context, 'يرجى إدخال الاسم الكامل');
        if (val.trim().length < 3) return uiTr(context, 'الاسم قصير جداً');
        return null;
      };
      _model.emailTextControllerValidator = (context, val) {
        if (widget.isEditMode) return null;
        if (val == null || val.trim().isEmpty) return uiTr(context, 'يرجى إدخال البريد الإلكتروني');
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
          return uiTr(context, 'صيغة البريد غير صحيحة');
        }
        return null;
      };
      _model.mobilTextControllerValidator = (context, val) {
        if (val == null || val.trim().isEmpty) return uiTr(context, 'يرجى إدخال رقم الجوال');
        if (val.replaceAll(RegExp(r'\D'), '').length < 9) {
          return uiTr(context, 'رقم الجوال غير مكتمل');
        }
        return null;
      };
      safeSetState(() {});
    });
  }

  Future<void> _bootstrapForm() async {
    if (AdminRoleService.isTransportCompany) {
      final companyRef = AdminRoleService.transportCompanyRef;
      if (companyRef != null) {
        try {
          final company =
              await TransportCompanyRecord.getDocumentOnce(companyRef);
          if (mounted) {
            setState(() {
              _companies = [company];
              _selectedCompany = company;
              _companiesLoading = false;
            });
          }
        } catch (_) {
          if (mounted) setState(() => _companiesLoading = false);
        }
      }
    } else {
      await _loadCompanies();
    }

    if (!mounted) return;

    if (widget.isEditMode) {
      await _loadRepresentativeForEdit();
    } else {
      FFAppState().update(() {
        FFAppState().typeCarText = '';
        FFAppState().RefTepeCar = null;
        FFAppState().workciteText = '';
        FFAppState().workcite = null;
      });
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await queryTransportCompanyRecordOnce(
        queryBuilder: (q) =>
            AdminCountryScope.applyTransportCompanyQuery(q).orderBy('naim'),
        limit: 200,
      );

      TransportCompanyRecord? preselected;
      if (widget.companyRef != null) {
        for (final c in companies) {
          if (c.reference.path == widget.companyRef!.path) {
            preselected = c;
            break;
          }
        }
        preselected ??=
            await TransportCompanyRecord.getDocumentOnce(widget.companyRef!);
      }

      if (!mounted) return;
      final merged = List<TransportCompanyRecord>.from(companies);
      if (preselected != null &&
          !merged.any((c) => c.reference.path == preselected!.reference.path)) {
        merged.insert(0, preselected);
      }
      setState(() {
        _companies = merged;
        _selectedCompany = preselected;
        _companiesLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _companiesLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'تعذر تحميل شركات النقل'))),
        );
      }
    }
  }

  Future<void> _loadRepresentativeForEdit() async {
    final ref = widget.editUserRef;
    if (ref == null) return;

    safeSetState(() => _model.isLoadingEdit = true);
    try {
      final snap = await ref.get();
      if (!snap.exists || !mounted) return;

      final user = UserRecord.fromSnapshot(snap);

      if (!AdminRoleService.isSuperAdmin) {
        final allowed = await AdminResourceGuard.canEditDriver(user);
        if (!allowed) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uiTr(context, 'لا تملك صلاحية تعديل هذا السائق'))),
          );
          context.safePop();
          return;
        }
      }

      _model.nameTextController!.text = user.displayName;
      _model.emailTextController!.text = user.email;
      _model.mobilTextController!.text = user.phoneNumber;
      _model.workcityTextController!.text = user.mndobVillText;
      _model.uploadedFileUrl_uploadDataLbm = user.photoUrl;

      _parseCarTypeAndPlate(user.textTypeCarMndob);

      FFAppState().update(() {
        FFAppState().workcite = user.mndobVill;
        FFAppState().workciteText = user.mndobVillText;
        FFAppState().RefTepeCar = user.mndobTypeCar;
        FFAppState().typeCarText = _model.cartypeTextController!.text;
      });

      if (user.hasTransportCompany()) {
        TransportCompanyRecord? match;
        for (final c in _companies) {
          if (c.reference.path == user.transportCompany!.path) {
            match = c;
            break;
          }
        }
        match ??= await TransportCompanyRecord.getDocumentOnce(
          user.transportCompany!,
        );
        if (mounted) {
          setState(() {
            if (!_companies.any((c) => c.reference.path == match!.reference.path)) {
              _companies = [match!, ..._companies];
            }
            _selectedCompany = match;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appTr(context, 'adm_load_courier_failed')}: '
            '${AdminUserFacingErrors.from(context, e)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        safeSetState(() => _model.isLoadingEdit = false);
      }
    }
  }

  void _parseCarTypeAndPlate(String raw) {
    final text = raw.trim();
    final separator = ' - ';
    final idx = text.lastIndexOf(separator);
    if (idx > 0) {
      _model.cartypeTextController!.text = text.substring(0, idx).trim();
      _model.platTextController!.text = text.substring(idx + separator.length).trim();
    } else {
      _model.cartypeTextController!.text = text;
      _model.platTextController!.clear();
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickRepPhoto() => handleAdminImagePick(
        context: context,
        storageFolder: 'representatives/uploads',
        useProfileCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataLbm = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataLbm = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataLbm = url),
      );

  Future<void> _submitRepresentative() async {
    if (_model.isSubmitting) return;

    if (!(_model.formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _model.nameTextController!.text.trim();
    final email = _model.emailTextController!.text.trim();
    final phone = _model.mobilTextController!.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى تعبئة الاسم والبريد ورقم الجوال'))),
      );
      return;
    }

    final carType = FFAppState().typeCarText.isNotEmpty
        ? FFAppState().typeCarText
        : _model.cartypeTextController!.text.trim();
    final plate = _model.platTextController!.text.trim();
    final workCity = FFAppState().workciteText.isNotEmpty
        ? FFAppState().workciteText
        : _model.workcityTextController!.text.trim();
    final workCityRef = FFAppState().workcite;
    final carTypeRef = FFAppState().RefTepeCar;

    if (carType.isEmpty || workCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uiTr(context, 'يرجى اختيار نوع السيارة ومدينة العمل')),
        ),
      );
      return;
    }

    if (AdminRoleService.isTransportCompany && _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uiTr(context, 'حسابك غير مربوط بشركة نقل — تواصل مع الإدارة')),
        ),
      );
      return;
    }
    if (AdminRoleService.isTransportCompany) {
      final owned = AdminRoleService.transportCompanyRef;
      if (owned == null ||
          _selectedCompany == null ||
          _selectedCompany!.reference.path != owned.path) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiTr(context, 'لا تملك صلاحية تعديل سائقي شركة أخرى')),
          ),
        );
        return;
      }
    }

    if (!widget.isEditMode) {
      if (_model.passTextController!.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiTr(context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
          ),
        );
        return;
      }

      if (_model.passTextController!.text != _model.cpassTextController!.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'كلمتا المرور غير متطابقتين'))),
        );
        return;
      }
    }

    final carLabel = plate.isEmpty ? carType : '$carType - $plate';
    final photoUrl = _model.uploadedFileUrl_uploadDataLbm.trim().isNotEmpty
        ? _model.uploadedFileUrl_uploadDataLbm.trim()
        : null;

    safeSetState(() => _model.isSubmitting = true);

    try {
      final countryRef = await AdminCountrySync.countryFromVillage(workCityRef);

      if (widget.isEditMode) {
        final update = createUserRecordData(
          displayName: name,
          phoneNumber: phone,
          photoUrl: photoUrl,
          mndobVill: workCityRef,
          mndobTypeCar: carTypeRef,
          mndobVillText: workCity,
          textTypeCarMndob: carLabel,
          transportCompany: _selectedCompany?.reference,
          transportCompanyText: _selectedCompany?.naim,
          revDolh: countryRef,
        );
        if (_selectedCompany == null) {
          await widget.editUserRef!.update({
            ...update,
            'transport_company': FieldValue.delete(),
            'transport_company_text': FieldValue.delete(),
          });
        } else {
          await widget.editUserRef!.update(update);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'تم تحديث بيانات المندوب بنجاح'))),
        );
        context.safePop();
        return;
      }

      await AdminUserCreation.createEmailUser(
        email: email,
        password: _model.passTextController!.text,
        userData: {
          'display_name': name,
          'phone_number': phone,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
          'actev_user': true,
          // Company portal: pending review. Admin/agent may activate immediately.
          'actev_mndob': !AdminRoleService.isTransportCompany,
          'ismndob': true,
          'ismndom': true,
          'ngl': false,
          'registration_status': AdminRoleService.isTransportCompany
              ? 'pending_review'
              : 'approved',
          'submission_status': AdminRoleService.isTransportCompany
              ? 'pending_review'
              : 'approved',
          'account_status':
              AdminRoleService.isTransportCompany ? 'inactive' : 'active',
          'operational_status': 'offline',
          'auto_activated': false,
          'document_review_status': AdminRoleService.isTransportCompany
              ? 'pending'
              : 'approved',
          'vehicle_review_status': AdminRoleService.isTransportCompany
              ? 'pending'
              : 'approved',
          if (workCityRef != null) 'mndob_vill': workCityRef.path,
          if (carTypeRef != null) 'mndob_type_car': carTypeRef.path,
          'mndob_vill_text': workCity,
          'text_type_car_mndob': carLabel,
          if (_selectedCompany != null)
            'transport_company': _selectedCompany!.reference.path,
          if (_selectedCompany != null)
            'transport_company_text': _selectedCompany!.naim,
          if (countryRef != null) 'Rev_dolh': countryRef.path,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم إضافة المندوب بنجاح'))),
      );
      context.safePop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'email-already-in-use' => uiTr(context, 'البريد الإلكتروني مستخدم مسبقاً'),
        'invalid-email' => uiTr(context, 'البريد الإلكتروني غير صالح'),
        'weak-password' => uiTr(context, 'كلمة المرور ضعيفة جداً'),
        _ => '${uiTr(context, 'تعذر إضافة المندوب')}: ${e.message ?? e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? '${uiTr(context, 'تعذر تحديث المندوب')}: ${AdminUserFacingErrors.from(context, e)}'
                : '${uiTr(context, 'تعذر إضافة المندوب')}: ${AdminUserFacingErrors.from(context, e)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        safeSetState(() => _model.isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;
    final theme = FlutterFlowTheme.of(context);

    return AdminEditScaffold(
      title: isEdit ? uiTr(context, 'تعديل بيانات المندوب') : uiTr(context, 'إضافة مندوب جديد'),
      subtitle: isEdit
          ? uiTr(context, 'عدّل البيانات المطلوبة ثم اضغط «حفظ التعديلات»')
          : uiTr(context, 'املأ الحقول المميزة بـ (*) ثم اضغط «إضافة المندوب»'),
      isLoading: _model.isLoadingEdit,
      floatingAction: AdminPrimaryButton(
        label: _model.isSubmitting
            ? uiTr(context, 'جاري الحفظ...')
            : isEdit
                ? uiTr(context, 'حفظ التعديلات')
                : uiTr(context, 'إضافة المندوب'),
        icon: isEdit ? Icons.save_rounded : Icons.person_add_rounded,
        isLoading: _model.isSubmitting,
        onPressed: _model.isSubmitting ? null : _submitRepresentative,
      ),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGuideBanner(context, isEdit),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, '١ — البيانات الشخصية'),
              children: [
                _buildFieldHint(
                  uiTr(context, 'أدخل بيانات التواصل الأساسية للمندوب. سيستخدم البريد وكلمة المرور لتسجيل الدخول في تطبيق المناديب.'),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  context: context,
                  controller: _model.nameTextController!,
                  focusNode: _model.nameFocusNode,
                  label: uiTr(context, 'الاسم الكامل *'),
                  hint: uiTr(context, 'مثال: محمد أحمد العتيبي'),
                  helper: uiTr(context, 'اكتب الاسم الثلاثي كما يظهر في الهوية'),
                  icon: Icons.person_outline_rounded,
                  validator: _model.nameTextControllerValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  context: context,
                  controller: _model.emailTextController!,
                  focusNode: _model.emailFocusNode,
                  label: uiTr(context, 'البريد الإلكتروني *'),
                  hint: 'example@email.com',
                  helper: isEdit
                      ? uiTr(context, 'لا يمكن تغيير البريد من هنا')
                      : uiTr(context, 'سيُستخدم كاسم مستخدم لتسجيل دخول المندوب'),
                  icon: Icons.alternate_email_rounded,
                  readOnly: isEdit,
                  keyboardType: TextInputType.emailAddress,
                  validator: _model.emailTextControllerValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  context: context,
                  controller: _model.mobilTextController!,
                  focusNode: _model.mobilFocusNode,
                  label: uiTr(context, 'رقم الجوال *'),
                  hint: '05xxxxxxxx',
                  helper: uiTr(context, 'أدخل رقم سعودي يبدأ بـ 05 ويتكون من 10 أرقام'),
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: _model.mobilTextControllerValidator,
                  textInputAction: isEdit ? TextInputAction.done : TextInputAction.next,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 14),
                  _buildFieldHint(
                    uiTr(context, 'كلمة المرور: 6 أحرف على الأقل. شاركها مع المندوب بشكل آمن بعد الإضافة.'),
                    icon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    context: context,
                    controller: _model.passTextController!,
                    focusNode: _model.passFocusNode,
                    label: uiTr(context, 'كلمة المرور *'),
                    hint: '••••••••',
                    helper: uiTr(context, '6 أحرف على الأقل — أحرف وأرقام'),
                    icon: Icons.lock_rounded,
                    obscureText: !_model.passVisibility,
                    suffix: _visibilityToggle(
                      visible: _model.passVisibility,
                      onTap: () => safeSetState(
                        () => _model.passVisibility = !_model.passVisibility,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    context: context,
                    controller: _model.cpassTextController!,
                    focusNode: _model.cpassFocusNode,
                    label: uiTr(context, 'تأكيد كلمة المرور *'),
                    hint: uiTr(context, 'أعد إدخال كلمة المرور'),
                    helper: uiTr(context, 'يجب أن تطابق كلمة المرور أعلاه'),
                    icon: Icons.verified_user_outlined,
                    obscureText: !_model.cpassVisibility,
                    suffix: _visibilityToggle(
                      visible: _model.cpassVisibility,
                      onTap: () => safeSetState(
                        () =>
                            _model.cpassVisibility = !_model.cpassVisibility,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, '٢ — الموقع والمركبة'),
              children: [
                _buildFieldHint(
                  uiTr(context, 'اختر شركة النقل (إن وُجدت) ثم نوع السيارة ومدينة العمل.'),
                ),
                const SizedBox(height: 12),
                if (_companiesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (AdminRoleService.isTransportCompany && _selectedCompany != null)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'شركة النقل'),
                    ),
                    child: Text(_selectedCompany!.naim),
                  )
                else
                  DropdownButtonFormField<TransportCompanyRecord?>(
                    key: ValueKey(
                      _selectedCompany?.reference.path ?? 'company-none',
                    ),
                    initialValue: _selectedCompany,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'شركة النقل (اختياري)'),
                      hintText: uiTr(context, 'مستقل — بدون شركة'),
                    ),
                    items: [
                      DropdownMenuItem<TransportCompanyRecord?>(
                        value: null,
                        child: Text(uiTr(context, 'مستقل — بدون شركة')),
                      ),
                      ..._companies.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.licenseNumber.isNotEmpty
                                ? '${c.naim} (${c.licenseNumber})'
                                : c.naim,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        safeSetState(() => _selectedCompany = v),
                  ),
                const SizedBox(height: 14),
                AdminEditPickerRow(
                  label: uiTr(context, 'نوع السيارة *'),
                  value: _model.cartypeTextController!.text,
                  placeholder: uiTr(context, 'اضغط لاختيار نوع السيارة'),
                  onTap: () async {
                    await showAdminPickerSheet(
                      context: context,
                      child: const AdminTypeCarPickerSheet(),
                    );
                    if (!mounted) return;
                    if (FFAppState().typeCarText.isNotEmpty) {
                      safeSetState(() {
                        _model.cartypeTextController!.text =
                            FFAppState().typeCarText;
                      });
                    }
                  },
                ),
                const SizedBox(height: 6),
                _buildHelperText(
                  context,
                  uiTr(context, 'مثال: سيدان، دفع رباعي، فان — حسب أنواع السيارات المفعّلة في النظام'),
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  context: context,
                  controller: _model.platTextController!,
                  focusNode: _model.platFocusNode,
                  label: uiTr(context, 'رقم اللوحة'),
                  hint: uiTr(context, 'مثال: أ ب ج 1234'),
                  helper: uiTr(context, 'اختياري — أدخل رقم لوحة المركبة إن وُجد'),
                  icon: Icons.confirmation_number_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AdminEditPickerRow(
                  label: uiTr(context, 'مدينة العمل *'),
                  value: _model.workcityTextController!.text,
                  placeholder: uiTr(context, 'اضغط لاختيار مدينة العمل'),
                  icon: Icons.location_city_rounded,
                  onTap: () async {
                    await showAdminPickerSheet(
                      context: context,
                      child: const AdminWorkCityPickerSheet(),
                    );
                    if (!mounted) return;
                    if (FFAppState().workciteText.isNotEmpty) {
                      safeSetState(() {
                        _model.workcityTextController!.text =
                            FFAppState().workciteText;
                      });
                    }
                  },
                ),
                const SizedBox(height: 6),
                _buildHelperText(
                  context,
                  uiTr(context, 'المدينة التي سيعمل فيها المندوب ويستقبل منها طلبات الحجز'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, '٣ — الصورة الشخصية'),
              children: [
                _buildFieldHint(
                  uiTr(context, 'صورة واضحة لوجه المندوب تظهر في التطبيق وفي قائمة المناديب.'),
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 12),
                _buildPhotoPicker(context, theme),
              ],
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        uiTr(context, 'بعد الإضافة يُفعَّل المندوب تلقائياً ويمكنه استقبال الطلبات بعد تسجيل الدخول.'),
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          color: const Color(0xFF1B5E20),
                          useGoogleFonts: !theme.bodySmallIsCustom,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuideBanner(BuildContext context, bool isEdit) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminUi.brandTeal.withValues(alpha: 0.12),
            AdminUi.brandMint.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: AdminUi.brandTeal, size: 22),
              const SizedBox(width: 8),
              Text(
                isEdit ? uiTr(context, 'خطوات التعديل') : uiTr(context, 'خطوات الإضافة'),
                style: theme.titleSmall.override(
                  fontFamily: theme.titleSmallFamily,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.brandTeal,
                  useGoogleFonts: !theme.titleSmallIsCustom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _guideStep(uiTr(context, '١'), uiTr(context, 'أدخل البيانات الشخصية ورقم الجوال')),
          _guideStep(uiTr(context, '٢'), uiTr(context, 'اختر نوع السيارة ومدينة العمل')),
          _guideStep(uiTr(context, '٣'), uiTr(context, 'أضف صورة شخصية (اختياري)')),
          if (!isEdit)
            _guideStep(uiTr(context, '٤'), uiTr(context, 'اضغط «إضافة المندوب» — يُفعَّل تلقائياً')),
        ],
      ),
    );
  }

  Widget _guideStep(String number, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminUi.brandTeal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHint(String text, {IconData? icon}) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.lightbulb_outline_rounded,
            size: 18,
            color: AdminUi.brandTeal.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperText(BuildContext context, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        text,
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: theme.secondaryText,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helper,
    required IconData icon,
    FocusNode? focusNode,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffix,
    String? Function(BuildContext, String?)? validator,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: AdminUi.inputDecoration(
            context,
            label: label,
            hint: hint,
            prefixIcon: icon,
          ).copyWith(
            suffixIcon: suffix,
            fillColor: readOnly ? theme.alternate.withValues(alpha: 0.15) : null,
          ),
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
          validator: validator?.asValidator(context),
        ),
        const SizedBox(height: 6),
        _buildHelperText(context, helper),
      ],
    );
  }

  Widget _visibilityToggle({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }

  Widget _buildPhotoPicker(BuildContext context, FlutterFlowTheme theme) {
    final hasPhoto = _model.uploadedFileUrl_uploadDataLbm.isNotEmpty ||
        _model.uploadedLocalFile_uploadDataLbm.bytes?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _model.isDataUploading_uploadDataLbm ? null : _pickRepPhoto,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(AdminUi.radiusSm),
            border: Border.all(
              color: hasPhoto
                  ? AdminUi.brandTeal.withValues(alpha: 0.5)
                  : theme.alternate,
              width: hasPhoto ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasPhoto
                        ? adminImagePreview(
                            imageUrl: _model.uploadedFileUrl_uploadDataLbm,
                            localBytes:
                                _model.uploadedLocalFile_uploadDataLbm.bytes,
                            width: 88,
                            height: 88,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 44,
                            color: theme.secondaryText.withValues(alpha: 0.5),
                          ),
                  ),
                  if (_model.isDataUploading_uploadDataLbm)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPhoto ? uiTr(context, 'تغيير الصورة') : uiTr(context, 'رفع صورة شخصية'),
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: AdminUi.brandTeal,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uiTr(context, 'اضغط لاختيار صورة من المعرض أو الكاميرا'),
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uiTr(context, 'يفضّل صورة مربعة واضحة للوجه'),
                      style: theme.labelSmall.override(
                        fontFamily: theme.labelSmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.labelSmallIsCustom,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AdminUi.brandTeal,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
