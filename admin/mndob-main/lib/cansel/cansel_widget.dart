import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_online_state.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/core/driver_i18n.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cansel_model.dart';
export 'cansel_model.dart';

/// Cancelled ملغاة
class CanselWidget extends StatefulWidget {
  const CanselWidget({super.key});

  static String routeName = 'cansel';
  static String routePath = '/cansel';

  @override
  State<CanselWidget> createState() => _CanselWidgetState();
}

class _CanselWidgetState extends State<CanselWidget> {
  late CanselModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CanselModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: driverTr(context, 'Cancelled'),
                automaticallyImplyLeading: false,
                centerTitle: false,
              ),
              body: SafeArea(
                top: true,
                child: DriverContentWidth(
                  child: DriverPagePadding(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (!DriverOnlineState.isApproved)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: DsSpacing.md,
                              ),
                              child: AuthUserStreamWidget(
                                builder: (context) => DsCard(
                                  color: colors.error,
                                  bordered: false,
                                  padding: const EdgeInsets.all(DsSpacing.sm),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'wrc914v3' /* This account is inactive. For ... */,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.onError,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          StreamBuilder<List<OrderRecord>>(
                            stream: queryOrderRecord(
                              queryBuilder: (orderRecord) => orderRecord
                                  .where(
                                    'mndob_user',
                                    isEqualTo: currentUserReference,
                                  )
                                  .orderBy('data_order', descending: true)
                                  .limit(80),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(DsSpacing.xxl),
                                  child: Center(child: DsLoading()),
                                );
                              }
                              final listViewOrderRecordList = snapshot.data!
                                  .where(
                                    (o) => DriverTripActionGates
                                        .isCancelledListItem(
                                      (o.snapshotData['status_code'] ?? '')
                                          .toString(),
                                      o.halhText,
                                    ),
                                  )
                                  .toList();

                              if (listViewOrderRecordList.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: DsSpacing.xxl,
                                  ),
                                  child: DriverEmptyState(
                                    title: driverTr(context, 'No orders'),
                                    message: driverTr(
                                      context,
                                      'New orders will appear here when available',
                                    ),
                                    icon: Icons.cancel_outlined,
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                itemCount: listViewOrderRecordList.length,
                                itemBuilder: (context, listViewIndex) {
                                  final order =
                                      listViewOrderRecordList[listViewIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: DsSpacing.sm,
                                    ),
                                    child: DriverOrderCardShell(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: colors.primarySoft,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  child: Image.network(
                                                    order.imgProfileClent,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                      Icons.person_rounded,
                                                      color:
                                                          colors.primaryStrong,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: DsSpacing.sm),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            driverTrNamed(
                                                                context,
                                                                'Order #{id}', {
                                                              'id':
                                                                  '${order.iDorder}'
                                                            }),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: typography
                                                                .titleSmall
                                                                .copyWith(
                                                              color: colors
                                                                  .textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            await Clipboard
                                                                .setData(
                                                              ClipboardData(
                                                                text: order
                                                                    .iDorder,
                                                              ),
                                                            );
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  driverTr(
                                                                      context,
                                                                      'Copied'),
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'cairo',
                                                                    color: colors
                                                                        .surface,
                                                                  ),
                                                                ),
                                                                duration:
                                                                    const Duration(
                                                                  milliseconds:
                                                                      4000,
                                                                ),
                                                                backgroundColor:
                                                                    colors
                                                                        .secondary,
                                                              ),
                                                            );
                                                          },
                                                          child: Icon(
                                                            Icons.content_copy,
                                                            color: colors
                                                                .textPrimary,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      order.naimUserText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: typography
                                                          .bodyLarge
                                                          .copyWith(
                                                        color:
                                                            colors.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 3,
                                                      ),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'g5a8p5v3' /* Cancelled */,
                                                        ),
                                                        style: typography
                                                            .labelSmall
                                                            .copyWith(
                                                          color: colors.error,
                                                        ),
                                                      ),
                                                    ),
                                                    Wrap(
                                                      spacing: DsSpacing.md,
                                                      runSpacing: DsSpacing.xxs,
                                                      children: [
                                                        _CancelMeta(
                                                          icon: Icons.schedule,
                                                          label: driverTrNamed(
                                                              context,
                                                              'Hours: {hours}',
                                                              {
                                                                'hours':
                                                                    '${order.totalTaim}'
                                                              }),
                                                        ),
                                                        _CancelMeta(
                                                          icon: Icons.place,
                                                          label: driverTrNamed(
                                                              context,
                                                              'Landmarks: {count}',
                                                              {
                                                                'count':
                                                                    '${order.addCartNumer}'
                                                              }),
                                                        ),
                                                      ],
                                                    ),
                                                  ].divide(
                                                    const SizedBox(
                                                      height: DsSpacing.xxs,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: colors.border,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'fhoeqp3k' /* Total Earnings */,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: typography.labelMedium
                                                    .copyWith(
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                formatNumber(
                                                  order.totalMndob2,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.automatic,
                                                  currency:
                                                      ' ${TouryCountryRegistry.currencySymbol(DriverCountryService.currentIso2())} ',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: typography.headlineSmall
                                                    .copyWith(
                                                  color: colors.error,
                                                  fontSize: 18,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ].divide(
                                              const SizedBox(
                                                height: DsSpacing.xxs,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            dateTimeFormat(
                                              'relative',
                                              order.dataOrder!,
                                              locale:
                                                  FFLocalizations.of(context)
                                                      .languageCode,
                                            ),
                                            style:
                                                typography.labelSmall.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ].divide(
                                          const SizedBox(height: DsSpacing.sm),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CancelMeta extends StatelessWidget {
  const _CancelMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.bodySmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
