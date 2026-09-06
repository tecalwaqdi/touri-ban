import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/backend/admin_settlements_query.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/admin_qa_fixture.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_settlements_model.dart';
export 'admin_settlements_model.dart';

class AdminSettlementsWidget extends StatefulWidget {
  const AdminSettlementsWidget({super.key});

  static const String routeName = 'AdminSettlements';
  static const String routePath = '/adminSettlements';

  @override
  State<AdminSettlementsWidget> createState() => _AdminSettlementsWidgetState();
}

class _AdminSettlementsWidgetState extends State<AdminSettlementsWidget> {
  late AdminSettlementsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  /// null = all open-ish; settled/voided filtered via chips.
  String? _statusFilter;
  /// Super Admin only — show QA/test settlements under diagnostics.
  bool _showQaDiagnostics = false;

  /// PERF-P1: chip/setState rebuilds must not recreate Firestore snapshots.
  final AdminSettlementsStreamOwner _settlementsStream =
      AdminSettlementsStreamOwner();

  /// PERF-P2A: older one-shot pages (not live listeners).
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _olderDocs = [];
  DocumentSnapshot<Map<String, dynamic>>? _liveLastDoc;
  bool _loadingMore = false;
  bool _hasMoreOlder = true;

  /// Period summary (bounded maps) — not first-page-only totals.
  List<Map<String, dynamic>>? _periodMaps;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSettlementsModel());
    _reloadPeriodSummary();
  }

  @override
  void dispose() {
    _settlementsStream.dispose();
    _model.dispose();
    super.dispose();
  }

  void _reloadPeriodSummary() {
    AccountantFinanceLoader.loadSettlementsMaps().then((m) {
      if (mounted) setState(() => _periodMaps = m);
    });
  }

  Future<void> _loadMoreOlder() async {
    if (_loadingMore || !_hasMoreOlder || _liveLastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final snap = await AdminSettlementsQuery.fetchPageAfter(_liveLastDoc!);
      if (snap.docs.isEmpty) {
        _hasMoreOlder = false;
      } else {
        _olderDocs.addAll(snap.docs);
        _liveLastDoc = snap.docs.last;
        if (snap.docs.length < AdminSettlementsQuery.pageLimit) {
          _hasMoreOlder = false;
        }
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التسويات'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'التسويات'), style: AccountantFinanceText.pageTitle(theme)),
          const SizedBox(height: 4),
          Text(
            uiTr(context, 'المستحق والمدفوع والمتبقي لكل تسوية.'),
            style: AccountantFinanceText.label(theme),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in [
                null,
                'open',
                'partially_paid',
                'settled',
                'voided',
              ])
                ChoiceChip(
                  label: Text(
                    s == null
                        ? uiTr(context, 'الكل')
                        : s == 'open'
                            ? uiTr(context, 'غير مسددة')
                            : AccountantFinanceLabels.settlementStatusAr(
                                s == 'open' ? 'draft' : s,
                              ),
                    style: AccountantFinanceText.label(theme).copyWith(
                      color: AccountantFinanceText.ink(theme),
                    ),
                  ),
                  selected: _statusFilter == s,
                  onSelected: (_) => setState(() => _statusFilter = s),
                ),
            ],
          ),
          if (AdminRoleService.isSuperAdmin) ...[
            const SizedBox(height: 8),
            FilterChip(
              label: Text(
                uiTr(context, 'تشخيص تقني — تسويات الاختبار'),
                style: AccountantFinanceText.label(theme).copyWith(
                  color: AccountantFinanceText.ink(theme),
                ),
              ),
              selected: _showQaDiagnostics,
              onSelected: (v) => setState(() => _showQaDiagnostics = v),
            ),
          ],
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _settlementsStream.streamForCurrentUser(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(
                  AdminUserFacingErrors.from(context, snap.error!),
                  style: AccountantFinanceText.body(theme).copyWith(
                    color: theme.error,
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final liveDocs = snap.data!.docs;
              if (liveDocs.isNotEmpty) {
                _liveLastDoc = liveDocs.last;
              }
              final byId =
                  <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                for (final d in liveDocs) d.id: d,
                for (final d in _olderDocs) d.id: d,
              };
              var docs = byId.values.toList();
              if (AdminRoleService.isCountryAgent &&
                  !AdminRoleService.canWriteSettlements) {
                final path = AdminRoleService.scopedCountryRef?.path;
                if (path != null) {
                  docs = docs
                      .where((d) => (d.data()['countryId'] as String?) == path)
                      .toList();
                }
              }

              // Normal accountant list excludes QA settlements.
              // Super Admin diagnostics may re-include them.
              if (!_showQaDiagnostics) {
                docs = docs
                    .where(
                      (d) => !AdminQaFixture.isFinanceQaSettlement(
                        d.data(),
                        settlementId: d.id,
                      ),
                    )
                    .toList();
              } else if (AdminRoleService.isSuperAdmin) {
                docs = docs
                    .where(
                      (d) => AdminQaFixture.isFinanceQaSettlement(
                        d.data(),
                        settlementId: d.id,
                      ),
                    )
                    .toList();
              }

              if (_statusFilter == 'open') {
                docs = docs
                    .where((d) {
                      final st = (d.data()['status'] ?? '').toString();
                      return st == 'draft' ||
                          st == 'locked' ||
                          st == 'partially_paid' ||
                          st == 'pending';
                    })
                    .toList();
              } else if (_statusFilter != null) {
                docs = docs
                    .where((d) => d.data()['status'] == _statusFilter)
                    .toList();
              }

              var openCount = 0;
              var dueCompany = 0;
              var dueDriver = 0;
              var paid = 0;
              var remaining = 0;
              var currency = 'SAR';
              final periodReady = _periodMaps != null;
              // PERF-P4A: never paint period KPIs from the live first page.
              final summaryRows = periodReady
                  ? _periodMaps!
                  : const <Map<String, dynamic>>[];
              for (final s in summaryRows) {
                if (!_showQaDiagnostics &&
                    AdminQaFixture.isFinanceQaSettlement(
                      s,
                      settlementId: (s['id'] ?? '').toString(),
                    )) {
                  continue;
                }
                currency = (s['currency'] as String?) ?? currency;
                final st = (s['status'] ?? '').toString();
                final out = (s['outstandingMinor'] as num?)?.toInt() ?? 0;
                final conf = (s['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
                final abs =
                    (s['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
                paid += conf;
                remaining += out;
                if (st != 'settled' && st != 'voided') openCount++;
                final dir = (s['direction'] ?? '').toString();
                if (dir == 'DRIVER_PAYS_COMPANY') {
                  dueCompany += out > 0 ? out : (abs - conf).clamp(0, abs);
                } else if (dir == 'COMPANY_PAYS_DRIVER') {
                  dueDriver += out > 0 ? out : (abs - conf).clamp(0, abs);
                }
              }
              final sym = AdminCurrency.symbolByCode[currency] ?? currency;
              String maj(int minor) => AdminFinanceUiLabels.formatMinorByCurrency(
                    {currency: minor},
                  );
              String kpi(String ready) => periodReady ? ready : '—';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_showQaDiagnostics)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        uiTr(
                          context,
                          'وضع التشخيص التقني — تسويات الاختبار فقط',
                        ),
                        style: AccountantFinanceText.label(theme),
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _sumChip(context, 'تسويات مفتوحة', kpi('$openCount')),
                      _sumChip(context, 'مستحق للشركة', kpi(maj(dueCompany))),
                      _sumChip(context, 'مستحق للسائقين', kpi(maj(dueDriver))),
                      _sumChip(context, 'مدفوع', kpi(maj(paid))),
                      _sumChip(context, 'متبقٍ', kpi(maj(remaining))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      periodReady
                          ? 'ملخص الفترة (محدود) — الجدول صفحته الأولى مباشرة'
                          : 'جاري ملخص الفترة… تظهر قائمة التسويات الآن.',
                      style: AccountantFinanceText.label(theme),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    AdminEmptyState(
                      title: uiTr(context, 'لا توجد تسويات'),
                      message: uiTr(
                        context,
                        'ستظهر التسويات هنا بعد أن تصبح العمليات مؤهلة.',
                      ),
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    AdminContentCard(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle:
                              AccountantFinanceText.tableHeader(theme),
                          dataTextStyle: AccountantFinanceText.body(theme),
                          columns: [
                            DataColumn(label: Text(uiTr(context, 'رقم التسوية'))),
                            DataColumn(label: Text(uiTr(context, 'الدولة'))),
                            DataColumn(label: Text(uiTr(context, 'الطرف الدافع'))),
                            DataColumn(label: Text(uiTr(context, 'الطرف المستلم'))),
                            DataColumn(label: Text(uiTr(context, 'المستحق'))),
                            DataColumn(label: Text(uiTr(context, 'المدفوع'))),
                            DataColumn(label: Text(uiTr(context, 'المتبقي'))),
                            DataColumn(label: Text(uiTr(context, 'الحالة'))),
                            DataColumn(label: Text(uiTr(context, 'التاريخ'))),
                            DataColumn(label: Text(uiTr(context, ''))),
                          ],
                          rows: [
                            for (final d in docs)
                              _row(context, theme, d, sym),
                          ],
                        ),
                      ),
                    ),
                  if (_hasMoreOlder && docs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMoreOlder,
                        child: Text(
                          _loadingMore ? 'جاري التحميل…' : 'تحميل المزيد',
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sumChip(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(uiTr(context, label), style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 4),
          Text(value, style: AccountantFinanceText.money(theme)),
        ],
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    FlutterFlowTheme theme,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String sym,
  ) {
    final s = d.data();
    final code = (s['settlementCode'] ?? d.id).toString();
    final country = AccountantFinanceLabels.countryHumanAr(
      (s['countryId'] ?? '').toString(),
    );
    final dir = (s['direction'] ?? '').toString();
    final payer = dir == 'DRIVER_PAYS_COMPANY'
        ? uiTr(context, 'السائق')
        : dir == 'COMPANY_PAYS_DRIVER'
            ? uiTr(context, 'الشركة')
            : uiTr(context, 'غير محدد');
    final payee = dir == 'DRIVER_PAYS_COMPANY'
        ? uiTr(context, 'الشركة')
        : dir == 'COMPANY_PAYS_DRIVER'
            ? uiTr(context, 'السائق')
            : uiTr(context, 'غير محدد');
    final due = (s['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
    final paid = (s['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
    final out = (s['outstandingMinor'] as num?)?.toInt() ?? 0;
    final status = AccountantFinanceLabels.settlementStatusAr(
      (s['status'] ?? '').toString(),
    );
    DateTime? when;
    final raw = s['lockedAt'] ?? s['createdAt'] ?? s['updatedAt'];
    if (raw is String) when = DateTime.tryParse(raw);
    if (raw is Timestamp) when = raw.toDate();
    final dateStr = when == null
        ? '—'
        : DateFormat('yyyy-MM-dd').format(when.toLocal());

    String m(int minor) =>
        AdminFinanceUiLabels.formatMinorByCurrency({s['currency'] ?? 'SAR': minor});

    return DataRow(
      cells: [
        DataCell(Text(code)),
        DataCell(Text(country)),
        DataCell(Text(payer)),
        DataCell(Text(payee)),
        DataCell(Text(m(due))),
        DataCell(Text(m(paid))),
        DataCell(Text(m(out))),
        DataCell(Text(status)),
        DataCell(Text(dateStr)),
        DataCell(
          TextButton(
            onPressed: () => context.pushNamed(
              AdminSettlementDetailsWidget.routeName,
              queryParameters: {
                'settlementId': serializeParam(d.id, ParamType.String),
                if (_showQaDiagnostics)
                  'diagnostic': serializeParam('1', ParamType.String),
              }.withoutNulls,
            ),
            child: Text(
              uiTr(context, 'التفاصيل'),
              style: AccountantFinanceText.body(theme).copyWith(
                color: AdminUi.brandTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
