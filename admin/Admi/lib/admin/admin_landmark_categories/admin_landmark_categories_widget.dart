import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/admin_landmark_category_catalog.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/nav_translations.dart';
import 'admin_landmark_categories_model.dart';
export 'admin_landmark_categories_model.dart';

/// Manage customer landmark filter chips (`landmark_categories` collection).
class AdminLandmarkCategoriesWidget extends StatefulWidget {
  const AdminLandmarkCategoriesWidget({super.key});

  static String routeName = 'AdminLandmarkCategories';
  static String routePath = '/adminLandmarkCategories';

  @override
  State<AdminLandmarkCategoriesWidget> createState() =>
      _AdminLandmarkCategoriesWidgetState();
}

class _AdminLandmarkCategoriesWidgetState
    extends State<AdminLandmarkCategoriesWidget> {
  late AdminLandmarkCategoriesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Future<List<AdminLandmarkCategory>>? _future;
  bool _busy = false;

  bool get _canWrite =>
      AdminRoleService.isSuperAdmin || AdminRoleService.isCountryAgent;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminLandmarkCategoriesModel());
    _future = AdminLandmarkCategoryCatalog.loadAll();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = AdminLandmarkCategoryCatalog.loadAll();
    });
  }

  Future<void> _seed({required bool overwrite}) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(
        context,
        overwrite ? 'استبدال التصنيفات' : 'تعبئة التصنيفات الافتراضية',
      ),
      whatHappens: uiTr(
        context,
        overwrite
            ? 'سيتم استبدال كل التصنيفات بالقائمة الافتراضية النظيفة.'
            : 'سيتم إضافة التصنيفات الافتراضية فقط إن كانت المجموعة فارغة أو ناقصة.',
      ),
      subject: 'landmark_categories',
      confirmLabel: uiTr(context, overwrite ? 'استبدال' : 'تعبئة'),
      destructive: overwrite,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await AdminLandmarkCategoryCatalog.seedDefaults(overwrite: overwrite);
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تحديث تصنيفات المعالم'),
      );
      _reload();
    } catch (e, st) {
      AdminUi.logDiagnostic('landmark_cat_seed', e, st);
      if (mounted) {
        AdminCrudFeedback.error(context, uiTr(context, 'تعذر تحديث التصنيفات'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([AdminLandmarkCategory? existing]) async {
    final isNew = existing == null;
    final existingId = existing?.id ?? '';
    final existingTrKey = existing?.trKey ?? '';
    final idCtrl = TextEditingController(text: existingId);
    final storageCtrl = TextEditingController(text: existing?.storage ?? '');
    final arCtrl = TextEditingController(text: existing?.labelAr ?? '');
    final enCtrl = TextEditingController(text: existing?.labelEn ?? '');
    final sortCtrl =
        TextEditingController(text: '${existing?.sort ?? 110}');
    final iconUrlCtrl = TextEditingController(text: existing?.iconUrl ?? '');
    var icon = existing?.icon ?? 'attraction';
    var enabled = existing?.enabled ?? true;

    final saved = await showDialog<AdminLandmarkCategory>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(uiTr(ctx, isNew ? 'تصنيف جديد' : 'تعديل التصنيف')),
              content: SizedBox(
                width: AdminUi.dialogMaxWidth(ctx),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNew)
                        TextField(
                          controller: idCtrl,
                          decoration: InputDecoration(
                            labelText: uiTr(ctx, 'المعرّف (إنجليزي، ثابت)'),
                            hintText: 'tourism',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-z0-9_]'),
                            ),
                          ],
                        ),
                      TextField(
                        controller: storageCtrl,
                        decoration: InputDecoration(
                          labelText: uiTr(ctx, 'قيمة التخزين (tsnef بالعربية)'),
                          hintText: uiTr(ctx, 'معالم سياحية'),
                        ),
                      ),
                      TextField(
                        controller: arCtrl,
                        decoration: InputDecoration(
                          labelText: uiTr(ctx, 'الاسم بالعربية'),
                        ),
                      ),
                      TextField(
                        controller: enCtrl,
                        decoration: InputDecoration(
                          labelText: uiTr(ctx, 'الاسم بالإنجليزية'),
                        ),
                      ),
                      TextField(
                        controller: sortCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: uiTr(ctx, 'الترتيب'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(icon),
                        initialValue: AdminLandmarkCategoryCatalog.iconChoices
                                .contains(icon)
                            ? icon
                            : 'landmark',
                        decoration: InputDecoration(labelText: uiTr(ctx, 'الأيقونة')),
                        items: [
                          for (final name
                              in AdminLandmarkCategoryCatalog.iconChoices)
                            DropdownMenuItem(
                              value: name,
                              child: Row(
                                children: [
                                  Icon(
                                    AdminLandmarkCategoryCatalog.materialIcon(
                                      name,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(name),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() => icon = v);
                        },
                      ),
                      TextField(
                        controller: iconUrlCtrl,
                        decoration: InputDecoration(
                          labelText: uiTr(ctx, 'رابط صورة الأيقونة (اختياري)'),
                          hintText: 'https://',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(uiTr(ctx, 'مفعّل في تطبيق العميل')),
                        value: enabled,
                        onChanged: (v) => setLocal(() => enabled = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(uiTr(ctx, 'إلغاء')),
                ),
                FilledButton(
                  onPressed: () {
                    final id =
                        (isNew ? idCtrl.text : existingId).trim();
                    final storage = storageCtrl.text.trim();
                    if (id.isEmpty || storage.isEmpty) return;
                    Navigator.pop(
                      ctx,
                      AdminLandmarkCategory(
                        id: id,
                        storage: storage,
                        labelAr: arCtrl.text.trim().isEmpty
                            ? storage
                            : arCtrl.text.trim(),
                        labelEn: enCtrl.text.trim().isEmpty
                            ? storage
                            : enCtrl.text.trim(),
                        icon: icon,
                        iconUrl: iconUrlCtrl.text.trim(),
                        trKey: existingTrKey,
                        enabled: enabled,
                        sort: int.tryParse(sortCtrl.text.trim()) ?? 110,
                      ),
                    );
                  },
                  child: Text(uiTr(ctx, isNew ? 'إضافة' : 'حفظ')),
                ),
              ],
            );
          },
        );
      },
    );

    idCtrl.dispose();
    storageCtrl.dispose();
    arCtrl.dispose();
    enCtrl.dispose();
    sortCtrl.dispose();
    iconUrlCtrl.dispose();

    if (saved == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await AdminLandmarkCategoryCatalog.upsert(saved);
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: isNew ? AdminCrudAction.add : AdminCrudAction.edit,
        message: uiTr(context, 'تم حفظ التصنيف'),
      );
      _reload();
    } catch (e, st) {
      AdminUi.logDiagnostic('landmark_cat_save', e, st);
      if (mounted) {
        AdminCrudFeedback.error(context, uiTr(context, 'تعذر حفظ التصنيف'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(AdminLandmarkCategory item) async {
    if (item.id == 'all') return;
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'حذف التصنيف'),
      whatHappens: uiTr(
        context,
        'حذف التصنيف من فلاتر العميل. لا يحذف المعالم نفسها من قاعدة البيانات.',
      ),
      subject: item.labelAr,
      confirmLabel: uiTr(context, 'حذف'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await AdminLandmarkCategoryCatalog.delete(item.id);
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم الحذف'),
      );
      _reload();
    } catch (e, st) {
      AdminUi.logDiagnostic('landmark_cat_delete', e, st);
      if (mounted) {
        AdminCrudFeedback.error(context, uiTr(context, 'تعذر الحذف'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: navLabel(context, AdminLandmarkCategoriesWidget.routeName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'تصنيفات فلاتر المعالم في تطبيق العميل. تظهر الشريحة فقط إن وُجدت معالم بنفس القيمة في المدينة.'),
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: (!_canWrite || _busy) ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(uiTr(context, 'تصنيف جديد')),
              ),
              OutlinedButton.icon(
                onPressed: (!_canWrite || _busy)
                    ? null
                    : () => _seed(overwrite: false),
                icon: const Icon(Icons.playlist_add_check),
                label: Text(uiTr(context, 'تعبئة الافتراضي')),
              ),
              OutlinedButton.icon(
                onPressed: (!_canWrite || _busy)
                    ? null
                    : () => _seed(overwrite: true),
                icon: const Icon(Icons.restart_alt),
                label: Text(uiTr(context, 'استبدال بالافتراضي النظيف')),
              ),
              IconButton(
                tooltip: uiTr(context, 'تحديث'),
                onPressed: _busy ? null : _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AdminLandmarkCategory>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('${uiTr(context, 'تعذر التحميل')}: ${snap.error}'),
                  );
                }
                final items = snap.data ?? const <AdminLandmarkCategory>[];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(uiTr(context, 'لا توجد تصنيفات بعد.')),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: (!_canWrite || _busy)
                              ? null
                              : () => _seed(overwrite: false),
                          child: Text(uiTr(context, 'تعبئة التصنيفات الافتراضية')),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      leading: item.iconUrl.startsWith('http')
                          ? ClipOval(
                              child: Image.network(
                                item.iconUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  AdminLandmarkCategoryCatalog.materialIcon(
                                    item.icon,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              AdminLandmarkCategoryCatalog.materialIcon(
                                item.icon,
                              ),
                              color: item.enabled
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).secondaryText,
                            ),
                      title: Text(
                        (Localizations.localeOf(context).languageCode == 'ar' ||
                                Localizations.localeOf(context).languageCode ==
                                    'ur')
                            ? item.labelAr
                            : (item.labelEn.isNotEmpty
                                ? item.labelEn
                                : item.labelAr),
                        style: TextStyle(
                          decoration: item.enabled
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        '${item.labelEn} · ${uiTr(context, 'قيمة التخزين')}: ${item.storage} · ${uiTr(context, 'الترتيب')} ${item.sort}'
                        '${item.enabled ? '' : ' · ${uiTr(context, 'معطّل')}'}',
                      ),
                      trailing: _canWrite
                          ? Wrap(
                              children: [
                                IconButton(
                                  tooltip: uiTr(context, 'تعديل'),
                                  onPressed: _busy ? null : () => _edit(item),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                if (item.id != 'all')
                                  IconButton(
                                    tooltip: uiTr(context, 'حذف'),
                                    onPressed:
                                        _busy ? null : () => _delete(item),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                              ],
                            )
                          : null,
                      onTap: _canWrite && !_busy ? () => _edit(item) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
