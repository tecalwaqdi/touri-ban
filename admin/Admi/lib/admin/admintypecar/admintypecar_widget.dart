import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/admin/admintypecar/admin_vehicle_types_adapter.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/components/admin_vehicle_type_editor.dart';
import '/core/admin_currency.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admintypecar_model.dart';
export 'admintypecar_model.dart';

class AdmintypecarWidget extends StatefulWidget {
  const AdmintypecarWidget({super.key});

  static String routeName = 'Admintypecar';
  static String routePath = '/admintypecar';

  @override
  State<AdmintypecarWidget> createState() => _AdmintypecarWidgetState();
}

class _AdmintypecarWidgetState extends State<AdmintypecarWidget> {
  late AdmintypecarModel _model;
  Future<List<TypeCarRecord>>? _typeCarsFuture;
  Future<Map<String, int>>? _driverUsageFuture;
  late final void Function() _listRefreshListener;
  AdminVehicleTypeFilters _filters = const AdminVehicleTypeFilters();
  late final TextEditingController _searchController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<TypeCarRecord>> _loadTypeCars() {
    return queryListCacheFirst(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: (q) => q.orderBy('sr'),
      limit: 200,
    );
  }

  /// One-pass driver→type usage (no N+1 per row).
  Future<Map<String, int>> _loadDriverUsage() async {
    final counts = <String, int>{};
    try {
      final docs = await queryUserRecordOnce(
        queryBuilder: (q) => q.where('ismndob', isEqualTo: true),
        limit: 400,
      );
      for (final u in docs) {
        final data = u.snapshotData;
        DocumentReference? ref;
        final a = data['mndob_type_car'];
        final b = data['mndobTypeCar'];
        final c = data['car_rev_mndob'] ?? data['carRev_mndob'];
        if (a is DocumentReference) {
          ref = a;
        } else if (b is DocumentReference) {
          ref = b;
        } else if (c is DocumentReference) {
          ref = c;
        }
        if (ref == null) continue;
        counts[ref.id] = (counts[ref.id] ?? 0) + 1;
      }
    } catch (_) {}
    return counts;
  }

  Future<void> _seedVehicleCatalog() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final preset in _vehicleTypePresets) {
      final ref = TypeCarRecord.collection.doc(preset.code);
      batch.set(
        ref,
        createTypeCarRecordData(
          naim: preset.names['ar'] ?? preset.names['en'],
          namesI18n: preset.names,
          sr: preset.hourlyRate,
          actev: true,
          ishafelh: preset.isBusLike,
          aglSaat: preset.minHours,
          codeCar: preset.code,
        ),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    if (!mounted) return;
    await AdminCrudFeedback.success(
      context,
      action: AdminCrudAction.add,
      message:
          '${uiTr(context, 'تمت إضافة/تحديث')} ${_vehicleTypePresets.length} ${uiTr(context, 'نوع مركبة جاهز')}',
      refreshScope: AdminListScope.typeCars,
      invalidateStats: false,
    );
  }

  void _reloadTypeCars() {
    if (!mounted) return;
    setState(() {
      _typeCarsFuture = _loadTypeCars();
      _driverUsageFuture = _loadDriverUsage();
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdmintypecarModel());
    _searchController = TextEditingController();
    _typeCarsFuture = _loadTypeCars();
    _driverUsageFuture = _loadDriverUsage();
    _listRefreshListener = _reloadTypeCars;
    AdminListRefresh.register(AdminListScope.typeCars, _listRefreshListener);
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_vehicle_types_search');
    AdminListRefresh.unregister(AdminListScope.typeCars, _listRefreshListener);
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _softDeactivate(AdminVehicleTypeRow row) async {
    final usage = await (_driverUsageFuture ?? Future.value(const <String, int>{}));
    final drivers = usage[row.record.reference.id] ?? 0;
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تعطيل نوع المركبة'),
      whatHappens: uiTr(
        context,
        'Soft-disable (actev=false). Historical drivers/bookings keep their reference.',
      ),
      subject: row.displayNameAr,
      impact: drivers > 0
          ? '${uiTr(context, 'مرتبط بـ')} $drivers ${uiTr(context, 'مندوب — لن يُحذف السجل')}'
          : uiTr(context, 'لن يظهر للحجوزات الجديدة حسب قواعد التطبيق'),
      confirmLabel: uiTr(context, 'تعطيل'),
      cancelLabel: uiTr(context, 'إلغاء'),
      destructive: true,
      irreversible: false,
      reference: row.record.reference.id,
    );
    if (!confirmed) return;
    try {
      await row.record.reference.update(
        createTypeCarRecordData(actev: false, updatedAt: DateTime.now()),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تعطيل نوع المركبة'),
        refreshScope: AdminListScope.typeCars,
        invalidateStats: false,
      );
      _reloadTypeCars();
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  Future<void> _toggleActive(AdminVehicleTypeRow row) async {
    final next = !row.active;
    try {
      await row.record.reference.update(
        createTypeCarRecordData(actev: next, updatedAt: DateTime.now()),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: next
            ? uiTr(context, 'تم تفعيل نوع المركبة')
            : uiTr(context, 'تم تعطيل نوع المركبة'),
        refreshScope: AdminListScope.typeCars,
        invalidateStats: false,
      );
      _reloadTypeCars();
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = AdminUi.useTableLayout(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: uiTr(context, 'أنواع المركبات'),
        child: AdminPageBody(
          title: uiTr(context, 'أنواع المركبات'),
          subtitle: uiTr(
            context,
            'إدارة تصنيفات وأنواع المركبات المستخدمة في الحجز والمناديب',
          ),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    wide
                        ? Row(
                            children: [
                              Expanded(child: _searchField(theme)),
                              const SizedBox(width: 10),
                              _addButton(),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _searchField(theme),
                              const SizedBox(height: 10),
                              _addButton(),
                            ],
                          ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text(uiTr(context, 'الكل')),
                          selected: _filters.status ==
                                  AdminVehicleTypeStatusFilter.all &&
                              _filters.classFilter ==
                                  AdminVehicleTypeClassFilter.all,
                          onSelected: (_) => setState(() {
                            _filters = const AdminVehicleTypeFilters();
                            _searchController.clear();
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'نشط')),
                          selected: _filters.status ==
                              AdminVehicleTypeStatusFilter.active,
                          onSelected: (_) => setState(() {
                            _filters = _filters.copyWith(
                              status: AdminVehicleTypeStatusFilter.active,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'غير نشط')),
                          selected: _filters.status ==
                              AdminVehicleTypeStatusFilter.inactive,
                          onSelected: (_) => setState(() {
                            _filters = _filters.copyWith(
                              status: AdminVehicleTypeStatusFilter.inactive,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'سيارات')),
                          selected: _filters.classFilter ==
                              AdminVehicleTypeClassFilter.car,
                          onSelected: (_) => setState(() {
                            _filters = _filters.copyWith(
                              classFilter: AdminVehicleTypeClassFilter.car,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'حافلات')),
                          selected: _filters.classFilter ==
                              AdminVehicleTypeClassFilter.bus,
                          onSelected: (_) => setState(() {
                            _filters = _filters.copyWith(
                              classFilter: AdminVehicleTypeClassFilter.bus,
                            );
                          }),
                        ),
                        if (_filters.hasActive)
                          TextButton(
                            onPressed: () => setState(() {
                              _filters = const AdminVehicleTypeFilters();
                              _searchController.clear();
                            }),
                            child: Text(uiTr(context, 'إعادة تعيين')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(uiTr(context, 'تأكيد باقة المركبات')),
                              content: Text(
                                '${uiTr(context, 'سيتم إضافة/تحديث')} ${_vehicleTypePresets.length} ${uiTr(context, 'نوع مركبة')} '
                                '${uiTr(context, 'بترجمات. العملية آمنة (merge).')}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(uiTr(context, 'إلغاء')),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(uiTr(context, 'تأكيد')),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          try {
                            await _seedVehicleCatalog();
                            _reloadTypeCars();
                          } catch (e) {
                            if (!mounted) return;
                            AdminCrudFeedback.error(
                              context,
                              AdminCrudFeedback.saveFailed(context, e),
                            );
                          }
                        },
                        icon: const Icon(Icons.library_add_outlined, size: 18),
                        label: Text(
                          '${uiTr(context, 'باقة جاهزة')} (${_vehicleTypePresets.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<TypeCarRecord>>(
                future: _typeCarsFuture,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return AdminContentCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(uiTr(context, 'تعذر تحميل أنواع السيارات')),
                          ),
                          TextButton(
                            onPressed: _reloadTypeCars,
                            child: Text(uiTr(context, 'إعادة')),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: SpinKitThreeBounce(
                          color: AdminUi.brandTeal,
                          size: 40,
                        ),
                      ),
                    );
                  }

                  final rows = adminSortVehicleTypes(
                    snap.data!
                        .map(AdminVehicleTypeRow.fromRecord)
                        .toList(growable: false),
                  );
                  final filtered = _filters.apply(rows);
                  final activeCount = rows.where((r) => r.active).length;
                  final pricedCount = rows.where((r) => r.hasPricing).length;

                  return FutureBuilder<Map<String, int>>(
                    future: _driverUsageFuture,
                    builder: (context, usageSnap) {
                      final usage = usageSnap.data ?? const <String, int>{};
                      final linkedDrivers = usage.values.fold<int>(0, (a, b) => a + b);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryStrip(
                            total: rows.length,
                            active: activeCount,
                            inactive: rows.length - activeCount,
                            priced: pricedCount,
                            driverLinks: linkedDrivers,
                          ),
                          const SizedBox(height: 10),
                          AdminContentCard(
                            padding: EdgeInsets.zero,
                            child: filtered.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.directions_car_outlined,
                                          size: 48,
                                          color: AdminUi.brandTeal
                                              .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          uiTr(context, 'لا توجد أنواع مطابقة'),
                                          style: theme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  )
                                : wide
                                    ? _VehicleTypesTable(
                                        rows: filtered,
                                        usage: usage,
                                        onEdit: (row) async {
                                          final ok =
                                              await AdminVehicleTypeEditor.open(
                                            context,
                                            row.record,
                                          );
                                          if (ok == true) _reloadTypeCars();
                                        },
                                        onToggle: _toggleActive,
                                        onDeactivate: _softDeactivate,
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(12),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) {
                                          final row = filtered[i];
                                          return _VehicleTypeCard(
                                            row: row,
                                            driverCount:
                                                usage[row.record.reference.id] ??
                                                    0,
                                            onEdit: () async {
                                              final ok =
                                                  await AdminVehicleTypeEditor
                                                      .open(
                                                context,
                                                row.record,
                                              );
                                              if (ok == true) _reloadTypeCars();
                                            },
                                            onToggle: () => _toggleActive(row),
                                            onDeactivate: () =>
                                                _softDeactivate(row),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(FlutterFlowTheme theme) {
    return TextField(
      controller: _searchController,
      onChanged: (v) {
        EasyDebounce.debounce(
          'admin_vehicle_types_search',
          const Duration(milliseconds: 280),
          () => setState(() {
            _filters = _filters.copyWith(searchQuery: v);
          }),
        );
      },
      decoration: InputDecoration(
        hintText: uiTr(context, 'بحث: الاسم / الإنجليزي / التصنيف / الكود'),
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  Widget _addButton() {
    return FilledButton.icon(
      onPressed: () => context.pushNamed(CarTypeAdditionWidget.routeName),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(uiTr(context, 'إضافة نوع')),
      style: FilledButton.styleFrom(
        backgroundColor: AdminUi.brandTeal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.active,
    required this.inactive,
    required this.priced,
    required this.driverLinks,
  });

  final int total;
  final int active;
  final int inactive;
  final int priced;
  final int driverLinks;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String, Color)>[
      (uiTr(context, 'إجمالي'), '$total', AdminUi.brandTeal),
      (uiTr(context, 'نشطة'), '$active', Colors.green.shade700),
      (uiTr(context, 'غير نشطة'), '$inactive', Colors.orange.shade800),
      (uiTr(context, 'مرتبطة بتسعير'), '$priced', Colors.blue.shade800),
      (uiTr(context, 'مرتبطة بمناديب'), '$driverLinks', Colors.purple.shade700),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.7),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.$3.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.$3.withValues(alpha: 0.28)),
              ),
              child: Text(
                '${c.$1}: ${c.$2}',
                style: TextStyle(
                  color: c.$3,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VehicleTypesTable extends StatelessWidget {
  const _VehicleTypesTable({
    required this.rows,
    required this.usage,
    required this.onEdit,
    required this.onToggle,
    required this.onDeactivate,
  });

  final List<AdminVehicleTypeRow> rows;
  final Map<String, int> usage;
  final ValueChanged<AdminVehicleTypeRow> onEdit;
  final ValueChanged<AdminVehicleTypeRow> onToggle;
  final ValueChanged<AdminVehicleTypeRow> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minW = constraints.maxWidth < 960 ? 960.0 : constraints.maxWidth;
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minW,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: AdminUi.brandTeal.withValues(alpha: 0.06),
                    child: Row(
                      children: [
                        _h(theme, uiTr(context, 'الصورة'), flex: 2),
                        _h(theme, uiTr(context, 'الاسم'), flex: 4),
                        _h(theme, uiTr(context, 'التصنيف'), flex: 2),
                        _h(theme, uiTr(context, 'السعة'), flex: 2),
                        _h(theme, uiTr(context, 'الحالة'), flex: 2),
                        _h(theme, uiTr(context, 'الترتيب'), flex: 2),
                        _h(theme, uiTr(context, 'الاستخدام'), flex: 3),
                        _h(theme, uiTr(context, 'إجراءات'), flex: 3),
                      ],
                    ),
                  ),
                  for (final row in rows)
                    _TableRow(
                      row: row,
                      driverCount: usage[row.record.reference.id] ?? 0,
                      onEdit: () => onEdit(row),
                      onToggle: () => onToggle(row),
                      onDeactivate: () => onDeactivate(row),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _h(FlutterFlowTheme theme, String t, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          t,
          style: theme.labelMedium.override(
            fontFamily: theme.labelMediumFamily,
            fontWeight: FontWeight.w800,
            useGoogleFonts: !theme.labelMediumIsCustom,
          ),
        ),
      );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.row,
    required this.driverCount,
    required this.onEdit,
    required this.onToggle,
    required this.onDeactivate,
  });

  final AdminVehicleTypeRow row;
  final int driverCount;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final price = formatNumber(
      row.hourlyRate,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
      currency: AdminCurrency.asFormatPrefix(
        AdminCurrency.symbolForIso(row.countryIso2),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.55)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AdminRecordThumbnail(
              key: ValueKey('vt_${row.record.reference.id}_${row.imageUrl.hashCode}'),
              imageUrl: row.imageUrl,
              width: 56,
              height: 42,
              borderRadius: BorderRadius.circular(8),
              fallback: Container(
                color: AdminUi.brandTeal.withValues(alpha: 0.08),
                child: const Icon(Icons.directions_car_rounded,
                    color: AdminUi.brandTeal),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayNameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
                if (row.displayNameEn.isNotEmpty)
                  Text(
                    row.displayNameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall,
                  ),
                Text(
                  'code: ${row.code}',
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(row.classificationLabel)),
          Expanded(
            flex: 2,
            child: Text(row.passengers > 0 ? '${row.passengers}' : '—'),
          ),
          Expanded(
            flex: 2,
            child: AdminStatusBadgeUnified(
              kind: row.active
                  ? AdminStatusKind.active
                  : AdminStatusKind.inactive,
              label: row.active
                  ? uiTr(context, 'نشط')
                  : uiTr(context, 'غير نشط'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(row.sortOrder > 0 ? '${row.sortOrder}' : '—'),
          ),
          Expanded(
            flex: 3,
            child: Text(
              [
                if (row.hasPricing) '$price/${uiTr(context, 'ساعة')}',
                if (driverCount > 0)
                  '$driverCount ${uiTr(context, 'مندوب')}',
                if (!row.hasPricing && driverCount == 0) '—',
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: uiTr(context, 'تعديل'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: row.active
                      ? uiTr(context, 'تعطيل')
                      : uiTr(context, 'تفعيل'),
                  onPressed: onToggle,
                  icon: Icon(
                    row.active
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 20,
                  ),
                ),
                if (row.active)
                  IconButton(
                    tooltip: uiTr(context, 'تعطيل آمن'),
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.block_outlined, size: 20),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.row,
    required this.driverCount,
    required this.onEdit,
    required this.onToggle,
    required this.onDeactivate,
  });

  final AdminVehicleTypeRow row;
  final int driverCount;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminRecordThumbnail(
                key: ValueKey(
                    'vt_m_${row.record.reference.id}_${row.imageUrl.hashCode}'),
                imageUrl: row.imageUrl,
                width: 72,
                height: 54,
                borderRadius: BorderRadius.circular(8),
                fallback: Container(
                  color: AdminUi.brandTeal.withValues(alpha: 0.08),
                  child: const Icon(Icons.directions_car_rounded,
                      color: AdminUi.brandTeal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayNameAr,
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w800,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    Text(row.classificationLabel, style: theme.bodySmall),
                  ],
                ),
              ),
              AdminStatusBadgeUnified(
                kind: row.active
                    ? AdminStatusKind.active
                    : AdminStatusKind.inactive,
                label: row.active
                    ? uiTr(context, 'نشط')
                    : uiTr(context, 'غير نشط'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: onEdit,
                child: Text(uiTr(context, 'تعديل')),
              ),
              OutlinedButton(
                onPressed: onToggle,
                child: Text(
                  row.active
                      ? uiTr(context, 'تعطيل')
                      : uiTr(context, 'تفعيل'),
                ),
              ),
              if (row.active)
                TextButton(
                  onPressed: onDeactivate,
                  child: Text(uiTr(context, 'تعطيل آمن')),
                ),
            ],
          ),
          if (driverCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$driverCount ${uiTr(context, 'مندوب مرتبط')}',
                style: theme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _VehicleTypePreset {
  const _VehicleTypePreset({
    required this.code,
    required this.names,
    required this.hourlyRate,
    required this.minHours,
    this.isBusLike = false,
  });

  final String code;
  final Map<String, String> names;
  final int hourlyRate;
  final int minHours;
  final bool isBusLike;
}

const List<_VehicleTypePreset> _vehicleTypePresets = [
  _VehicleTypePreset(
    code: 'economy',
    names: {
      'ar': 'اقتصادية',
      'en': 'Economy',
      'ru': 'Эконом',
      'ky': 'Эконом',
      'uz': 'Ekonom'
    },
    hourlyRate: 160,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'compact',
    names: {
      'ar': 'مدمجة',
      'en': 'Compact',
      'ru': 'Компакт',
      'ky': 'Компакт',
      'uz': 'Kompakt'
    },
    hourlyRate: 170,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'sedan_standard',
    names: {
      'ar': 'سيدان قياسية',
      'en': 'Standard Sedan',
      'ru': 'Стандартный седан',
      'ky': 'Стандарт седан',
      'uz': 'Standart sedan'
    },
    hourlyRate: 180,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'comfort',
    names: {
      'ar': 'مريحة',
      'en': 'Comfort',
      'ru': 'Комфорт',
      'ky': 'Комфорт',
      'uz': 'Komfort'
    },
    hourlyRate: 210,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'sedan_business',
    names: {
      'ar': 'سيدان أعمال',
      'en': 'Business Sedan',
      'ru': 'Бизнес седан',
      'ky': 'Бизнес седан',
      'uz': 'Biznes sedan'
    },
    hourlyRate: 240,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'business',
    names: {
      'ar': 'أعمال',
      'en': 'Business',
      'ru': 'Бизнес',
      'ky': 'Бизнес',
      'uz': 'Biznes'
    },
    hourlyRate: 280,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'premium',
    names: {
      'ar': 'ممتازة',
      'en': 'Premium',
      'ru': 'Премиум',
      'ky': 'Премиум',
      'uz': 'Premium'
    },
    hourlyRate: 320,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'premium_sedan',
    names: {
      'ar': 'سيدان فاخرة',
      'en': 'Premium Sedan',
      'ru': 'Премиум седан',
      'ky': 'Премиум седан',
      'uz': 'Premium sedan'
    },
    hourlyRate: 420,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'luxury',
    names: {
      'ar': 'فاخرة',
      'en': 'Luxury',
      'ru': 'Люкс',
      'ky': 'Люкс',
      'uz': 'Lyuks'
    },
    hourlyRate: 480,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'suv_compact',
    names: {
      'ar': 'SUV مدمجة',
      'en': 'Compact SUV',
      'ru': 'Компактный SUV',
      'ky': 'Ыкчам SUV',
      'uz': 'Kompakt SUV'
    },
    hourlyRate: 260,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_standard',
    names: {
      'ar': 'SUV قياسية',
      'en': 'SUV Standard',
      'ru': 'Стандартный SUV',
      'ky': 'Стандарт SUV',
      'uz': 'Standart SUV'
    },
    hourlyRate: 300,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_family',
    names: {
      'ar': 'SUV عائلية',
      'en': 'Family SUV',
      'ru': 'Семейный SUV',
      'ky': 'Үй-бүлөлүк SUV',
      'uz': 'Oilaviy SUV'
    },
    hourlyRate: 320,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_large',
    names: {
      'ar': 'SUV كبيرة',
      'en': 'SUV Large',
      'ru': 'Большой SUV',
      'ky': 'Чоң SUV',
      'uz': 'Katta SUV'
    },
    hourlyRate: 380,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'coach_mini',
    names: {
      'ar': 'حافلة صغيرة',
      'en': 'Mini Coach',
      'ru': 'Мини автобус',
      'ky': 'Мини автобус',
      'uz': 'Mini avtobus'
    },
    hourlyRate: 100,
    minHours: 4,
    isBusLike: true,
  ),
  _VehicleTypePreset(
    code: 'coach_tour',
    names: {
      'ar': 'حافلة سياحية',
      'en': 'Tour Coach',
      'ru': 'Туристический автобус',
      'ky': 'Туристтик автобус',
      'uz': 'Turistik avtobus'
    },
    hourlyRate: 180,
    minHours: 5,
    isBusLike: true,
  ),
];
