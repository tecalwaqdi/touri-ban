import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/admin/adminuser/admin_customers_adapter.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminCustomersFilterBar extends StatefulWidget {
  const AdminCustomersFilterBar({
    super.key,
    required this.value,
    required this.extra,
    required this.pageSize,
    required this.onChanged,
    required this.onExtraChanged,
    required this.onPageSizeChanged,
  });

  final AdminOpsFilterState value;
  final AdminCustomerExtraFilters extra;
  final int pageSize;
  final ValueChanged<AdminOpsFilterState> onChanged;
  final ValueChanged<AdminCustomerExtraFilters> onExtraChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  State<AdminCustomersFilterBar> createState() =>
      _AdminCustomersFilterBarState();
}

class _AdminCustomersFilterBarState extends State<AdminCustomersFilterBar> {
  late final TextEditingController _searchController;
  List<CountriesRecord> _countries = const [];
  bool _advancedOpen = false;

  bool get _lockCountry => AdminRoleService.isCountryAgent;

  int get _activeCount =>
      widget.value.activeFilterCount + widget.extra.activeCount;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.value.searchQuery);
    _loadCountries();
  }

  @override
  void didUpdateWidget(covariant AdminCustomersFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.searchQuery != widget.value.searchQuery &&
        _searchController.text != widget.value.searchQuery) {
      _searchController.text = widget.value.searchQuery;
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_customers_search');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    if (_lockCountry) return;
    try {
      final docs = await queryCountriesRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() => _countries = docs);
    } catch (_) {}
  }

  void _emit(AdminOpsFilterState next) => widget.onChanged(next);

  void _reset() {
    _searchController.clear();
    widget.onChanged(const AdminOpsFilterState());
    widget.onExtraChanged(AdminCustomerExtraFilters.empty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: theme.bodySmall,
                    onChanged: (v) {
                      EasyDebounce.debounce(
                        'admin_customers_search',
                        const Duration(milliseconds: 320),
                        () => _emit(widget.value.copyWith(searchQuery: v)),
                      );
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: uiTr(
                        context,
                        'بحث بالاسم، البريد الإلكتروني أو رقم الهاتف...',
                      ),
                      hintStyle: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: theme.secondaryText,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      filled: true,
                      fillColor: theme.primaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.alternate.withValues(alpha: 0.7),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.alternate.withValues(alpha: 0.7),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AdminUi.brandTeal.withValues(alpha: 0.6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                context,
                tooltip: uiTr(context, 'فلاتر'),
                onPressed: () => setState(() => _advancedOpen = !_advancedOpen),
                icon: _advancedOpen
                    ? Icons.tune_rounded
                    : Icons.tune_outlined,
                badge: _activeCount > 0 ? '$_activeCount' : null,
              ),
              _pageSizeChip(theme),
              if (_activeCount > 0)
                TextButton(
                  onPressed: _reset,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    uiTr(context, 'إعادة'),
                    style: theme.labelSmall,
                  ),
                ),
            ],
          ),
          if (_advancedOpen) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (!_lockCountry)
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String?>(
                      value: widget.value.countryRef?.id,
                      isExpanded: true,
                      isDense: true,
                      style: theme.bodySmall,
                      decoration: _dec(uiTr(context, 'الدولة')),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            uiTr(context, 'كل الدول'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._countries.map(
                          (c) => DropdownMenuItem(
                            value: c.reference.id,
                            child: Text(
                              c.naim.isNotEmpty ? c.naim : c.reference.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (id) {
                        if (id == null) {
                          _emit(widget.value.copyWith(clearCountry: true));
                          return;
                        }
                        CountriesRecord? match;
                        for (final c in _countries) {
                          if (c.reference.id == id) {
                            match = c;
                            break;
                          }
                        }
                        if (match != null) {
                          _emit(
                            widget.value.copyWith(countryRef: match.reference),
                          );
                        }
                      },
                    ),
                  ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<AdminDatePreset>(
                    value: widget.value.datePreset,
                    isExpanded: true,
                    isDense: true,
                    style: theme.bodySmall,
                    decoration: _dec(uiTr(context, 'التسجيل')),
                    items: [
                      for (final p in [
                        AdminDatePreset.all,
                        AdminDatePreset.today,
                        AdminDatePreset.last7Days,
                        AdminDatePreset.last30Days,
                        AdminDatePreset.thisMonth,
                      ])
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                            _dateLabel(context, p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (p) {
                      if (p == null) return;
                      _emit(widget.value.copyWith(datePreset: p));
                    },
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<AdminCustomerAccountFilter>(
                    value: widget.extra.account,
                    isExpanded: true,
                    isDense: true,
                    style: theme.bodySmall,
                    decoration: _dec(uiTr(context, 'الحساب')),
                    items: [
                      DropdownMenuItem(
                        value: AdminCustomerAccountFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerAccountFilter.active,
                        child: Text(uiTr(context, 'نشط')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerAccountFilter.suspended,
                        child: Text(uiTr(context, 'موقوف')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerAccountFilter.unknown,
                        child: Text(uiTr(context, 'غير محدد')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(account: v));
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<AdminCustomerTripFilter>(
                    value: widget.extra.trip,
                    isExpanded: true,
                    isDense: true,
                    style: theme.bodySmall,
                    decoration: _dec(uiTr(context, 'الرحلة')),
                    items: [
                      DropdownMenuItem(
                        value: AdminCustomerTripFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerTripFilter.hasLiveTrip,
                        child: Text(uiTr(context, 'رحلة حالية')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerTripFilter.noLiveTrip,
                        child: Text(uiTr(context, 'بدون رحلة')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(trip: v));
                    },
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<AdminCustomerBookingsFilter>(
                    value: widget.extra.bookings,
                    isExpanded: true,
                    isDense: true,
                    style: theme.bodySmall,
                    decoration: _dec(uiTr(context, 'الحجوزات')),
                    items: [
                      DropdownMenuItem(
                        value: AdminCustomerBookingsFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerBookingsFilter.withBookings,
                        child: Text(uiTr(context, 'لديه حجوزات')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerBookingsFilter.withoutBookings,
                        child: Text(uiTr(context, 'بدون حجوزات')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(bookings: v));
                    },
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<AdminCustomerSort>(
                    value: widget.extra.sort,
                    isExpanded: true,
                    isDense: true,
                    style: theme.bodySmall,
                    decoration: _dec(uiTr(context, 'الترتيب')),
                    items: [
                      DropdownMenuItem(
                        value: AdminCustomerSort.newest,
                        child: Text(uiTr(context, 'الأحدث')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerSort.nameAsc,
                        child: Text(uiTr(context, 'الاسم')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerSort.lastActivity,
                        child: Text(uiTr(context, 'آخر نشاط')),
                      ),
                      DropdownMenuItem(
                        value: AdminCustomerSort.bookings,
                        child: Text(uiTr(context, 'الرحلات')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(sort: v));
                    },
                  ),
                ),
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    uiTr(context, 'جدد اليوم'),
                    style: theme.labelSmall,
                  ),
                  selected: widget.extra.newTodayOnly,
                  onSelected: (v) => widget.onExtraChanged(
                    widget.extra.copyWith(newTodayOnly: v),
                  ),
                ),
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    uiTr(context, 'جدد الشهر'),
                    style: theme.labelSmall,
                  ),
                  selected: widget.extra.newThisMonthOnly,
                  onSelected: (v) => widget.onExtraChanged(
                    widget.extra.copyWith(newThisMonthOnly: v),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
    String? badge,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: badge != null,
        label: Text(badge ?? ''),
        child: Icon(icon, size: 20, color: AdminUi.brandTeal),
      ),
    );
  }

  Widget _pageSizeChip(FlutterFlowTheme theme) {
    return PopupMenuButton<int>(
      tooltip: uiTr(context, 'عدد الصفوف'),
      initialValue: widget.pageSize,
      onSelected: widget.onPageSizeChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_list_rounded, size: 18, color: theme.secondaryText),
            const SizedBox(width: 2),
            Text('${widget.pageSize}', style: theme.labelSmall),
          ],
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 20, child: Text('20')),
        PopupMenuItem(value: 50, child: Text('50')),
        PopupMenuItem(value: 100, child: Text('100')),
      ],
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      );

  String _dateLabel(BuildContext context, AdminDatePreset p) => switch (p) {
        AdminDatePreset.all => uiTr(context, 'كل التواريخ'),
        AdminDatePreset.today => uiTr(context, 'اليوم'),
        AdminDatePreset.last7Days => uiTr(context, '7 أيام'),
        AdminDatePreset.last30Days => uiTr(context, '30 يوم'),
        AdminDatePreset.thisMonth => uiTr(context, 'هذا الشهر'),
        _ => p.name,
      };
}
