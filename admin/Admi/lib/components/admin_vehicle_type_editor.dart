import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/admin_audit_log.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_image_picker.dart';
import '/core/admin_vehicle_price_preview.dart';
import '/core/i18n/toury_i18n_locales.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Full vehicle-type editor: i18n names/descriptions, pricing, capacity, sort, image.
class AdminVehicleTypeEditor extends StatefulWidget {
  const AdminVehicleTypeEditor({
    super.key,
    required this.record,
  });

  final TypeCarRecord record;

  static Future<bool?> open(BuildContext context, TypeCarRecord record) async {
    TypeCarRecord fresh = record;
    try {
      final snap = await record.reference.get(
        const GetOptions(source: Source.server),
      );
      if (snap.exists) {
        fresh = TypeCarRecord.fromSnapshot(snap);
      }
    } catch (_) {}
    if (!context.mounted) return null;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      builder: (ctx) => AdminVehicleTypeEditor(record: fresh),
    );
  }

  @override
  State<AdminVehicleTypeEditor> createState() => _AdminVehicleTypeEditorState();
}

class _AdminVehicleTypeEditorState extends State<AdminVehicleTypeEditor> {
  static const _activeLocales = [
    'ar',
    'en',
    'ur',
    'fr',
    'ru',
    'pt',
    'ky',
  ];

  late final Map<String, TextEditingController> _nameCtrls;
  late final Map<String, TextEditingController> _descCtrls;
  late final TextEditingController _srCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _discountPctCtrl;
  late final TextEditingController _discountCapCtrl;
  late final TextEditingController _sortCtrl;
  late final TextEditingController _passengersCtrl;
  late final TextEditingController _luggageCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _previewHoursCtrl;
  late final TextEditingController _previewExtraCtrl;

  bool _actev = true;
  bool _ishafelh = false;
  bool _saving = false;
  bool _uploading = false;
  String _imgUrl = '';
  FFUploadedFile _localImage = FFUploadedFile(bytes: Uint8List.fromList([]));

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _nameCtrls = {
      for (final lang in _activeLocales)
        lang: TextEditingController(
          text: r.namesI18n[lang] ?? (lang == 'ar' ? r.naim : ''),
        ),
    };
    _descCtrls = {
      for (final lang in _activeLocales)
        lang: TextEditingController(text: r.osfI18n[lang] ?? (lang == 'ar' ? r.osf : '')),
    };
    _srCtrl = TextEditingController(text: r.sr.toString());
    _hoursCtrl = TextEditingController(text: r.aglSaat.toString());
    _discountPctCtrl = TextEditingController(
      text: r.nesbahkKsm == 0 ? '' : r.nesbahkKsm.toString(),
    );
    _discountCapCtrl = TextEditingController(
      text: r.totalKsmUb == 0 ? '' : r.totalKsmUb.toString(),
    );
    _sortCtrl = TextEditingController(
      text: (r.sortOrder > 0 ? r.sortOrder : r.numTrteb).toString(),
    );
    _passengersCtrl = TextEditingController(
      text: r.passengers == 0 ? '' : r.passengers.toString(),
    );
    _luggageCtrl = TextEditingController(
      text: r.luggage == 0 ? '' : r.luggage.toString(),
    );
    _codeCtrl = TextEditingController(text: r.codeCar);
    _previewHoursCtrl = TextEditingController(
      text: (r.aglSaat > 0 ? r.aglSaat : 3).toString(),
    );
    _previewExtraCtrl = TextEditingController(text: '0');
    _actev = r.actev;
    _ishafelh = r.ishafelh;
    _imgUrl = r.img;
  }

  @override
  void dispose() {
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final c in _descCtrls.values) {
      c.dispose();
    }
    _srCtrl.dispose();
    _hoursCtrl.dispose();
    _discountPctCtrl.dispose();
    _discountCapCtrl.dispose();
    _sortCtrl.dispose();
    _passengersCtrl.dispose();
    _luggageCtrl.dispose();
    _codeCtrl.dispose();
    _previewHoursCtrl.dispose();
    _previewExtraCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'type_car/uploads',
        useContentCompression: true,
        setUploading: (v) => setState(() => _uploading = v),
        setLocal: (file) => setState(() => _localImage = file),
        setUrl: (url) => setState(() => _imgUrl = url),
      );

  String? _validate() {
    final ar = _nameCtrls['ar']!.text.trim();
    final en = _nameCtrls['en']!.text.trim();
    if (ar.isEmpty && en.isEmpty) {
      return uiTr(context, 'أدخل الاسم العربي أو الإنجليزي على الأقل');
    }
    final sr = int.tryParse(_srCtrl.text.trim());
    if (sr == null || sr < 0) {
      return uiTr(context, 'يرجى إدخال سعر صحيح');
    }
    final hours = int.tryParse(_hoursCtrl.text.trim());
    if (hours == null || hours < 1) {
      return uiTr(context, 'الحد الأدنى للساعات غير صالح');
    }
    return null;
  }

  Map<String, String> _collectNames() {
    final out = <String, String>{};
    for (final lang in _activeLocales) {
      final v = _nameCtrls[lang]!.text.trim();
      if (v.isNotEmpty) out[lang] = v;
    }
    return out;
  }

  Map<String, String> _collectDescs() {
    final out = <String, String>{};
    for (final lang in _activeLocales) {
      final v = _descCtrls[lang]!.text.trim();
      if (v.isNotEmpty) out[lang] = v;
    }
    return out;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final r = widget.record;
    final names = _collectNames();
    final descs = _collectDescs();
    final arName = names['ar'] ?? names['en'] ?? r.naim;
    final sr = int.parse(_srCtrl.text.trim());
    final hours = int.parse(_hoursCtrl.text.trim());
    final discountPct = double.tryParse(_discountPctCtrl.text.trim()) ?? 0;
    final discountCap = int.tryParse(_discountCapCtrl.text.trim()) ?? 0;
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? 0;
    final passengers = int.tryParse(_passengersCtrl.text.trim()) ?? 0;
    final luggage = int.tryParse(_luggageCtrl.text.trim()) ?? 0;
    final code = _codeCtrl.text.trim();

    final oldSr = r.sr;
    final oldImg = r.img;
    final oldActev = r.actev;

    try {
      var imgUrl = await resolveImageForFirestoreSave(
        pickedUrl: _imgUrl,
        existingUrl: r.img,
        localBytes: _localImage.bytes,
      );
      // Cache-bust query for CDN/clients when Storage URL unchanged path.
      if (imgUrl.isNotEmpty &&
          !imgUrl.startsWith('data:') &&
          imgUrl != oldImg &&
          !imgUrl.contains('v=')) {
        final sep = imgUrl.contains('?') ? '&' : '?';
        imgUrl = '$imgUrl${sep}v=${DateTime.now().millisecondsSinceEpoch}';
      }

      await r.reference.update(
        createTypeCarRecordData(
          naim: arName,
          namesI18n: names,
          osf: descs['ar'] ?? descs['en'],
          osfI18n: descs.isEmpty ? null : descs,
          sr: sr,
          aglSaat: hours,
          nesbahkKsm: discountPct,
          totalKsmUb: discountCap,
          sortOrder: sort,
          numTrteb: sort,
          passengers: passengers,
          luggage: luggage,
          codeCar: code.isEmpty ? null : code,
          actev: _actev,
          ishafelh: _ishafelh,
          img: imgUrl.isEmpty ? null : imgUrl,
          updatedAt: DateTime.now(),
        ),
      );

      if (oldSr != sr ||
          (double.tryParse(_discountPctCtrl.text.trim()) ?? 0) != r.nesbahkKsm ||
          (int.tryParse(_discountCapCtrl.text.trim()) ?? 0) != r.totalKsmUb) {
        await AdminAuditLog.record(
          action: 'vehicle_price_update',
          targetType: 'type_car',
          targetId: r.reference.id,
          targetLabel: arName,
          metadata: {
            'old_sr': oldSr,
            'new_sr': sr,
            'old_discount_pct': r.nesbahkKsm,
            'new_discount_pct': discountPct,
            'old_discount_cap': r.totalKsmUb,
            'new_discount_cap': discountCap,
            'agl_saat': hours,
          },
        );
      }
      if (oldImg != imgUrl && imgUrl.isNotEmpty) {
        await AdminAuditLog.record(
          action: 'vehicle_image_update',
          targetType: 'type_car',
          targetId: r.reference.id,
          targetLabel: arName,
          metadata: {'had_previous': oldImg.isNotEmpty},
        );
      }
      if (oldActev != _actev) {
        await AdminAuditLog.recordToggle(
          targetType: 'type_car',
          targetId: r.reference.id,
          activated: _actev,
          targetLabel: arName,
        );
      }

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم حفظ نوع المركبة'),
        refreshScope: AdminListScope.typeCars,
        invalidateStats: false,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.saveFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final previewHours = int.tryParse(_previewHoursCtrl.text.trim()) ?? 3;
    final previewExtra = int.tryParse(_previewExtraCtrl.text.trim()) ?? 0;
    final sr = int.tryParse(_srCtrl.text.trim()) ?? widget.record.sr;
    final discountPct =
        double.tryParse(_discountPctCtrl.text.trim()) ?? widget.record.nesbahkKsm;
    final discountCap =
        int.tryParse(_discountCapCtrl.text.trim()) ?? widget.record.totalKsmUb;
    final preview = adminVehiclePricePreview(
      hourlyRateSar: sr,
      bookingHours: previewHours,
      additionalHours: previewExtra,
      additionalHoursDiscountPercent: discountPct,
      additionalHoursDiscountCapSar: discountCap,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        uiTr(context, 'تعديل نوع السيارة'),
                        style: theme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(uiTr(context, 'الصورة'), style: theme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: adminImagePreview(
                            imageUrl: _imgUrl,
                            localBytes: _localImage.bytes,
                            width: 96,
                            height: 72,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FFButtonWidget(
                          onPressed: _uploading ? null : _pickImage,
                          text: _uploading
                              ? uiTr(context, 'جاري الرفع…')
                              : uiTr(context, 'رفع / استبدال'),
                          options: FFButtonOptions(
                            height: 40,
                            color: theme.primary,
                            textStyle: theme.labelMedium.override(
                              fontFamily: theme.labelMediumFamily,
                              color: theme.info,
                              useGoogleFonts: !theme.labelMediumIsCustom,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(uiTr(context, 'مفعّل للحجز')),
                      value: _actev,
                      onChanged: (v) => setState(() => _actev = v),
                    ),
                    SwitchListTile(
                      title: Text(uiTr(context, 'حافلة / خدمة جماعية')),
                      value: _ishafelh,
                      onChanged: (v) => setState(() => _ishafelh = v),
                    ),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'رمز النوع (codeCar)'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(uiTr(context, 'الأسماء'), style: theme.titleSmall),
                    for (final lang in _activeLocales) ...[
                      TextFormField(
                        controller: _nameCtrls[lang],
                        decoration: InputDecoration(
                          labelText:
                              '${uiTr(context, 'الاسم')} (${touryI18nLabel(lang)})',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(uiTr(context, 'الوصف'), style: theme.titleSmall),
                    for (final lang in _activeLocales) ...[
                      TextFormField(
                        controller: _descCtrls[lang],
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText:
                              '${uiTr(context, 'الوصف')} (${touryI18nLabel(lang)})',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      uiTr(context, 'التسعير (بالساعة — نفس محرك الحجز)'),
                      style: theme.titleSmall,
                    ),
                    TextFormField(
                      controller: _srCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'السعر للساعة'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextFormField(
                      controller: _hoursCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'الحد الأدنى للساعات'),
                      ),
                    ),
                    TextFormField(
                      controller: _discountPctCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'خصم الساعات الإضافية %'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextFormField(
                      controller: _discountCapCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'سقف الخصم'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      uiTr(context, 'معاينة السعر (غير ملزمة)'),
                      style: theme.labelLarge,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _previewHoursCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: uiTr(context, 'ساعات'),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _previewExtraCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: uiTr(context, 'إضافي'),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${uiTr(context, 'الإجمالي المتوقع')}: ${preview.customerTotalSar}',
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        fontWeight: FontWeight.w700,
                        useGoogleFonts: !theme.bodyMediumIsCustom,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(uiTr(context, 'السعة والترتيب'), style: theme.titleSmall),
                    TextFormField(
                      controller: _passengersCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'عدد الركاب'),
                      ),
                    ),
                    TextFormField(
                      controller: _luggageCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'عدد الحقائب'),
                      ),
                    ),
                    TextFormField(
                      controller: _sortCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'ترتيب العرض'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FFButtonWidget(
                      onPressed: _saving ? null : _save,
                      text: _saving
                          ? uiTr(context, 'جاري الحفظ…')
                          : uiTr(context, 'حفظ'),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 48,
                        color: theme.primary,
                        textStyle: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          color: theme.info,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
