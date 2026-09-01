import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/finance/admin_finance_date_range.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Which filter groups to show on a given ops page.
class AdminOpsFilterConfig {
  const AdminOpsFilterConfig({
    this.showDate = true,
    this.showOrderLifecycle = false,
    this.showDriverActivation = false,
    this.showDriverReview = false,
    this.showDriverDocuments = false,
    this.showDriverVehicleType = false,
    this.showSupportStatus = false,
    this.showCountry = true,
    this.showRegion = false,
    this.showCity = false,
    this.showSearch = true,
    this.searchHint,

    /// When true, chip/dropdown filters start collapsed so the list stays
    /// above the fold (Drivers / dense ops pages).
    this.collapseAdvancedByDefault = false,
  });

  final bool showDate;
  final bool showOrderLifecycle;
  final bool showDriverActivation;
  final bool showDriverReview;
  final bool showDriverDocuments;
  final bool showDriverVehicleType;
  final bool showSupportStatus;
  final bool showCountry;
  final bool showRegion;
  final bool showCity;
  final bool showSearch;
  final String? searchHint;
  final bool collapseAdvancedByDefault;
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
  List<TypeCarRecord> _vehicleTypes = const [];
  bool _loadingGeo = false;
  late bool _advancedOpen;

  bool get _lockCountry => AdminRoleService.isCountryAgent;

  @override
  void initState() {
    super.initState();
    _advancedOpen = !widget.config.collapseAdvancedByDefault;
    _searchController = TextEditingController(text: widget.value.searchQuery);
    _loadCountries();
    if (widget.config.showDriverVehicleType) {
      _loadVehicleTypes();
    }
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

  Future<void> _loadVehicleTypes() async {
    try {
      final docs = await queryTypeCarRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() => _vehicleTypes = docs);
    } catch (_) {
      if (mounted) setState(() => _vehicleTypes = const []);
    }
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

    return Semantics(
      identifier: 'qa-driver-filter',
      label: 'qa-driver-filter',
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    f.activeFilterCount == 0
                        ? uiTr(context, 'Filters')
                        : '${uiTr(context, 'Filters')} (${f.activeFilterCount})',
                    softWrap: true,
                    style: theme.titleSmall,
                  ),
                ),
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
            if (cfg.collapseAdvancedByDefault)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _advancedOpen = !_advancedOpen),
                  icon: Icon(
                    _advancedOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _advancedOpen
                        ? uiTr(context, 'إخفاء الفلاتر المتقدمة')
                        : uiTr(context, 'إظهار الفلاتر المتقدمة'),
                  ),
                ),
              ),
            if (_advancedOpen) ...[
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
                          qaIdentifier: preset == AdminDatePreset.last30Days
                              ? 'qa-filter-date-last30days'
                              : null,
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
                        qaIdentifier: s == AdminDriverActivationFilter.activated
                            ? 'qa-filter-activation-activated'
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (cfg.showDriverReview) ...[
                Text(uiTr(context, 'حالة المراجعة'), style: theme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in AdminDriverReviewFilter.values)
                      _chip(
                        label: _driverReviewLabel(context, s),
                        selected: f.driverReview == s,
                        onTap: () => _emit(f.copyWith(driverReview: s)),
                        qaIdentifier: s == AdminDriverReviewFilter.pendingReview
                            ? 'qa-filter-review-pending'
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (cfg.showDriverDocuments) ...[
                Text(uiTr(context, 'الوثائق'), style: theme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in AdminDriverDocumentsFilter.values)
                      _chip(
                        label: _driverDocsLabel(context, s),
                        selected: f.driverDocuments == s,
                        onTap: () => _emit(f.copyWith(driverDocuments: s)),
                        qaIdentifier: s == AdminDriverDocumentsFilter.missing
                            ? 'qa-filter-documents-missing'
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (cfg.showDriverVehicleType && _vehicleTypes.isNotEmpty) ...[
                Text(uiTr(context, 'تصنيف السيارة'), style: theme.labelMedium),
                const SizedBox(height: 6),
                Semantics(
                  identifier: 'qa-filter-vehicle-type',
                  label: 'qa-filter-vehicle-type',
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DocumentReference?>(
                        isExpanded: true,
                        value: f.vehicleTypeRef,
                        hint: Text(uiTr(context, 'الكل')),
                        items: [
                          DropdownMenuItem<DocumentReference?>(
                            value: null,
                            child: Text(uiTr(context, 'الكل')),
                          ),
                          for (final t in _vehicleTypes)
                            DropdownMenuItem<DocumentReference?>(
                              value: t.reference,
                              child: Text(
                                t.naim.isNotEmpty ? t.naim : t.reference.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => _emit(
                          v == null
                              ? f.copyWith(clearVehicleType: true)
                              : f.copyWith(vehicleTypeRef: v),
                        ),
                      ),
                    ),
                  ),
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
              if (_loadingGeo) const LinearProgressIndicator(minHeight: 2),
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
                  label: Text(
                    uiTr(context, 'إعادة ضبط الفلاتر'),
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdownCountry(FlutterFlowTheme theme) {
    return Semantics(
      identifier: 'qa-filter-country',
      label: 'qa-filter-country',
      child: InputDecorator(
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
      initialDateRange:
          widget.value.customStart != null && widget.value.customEnd != null
              ? DateTimeRange(
                  start: widget.value.customStart!,
                  end: widget.value.customEnd!,
                )
              : null,
    );
    if (picked == null) return;
    if (AdminFinanceDateRangeResolver.isInvalidCustom(
      customStart: picked.start,
      customEnd: picked.end,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(context, 'نطاق التاريخ غير صالح: تاريخ البداية بعد النهاية'),
          ),
        ),
      );
      return;
    }
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
    String? qaIdentifier,
  }) {
    final chip = FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AdminUi.brandTeal.withValues(alpha: 0.25),
      checkmarkColor: AdminUi.brandTeal,
    );
    if (qaIdentifier == null) return chip;
    return Semantics(
      identifier: qaIdentifier,
      label: qaIdentifier,
      button: true,
      child: chip,
    );
  }

  String _fmtDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateLabel(BuildContext context, AdminDatePreset p) => switch (p) {
        AdminDatePreset.all => uiTr(context, 'الكل'),
        AdminDatePreset.today => uiTr(context, 'اليوم'),
        AdminDatePreset.yesterday => uiTr(context, 'أمس'),
        AdminDatePreset.last7Days => uiTr(context, 'آخر 7 أيام'),
        AdminDatePreset.last30Days => uiTr(context, 'آخر 30 يومًا'),
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
        AdminDriverActivationFilter.unknown => uiTr(context, 'حالة غير محددة'),
      };

  String _driverReviewLabel(BuildContext context, AdminDriverReviewFilter s) =>
      switch (s) {
        AdminDriverReviewFilter.all => uiTr(context, 'الكل'),
        AdminDriverReviewFilter.pendingReview => uiTr(context, 'تحت المراجعة'),
        AdminDriverReviewFilter.approved => uiTr(context, 'معتمد'),
        AdminDriverReviewFilter.rejected => uiTr(context, 'مرفوض'),
        AdminDriverReviewFilter.needsChanges => uiTr(context, 'يحتاج استكمال'),
        AdminDriverReviewFilter.inactive => uiTr(context, 'غير مفعّل'),
        AdminDriverReviewFilter.unknownLegacy =>
          uiTr(context, 'حالة غير محددة'),
      };

  String _driverDocsLabel(BuildContext context, AdminDriverDocumentsFilter s) =>
      switch (s) {
        AdminDriverDocumentsFilter.all => uiTr(context, 'الكل'),
        AdminDriverDocumentsFilter.complete => uiTr(context, 'وثائق مكتملة'),
        AdminDriverDocumentsFilter.missing => uiTr(context, 'وثائق ناقصة'),
        AdminDriverDocumentsFilter.needsReupload =>
          uiTr(context, 'تحتاج إعادة رفع'),
        AdminDriverDocumentsFilter.unknownLegacy =>
          uiTr(context, 'وثائق غير محددة (قديم)'),
      };

  String _supportLabel(BuildContext context, AdminSupportStatusFilter s) =>
      switch (s) {
        AdminSupportStatusFilter.all => uiTr(context, 'الكل'),
        AdminSupportStatusFilter.open => uiTr(context, 'مفتوحة'),
        AdminSupportStatusFilter.closed => uiTr(context, 'مغلقة'),
        AdminSupportStatusFilter.resolved => uiTr(context, 'تم الحل'),
      };
}
