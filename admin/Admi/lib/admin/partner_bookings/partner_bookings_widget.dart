import 'dart:async';

import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/backend/admin_partner_orders.dart';
import '/backend/dashboard_stats_loader.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'partner_bookings_model.dart';
export 'partner_bookings_model.dart';

/// Partner portal — bookings linked to the partner's landmark (`partner_mkan`).
class PartnerBookingsWidget extends StatefulWidget {
  const PartnerBookingsWidget({super.key});

  static String routeName = 'PartnerBookings';
  static String routePath = '/partnerBookings';

  @override
  State<PartnerBookingsWidget> createState() => _PartnerBookingsWidgetState();
}

class _PartnerBookingsWidgetState extends State<PartnerBookingsWidget> {
  late PartnerBookingsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DashboardStats> _statsFuture;
  StreamSubscription<int>? _statsInvalidationSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PartnerBookingsModel());
    _statsFuture = loadDashboardStats(forceRefresh: false);
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.dashboard).listen((_) {
      if (!mounted) return;
      setState(() {
        _statsFuture = loadDashboardStats(forceRefresh: true);
      });
    });
  }

  @override
  void dispose() {
    _statsInvalidationSub?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final partnerMkan = AdminRoleService.partnerMkanRef;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: appTr(context, 'nav_partner_bookings'),
      child: AdminPageBody(
        title: appTr(context, 'scr_partner_bookings_title'),
        subtitle: partnerMkan != null
            ? 'الحجوزات المرتبطة بمعالمك السياحية'
            : 'لم يُربط حسابك بمعالم بعد — تواصل مع الإدارة',
        scrollable: true,
        child: partnerMkan == null
            ? AdminContentCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      size: 48,
                      color: theme.secondaryText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'حساب الشريك غير مربوط بمعالم',
                      style: theme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : FutureBuilder<DashboardStats>(
                    future: _statsFuture,
                    builder: (context, statsSnap) {
                      return AdminFirestoreList<OrderRecord>(
                        query: OrderRecord.collection,
                        recordBuilder: OrderRecord.fromSnapshot,
                        pageSize: kAdminPageSize,
                        queryBuilder: (q) =>
                            AdminPartnerOrders.applyPartnerOrderQuery(
                          q,
                          partnerMkan,
                          countryRef: AdminPanelDataBootstrap.partnerCountryRef,
                        ),
                        builder: (context, bookings, listState) {
                          final totalBookings =
                              statsSnap.data?.activeBookings ?? bookings.length;

                          return AdminContentCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'عدد الحجوزات: $totalBookings',
                                  style: theme.labelLarge.override(
                                    fontFamily: theme.labelLargeFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts:
                                        !theme.labelLargeIsCustom,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (bookings.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Text(
                                      'لا توجد حجوزات مرتبطة بمعالمك حالياً',
                                      textAlign: TextAlign.center,
                                      style: theme.bodyLarge,
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: bookings.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final order = bookings[index];
                                      return ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: theme.alternate),
                                        ),
                                        tileColor: theme.primaryBackground,
                                        leading: CircleAvatar(
                                          backgroundColor: AdminUi.brandTeal
                                              .withValues(alpha: 0.15),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            color: AdminUi.brandTeal,
                                          ),
                                        ),
                                        title: Text(
                                          'حجز #${order.iDorder}',
                                          style: theme.titleSmall,
                                        ),
                                        subtitle: Text(
                                          '${order.naimUserText} — ${order.halhText}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          '${order.total} ر.س',
                                          style: theme.titleSmall.override(
                                            fontFamily: theme.titleSmallFamily,
                                            fontWeight: FontWeight.w700,
                                            useGoogleFonts:
                                                !theme.titleSmallIsCustom,
                                          ),
                                        ),
                                        onTap: () {
                                          context.pushNamed(
                                            AdminBookingDetailsWidget
                                                .routeName,
                                            queryParameters: {
                                              'idbokeng': serializeParam(
                                                order.reference,
                                                ParamType.DocumentReference,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                if (bookings.isNotEmpty)
                                  AdminListLoadMoreFooter(state: listState),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
