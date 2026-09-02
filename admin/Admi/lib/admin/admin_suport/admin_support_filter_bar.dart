import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/admin/admin_suport/admin_support_adapter.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminSupportFilterBar extends StatefulWidget {
  const AdminSupportFilterBar({
    super.key,
    required this.value,
    required this.extra,
    required this.pageSize,
    required this.onChanged,
    required this.onExtraChanged,
    required this.onPageSizeChanged,
  });

  final AdminOpsFilterState value;
  final AdminSupportExtraFilters extra;
  final int pageSize;
  final ValueChanged<AdminOpsFilterState> onChanged;
  final ValueChanged<AdminSupportExtraFilters> onExtraChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  State<AdminSupportFilterBar> createState() => _AdminSupportFilterBarState();
}

class _AdminSupportFilterBarState extends State<AdminSupportFilterBar> {
  List<CountriesRecord> _countries = const [];
  bool _advancedOpen = false;
  int _searchResetGen = 0;

  bool get _lockCountry => AdminRoleService.isCountryAgent;

  int get _activeCount =>
      widget.value.activeFilterCount + widget.extra.activeCount;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    EasyDebounce.cancel('admin_support_search');
    super.dispose();
  }

  Future<void> _loadCountries() async {
    if (_lockCountry) return;
    try {
      final docs = await queryCountriesRecordOnce(limit: 80);
      if (!mounted) return;
      setState(() => _countries = docs);
    } catch (e, st) {
      AdminUi.logDiagnostic('support_filter_countries', e, st);
    }
  }

  void _reset() {
    setState(() => _searchResetGen++);
    widget.onChanged(const AdminOpsFilterState());
    widget.onExtraChanged(AdminSupportExtraFilters.empty);
  }

  Widget _pageSizeDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: widget.pageSize,
        items: const [
          DropdownMenuItem(value: 20, child: Text('20')),
          DropdownMenuItem(value: 50, child: Text('50')),
          DropdownMenuItem(value: 100, child: Text('100')),
        ],
        onChanged: (v) {
          if (v != null) widget.onPageSizeChanged(v);
        },
      ),
    );
  }

  Widget _searchField() {
    return AdminSearchField(
      key: ValueKey('support_search_$_searchResetGen'),
      debounceTag: 'admin_support_search',
      hint: uiTr(
        context,
        'بحث برقم التذكرة / الاسم / الهاتف / الحجز',
      ),
      helperText: uiTr(
        context,
        'بحث الصفحة الحالية؛ رقم التذكرة الكامل (4+) يبحث عالمياً',
      ),
      initialValue: widget.value.searchQuery,
      onChanged: (v) => widget.onChanged(widget.value.copyWith(searchQuery: v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stacked = AdminUi.useStackedHeader(context);

    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked) ...[
            _searchField(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _pageSizeDropdown()),
                IconButton(
                  onPressed: () =>
                      setState(() => _advancedOpen = !_advancedOpen),
                  icon: Badge(
                    isLabelVisible: _activeCount > 0,
                    label: Text('$_activeCount'),
                    child: Icon(
                      _advancedOpen
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      color: AdminUi.brandTeal,
                    ),
                  ),
                ),
                if (_activeCount > 0)
                  TextButton(
                    onPressed: _reset,
                    child: Text(uiTr(context, 'إعادة تعيين')),
                  ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 8),
                _pageSizeDropdown(),
                IconButton(
                  onPressed: () =>
                      setState(() => _advancedOpen = !_advancedOpen),
                  icon: Badge(
                    isLabelVisible: _activeCount > 0,
                    label: Text('$_activeCount'),
                    child: Icon(
                      _advancedOpen
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      color: AdminUi.brandTeal,
                    ),
                  ),
                ),
                if (_activeCount > 0)
                  TextButton(
                    onPressed: _reset,
                    child: Text(uiTr(context, 'إعادة تعيين')),
                  ),
              ],
            ),
          if (_advancedOpen) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!_lockCountry)
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String?>(
                      initialValue: widget.value.countryRef?.id,
                      isExpanded: true,
                      decoration: _dec(uiTr(context, 'الدولة')),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(uiTr(context, 'كل الدول')),
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
                          widget.onChanged(
                            widget.value.copyWith(clearCountry: true),
                          );
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
                          widget.onChanged(
                            widget.value.copyWith(countryRef: match.reference),
                          );
                        }
                      },
                    ),
                  ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<AdminDatePreset>(
                    initialValue: widget.value.datePreset,
                    isExpanded: true,
                    decoration: _dec(uiTr(context, 'التاريخ')),
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
                          child: Text(_dateLabel(context, p)),
                        ),
                    ],
                    onChanged: (p) {
                      if (p == null) return;
                      widget.onChanged(widget.value.copyWith(datePreset: p));
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child:
                      DropdownButtonFormField<AdminSupportTicketStatusFilter>(
                    initialValue: widget.extra.status,
                    isExpanded: true,
                    decoration: _dec(uiTr(context, 'الحالة')),
                    items: [
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.open,
                        child: Text(uiTr(context, 'مفتوحة')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.inProgress,
                        child: Text(uiTr(context, 'قيد المعالجة')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.waitingUser,
                        child: Text(uiTr(context, 'بانتظار العميل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.resolved,
                        child: Text(uiTr(context, 'تم الحل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportTicketStatusFilter.closed,
                        child: Text(uiTr(context, 'مغلقة')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(status: v));
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<AdminSupportOwnerFilter>(
                    initialValue: widget.extra.owner,
                    isExpanded: true,
                    decoration: _dec(uiTr(context, 'نوع المستخدم')),
                    items: [
                      DropdownMenuItem(
                        value: AdminSupportOwnerFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportOwnerFilter.customer,
                        child: Text(uiTr(context, 'عميل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportOwnerFilter.driver,
                        child: Text(uiTr(context, 'مندوب')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(owner: v));
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<AdminSupportOrderLinkFilter>(
                    initialValue: widget.extra.orderLink,
                    isExpanded: true,
                    decoration: _dec(uiTr(context, 'الحجز')),
                    items: [
                      DropdownMenuItem(
                        value: AdminSupportOrderLinkFilter.all,
                        child: Text(uiTr(context, 'الكل')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportOrderLinkFilter.linked,
                        child: Text(uiTr(context, 'مرتبط بحجز')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportOrderLinkFilter.notLinked,
                        child: Text(uiTr(context, 'بدون حجز')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(
                        widget.extra.copyWith(orderLink: v),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<AdminSupportSort>(
                    initialValue: widget.extra.sort,
                    isExpanded: true,
                    decoration: _dec(uiTr(context, 'الترتيب')),
                    items: [
                      DropdownMenuItem(
                        value: AdminSupportSort.newest,
                        child: Text(uiTr(context, 'الأحدث')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportSort.updated,
                        child: Text(uiTr(context, 'آخر تحديث')),
                      ),
                      DropdownMenuItem(
                        value: AdminSupportSort.oldest,
                        child: Text(uiTr(context, 'الأقدم')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onExtraChanged(widget.extra.copyWith(sort: v));
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        isDense: true,
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  String _dateLabel(BuildContext context, AdminDatePreset p) => switch (p) {
        AdminDatePreset.all => uiTr(context, 'كل التواريخ'),
        AdminDatePreset.today => uiTr(context, 'اليوم'),
        AdminDatePreset.last7Days => uiTr(context, 'آخر 7 أيام'),
        AdminDatePreset.last30Days => uiTr(context, 'آخر 30 يوم'),
        AdminDatePreset.thisMonth => uiTr(context, 'هذا الشهر'),
        _ => p.name,
      };
}
