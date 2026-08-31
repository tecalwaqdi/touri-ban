import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_query.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Drivers-only filter bar (does not modify shared AdminOpsFilterBar).
class AdminDriversFilterBar extends StatefulWidget {
  const AdminDriversFilterBar({
    super.key,
    required this.value,
    required this.extra,
    required this.pageSize,
    required this.onChanged,
    required this.onExtraChanged,
    required this.onPageSizeChanged,
  });

  final AdminOpsFilterState value;
  final AdminDriversExtraFilters extra;
  final int pageSize;
  final ValueChanged<AdminOpsFilterState> onChanged;
  final ValueChanged<AdminDriversExtraFilters> onExtraChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  State<AdminDriversFilterBar> createState() => _AdminDriversFilterBarState();
}

class _AdminDriversFilterBarState extends State<AdminDriversFilterBar> {
  late final TextEditingController _searchController;
  List<CountriesRecord> _countries = const [];
  List<CitiesRecord> _regions = const [];
  List<VillagesRecord> _cities = const [];
  List<TypeCarRecord> _vehicles = const [];
  bool _advancedOpen = false;
  bool _loadingGeo = false;

  bool get _lockCountry => AdminRoleService.isCountryAgent;

  int get _activeCount =>
      widget.value.activeFilterCount + widget.extra.activeCount;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.value.searchQuery);
    _loadCountries();
    _loadVehicles();
    final country = widget.value.effectiveCountryRef;
    if (country != null) {
      _loadRegions(country);
      if (widget.value.regionRef != null) {
        _loadCities(widget.value.regionRef!);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AdminDriversFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.searchQuery != widget.value.searchQuery &&
        _searchController.text != widget.value.searchQuery) {
      _searchController.text = widget.value.searchQuery;
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_drivers_search');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    if (_lockCountry) return;
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
    try {
      final docs = await queryCitiesRecordOnce(
        queryBuilder: (q) => q.where('dolh', isEqualTo: country),
        limit: 120,
      );
      if (!mounted) return;
      setState(() => _regions = docs);
    } catch (_) {}
  }

  Future<void> _loadCities(DocumentReference region) async {
    try {
      final docs = await queryVillagesRecordOnce(
        queryBuilder: (q) => q.where('cities', isEqualTo: region),
        limit: 200,
      );
      if (!mounted) return;
      setState(() => _cities = docs);
    } catch (_) {}
  }

  Future<void> _loadVehicles() async {
    try {
      final docs = await queryTypeCarRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() => _vehicles = docs);
    } catch (_) {}
  }

  void _reset() {
    _searchController.clear();
    widget.onChanged(const AdminOpsFilterState());
    widget.onExtraChanged(AdminDriversExtraFilters.empty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: uiTr(
                      context,
                      'بحث بالاسم، الهاتف، البريد، رقم اللوحة...',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) {
                    EasyDebounce.debounce(
                      'admin_drivers_search',
                      const Duration(milliseconds: 320),
                      () => widget.onChanged(
                        widget.value.copyWith(searchQuery: v),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _pageSizeDropdown(theme),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    setState(() => _advancedOpen = !_advancedOpen),
                icon: Icon(
                  _advancedOpen
                      ? Icons.expand_less_rounded
                      : Icons.tune_rounded,
                  size: 18,
                ),
                label: Text(
                  _advancedOpen
                      ? uiTr(context, 'إخفاء الفلاتر المتقدمة')
                      : uiTr(context, 'إظهار الفلاتر المتقدمة'),
                ),
              ),
              if (_activeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminUi.brandTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_activeCount',
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      fontWeight: FontWeight.w800,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text(uiTr(context, 'Reset Filters')),
                ),
              ],
            ],
          ),
          if (_advancedOpen) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _enumDropdown<AdminDriverReviewFilter>(
                  label: uiTr(context, 'حالة التسجيل'),
                  value: widget.value.driverReview,
                  items: const [
                    AdminDriverReviewFilter.all,
                    AdminDriverReviewFilter.pendingReview,
                    AdminDriverReviewFilter.approved,
                    AdminDriverReviewFilter.rejected,
                    AdminDriverReviewFilter.needsChanges,
                    AdminDriverReviewFilter.inactive,
                    AdminDriverReviewFilter.unknownLegacy,
                  ],
                  labelOf: (v) => switch (v) {
                    AdminDriverReviewFilter.all => uiTr(context, 'الكل'),
                    AdminDriverReviewFilter.pendingReview =>
                      uiTr(context, 'بانتظار المراجعة'),
                    AdminDriverReviewFilter.approved =>
                      uiTr(context, 'معتمد'),
                    AdminDriverReviewFilter.rejected =>
                      uiTr(context, 'مرفوض'),
                    AdminDriverReviewFilter.needsChanges =>
                      uiTr(context, 'يحتاج تعديلات'),
                    AdminDriverReviewFilter.inactive =>
                      uiTr(context, 'موقوف'),
                    AdminDriverReviewFilter.unknownLegacy =>
                      uiTr(context, 'حالة غير محددة'),
                  },
                  onChanged: (v) => widget.onChanged(
                    widget.value.copyWith(driverReview: v),
                  ),
                ),
                _enumDropdown<AdminDriverActivationFilter>(
                  label: uiTr(context, 'حالة الحساب'),
                  value: widget.value.driverActivation,
                  items: const [
                    AdminDriverActivationFilter.all,
                    AdminDriverActivationFilter.activated,
                    AdminDriverActivationFilter.deactivated,
                  ],
                  labelOf: (v) => switch (v) {
                    AdminDriverActivationFilter.all => uiTr(context, 'الكل'),
                    AdminDriverActivationFilter.activated =>
                      uiTr(context, 'نشط'),
                    AdminDriverActivationFilter.deactivated =>
                      uiTr(context, 'موقوف'),
                    AdminDriverActivationFilter.unknown =>
                      uiTr(context, 'غير معروف'),
                  },
                  onChanged: (v) => widget.onChanged(
                    widget.value.copyWith(driverActivation: v),
                  ),
                ),
                _enumDropdown<AdminDriversConnectionFilter>(
                  label: uiTr(context, 'حالة الاتصال'),
                  value: widget.extra.connection,
                  items: AdminDriversConnectionFilter.values,
                  labelOf: (v) => switch (v) {
                    AdminDriversConnectionFilter.all => uiTr(context, 'الكل'),
                    AdminDriversConnectionFilter.online => 'Online',
                    AdminDriversConnectionFilter.offline => 'Offline',
                  },
                  onChanged: (v) => widget.onExtraChanged(
                    widget.extra.copyWith(connection: v),
                  ),
                ),
                _enumDropdown<AdminDriversAvailabilityFilter>(
                  label: uiTr(context, 'حالة التشغيل'),
                  value: widget.extra.availability,
                  items: AdminDriversAvailabilityFilter.values,
                  labelOf: (v) => switch (v) {
                    AdminDriversAvailabilityFilter.all =>
                      uiTr(context, 'الكل'),
                    AdminDriversAvailabilityFilter.available =>
                      uiTr(context, 'متاح'),
                    AdminDriversAvailabilityFilter.busy =>
                      uiTr(context, 'مشغول'),
                  },
                  onChanged: (v) => widget.onExtraChanged(
                    widget.extra.copyWith(availability: v),
                  ),
                ),
                if (!_lockCountry)
                  _refDropdown<CountriesRecord>(
                    label: uiTr(context, 'الدولة'),
                    valuePath: widget.value.countryRef?.path,
                    items: _countries,
                    nameOf: (c) => c.naim.isNotEmpty ? c.naim : c.reference.id,
                    refOf: (c) => c.reference,
                    loading: _loadingGeo,
                    onChanged: (ref) {
                      widget.onChanged(
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
                _refDropdown<CitiesRecord>(
                  label: uiTr(context, 'المنطقة'),
                  valuePath: widget.value.regionRef?.path,
                  items: _regions,
                  nameOf: (c) => c.naim.isNotEmpty ? c.naim : c.reference.id,
                  refOf: (c) => c.reference,
                  onChanged: (ref) {
                    widget.onChanged(
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
                _refDropdown<VillagesRecord>(
                  label: uiTr(context, 'المدينة'),
                  valuePath: widget.value.cityRef?.path,
                  items: _cities,
                  nameOf: (c) => c.naim.isNotEmpty ? c.naim : c.reference.id,
                  refOf: (c) => c.reference,
                  onChanged: (ref) => widget.onChanged(
                    widget.value.copyWith(
                      cityRef: ref,
                      clearCity: ref == null,
                    ),
                  ),
                ),
                _refDropdown<TypeCarRecord>(
                  label: uiTr(context, 'تصنيف المركبة'),
                  valuePath: widget.value.vehicleTypeRef?.path,
                  items: _vehicles,
                  nameOf: (c) => c.naim.isNotEmpty ? c.naim : c.reference.id,
                  refOf: (c) => c.reference,
                  onChanged: (ref) => widget.onChanged(
                    widget.value.copyWith(
                      vehicleTypeRef: ref,
                      clearVehicleType: ref == null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pageSizeDropdown(FlutterFlowTheme theme) {
    return SizedBox(
      width: 88,
      child: DropdownButtonFormField<int>(
        value: widget.pageSize,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: uiTr(context, 'الصفحة'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: const [20, 50, 100]
            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
            .toList(),
        onChanged: (v) {
          if (v != null) widget.onPageSizeChanged(v);
        },
      ),
    );
  }

  Widget _enumDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<T>(
        value: value,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e))))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _refDropdown<T>({
    required String label,
    required String? valuePath,
    required List<T> items,
    required String Function(T) nameOf,
    required DocumentReference Function(T) refOf,
    required ValueChanged<DocumentReference?> onChanged,
    bool loading = false,
  }) {
    DocumentReference? selected;
    for (final item in items) {
      if (refOf(item).path == valuePath) {
        selected = refOf(item);
        break;
      }
    }
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<DocumentReference?>(
        value: selected,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: [
          DropdownMenuItem<DocumentReference?>(
            value: null,
            child: Text(uiTr(context, 'الكل')),
          ),
          ...items.map(
            (e) => DropdownMenuItem<DocumentReference?>(
              value: refOf(e),
              child: Text(nameOf(e), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loading ? null : onChanged,
      ),
    );
  }
}
