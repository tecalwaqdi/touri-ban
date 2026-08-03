import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_transport_companies_model.dart';
export 'admin_transport_companies_model.dart';

/// شركات النقل المرخّصة من هيئة النقل — إدارة الشركات وسائقيها.
class AdminTransportCompaniesWidget extends StatefulWidget {
  const AdminTransportCompaniesWidget({super.key});

  static String routeName = 'AdminTransportCompanies';
  static String routePath = '/adminTransportCompanies';

  @override
  State<AdminTransportCompaniesWidget> createState() =>
      _AdminTransportCompaniesWidgetState();
}

class _AdminTransportCompaniesWidgetState
    extends State<AdminTransportCompaniesWidget> {
  late AdminTransportCompaniesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminTransportCompaniesModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<TransportCompanyRecord> _filter(List<TransportCompanyRecord> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (c) =>
              c.naim.toLowerCase().contains(q) ||
              c.licenseNumber.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openAddDriver(TransportCompanyRecord company) {
    context.pushNamed(
      AddDrevWidget.routeName,
      queryParameters: {
        'companyRef': serializeParam(
          company.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: appTr(context, 'nav_transport_companies'),
      child: AdminPageBody(
        title: appTr(context, 'scr_transport_companies'),
        subtitle:
            'الشركات المرخّصة من هيئة النقل — أضف الشركة ثم سجّل سائقيها ومركباتهم',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminContentCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _model.textController,
                    focusNode: _model.textFieldFocusNode,
                    onChanged: (_) => EasyDebounce.debounce(
                      '_search_transport_co',
                      const Duration(milliseconds: 300),
                      () => safeSetState(
                        () => _searchQuery = _model.textController!.text,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: uiTr(context, 'بحث باسم الشركة أو رقم الترخيص...'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminPrimaryButton(
                    label: uiTr(context, 'إضافة شركة نقل'),
                    icon: Icons.local_shipping_rounded,
                    onPressed: () =>
                        context.pushNamed(AddTransportCompanyWidget.routeName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminFirestoreList<TransportCompanyRecord>(
              refreshScope: AdminListScope.transportCompanies,
              query: TransportCompanyRecord.collection,
              recordBuilder: TransportCompanyRecord.fromSnapshot,
              queryBuilder: (q) => AdminCountryScope.applyTransportCompanyQuery(q)
                  .orderBy('naim'),
              builder: (context, allCompanies, listState) {
                final companies = _filter(allCompanies);

                return AdminContentCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'عدد الشركات: ${companies.length}',
                        style: theme.labelLarge.override(
                          fontFamily: theme.labelLargeFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelLargeIsCustom,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (companies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'لا توجد شركات نقل مسجّلة',
                            textAlign: TextAlign.center,
                            style: theme.titleMedium,
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: companies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final company = companies[index];
                            return _CompanyCard(
                              company: company,
                              onAddDriver: () => _openAddDriver(company),
                              onEdit: () => context.pushNamed(
                                EdetTransportCompanyWidget.routeName,
                                queryParameters: {
                                  'companyRef': serializeParam(
                                    company.reference,
                                    ParamType.DocumentReference,
                                  ),
                                }.withoutNulls,
                              ),
                              onToggleActive: () async {
                                try {
                                  await company.reference.update(
                                    createTransportCompanyRecordData(
                                      actev: !company.actev,
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        company.actev
                                            ? 'تم إيقاف الشركة'
                                            : 'تم تفعيل الشركة',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AdminCrudFeedback.updateFailed(context, e)),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      if (companies.isNotEmpty)
                        AdminListLoadMoreFooter(state: listState),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.onAddDriver,
    required this.onEdit,
    required this.onToggleActive,
  });

  final TransportCompanyRecord company;
  final VoidCallback onAddDriver;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AdminUi.brandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.naim.isNotEmpty ? company.naim : '—',
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    if (company.licenseNumber.isNotEmpty)
                      Text(
                        'ترخيص: ${company.licenseNumber}',
                        style: theme.labelMedium.override(
                          fontFamily: theme.labelMediumFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelMediumIsCustom,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusChip(active: company.actev),
            ],
          ),
          const SizedBox(height: 10),
          if (company.dolhText.isNotEmpty)
            Text(
              'الدولة: ${company.dolhText}',
              style: theme.bodySmall,
            ),
          if (company.phone.isNotEmpty)
            Text(appTrFormat(context, 'adm_phone_label', company.phone), style: theme.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddDriver,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(uiTr(context, 'إضافة سائق')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: company.actev ? 'إيقاف الشركة' : 'تفعيل الشركة',
                onPressed: onToggleActive,
                icon: Icon(
                  company.actev
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                ),
              ),
              IconButton(
                tooltip: 'تعديل',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'مفعّلة' : 'موقوفة',
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
