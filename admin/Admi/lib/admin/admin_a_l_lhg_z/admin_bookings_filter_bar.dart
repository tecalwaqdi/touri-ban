import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact bookings-only filter bar (does not modify shared AdminOpsFilterBar).
class AdminBookingsFilterBar extends StatefulWidget {
  const AdminBookingsFilterBar({
    super.key,
    required this.value,
    required this.extra,
    required this.sortKey,
    required this.pageSize,
    required this.onChanged,
    required this.onExtraChanged,
    required this.onSortChanged,
    required this.onPageSizeChanged,
  });

  final AdminOpsFilterState value;
  final AdminBookingsExtraFilters extra;
  final AdminBookingsSortKey sortKey;
  final int pageSize;
  final ValueChanged<AdminOpsFilterState> onChanged;
  final ValueChanged<AdminBookingsExtraFilters> onExtraChanged;
  final ValueChanged<AdminBookingsSortKey> onSortChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  State<AdminBookingsFilterBar> createState() => _AdminBookingsFilterBarState();
}

class _AdminBookingsFilterBarState extends State<AdminBookingsFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _customerController;
  late final TextEditingController _driverController;
  late final TextEditingController _amountMinController;
  late final TextEditingController _amountMaxController;

  List<CountriesRecord> _countries = const [];
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
    _customerController =
        TextEditingController(text: widget.extra.customerQuery);
    _driverController = TextEditingController(text: widget.extra.driverQuery);
    _amountMinController = TextEditingController(
      text: widget.extra.amountMin?.toString() ?? '',
    );
    _amountMaxController = TextEditingController(
      text: widget.extra.amountMax?.toString() ?? '',
    );
    _loadCountries();
    _loadVehicles();
    final country = widget.value.effectiveCountryRef;
    if (country != null) _loadCities(country);
  }

  @override
  void didUpdateWidget(covariant AdminBookingsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.searchQuery != widget.value.searchQuery &&
        _searchController.text != widget.value.searchQuery) {
      _searchController.text = widget.value.searchQuery;
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_bookings_search');
    EasyDebounce.cancel('admin_bookings_customer');
    EasyDebounce.cancel('admin_bookings_driver');
    EasyDebounce.cancel('admin_bookings_amount');
    _searchController.dispose();
    _customerController.dispose();
    _driverController.dispose();
    _amountMinController.dispose();
    _amountMaxController.dispose();
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

  Future<void> _loadCities(DocumentReference country) async {
    try {
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

  Future<void> _loadVehicles() async {
    try {
      final docs = await queryTypeCarRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() => _vehicles = docs);
    } catch (_) {
      if (mounted) setState(() => _vehicles = const []);
    }
  }

  void _emit(AdminOpsFilterState next) => widget.onChanged(next);

  void _resetAll() {
    _searchController.clear();
    _customerController.clear();
    _driverController.clear();
    _amountMinController.clear();
    _amountMaxController.clear();
    final base = const AdminOpsFilterState();
    _emit(
      AdminRoleService.isCountryAgent
          ? base.copyWith(countryRef: AdminRoleService.scopedCountryRef)
          : base,
    );
    widget.onExtraChanged(AdminBookingsExtraFilters.empty);
    widget.onSortChanged(AdminBookingsSortKey.dateDesc);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final f = widget.value;
    final searchPlan = AdminOpsSearch.classify(f.searchQuery);

    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _activeCount == 0
                      ? uiTr(context, 'الفلاتر')
                      : '${uiTr(context, 'الفلاتر')} ($_activeCount)',
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _advancedOpen = !_advancedOpen),
                child: Text(
                  _advancedOpen
                      ? uiTr(context, 'إخفاء المتقدمة')
                      : uiTr(context, 'متقدمة'),
                ),
              ),
              if (_activeCount > 0)
                TextButton(
                  onPressed: _resetAll,
                  child: Text(uiTr(context, 'إعادة ضبط')),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 1: search + date + status + geo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: uiTr(
                      context,
                      'رقم الحجز / العميل / المندوب / الجوال',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: f.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _emit(f.copyWith(searchQuery: ''));
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) {
                    EasyDebounce.debounce(
                      'admin_bookings_search',
                      const Duration(milliseconds: 350),
                      () => _emit(f.copyWith(searchQuery: v)),
                    );
                  },
                ),
              ),
              _dropdown<AdminDatePreset>(
                context,
                width: 140,
                value: f.datePreset,
                label: uiTr(context, 'الفترة'),
                items: const [
                  AdminDatePreset.all,
                  AdminDatePreset.today,
                  AdminDatePreset.yesterday,
                  AdminDatePreset.last7Days,
                  AdminDatePreset.last30Days,
                  AdminDatePreset.thisMonth,
                  AdminDatePreset.custom,
                ],
                itemLabel: _dateLabel,
                onChanged: (v) {
                  if (v == null) return;
                  if (v == AdminDatePreset.custom) {
                    _pickCustomRange(f);
                  } else {
                    _emit(
                      f.copyWith(datePreset: v, clearCustomDates: true),
                    );
                  }
                },
              ),
              _dropdown<AdminOrderLifecycleFilter>(
                context,
                width: 160,
                value: f.orderLifecycle,
                label: uiTr(context, 'الحالة'),
                items: AdminOrderLifecycleFilter.values,
                itemLabel: _lifecycleLabel,
                onChanged: (v) {
                  if (v == null) return;
                  _emit(f.copyWith(orderLifecycle: v));
                },
              ),
              if (!_lockCountry)
                _dropdown<DocumentReference?>(
                  context,
                  width: 150,
                  value: f.countryRef,
                  label: uiTr(context, 'الدولة'),
                  items: [null, ..._countries.map((c) => c.reference)],
                  itemLabel: (ref) {
                    if (ref == null) return uiTr(context, 'الكل');
                    final match = _countries
                        .where((c) => c.reference.path == ref.path)
                        .toList();
                    return match.isEmpty ? ref.id : match.first.naim;
                  },
                  onChanged: (ref) {
                    _emit(
                      f.copyWith(
                        countryRef: ref,
                        clearCountry: ref == null,
                        clearCity: true,
                      ),
                    );
                    if (ref != null) {
                      _loadCities(ref);
                    } else {
                      setState(() => _cities = const []);
                    }
                  },
                )
              else if (_loadingGeo)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (f.effectiveCountryRef != null)
                _dropdown<DocumentReference?>(
                  context,
                  width: 150,
                  value: f.cityRef,
                  label: uiTr(context, 'المدينة'),
                  items: [null, ..._cities.map((c) => c.reference)],
                  itemLabel: (ref) {
                    if (ref == null) return uiTr(context, 'الكل');
                    final match = _cities
                        .where((c) => c.reference.path == ref.path)
                        .toList();
                    return match.isEmpty ? ref.id : match.first.naim;
                  },
                  onChanged: (ref) {
                    _emit(
                      f.copyWith(
                        cityRef: ref,
                        clearCity: ref == null,
                      ),
                    );
                  },
                ),
              _dropdown<AdminBookingsSortKey>(
                context,
                width: 150,
                value: widget.sortKey,
                label: uiTr(context, 'الترتيب'),
                items: AdminBookingsSortKey.values,
                itemLabel: _sortLabel,
                onChanged: (v) {
                  if (v != null) widget.onSortChanged(v);
                },
              ),
              _dropdown<int>(
                context,
                width: 110,
                value: widget.pageSize,
                label: uiTr(context, 'الصفحة'),
                items: const [20, 50, 100],
                itemLabel: (n) => '$n',
                onChanged: (v) {
                  if (v != null) widget.onPageSizeChanged(v);
                },
              ),
            ],
          ),
          if (searchPlan.userMessageKey != null &&
              f.searchQuery.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              AdminOpsSearch.hintFor(searchPlan),
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ],
          if (_advancedOpen) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.alternate),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _customerController,
                    decoration: _denseDecoration(
                      context,
                      uiTr(context, 'العميل'),
                    ),
                    onChanged: (v) {
                      EasyDebounce.debounce(
                        'admin_bookings_customer',
                        const Duration(milliseconds: 300),
                        () => widget.onExtraChanged(
                          widget.extra.copyWith(customerQuery: v),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _driverController,
                    decoration: _denseDecoration(
                      context,
                      uiTr(context, 'المندوب'),
                    ),
                    onChanged: (v) {
                      EasyDebounce.debounce(
                        'admin_bookings_driver',
                        const Duration(milliseconds: 300),
                        () => widget.onExtraChanged(
                          widget.extra.copyWith(driverQuery: v),
                        ),
                      );
                    },
                  ),
                ),
                _dropdown<PaymentMethod?>(
                  context,
                  width: 140,
                  value: widget.extra.paymentMethod,
                  label: uiTr(context, 'الدفع'),
                  items: const [
                    null,
                    PaymentMethod.Cash,
                    PaymentMethod.OnlinePayment,
                  ],
                  itemLabel: (m) {
                    if (m == null) return uiTr(context, 'الكل');
                    if (m == PaymentMethod.Cash) {
                      return uiTr(context, 'نقداً');
                    }
                    return uiTr(context, 'إلكتروني');
                  },
                  onChanged: (m) {
                    widget.onExtraChanged(
                      widget.extra.copyWith(
                        paymentMethod: m,
                        clearPayment: m == null,
                      ),
                    );
                  },
                ),
                _dropdown<DocumentReference?>(
                  context,
                  width: 160,
                  value: widget.extra.vehicleTypeRef,
                  label: uiTr(context, 'المركبة'),
                  items: [null, ..._vehicles.map((v) => v.reference)],
                  itemLabel: (ref) {
                    if (ref == null) return uiTr(context, 'الكل');
                    final match = _vehicles
                        .where((v) => v.reference.path == ref.path)
                        .toList();
                    return match.isEmpty ? ref.id : match.first.naim;
                  },
                  onChanged: (ref) {
                    widget.onExtraChanged(
                      widget.extra.copyWith(
                        vehicleTypeRef: ref,
                        clearVehicle: ref == null,
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _amountMinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _denseDecoration(
                      context,
                      uiTr(context, 'من مبلغ'),
                    ),
                    onChanged: (_) => _emitAmount(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _amountMaxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _denseDecoration(
                      context,
                      uiTr(context, 'إلى مبلغ'),
                    ),
                    onChanged: (_) => _emitAmount(),
                  ),
                ),
              ],
            ),
            if (widget.extra.hasAny) ...[
              const SizedBox(height: 6),
              Text(
                uiTr(
                  context,
                  'الفلاتر المتقدمة تُطبَّق على الصفحة المحمّلة',
                ),
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _emitAmount() {
    EasyDebounce.debounce(
      'admin_bookings_amount',
      const Duration(milliseconds: 400),
      () {
        final minV = double.tryParse(_amountMinController.text.trim());
        final maxV = double.tryParse(_amountMaxController.text.trim());
        widget.onExtraChanged(
          AdminBookingsExtraFilters(
            customerQuery: widget.extra.customerQuery,
            driverQuery: widget.extra.driverQuery,
            paymentMethod: widget.extra.paymentMethod,
            vehicleTypeRef: widget.extra.vehicleTypeRef,
            amountMin: minV,
            amountMax: maxV,
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRange(AdminOpsFilterState f) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: f.customStart != null && f.customEnd != null
          ? DateTimeRange(start: f.customStart!, end: f.customEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
    );
    if (range == null) return;
    _emit(
      f.copyWith(
        datePreset: AdminDatePreset.custom,
        customStart: range.start,
        customEnd: range.end,
      ),
    );
  }

  String _dateLabel(AdminDatePreset p) {
    switch (p) {
      case AdminDatePreset.all:
        return uiTr(context, 'كل الفترات');
      case AdminDatePreset.today:
        return uiTr(context, 'اليوم');
      case AdminDatePreset.yesterday:
        return uiTr(context, 'أمس');
      case AdminDatePreset.last7Days:
        return uiTr(context, '7 أيام');
      case AdminDatePreset.last30Days:
        return uiTr(context, '30 يوم');
      case AdminDatePreset.thisMonth:
        return uiTr(context, 'هذا الشهر');
      case AdminDatePreset.lastMonth:
        return uiTr(context, 'الشهر السابق');
      case AdminDatePreset.thisYear:
        return uiTr(context, 'هذه السنة');
      case AdminDatePreset.custom:
        return uiTr(context, 'مخصص');
    }
  }

  String _lifecycleLabel(AdminOrderLifecycleFilter v) {
    switch (v) {
      case AdminOrderLifecycleFilter.all:
        return uiTr(context, 'كل الحالات');
      case AdminOrderLifecycleFilter.pending:
        return uiTr(context, 'بانتظار قبول مندوب');
      case AdminOrderLifecycleFilter.active:
        return uiTr(context, 'الحالية');
      case AdminOrderLifecycleFilter.completed:
        return uiTr(context, 'مكتملة');
      case AdminOrderLifecycleFilter.cancelled:
        return uiTr(context, 'ملغية');
      case AdminOrderLifecycleFilter.expired:
        return uiTr(context, 'منتهية الصلاحية');
    }
  }

  String _sortLabel(AdminBookingsSortKey k) {
    switch (k) {
      case AdminBookingsSortKey.dateDesc:
        return uiTr(context, 'الأحدث');
      case AdminBookingsSortKey.dateAsc:
        return uiTr(context, 'الأقدم');
      case AdminBookingsSortKey.amountDesc:
        return uiTr(context, 'المبلغ ↓');
      case AdminBookingsSortKey.amountAsc:
        return uiTr(context, 'المبلغ ↑');
      case AdminBookingsSortKey.status:
        return uiTr(context, 'الحالة');
      case AdminBookingsSortKey.orderId:
        return uiTr(context, 'رقم الحجز');
    }
  }

  InputDecoration _denseDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _dropdown<T>(
    BuildContext context, {
    required double width,
    required T value,
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: _denseDecoration(context, label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            isDense: true,
            value: items.contains(value) ? value : items.first,
            items: items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      itemLabel(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
