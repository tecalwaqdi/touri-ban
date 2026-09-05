import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_country_sync.dart';
import '/backend/admin_resource_guard.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_plate.dart';
import '/core/admin_driver_route_params.dart';
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
  const AddDrevWidget({super.key, this.editUserRef, this.companyRef});

  final DocumentReference? editUserRef;
  final DocumentReference? companyRef;

  static String routeName = 'addDrev';
  static String routePath = '/addDrev';

  @override
  State<AddDrevWidget> createState() => _AddDrevWidgetState();
}

class _AddDrevWidgetState extends State<AddDrevWidget> {
  late AddDrevModel _model;
  List<TransportCompanyRecord> _companies = [];
  TransportCompanyRecord? _selectedCompany;
  bool _companiesLoading = true;
  DocumentReference? _resolvedEditRef;

  bool get _isEdit => _resolvedEditRef != null;

  /// Dropdown must use an instance present in [items] (path match), else the
  /// field asserts and the whole create/edit form body fails to paint.
  TransportCompanyRecord? get _safeSelectedCompany {
    final selected = _selectedCompany;
    if (selected == null) return null;
    for (final c in _companies) {
      if (c.reference.path == selected.reference.path) return c;
    }
    return null;
  }

  String? _rawEditUser() {
    try {
      return GoRouterState.of(context).uri.queryParameters['editUser'];
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddDrevModel());

    AdminAgentCountryLock.applyToAppState();

    // Resolve edit target before first paint so we never flash create-mode Save.
    if (widget.editUserRef != null) {
      _resolvedEditRef = AdminDriverRouteParams.resolveUserRef(
        rawQuery: null,
        deserialized: widget.editUserRef,
      );
      _model.editPhase = 'loading';
      _model.isLoadingEdit = true;
    }
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
        if (val == null || val.trim().isEmpty)
          return uiTr(context, 'يرجى إدخال الاسم الكامل');
        if (val.trim().length < 3) return uiTr(context, 'الاسم قصير جداً');
        return null;
      };
      _model.emailTextControllerValidator = (context, val) {
        if (_isEdit) return null;
        if (val == null || val.trim().isEmpty)
          return uiTr(context, 'يرجى إدخال البريد الإلكتروني');
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
          return uiTr(context, 'صيغة البريد غير صحيحة');
        }
        return null;
      };
      _model.mobilTextControllerValidator = (context, val) {
        if (val == null || val.trim().isEmpty)
          return uiTr(context, 'يرجى إدخال رقم الجوال');
        if (val.replaceAll(RegExp(r'\D'), '').length < 9) {
          return uiTr(context, 'رقم الجوال غير مكتمل');
        }
        return null;
      };
      safeSetState(() {});
    });
  }

  Future<void> _bootstrapForm() async {
    final raw = _rawEditUser();
    _resolvedEditRef = AdminDriverRouteParams.resolveUserRef(
      rawQuery: raw,
      deserialized: widget.editUserRef,
    );
    final wantsEdit =
        (raw != null && raw.trim().isNotEmpty) || widget.editUserRef != null;
    if (wantsEdit && _resolvedEditRef == null) {
      safeSetState(() {
        _model.editPhase = 'notFound';
        _model.isLoadingEdit = false;
      });
      return;
    }

    if (_isEdit) {
      safeSetState(() {
        _model.editPhase = 'loading';
        _model.isLoadingEdit = true;
      });
    }

    if (AdminRoleService.isTransportCompany) {
      final companyRef = AdminRoleService.transportCompanyRef;
      if (companyRef != null) {
        try {
          final company = await TransportCompanyRecord.getDocumentOnce(
            companyRef,
          );
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

    if (_isEdit) {
      await _loadRepresentativeForEdit();
    } else {
      FFAppState().update(() {
        FFAppState().typeCarText = '';
        FFAppState().RefTepeCar = null;
        FFAppState().workciteText = '';
        FFAppState().workcite = null;
      });
      safeSetState(() {
        _model.editPhase = 'creating';
        _model.isLoadingEdit = false;
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
        preselected ??= await TransportCompanyRecord.getDocumentOnce(
          widget.companyRef!,
        );
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
    final ref = _resolvedEditRef;
    if (ref == null) return;

    safeSetState(() {
      _model.isLoadingEdit = true;
      _model.editPhase = 'loading';
      _model.editLoadError = null;
    });
    try {
      final snap = await ref.get().timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (!snap.exists) {
        safeSetState(() {
          _model.editPhase = 'notFound';
          _model.isLoadingEdit = false;
        });
        return;
      }

      final user = UserRecord.fromSnapshot(snap);

      if (!AdminRoleService.isSuperAdmin) {
        final allowed = await AdminResourceGuard.canEditDriver(user);
        if (!allowed) {
          if (!mounted) return;
          safeSetState(() {
            _model.editPhase = 'unauthorized';
            _model.isLoadingEdit = false;
          });
          return;
        }
      }

      _model.nameTextController!.text = user.displayName;
      _model.emailTextController!.text = user.email;
      _model.mobilTextController!.text = user.phoneNumber;
      _model.workcityTextController!.text = user.mndobVillText;
      _model.uploadedFileUrl_uploadDataLbm = user.photoUrl;

      _parseCarTypeAndPlate(user.textTypeCarMndob);
      final plateFromDoc = AdminDriverPlate.display(
        '${user.snapshotData['number_lohh_car'] ?? user.snapshotData['plate'] ?? ''}',
      );
      if (plateFromDoc.isNotEmpty &&
          (_model.platTextController?.text.trim().isEmpty ?? true)) {
        _model.platTextController!.text = plateFromDoc;
      }

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
            if (!_companies.any(
              (c) => c.reference.path == match!.reference.path,
            )) {
              _companies = [match!, ..._companies];
            }
            _selectedCompany = match;
          });
        }
      }
      if (!mounted) return;
      safeSetState(() {
        _model.editPhase = 'loaded';
        _model.isLoadingEdit = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _model.editPhase = 'error';
        _model.editLoadError = e;
        _model.isLoadingEdit = false;
      });
    }
  }

  void _parseCarTypeAndPlate(String raw) {
    final text = raw.trim();
    final separator = ' - ';
    final idx = text.lastIndexOf(separator);
    if (idx > 0) {
      _model.cartypeTextController!.text = text.substring(0, idx).trim();
      _model.platTextController!.text =
          text.substring(idx + separator.length).trim();
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
        SnackBar(
          content: Text(uiTr(context, 'يرجى تعبئة الاسم والبريد ورقم الجوال')),
        ),
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
          content: Text(
            uiTr(context, 'حسابك غير مربوط بشركة نقل — تواصل مع الإدارة'),
          ),
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
            content: Text(
              uiTr(context, 'لا تملك صلاحية تعديل سائقي شركة أخرى'),
            ),
          ),
        );
        return;
      }
    }

    // Busy immediately before any await — blocks double-submit.
    safeSetState(() => _model.isSubmitting = true);

    if (_isEdit && _resolvedEditRef != null) {
      try {
        final snap = await _resolvedEditRef!.get();
        if (!snap.exists) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uiTr(context, 'تعذر تحديث المندوب'))),
          );
          safeSetState(() => _model.isSubmitting = false);
          return;
        }
        final existing = UserRecord.fromSnapshot(snap);
        if (!AdminRoleService.isSuperAdmin) {
          final allowed = await AdminResourceGuard.canEditDriver(existing);
          if (!allowed) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uiTr(context, 'لا تملك صلاحية تعديل هذا السائق')),
              ),
            );
            safeSetState(() => _model.isSubmitting = false);
            return;
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uiTr(context, 'تعذر تحديث المندوب')}: ${AdminUserFacingErrors.from(context, e)}',
            ),
          ),
        );
        safeSetState(() => _model.isSubmitting = false);
        return;
      }
    }

    if (!_isEdit) {
      if (_model.passTextController!.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uiTr(context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
            ),
          ),
        );
        safeSetState(() => _model.isSubmitting = false);
        return;
      }

      if (_model.passTextController!.text != _model.cpassTextController!.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'كلمتا المرور غير متطابقتين'))),
        );
        safeSetState(() => _model.isSubmitting = false);
        return;
      }
    }

    final carLabel = plate.isEmpty ? carType : '$carType - $plate';
    final photoUrl = _model.uploadedFileUrl_uploadDataLbm.trim().isNotEmpty
        ? _model.uploadedFileUrl_uploadDataLbm.trim()
        : null;

    try {
      final countryRef = await AdminCountrySync.countryFromVillage(workCityRef);

      if (_isEdit) {
        final plateDisplay = AdminDriverPlate.display(plate);
        final plateNorm = AdminDriverPlate.normalize(plate);
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
        final plateFields = <String, dynamic>{};
        if (plateDisplay.isNotEmpty) {
          plateFields['number_lohh_car'] = plateDisplay;
          plateFields['normalized_plate'] = plateNorm;
        }
        if (_selectedCompany == null) {
          await _resolvedEditRef!.update({
            ...update,
            ...plateFields,
            'transport_company': FieldValue.delete(),
            'transport_company_text': FieldValue.delete(),
          });
        } else {
          await _resolvedEditRef!.update({...update, ...plateFields});
        }

        AdminListRefresh.notify(AdminListScope.representatives);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiTr(context, 'تم تحديث بيانات المندوب بنجاح')),
          ),
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
          'document_review_status':
              AdminRoleService.isTransportCompany ? 'pending' : 'approved',
          'vehicle_review_status':
              AdminRoleService.isTransportCompany ? 'pending' : 'approved',
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
        'email-already-in-use' => uiTr(
            context,
            'البريد الإلكتروني مستخدم مسبقاً',
          ),
        'invalid-email' => uiTr(context, 'البريد الإلكتروني غير صالح'),
        'weak-password' => uiTr(context, 'كلمة المرور ضعيفة جداً'),
        _ => '${uiTr(context, 'تعذر إضافة المندوب')}: ${e.message ?? e.code}',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
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
    final isEdit = _isEdit;
    final theme = FlutterFlowTheme.of(context);
    String? editSubtitle;
    if (isEdit && _resolvedEditRef != null) {
      // Subtitle filled after load via model if available.
      editSubtitle = _model.nameTextController?.text.trim();
    }

    final phase = _model.editPhase;
    final canMutate =
        (!isEdit && phase == 'creating') || (isEdit && phase == 'loaded');
    final Widget phaseBody;
    if (isEdit && phase == 'loading') {
      phaseBody = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    } else if (isEdit && phase == 'notFound') {
      phaseBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            uiTr(context, 'المندوب غير موجود'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (isEdit && phase == 'unauthorized') {
      phaseBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            uiTr(context, 'لا تملك صلاحية تعديل هذا السائق'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (isEdit && phase == 'error') {
      phaseBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                uiTr(context, 'تعذر تحميل بيانات المندوب'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _bootstrapForm,
                child: Text(uiTr(context, 'إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    } else {
      // Create + loaded edit: paint real fields. Prefer Column+scroll over
      // ListView so form sections never collapse to zero paint height.
      phaseBody = Form(
        key: _model.formKey,
        child: SingleChildScrollView(
          padding: AdminUi.pagePadding(context).copyWith(top: 12, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDriverCompactTip(
                text: isEdit
                    ? uiTr(
                        context,
                        'عدّل البيانات المطلوبة — الاسم، الموقع، المركبة، الصورة — ثم احفظ.',
                      )
                    : uiTr(
                        context,
                        'أدخل البيانات الشخصية، الموقع، المركبة، ثم اضغط «إضافة المندوب».',
                      ),
              ),
              const SizedBox(height: 14),
              AdminEditFormCard(
                sectionTitle: uiTr(context, 'البيانات الشخصية'),
                children: [
                  AdminDriverFormGrid(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _model.nameTextController!,
                        focusNode: _model.nameFocusNode,
                        label: uiTr(context, 'الاسم الكامل *'),
                        hint: uiTr(context, 'مثال: محمد أحمد العتيبي'),
                        icon: Icons.person_outline_rounded,
                        validator: _model.nameTextControllerValidator,
                        textInputAction: TextInputAction.next,
                      ),
                      _buildTextField(
                        context: context,
                        controller: _model.mobilTextController!,
                        focusNode: _model.mobilFocusNode,
                        label: uiTr(context, 'رقم الجوال *'),
                        hint: '05xxxxxxxx',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: _model.mobilTextControllerValidator,
                        textInputAction: TextInputAction.next,
                      ),
                      _buildTextField(
                        context: context,
                        controller: _model.emailTextController!,
                        focusNode: _model.emailFocusNode,
                        label: uiTr(context, 'البريد الإلكتروني *'),
                        hint: 'example@email.com',
                        icon: Icons.alternate_email_rounded,
                        readOnly: isEdit,
                        keyboardType: TextInputType.emailAddress,
                        validator: _model.emailTextControllerValidator,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 14),
                    _buildFieldHint(
                      uiTr(
                        context,
                        'كلمة المرور: 6 أحرف على الأقل. شاركها مع المندوب بشكل آمن بعد الإضافة.',
                      ),
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
                sectionTitle: uiTr(context, 'الموقع والمركبة'),
                children: [
                  _buildFieldHint(
                    uiTr(
                      context,
                      'اختر شركة النقل (إن وُجدت) ثم نوع السيارة ومدينة العمل.',
                    ),
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
                  else if (AdminRoleService.isTransportCompany &&
                      _selectedCompany != null)
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'شركة النقل'),
                      ),
                      child: Text(_selectedCompany!.naim),
                    )
                  else
                    DropdownButtonFormField<TransportCompanyRecord?>(
                      key: ValueKey(
                        'company-${_safeSelectedCompany?.reference.path ?? 'none'}-${_companies.length}',
                      ),
                      initialValue: _safeSelectedCompany,
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
                    uiTr(
                      context,
                      'مثال: سيدان، دفع رباعي، فان — حسب أنواع السيارات المفعّلة في النظام',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    context: context,
                    controller: _model.platTextController!,
                    focusNode: _model.platFocusNode,
                    label: uiTr(context, 'رقم اللوحة'),
                    hint: uiTr(context, 'مثال: أ ب ج 1234'),
                    helper: uiTr(
                      context,
                      'اختياري — أدخل رقم لوحة المركبة إن وُجد',
                    ),
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
                    uiTr(
                      context,
                      'المدينة التي سيعمل فيها المندوب ويستقبل منها طلبات الحجز',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AdminEditFormCard(
                sectionTitle: uiTr(context, 'الصورة الشخصية'),
                children: [_buildPhotoPicker(context, theme)],
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
                          uiTr(
                            context,
                            'بعد الإضافة يُفعَّل المندوب تلقائياً ويمكنه استقبال الطلبات بعد تسجيل الدخول.',
                          ),
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

    return AdminDriverModuleScaffold(
      title: isEdit
          ? uiTr(context, 'تعديل بيانات المندوب')
          : uiTr(context, 'إضافة مندوب'),
      subtitle: isEdit && (editSubtitle?.isNotEmpty ?? false)
          ? editSubtitle
          : (isEdit
              ? uiTr(context, 'عدّل البيانات ثم احفظ')
              : uiTr(context, 'املأ الحقول المطلوبة')),
      isLoading: false,
      bottomBar: canMutate
          ? AdminDriverStickyActions(
              primaryLabel: _model.isSubmitting
                  ? uiTr(context, 'جاري الحفظ...')
                  : isEdit
                      ? uiTr(context, 'حفظ التعديلات')
                      : uiTr(context, 'إضافة المندوب'),
              primaryLoading: _model.isSubmitting,
              primaryIcon:
                  isEdit ? Icons.save_rounded : Icons.person_add_rounded,
              onPrimary: _model.isSubmitting ? null : _submitRepresentative,
            )
          : null,
      body: phaseBody,
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
    String helper = '',
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
            fillColor:
                readOnly ? theme.alternate.withValues(alpha: 0.15) : null,
          ),
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
          validator: validator?.asValidator(context),
        ),
        const SizedBox(height: 6),
        if (helper.isNotEmpty) _buildHelperText(context, helper),
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
                      hasPhoto
                          ? uiTr(context, 'تغيير الصورة')
                          : uiTr(context, 'رفع صورة شخصية'),
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
