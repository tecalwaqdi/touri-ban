import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/backend/admin_performance.dart';
import '/backend/dashboard_stats_loader.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'company_drivers_model.dart';
export 'company_drivers_model.dart';

/// بوابة مدير شركة النقل — سائقو شركته فقط.
class CompanyDriversWidget extends StatefulWidget {
  const CompanyDriversWidget({super.key});

  static String routeName = 'CompanyDrivers';
  static String routePath = '/companyDrivers';

  @override
  State<CompanyDriversWidget> createState() => _CompanyDriversWidgetState();
}

class _CompanyDriversWidgetState extends State<CompanyDriversWidget> {
  late CompanyDriversModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DashboardStats> _statsFuture;
  StreamSubscription<int>? _statsInvalidationSub;

  DocumentReference? get _companyRef =>
      AdminRoleService.transportCompanyRef;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompanyDriversModel());
    _statsFuture = loadDashboardStats(forceRefresh: false);
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.dashboard).listen((_) {
      if (!mounted) return;
      setState(() {
        _statsFuture = loadDashboardStats(forceRefresh: true);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _statsInvalidationSub?.cancel();
    _model.dispose();
    super.dispose();
  }

  void _addDriver() {
    final company = _companyRef;
    if (company == null) return;
    context.pushNamed(
      AddDrevWidget.routeName,
      queryParameters: {
        'companyRef': serializeParam(company, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  Future<void> _toggleActivation(
    UserRecord driver, {
    required bool activate,
  }) async {
    final title = activate ? 'تأكيد التفعيل' : 'تأكيد الإيقاف';
    final content = activate
        ? 'هل أنت متأكد من تفعيل السائق؟'
        : 'هل أنت متأكد من إيقاف السائق؟';

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(uiTr(context, 'نعم')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await driver.reference.update(
        createUserRecordData(actevMndob: activate),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activate ? 'تم تفعيل السائق' : 'تم إيقاف السائق'),
        ),
      );
      safeSetState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_update_driver_status_failed')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final companyRef = _companyRef;
    final companyName =
        currentUserDocument?.transportCompanyText ?? 'شركة النقل';

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: appTr(context, 'nav_company_drivers'),
      child: AdminPageBody(
        title: companyName,
        subtitle: appTr(context, 'scr_company_drivers_subtitle'),
        scrollable: true,
        child: companyRef == null
            ? AdminContentCard(
                child: Column(
                  children: [
                    Icon(Icons.link_off_rounded,
                        size: 48, color: theme.secondaryText),
                    const SizedBox(height: 12),
                    Text(
                      'حسابك غير مربوط بشركة نقل',
                      style: theme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminContentCard(
                    padding: const EdgeInsets.all(16),
                    child: AdminPrimaryButton(
                      label: uiTr(context, 'إضافة سائق جديد'),
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: _addDriver,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<DashboardStats>(
                    future: _statsFuture,
                    builder: (context, statsSnap) {
                      final totalDrivers =
                          statsSnap.data?.representatives ?? 0;

                      return AdminFirestoreList<UserRecord>(
                        query: UserRecord.collection,
                        recordBuilder: UserRecord.fromSnapshot,
                        pageSize: kAdminPageSize,
                        queryBuilder: (q) => q
                            .where('ismndob', isEqualTo: true)
                            .where('transport_company', isEqualTo: companyRef)
                            .orderBy(FieldPath.documentId),
                        builder: (context, drivers, listState) {
                          return AdminContentCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'عدد السائقين: ${totalDrivers > 0 ? totalDrivers : drivers.length}',
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.labelLargeIsCustom,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (drivers.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'لا يوجد سائقون مسجّلون بعد',
                                  textAlign: TextAlign.center,
                                  style: theme.titleMedium,
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: drivers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final driver = drivers[index];
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: theme.alternate),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AdminUi.brandTeal
                                          .withValues(alpha: 0.15),
                                      child: Icon(
                                        Icons.directions_car_rounded,
                                        color: AdminUi.brandTeal,
                                      ),
                                    ),
                                    title: Text(driver.displayName),
                                    subtitle: Text(
                                      '${driver.textTypeCarMndob.isNotEmpty ? driver.textTypeCarMndob : '—'} · ${driver.mndobVillText}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      tooltip: driver.actevMndob
                                          ? 'إيقاف السائق'
                                          : 'تفعيل السائق',
                                      icon: Icon(
                                        driver.actevMndob
                                            ? Icons.check_circle_rounded
                                            : Icons.pause_circle_outline_rounded,
                                        color: driver.actevMndob
                                            ? Colors.green
                                            : theme.secondaryText,
                                      ),
                                      onPressed: () => _toggleActivation(
                                        driver,
                                        activate: !driver.actevMndob,
                                      ),
                                    ),
                                    onTap: () {
                                      context.pushNamed(
                                        AddDrevWidget.routeName,
                                        queryParameters: {
                                          'editUser': serializeParam(
                                            driver.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                  );
                                },
                              ),
                            if (drivers.isNotEmpty)
                              AdminListLoadMoreFooter(state: listState),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
