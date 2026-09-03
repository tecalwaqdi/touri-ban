import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/core/finance/settlement_exposure.dart';
import '/core/finance/settlement_state_labels.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
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
  String? _status;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSettlementsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التسويات'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'سجل التسويات المحاسبية'), style: theme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            uiTr(
              context,
              'دفتر التسويات المحاسبية فقط — لا حركة محفظة أو دفع من هذه الشاشة.',
            ),
            softWrap: true,
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in [null, 'draft', 'locked', 'settled', 'voided'])
                ChoiceChip(
                  label: Text(
                    s == null
                        ? uiTr(context, 'الكل')
                        : AdminFinanceUiLabels.settlementStatusAr(s),
                  ),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: () {
              Query<Map<String, dynamic>> q = FirebaseFirestore.instance
                  .collection('financial_settlements');
              if (AdminRoleService.isCountryAgent &&
                  !AdminRoleService.isSuperAdmin) {
                final path = AdminRoleService.scopedCountryRef?.path;
                if (path != null) {
                  q = q.where('countryId', isEqualTo: path);
                }
              }
              return q.limit(200).snapshots();
            }(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(
                  AdminUserFacingErrors.from(context, snap.error!),
                  softWrap: true,
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data!.docs;
              if (AdminRoleService.isCountryAgent &&
                  !AdminRoleService.canWriteSettlements) {
                final path = AdminRoleService.scopedCountryRef?.path;
                if (path != null) {
                  docs = docs
                      .where((d) => (d.data()['countryId'] as String?) == path)
                      .toList();
                }
              }
              if (_status != null) {
                docs = docs.where((d) => d.data()['status'] == _status).toList();
              }

              int n(String status) =>
                  docs.where((d) => d.data()['status'] == status).length;
              final byCur = <String, int>{};
              for (final d in docs) {
                final c = (d.data()['currency'] as String?) ?? '?';
                byCur[c] = (byCur[c] ?? 0) + 1;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    uiTr(
                      context,
                      'عرض حتى 200 تسوية في هذه الصفحة — الأرقام أدناه لنطاق القائمة فقط.',
                    ),
                    softWrap: true,
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('${uiTr(context, 'مسودة')} ${n('draft')}'),
                      Text('${uiTr(context, 'مقفلة')} ${n('locked')}'),
                      Text('${uiTr(context, 'مسدد')} ${n('settled')}'),
                      Text(
                        '${SettlementStateLabels.directionAr('DRIVER_PAYS_COMPANY')} '
                        '${docs.where((d) => d.data()['direction'] == 'DRIVER_PAYS_COMPANY').length}',
                      ),
                      Text(
                        '${SettlementStateLabels.directionAr('COMPANY_PAYS_DRIVER')} '
                        '${docs.where((d) => d.data()['direction'] == 'COMPANY_PAYS_DRIVER').length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${uiTr(context, 'حسب العملة')}: '
                    '${AdminFinanceUiLabels.formatCurrencyCountMap(byCur)}',
                    softWrap: true,
                    style: theme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final recv = <String, int>{};
                      final pay = <String, int>{};
                      final collected = <String, int>{};
                      final agingRecv = <String, Map<String, int>>{};
                      final now = DateTime.now();
                      for (final d in docs) {
                        final s = d.data();
                        if (s['status'] == 'draft' || s['status'] == 'voided') {
                          continue;
                        }
                        final c = (s['currency'] as String?) ?? '?';
                        final out = (s['outstandingMinor'] as num?)?.toInt() ?? 0;
                        final paid = (s['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
                        collected[c] = (collected[c] ?? 0) + paid;
                        DateTime? lockedAt;
                        final raw = s['lockedAt'];
                        if (raw is String) lockedAt = DateTime.tryParse(raw);
                        final bucket =
                            SettlementExposureBucket.agingBucket(lockedAt, now);
                        if (s['direction'] == 'DRIVER_PAYS_COMPANY') {
                          recv[c] = (recv[c] ?? 0) + out;
                          agingRecv[c] ??= {};
                          agingRecv[c]![bucket] =
                              (agingRecv[c]![bucket] ?? 0) + out;
                        } else if (s['direction'] == 'COMPANY_PAYS_DRIVER') {
                          pay[c] = (pay[c] ?? 0) + out;
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uiTr(context, 'الذمم ضمن نطاق القائمة'),
                            style: theme.titleSmall,
                          ),
                          Text(
                            '${AdminFinanceUiLabels.receivablesAr()}: '
                            '${AdminFinanceUiLabels.formatMinorByCurrency(recv)}',
                            softWrap: true,
                          ),
                          Text(
                            '${AdminFinanceUiLabels.payablesAr()}: '
                            '${AdminFinanceUiLabels.formatMinorByCurrency(pay)}',
                            softWrap: true,
                          ),
                          Text(
                            '${AdminFinanceUiLabels.collectedAr()}: '
                            '${AdminFinanceUiLabels.formatMinorByCurrency(collected)}',
                            softWrap: true,
                          ),
                          Text(
                            '${AdminFinanceUiLabels.partiallyPaidAr()} ${n('partially_paid')}',
                            softWrap: true,
                          ),
                          Text(
                            '${uiTr(context, 'أعمار المستحقات')}: '
                            '${AdminFinanceUiLabels.formatMinorByCurrency({
                                  for (final e in agingRecv.entries)
                                    e.key: e.value.values.fold<int>(
                                      0,
                                      (a, b) => a + b,
                                    ),
                                })}',
                            softWrap: true,
                            style: theme.labelSmall,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    AdminEmptyState(
                      title: uiTr(
                        context,
                        'لا توجد تسويات مالية مسجلة حتى الآن.',
                      ),
                      message: uiTr(
                        context,
                        'ستظهر التسويات هنا بعد أن تصبح العمليات مؤهلة للتسوية.',
                      ),
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    ...docs.map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${d.data()['settlementCode'] ?? d.id} · '
                          '${SettlementStateLabels.statusAr('${d.data()['status']}')}',
                          softWrap: true,
                        ),
                        subtitle: Text(
                          '${d.data()['currency']} · '
                          '${SettlementStateLabels.directionAr('${d.data()['direction']}')} · '
                          '${uiTr(context, 'مندوب')} ${d.data()['driverId']}',
                          softWrap: true,
                        ),
                        onTap: () => context.pushNamed(
                          AdminSettlementDetailsWidget.routeName,
                          queryParameters: {
                            'settlementId': serializeParam(
                              d.id,
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
