import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Which filter groups to show on a given ops page.
class AdminOpsFilterConfig {
  const AdminOpsFilterConfig({
    this.showDate = true,
    this.showOrderLifecycle = false,
    this.showDriverActivation = false,
    this.showSupportStatus = false,
    this.showCountry = true,
    this.showRegion = false,
    this.showCity = false,
    this.showSearch = true,
    this.searchHint,
  });

  final bool showDate;
  final bool showOrderLifecycle;
  final bool showDriverActivation;
  final bool showSupportStatus;
  final bool showCountry;
  final bool showRegion;
  final bool showCity;
  final bool showSearch;
  final String? searchHint;
}

/// Unified filter bar — date / status / geo / search.
class AdminOpsFilterBar extends StatefulWidget {
  const AdminOpsFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.config,
  });

  final AdminOpsFilterState value;
  final ValueChanged<AdminOpsFilterState> onChanged;
  final AdminOpsFilterConfig config;

  @override
  State<AdminOpsFilterBar> createState() => _AdminOpsFilterBarState();
}

class _AdminOpsFilterBarState extends State<AdminOpsFilterBar> {
  late final TextEditingController _searchController;
  List<CountriesRecord> _countries = const [];
  List<CitiesRecord> _regions = const [];
  List<VillagesRecord> _cities = const [];
  bool _loadingGeo = false;

  bool get _lockCountry => AdminRoleService.isCountryAgent;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.value.searchQuery);
    _loadCountries();
    if (widget.value.effectiveCountryRef != null) {
      _loadRegions(widget.value.effectiveCountryRef!);
    }
    if (widget.value.regionRef != null) {
      _loadCities(widget.value.regionRef!);
    }
  }

  @override
  void didUpdateWidget(covariant AdminOpsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.searchQuery != widget.value.searchQuery &&
        _searchController.text != widget.value.searchQuery) {
      _searchController.text = widget.value.searchQuery;
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_ops_filter_search');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    if (!widget.config.showCountry || _lockCountry) return;
    setState(() => _loadingGeo = true);
    try {
      final docs = await queryCountriesRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() {
        _countries = docs;
        _loadingGeo = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  Future<void> _loadRegions(DocumentReference country) async {
    if (!widget.config.showRegion) return;
    try {
      final docs = await queryCitiesRecordOnce(
        queryBuilder: (q) => q.where('dolh', isEqualTo: country),
        limit: 120,
      );
      if (!mounted) return;
      setState(() => _regions = docs);
    } catch (_) {
      if (mounted) setState(() => _regions = const []);
    }
  }

  Future<void> _loadCities(DocumentReference region) async {
    if (!widget.config.showCity) return;
    try {
      final docs = await queryVillagesRecordOnce(
        queryBuilder: (q) => q.where('cities', isEqualTo: region),
        limit: 200,
      );
      if (!mounted) return;
      setState(() => _cities = docs);
    } catch (_) {
      // Fallback: cities linked by country only.
      try {
        final country = widget.value.effectiveCountryRef;
        if (country == null) {
          setState(() => _cities = const []);
          return;
        }
        final docs = await queryVillagesRecordOnce(
          queryBuilder: (q) => q.where('dolh', isEqualTo: country),
          limit: 200,
        );
        if (!mounted) return;
        setState(() => _cities = docs);
      } catch (_) {
        if (mounted) setState(() => _cities = const []);
      }
    }
  }

  void _emit(AdminOpsFilterState next) => widget.onChanged(next);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final f = widget.value;
    final cfg = widget.config;

    return AdminContentCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                f.activeFilterCount == 0
                    ? uiTr(context, 'Filters')
                    : '${uiTr(context, 'Filters')} (${f.activeFilterCount})',
                style: theme.titleSmall,
              ),
              const Spacer(),
              if (f.activeFilterCount > 0)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    final base = AdminOpsFilterState.empty.reset();
                    _emit(
                      AdminRoleService.isCountryAgent
                          ? base.copyWith(
                              countryRef: AdminRoleService.scopedCountryRef,
                            )
                          : base,
                    );
                  },
                  child: Text(uiTr(context, 'Reset')),
                ),
            ],
          ),
          if (cfg.showSearch) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: cfg.searchHint ??
                    uiTr(context, 'بحث (اسم / هاتف / معرف)'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: f.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _emit(f.copyWith(searchQuery: ''));
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) {
                EasyDebounce.debounce(
                  'admin_ops_filter_search',
                  const Duration(milliseconds: 350),
                  () => _emit(f.copyWith(searchQuery: v)),
                );
              },
            ),
            Builder(
              builder: (context) {
                final plan = AdminOpsSearch.classify(f.searchQuery);
                final hint = AdminOpsSearch.hintFor(plan);
                if (hint.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    hint,
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.showDate) ...[
            Text(
              uiTr(context, 'الفترة'),
              style: theme.labelMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in AdminDatePreset.values)
                  if (preset != AdminDatePreset.custom)
                    _chip(
                      label: _dateLabel(context, preset),
                      selected: f.datePreset == preset,
                      onTap: () => _emit(
                        f.copyWith(
                          datePreset: preset,
                          clearCustomDates: true,
                        ),
                      ),
                    ),
                _chip(
                  label: uiTr(context, 'مخصص'),
                  selected: f.datePreset == AdminDatePreset.custom,
                  onTap: () => _pickCustomRange(context),
                ),
              ],
            ),
            if (f.datePreset == AdminDatePreset.custom &&
                f.customStart != null &&
                f.customEnd != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_fmtDay(f.customStart!)} → ${_fmtDay(f.customEnd!)}',
                  style: theme.labelSmall,
                ),
              ),
            const SizedBox(height: 10),
          ],
          if (cfg.showOrderLifecycle) ...[
            Text(uiTr(context, 'حالة الحجز'), style: theme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in AdminOrderLifecycleFilter.values)
                  _chip(
                    label: _orderStatusLabel(context, s),
                    selected: f.orderLifecycle == s,
                    onTap: () => _emit(f.copyWith(orderLifecycle: s)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.showDriverActivation) ...[
            Text(uiTr(context, 'حالة التفعيل'), style: theme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in AdminDriverActivationFilter.values)
                  _chip(
                    label: _driverActLabel(context, s),
                    selected: f.driverActivation == s,
                    onTap: () => _emit(f.copyWith(driverActivation: s)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.showSupportStatus) ...[
            Text(uiTr(context, 'حالة التذكرة'), style: theme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in AdminSupportStatusFilter.values)
                  _chip(
                    label: _supportLabel(context, s),
                    selected: f.supportStatus == s,
                    onTap: () => _emit(f.copyWith(supportStatus: s)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.showCountry && !_lockCountry) ...[
            _dropdownCountry(theme),
            const SizedBox(height: 8),
          ],
          if (cfg.showRegion && f.effectiveCountryRef != null) ...[
            _dropdownRegion(theme),
            const SizedBox(height: 8),
          ],
          if (cfg.showCity &&
              (f.regionRef != null || f.effectiveCountryRef != null)) ...[
            _dropdownCity(theme),
            const SizedBox(height: 8),
          ],
          if (_loadingGeo)
            const LinearProgressIndicator(minHeight: 2),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: f.hasActiveFilters
                  ? () {
                      _searchController.clear();
                      setState(() {
                        _regions = const [];
                        _cities = const [];
                      });
                      _emit(f.reset());
                    }
                  : null,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(uiTr(context, 'إعادة ضبط الفلاتر')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownCountry(FlutterFlowTheme theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: uiTr(context, 'الدولة'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentReference?>(
          isExpanded: true,
          value: widget.value.countryRef,
          hint: Text(uiTr(context, 'كل الدول')),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(uiTr(context, 'كل الدول')),
            ),
            ..._countries.map(
              (c) => DropdownMenuItem(
                value: c.reference,
                child: Text(c.naim.isNotEmpty ? c.naim : c.reference.id),
              ),
            ),
          ],
          onChanged: (ref) {
            _emit(
              widget.value.copyWith(
                countryRef: ref,
                clearCountry: ref == null,
                clearRegion: true,
                clearCity: true,
              ),
            );
            setState(() {
              _regions = const [];
              _cities = const [];
            });
            if (ref != null) _loadRegions(ref);
          },
        ),
      ),
    );
  }

  Widget _dropdownRegion(FlutterFlowTheme theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: uiTr(context, 'المنطقة'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentReference?>(
          isExpanded: true,
          value: widget.value.regionRef,
          hint: Text(uiTr(context, 'كل المناطق')),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(uiTr(context, 'كل المناطق')),
            ),
            ..._regions.map(
              (r) => DropdownMenuItem(
                value: r.reference,
                child: Text(r.naim.isNotEmpty ? r.naim : r.reference.id),
              ),
            ),
          ],
          onChanged: (ref) {
            _emit(
              widget.value.copyWith(
                regionRef: ref,
                clearRegion: ref == null,
                clearCity: true,
              ),
            );
            setState(() => _cities = const []);
            if (ref != null) _loadCities(ref);
          },
        ),
      ),
    );
  }

  Widget _dropdownCity(FlutterFlowTheme theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: uiTr(context, 'المدينة'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentReference?>(
          isExpanded: true,
          value: widget.value.cityRef,
          hint: Text(uiTr(context, 'كل المدن')),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(uiTr(context, 'كل المدن')),
            ),
            ..._cities.map(
              (c) => DropdownMenuItem(
                value: c.reference,
                child: Text(c.naim.isNotEmpty ? c.naim : c.reference.id),
              ),
            ),
          ],
          onChanged: (ref) {
            _emit(
              widget.value.copyWith(
                cityRef: ref,
                clearCity: ref == null,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: widget.value.customStart != null &&
              widget.value.customEnd != null
          ? DateTimeRange(
              start: widget.value.customStart!,
              end: widget.value.customEnd!,
            )
          : null,
    );
    if (picked == null) return;
    _emit(
      widget.value.copyWith(
        datePreset: AdminDatePreset.custom,
        customStart: picked.start,
        customEnd: picked.end,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AdminUi.brandTeal.withValues(alpha: 0.25),
      checkmarkColor: AdminUi.brandTeal,
    );
  }

  String _fmtDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateLabel(BuildContext context, AdminDatePreset p) => switch (p) {
        AdminDatePreset.all => uiTr(context, 'الكل'),
        AdminDatePreset.today => uiTr(context, 'اليوم'),
        AdminDatePreset.yesterday => uiTr(context, 'أمس'),
        AdminDatePreset.last7Days => uiTr(context, 'آخر 7 أيام'),
        AdminDatePreset.last30Days => uiTr(context, 'آخر 30 يوم'),
        AdminDatePreset.thisMonth => uiTr(context, 'هذا الشهر'),
        AdminDatePreset.lastMonth => uiTr(context, 'الشهر السابق'),
        AdminDatePreset.thisYear => uiTr(context, 'هذه السنة'),
        AdminDatePreset.custom => uiTr(context, 'مخصص'),
      };

  String _orderStatusLabel(BuildContext context, AdminOrderLifecycleFilter s) =>
      switch (s) {
        AdminOrderLifecycleFilter.all => uiTr(context, 'الكل'),
        AdminOrderLifecycleFilter.pending => uiTr(context, 'قيد الانتظار'),
        AdminOrderLifecycleFilter.active => uiTr(context, 'نشط'),
        AdminOrderLifecycleFilter.completed => uiTr(context, 'مكتمل'),
        AdminOrderLifecycleFilter.cancelled => uiTr(context, 'ملغى'),
        AdminOrderLifecycleFilter.expired => uiTr(context, 'منتهٍ'),
      };

  String _driverActLabel(BuildContext context, AdminDriverActivationFilter s) =>
      switch (s) {
        AdminDriverActivationFilter.all => uiTr(context, 'الكل'),
        AdminDriverActivationFilter.activated => uiTr(context, 'مفعّل'),
        AdminDriverActivationFilter.deactivated => uiTr(context, 'غير مفعّل'),
        AdminDriverActivationFilter.unknown =>
          uiTr(context, 'حالة غير محددة'),
      };

  String _supportLabel(BuildContext context, AdminSupportStatusFilter s) =>
      switch (s) {
        AdminSupportStatusFilter.all => uiTr(context, 'الكل'),
        AdminSupportStatusFilter.open => uiTr(context, 'مفتوحة'),
        AdminSupportStatusFilter.closed => uiTr(context, 'مغلقة'),
        AdminSupportStatusFilter.resolved => uiTr(context, 'تم الحل'),
      };
}
