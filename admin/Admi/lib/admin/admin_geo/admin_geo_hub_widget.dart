import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/admin/admin_geo/admin_geo_adapter.dart';
import '/admin/admin_geo/admin_geo_reference_scan.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_geo_hub_model.dart';
export 'admin_geo_hub_model.dart';

/// Unified Geo Management: Countries → Regions → Cities.
class AdminGeoHubWidget extends StatefulWidget {
  const AdminGeoHubWidget({
    super.key,
    this.initialTab = AdminGeoTab.countries,
  });

  final AdminGeoTab initialTab;

  static String routeName = 'AdminGeoHub';
  static String routePath = '/adminGeoHub';

  @override
  State<AdminGeoHubWidget> createState() => _AdminGeoHubWidgetState();
}

class _AdminGeoHubWidgetState extends State<AdminGeoHubWidget>
    with SingleTickerProviderStateMixin {
  late AdminGeoHubModel _model;
  late TabController _tabs;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _search = '';
  AdminGeoActiveFilter _activeFilter = AdminGeoActiveFilter.all;
  DocumentReference? _countryFilter;
  DocumentReference? _regionFilter;
  int _pageSize = 20;
  int _pageIndex = 0;

  List<CountriesRecord> _countries = const [];
  List<CitiesRecord> _regions = const [];
  List<VillagesRecord> _cities = const [];
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminGeoHubModel());
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {
        _pageIndex = 0;
        _search = '';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_geo_search');
    _tabs.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        CountriesRecord.collection.orderBy('naim').get(),
        CitiesRecord.collection.orderBy('naim').get(),
        VillagesRecord.collection.orderBy('naim').get(),
      ]);
      if (!mounted) return;
      setState(() {
        _countries =
            results[0].docs.map(CountriesRecord.fromSnapshot).toList();
        _regions = results[1].docs.map(CitiesRecord.fromSnapshot).toList();
        _cities = results[2].docs.map(VillagesRecord.fromSnapshot).toList();
        _bootstrapped = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bootstrapped = true);
    }
  }

  AdminGeoTab get _tab => AdminGeoTab.values[_tabs.index];

  bool get _countriesAllowed => AdminSuperAdminGate.isAllowed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final title = uiTr(context, 'إدارة المواقع الجغرافية');

    // Country agents may open regions/cities; countries remain SuperAdmin.
    if (_tab == AdminGeoTab.countries && !_countriesAllowed) {
      final blocked = AdminSuperAdminGate.guardLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: title,
        feature: uiTr(context, 'إدارة الدول'),
      );
      if (blocked != null) {
        // Still allow switching to other tabs via menu routes.
      }
    }

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
        title: title,
        child: AdminPageBody(
          title: title,
          subtitle: uiTr(
            context,
            'إدارة الدول والمناطق والمدن المستخدمة في التسجيل والحجوزات والمعالم',
          ),
          compactHeader: true,
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryStrip(theme),
              const SizedBox(height: 12),
              _tabBar(theme),
              const SizedBox(height: 12),
              _toolbar(theme),
              const SizedBox(height: 12),
              if (!_bootstrapped)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _tableCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryStrip(FlutterFlowTheme theme) {
    final summary = AdminGeoAdapter.summary(
      countries: _countries,
      regions: _regions,
      cities: _cities,
    );
    Widget chip(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(uiTr(context, 'الدول'), '${summary.countries}'),
        chip(uiTr(context, 'المناطق'), '${summary.regions}'),
        chip(uiTr(context, 'المدن'), '${summary.cities}'),
        chip(uiTr(context, 'النشطة'), '${summary.active}'),
        chip(uiTr(context, 'غير النشطة'), '${summary.inactive}'),
      ],
    );
  }

  Widget _tabBar(FlutterFlowTheme theme) {
    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: TabBar(
        controller: _tabs,
        labelColor: AdminUi.brandTeal,
        unselectedLabelColor: theme.secondaryText,
        indicatorColor: AdminUi.brandTeal,
        tabs: [
          Tab(text: uiTr(context, 'الدول')),
          Tab(text: uiTr(context, 'المناطق')),
          Tab(text: uiTr(context, 'المدن')),
        ],
      ),
    );
  }

  Widget _toolbar(FlutterFlowTheme theme) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final search = TextField(
      onChanged: (v) {
        EasyDebounce.debounce(
          'admin_geo_search',
          const Duration(milliseconds: 280),
          () => setState(() {
            _search = v;
            _pageIndex = 0;
          }),
        );
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: _tab == AdminGeoTab.countries
            ? uiTr(context, 'بحث باسم الدولة')
            : _tab == AdminGeoTab.regions
                ? uiTr(context, 'بحث باسم المنطقة')
                : uiTr(context, 'بحث باسم المدينة'),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final active = SizedBox(
      width: 140,
      child: DropdownButtonFormField<AdminGeoActiveFilter>(
        value: _activeFilter,
        isDense: true,
        decoration: InputDecoration(
          labelText: uiTr(context, 'الحالة'),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: [
          DropdownMenuItem(
            value: AdminGeoActiveFilter.all,
            child: Text(uiTr(context, 'الكل')),
          ),
          DropdownMenuItem(
            value: AdminGeoActiveFilter.active,
            child: Text(uiTr(context, 'نشط')),
          ),
          DropdownMenuItem(
            value: AdminGeoActiveFilter.inactive,
            child: Text(uiTr(context, 'غير نشط')),
          ),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _activeFilter = v;
            _pageIndex = 0;
          });
        },
      ),
    );

    final countryDd = _tab == AdminGeoTab.countries
        ? const SizedBox.shrink()
        : SizedBox(
            width: 180,
            child: DropdownButtonFormField<DocumentReference?>(
              value: _countryFilter,
              isDense: true,
              decoration: InputDecoration(
                labelText: uiTr(context, 'الدولة'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                DropdownMenuItem<DocumentReference?>(
                  value: null,
                  child: Text(uiTr(context, 'الكل')),
                ),
                ..._countries.map(
                  (c) => DropdownMenuItem<DocumentReference?>(
                    value: c.reference,
                    child: Text(
                      AdminGeoAdapter.displayName(c.naim, c.reference.id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _countryFilter = v;
                  _regionFilter = null;
                  _pageIndex = 0;
                });
              },
            ),
          );

    final regionOptions = _countryFilter == null
        ? AdminGeoAdapter.logicalRegions(_regions)
        : AdminGeoAdapter.logicalRegions(_regions)
            .where((r) => r.dolh?.path == _countryFilter!.path)
            .toList();

    final regionDd = _tab != AdminGeoTab.cities
        ? const SizedBox.shrink()
        : SizedBox(
            width: 180,
            child: DropdownButtonFormField<DocumentReference?>(
              value: _regionFilter,
              isDense: true,
              decoration: InputDecoration(
                labelText: uiTr(context, 'المنطقة'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                DropdownMenuItem<DocumentReference?>(
                  value: null,
                  child: Text(uiTr(context, 'الكل')),
                ),
                ...regionOptions.map(
                  (r) => DropdownMenuItem<DocumentReference?>(
                    value: r.reference,
                    child: Text(
                      AdminGeoAdapter.displayName(r.naim, r.reference.id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _regionFilter = v;
                _pageIndex = 0;
              }),
            ),
          );

    final pageSize = SizedBox(
      width: 96,
      child: DropdownButtonFormField<int>(
        value: _pageSize,
        isDense: true,
        decoration: InputDecoration(
          labelText: uiTr(context, 'الصفحة'),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: const [
          DropdownMenuItem(value: 20, child: Text('20')),
          DropdownMenuItem(value: 50, child: Text('50')),
          DropdownMenuItem(value: 100, child: Text('100')),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _pageSize = v;
            _pageIndex = 0;
          });
        },
      ),
    );

    final add = _buildAddButton();

    final controls = <Widget>[
      if (_tab != AdminGeoTab.countries) ...[
        countryDd,
        const SizedBox(width: 8),
      ],
      if (_tab == AdminGeoTab.cities) ...[
        regionDd,
        const SizedBox(width: 8),
      ],
      active,
      const SizedBox(width: 8),
      pageSize,
      const SizedBox(width: 8),
      add,
    ];

    return AdminContentCard(
      padding: const EdgeInsets.all(12),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 3, child: search),
                const SizedBox(width: 10),
                ...controls,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: controls),
              ],
            ),
    );
  }

  Widget _buildAddButton() {
    final label = _tab == AdminGeoTab.countries
        ? uiTr(context, 'إضافة دولة')
        : _tab == AdminGeoTab.regions
            ? uiTr(context, 'إضافة منطقة')
            : uiTr(context, 'إضافة مدينة');
    return FilledButton.icon(
      onPressed: () {
        if (_tab == AdminGeoTab.countries) {
          if (!_countriesAllowed) return;
          context.pushNamed(AddDolhWidget.routeName);
        } else if (_tab == AdminGeoTab.regions) {
          context.pushNamed(AddRegWidget.routeName);
        } else {
          context.pushNamed(AddVillWidget.routeName);
        }
      },
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AdminUi.brandTeal,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _tableCard(FlutterFlowTheme theme) {
    if (_tab == AdminGeoTab.countries && !_countriesAllowed) {
      return AdminContentCard(
        padding: const EdgeInsets.all(24),
        child: Text(
          uiTr(context, 'إدارة الدول متاحة لصلاحية السوبر أدمن فقط'),
          style: theme.bodyMedium,
        ),
      );
    }

    if (_tab == AdminGeoTab.countries) {
      final rows = AdminGeoAdapter.countryRows(
        countries: _countries,
        regions: _regions,
        cities: _cities,
        search: _search,
        activeFilter: _activeFilter,
      );
      return _paginatedTable(
        theme: theme,
        total: rows.length,
        headers: [
          uiTr(context, 'الدولة'),
          uiTr(context, 'الكود'),
          uiTr(context, 'المناطق'),
          uiTr(context, 'المدن'),
          uiTr(context, 'الحالة'),
          uiTr(context, 'الترتيب'),
          uiTr(context, 'الإجراءات'),
        ],
        rowBuilder: (i) {
          final page = _pageSlice(rows);
          final row = page[i];
          return [
            _nameCell(row.displayName, tip: row.id),
            Text(row.iso.isEmpty ? '—' : row.iso),
            Text('${row.regionCount}'),
            Text('${row.cityCount}'),
            _statusBadge(row.active),
            Text('${row.sort}'),
            _actions(
              onEdit: () => context.pushNamed(
                EdetDolhWidget.routeName,
                queryParameters: {
                  'iddolhe': serializeParam(
                    row.record.reference,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
              onToggle: () => _toggleCountry(row.record, !row.active),
              active: row.active,
              onDeleteAttempt: () => _safeDisableCountry(row.record),
            ),
          ];
        },
        pageLength: _pageSlice(rows).length,
      );
    }

    if (_tab == AdminGeoTab.regions) {
      final rows = AdminGeoAdapter.regionRows(
        regions: _regions,
        countries: _countries,
        cities: _cities,
        search: _search,
        activeFilter: _activeFilter,
        countryFilter: _countryFilter ?? AdminCountryScope.activeCountryRef,
      );
      return _paginatedTable(
        theme: theme,
        total: rows.length,
        headers: [
          uiTr(context, 'المنطقة'),
          uiTr(context, 'الدولة'),
          uiTr(context, 'المدن'),
          uiTr(context, 'الحالة'),
          uiTr(context, 'الترتيب'),
          uiTr(context, 'الإجراءات'),
        ],
        rowBuilder: (i) {
          final page = _pageSlice(rows);
          final row = page[i];
          return [
            _nameCell(
              row.displayName,
              tip: row.orphanParent ? 'يتيم: بدون دولة' : row.id,
              warn: row.orphanParent,
            ),
            Text(row.countryName),
            Text('${row.cityCount}'),
            _statusBadge(row.active),
            Text('${row.sort}'),
            _actions(
              onEdit: () => context.pushNamed(
                EdetRegWidget.routeName,
                queryParameters: {
                  'idreg': serializeParam(
                    row.record.reference,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
              onToggle: () => _toggleRegion(row.record, !row.active),
              active: row.active,
              onDeleteAttempt: () => _safeDisableRegion(row.record),
            ),
          ];
        },
        pageLength: _pageSlice(rows).length,
      );
    }

    final rows = AdminGeoAdapter.cityRows(
      cities: _cities,
      regions: _regions,
      countries: _countries,
      search: _search,
      activeFilter: _activeFilter,
      countryFilter: _countryFilter ?? AdminCountryScope.activeCountryRef,
      regionFilter: _regionFilter,
    );
    return _paginatedTable(
      theme: theme,
      total: rows.length,
      headers: [
        uiTr(context, 'المدينة'),
        uiTr(context, 'المنطقة'),
        uiTr(context, 'الدولة'),
        uiTr(context, 'الحالة'),
        uiTr(context, 'الاستخدام'),
        uiTr(context, 'الإجراءات'),
      ],
      rowBuilder: (i) {
        final page = _pageSlice(rows);
        final row = page[i];
        final usage = row.orphanRegion || row.countryMismatch
            ? uiTr(context, 'علاقة غير مكتملة')
            : uiTr(context, 'جاهزة');
        return [
          _nameCell(
            row.displayName,
            tip: row.id,
            warn: row.orphanRegion || row.countryMismatch,
          ),
          Text(row.regionName),
          Text(row.countryName),
          _statusBadge(row.active),
          Text(usage),
          _actions(
            onEdit: () => context.pushNamed(
              EdetVillWidget.routeName,
              queryParameters: {
                'idvill': serializeParam(
                  row.record.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            ),
            onToggle: () => _toggleCity(row.record, !row.active),
            active: row.active,
            onDeleteAttempt: () => _safeDisableCity(row.record),
          ),
        ];
      },
      pageLength: _pageSlice(rows).length,
    );
  }

  List<T> _pageSlice<T>(List<T> rows) {
    if (rows.isEmpty) return const [];
    final start = (_pageIndex * _pageSize).clamp(0, rows.length);
    final end = (start + _pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  Widget _paginatedTable({
    required FlutterFlowTheme theme,
    required int total,
    required List<String> headers,
    required List<Widget> Function(int index) rowBuilder,
    required int pageLength,
  }) {
    final maxPage = total == 0 ? 0 : ((total - 1) / _pageSize).floor();
    if (_pageIndex > maxPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pageIndex = maxPage);
      });
    }

    if (total == 0) {
      return AdminContentCard(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            uiTr(context, 'لا توجد نتائج'),
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ),
      );
    }

    final isWide = AdminUi.useTableLayout(context);
    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              '${uiTr(context, 'النتائج')} $total',
              style: theme.labelSmall,
            ),
          ),
          if (isWide)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width - 320,
                ),
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 56,
                  columnSpacing: 18,
                  horizontalMargin: 8,
                  columns: [
                    for (final h in headers)
                      DataColumn(
                        label: Text(
                          h,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            fontWeight: FontWeight.w700,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ),
                  ],
                  rows: [
                    for (var i = 0; i < pageLength; i++)
                      DataRow(
                        cells: [
                          for (final cell in rowBuilder(i))
                            DataCell(cell),
                        ],
                      ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(pageLength, (i) {
              final cells = rowBuilder(i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.alternate.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var h = 0; h < headers.length; h++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 88,
                                child: Text(
                                  headers[h],
                                  style: theme.labelSmall.override(
                                    fontFamily: theme.labelSmallFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts: !theme.labelSmallIsCustom,
                                  ),
                                ),
                              ),
                              Expanded(child: cells[h]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${uiTr(context, 'صفحة')} ${_pageIndex + 1} / ${maxPage + 1}',
                style: theme.labelSmall,
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _pageIndex <= 0
                    ? null
                    : () => setState(() => _pageIndex--),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _pageIndex >= maxPage
                    ? null
                    : () => setState(() => _pageIndex++),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nameCell(String name, {String? tip, bool warn = false}) {
    final theme = FlutterFlowTheme.of(context);
    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.bodyMedium.override(
        fontFamily: theme.bodyMediumFamily,
        fontWeight: FontWeight.w600,
        color: warn ? theme.error : null,
        useGoogleFonts: !theme.bodyMediumIsCustom,
      ),
    );
    if (tip == null || tip.isEmpty) return text;
    return Tooltip(message: tip, child: text);
  }

  Widget _statusBadge(bool active) {
    final theme = FlutterFlowTheme.of(context);
    final bg = active
        ? theme.success.withValues(alpha: 0.12)
        : theme.error.withValues(alpha: 0.10);
    final fg = active ? theme.success : theme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? uiTr(context, 'نشط') : uiTr(context, 'غير نشط'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: fg,
          fontWeight: FontWeight.w700,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }

  Widget _actions({
    required VoidCallback onEdit,
    required VoidCallback onToggle,
    required bool active,
    required VoidCallback onDeleteAttempt,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: uiTr(context, 'تعديل'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: active
              ? uiTr(context, 'تعطيل')
              : uiTr(context, 'تفعيل'),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            active ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        IconButton(
          tooltip: uiTr(context, 'تعطيل آمن'),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.block, size: 18, color: FlutterFlowTheme.of(context).error),
          onPressed: onDeleteAttempt,
        ),
      ],
    );
  }

  Future<void> _toggleCountry(CountriesRecord record, bool activate) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: activate ? uiTr(context, 'تفعيل الدولة') : uiTr(context, 'تعطيل الدولة'),
      whatHappens: activate
          ? uiTr(context, 'ستظهر الدولة في القوائم النشطة')
          : uiTr(context, 'ستُخفى الدولة من القوائم النشطة دون حذف'),
      subject: record.naim,
      confirmLabel: activate ? uiTr(context, 'تفعيل') : uiTr(context, 'تعطيل'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: !activate,
    );
    if (!ok) return;
    try {
      await record.reference.update(createCountriesRecordData(acctev: activate));
      await AdminAuditLog.recordToggle(
        targetType: 'country',
        targetId: record.reference.id,
        targetLabel: record.naim,
        activated: activate,
      );
      await _bootstrap();
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: activate
            ? uiTr(context, 'تم تفعيل الدولة')
            : uiTr(context, 'تم تعطيل الدولة'),
        refreshScope: AdminListScope.countries,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  Future<void> _toggleRegion(CitiesRecord record, bool activate) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: activate ? uiTr(context, 'تفعيل المنطقة') : uiTr(context, 'تعطيل المنطقة'),
      whatHappens: activate
          ? uiTr(context, 'ستظهر المنطقة في القوائم النشطة')
          : uiTr(context, 'ستُخفى المنطقة دون حذف السجل'),
      subject: record.naim,
      confirmLabel: activate ? uiTr(context, 'تفعيل') : uiTr(context, 'تعطيل'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: !activate,
    );
    if (!ok) return;
    try {
      await record.reference.update(createCitiesRecordData(acctev: activate));
      await AdminAuditLog.recordToggle(
        targetType: 'region',
        targetId: record.reference.id,
        targetLabel: record.naim,
        activated: activate,
      );
      await _bootstrap();
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: activate
            ? uiTr(context, 'تم تفعيل المنطقة')
            : uiTr(context, 'تم تعطيل المنطقة'),
        refreshScope: AdminListScope.regions,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  Future<void> _toggleCity(VillagesRecord record, bool activate) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: activate ? uiTr(context, 'تفعيل المدينة') : uiTr(context, 'تعطيل المدينة'),
      whatHappens: activate
          ? uiTr(context, 'ستظهر المدينة في القوائم النشطة')
          : uiTr(context, 'ستُخفى المدينة دون حذف السجل'),
      subject: record.naim,
      confirmLabel: activate ? uiTr(context, 'تفعيل') : uiTr(context, 'تعطيل'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: !activate,
    );
    if (!ok) return;
    try {
      await record.reference.update(createVillagesRecordData(acctev: activate));
      if (!activate) {
        await setCityLandmarksActive(record.reference, false);
      }
      await AdminAuditLog.recordToggle(
        targetType: 'city',
        targetId: record.reference.id,
        targetLabel: record.naim,
        activated: activate,
      );
      await _bootstrap();
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: activate
            ? uiTr(context, 'تم تفعيل المدينة')
            : uiTr(context, 'تم تعطيل المدينة'),
        refreshScope: AdminListScope.cities,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  Future<void> _safeDisableCountry(CountriesRecord record) async {
    final scan = await AdminGeoReferenceScan.scanCountry(record.reference);
    if (!mounted) return;
    if (scan.hasReferences) {
      await showAdminConfirmDialog(
        context: context,
        title: uiTr(context, 'لا يمكن الحذف'),
        whatHappens: uiTr(
          context,
          'هذا العنصر مستخدم في النظام. يمكنك تعطيله فقط.',
        ),
        subject: record.naim,
        impact: scan.arabicSummary,
        confirmLabel: uiTr(context, 'تعطيل بدل الحذف'),
        cancelLabel: appTr(context, 'adm_no'),
        destructive: true,
      ).then((ok) async {
        if (ok) await _toggleCountry(record, false);
      });
      return;
    }
    await _toggleCountry(record, false);
  }

  Future<void> _safeDisableRegion(CitiesRecord record) async {
    final scan = await AdminGeoReferenceScan.scanRegion(record.reference);
    if (!mounted) return;
    if (scan.hasReferences) {
      final ok = await showAdminConfirmDialog(
        context: context,
        title: uiTr(context, 'لا يمكن الحذف'),
        whatHappens: uiTr(
          context,
          'هذا العنصر مستخدم في النظام. يمكنك تعطيله فقط.',
        ),
        subject: record.naim,
        impact: scan.arabicSummary,
        confirmLabel: uiTr(context, 'تعطيل بدل الحذف'),
        cancelLabel: appTr(context, 'adm_no'),
        destructive: true,
      );
      if (ok) await _toggleRegion(record, false);
      return;
    }
    await _toggleRegion(record, false);
  }

  Future<void> _safeDisableCity(VillagesRecord record) async {
    final scan = await AdminGeoReferenceScan.scanCity(record.reference);
    if (!mounted) return;
    if (scan.hasReferences) {
      final ok = await showAdminConfirmDialog(
        context: context,
        title: uiTr(context, 'لا يمكن الحذف'),
        whatHappens: uiTr(
          context,
          'هذا العنصر مستخدم في النظام. يمكنك تعطيله فقط.',
        ),
        subject: record.naim,
        impact: scan.arabicSummary,
        confirmLabel: uiTr(context, 'تعطيل بدل الحذف'),
        cancelLabel: appTr(context, 'adm_no'),
        destructive: true,
      );
      if (ok) await _toggleCity(record, false);
      return;
    }
    await _toggleCity(record, false);
  }
}
