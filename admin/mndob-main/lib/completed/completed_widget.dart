import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'completed_model.dart';
export 'completed_model.dart';

/// Completed مكتملة
class CompletedWidget extends StatefulWidget {
  const CompletedWidget({super.key});

  static String routeName = 'Completed';
  static String routePath = '/Completed';

  @override
  State<CompletedWidget> createState() => _CompletedWidgetState();
}

class _CompletedWidgetState extends State<CompletedWidget> {
  late CompletedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompletedModel());

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
              appBar: DriverMainAppBar(
                title: FFLocalizations.of(context).getText(
                  '49igunvq' /* Completed requests */,
                ),
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
                              padding: const EdgeInsets.only(
                                top: DsSpacing.md,
                                bottom: DsSpacing.md,
                              ),
                              child: AuthUserStreamWidget(
                                builder: (context) => DsCard(
                                  color: colors.error,
                                  bordered: false,
                                  padding: const EdgeInsets.all(DsSpacing.sm),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      't4jivayf' /* This account is inactive. For ... */,
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
                              queryBuilder:
                                  DriverOrderMatch.assignedToMeQuery(),
                              limit: 40,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(DsSpacing.xl),
                                  child: Text(
                                    '${FFLocalizations.of(context).getText('error')}\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.error,
                                    ),
                                  ),
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(DsSpacing.xxl),
                                  child: Center(child: DsLoading()),
                                );
                              }
                              final listViewOrderRecordList = snapshot.data!
                                  .where(
                                    (o) => DriverTripActionGates
                                        .isCompletedListItem(
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
                                    icon: Icons.check_circle_outline_rounded,
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
                                      onTap: () async {
                                        context.pushNamed(
                                          TfaselOrserWidget.routeName,
                                          queryParameters: {
                                            'id': serializeParam(
                                              order.reference,
                                              ParamType.DocumentReference,
                                            ),
                                          }.withoutNulls,
                                        );
                                      },
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
                                                  child: Image(
                                                    fit: BoxFit.cover,
                                                    image: (order
                                                            .imgProfileClent
                                                            .isNotEmpty)
                                                        ? NetworkImage(order
                                                            .imgProfileClent)
                                                        : const AssetImage(
                                                                'assets/images/logo.png')
                                                            as ImageProvider,
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
                                                    Text(
                                                      order.naimUserText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: typography
                                                          .titleMedium
                                                          .copyWith(
                                                        color:
                                                            colors.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: DsSpacing.xxs),
                                                    Wrap(
                                                      spacing: DsSpacing.md,
                                                      runSpacing: DsSpacing.xxs,
                                                      children: [
                                                        _MetaChip(
                                                          icon: Icons.schedule,
                                                          label: driverTrNamed(
                                                              context,
                                                              'Hours: {hours}',
                                                              {
                                                                'hours':
                                                                    '${order.totalTaim}'
                                                              }),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .grid_3x3_sharp,
                                                              color: colors
                                                                  .textSecondary,
                                                              size: 12,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            ConstrainedBox(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                maxWidth: 120,
                                                              ),
                                                              child: Text(
                                                                order.iDorder,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: typography
                                                                    .bodySmall
                                                                    .copyWith(
                                                                  color: colors
                                                                      .textSecondary,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
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
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content:
                                                                        Text(
                                                                      'تم ا',
                                                                      style:
                                                                          TextStyle(
                                                                        color: colors
                                                                            .textPrimary,
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
                                                                Icons
                                                                    .content_copy,
                                                                color: colors
                                                                    .textPrimary,
                                                                size: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        _MetaChip(
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
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: colors.border,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'z3snkf0u' /* Total Earnings */,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: typography
                                                          .labelMedium
                                                          .copyWith(
                                                        color: colors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      formatNumber(
                                                        order.totalMndob2,
                                                        formatType:
                                                            FormatType.decimal,
                                                        decimalType: DecimalType
                                                            .automatic,
                                                        currency:
                                                            ' ${TouryCountryRegistry.currencySymbol(DriverCountryService.currentIso2())} ',
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: typography
                                                          .headlineSmall
                                                          .copyWith(
                                                        color: colors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DsButton.secondary(
                                                label:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  'd1vcn2dg' /* Details */,
                                                ),
                                                onPressed: () async {
                                                  context.pushNamed(
                                                    TfaselOrserWidget.routeName,
                                                    queryParameters: {
                                                      'id': serializeParam(
                                                        order.reference,
                                                        ParamType
                                                            .DocumentReference,
                                                      ),
                                                    }.withoutNulls,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          Text(
                                            dateTimeFormat(
                                              'relative',
                                              order.dataOrder!,
                                              locale:
                                                  FFLocalizations.of(context)
                                                      .languageCode,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.textSecondary, size: 12),
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
