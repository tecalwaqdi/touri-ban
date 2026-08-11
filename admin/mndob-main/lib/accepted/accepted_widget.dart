import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_ux_widgets.dart';
import '/core/driver_i18n.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'accepted_model.dart';
export 'accepted_model.dart';

/// Create a "New Orders" page in FlutterFlow for a service provider app.
///
/// Each order item in the list should include the following:
///
/// A circular user image (avatar).
///
/// The user's name.
///
/// Number of requested hours (e.g., "Hours: 4").
///
/// Number of requested destinations (e.g., "Destinations: 2").
///
/// Total earnings for the order (e.g., "$150").
///
/// Date and time of the order (e.g., "April 28, 2025 - 2:30 PM").
///
/// A green "Accept" button aligned to the right or bottom of each item.
///
/// Use card-style list items with proper spacing, a clean layout, and mobile
/// responsiveness. Ensure the green "Accept" button is clearly visible and
/// styled to attract attention. The UI should be optimized for mobile and
/// support both Android and iOS platforms.
class AcceptedWidget extends StatefulWidget {
  const AcceptedWidget({super.key});

  static String routeName = 'Accepted';
  static String routePath = '/Accepted';

  @override
  State<AcceptedWidget> createState() => _AcceptedWidgetState();
}

class _AcceptedWidgetState extends State<AcceptedWidget>
    with TickerProviderStateMixin {
  late AcceptedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AcceptedModel());

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            'xolnmkh5' /* Accepted requests */,
          ),
        ),
        body: SafeArea(
          top: true,
          child: DriverContentWidth(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (!DriverOnlineState.isApproved)
                    DriverPagePadding(
                      top: DsSpacing.md,
                      bottom: DsSpacing.md,
                      child: AuthUserStreamWidget(
                        builder: (context) => DsCard(
                          color: colors.error,
                          bordered: false,
                          padding: const EdgeInsets.all(DsSpacing.xs),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'jjqc2d63' /* This account is inactive. For ... */,
                            ),
                            textAlign: TextAlign.center,
                            style: typography.bodyMedium.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  DriverPagePadding(
                    child: StreamBuilder<List<OrderRecord>>(
                      stream: queryOrderRecord(
                        queryBuilder: DriverOrderMatch.assignedToMeQuery(),
                        limit: 40,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return DriverEmptyState(
                            title: driverTr(context, 'Error'),
                            message:
                                '${driverTr(context, 'Something went wrong. Please try again.')}\n(${snapshot.error})',
                            icon: Icons.cloud_off_rounded,
                            actionLabel: driverTr(context, 'Retry'),
                            onAction: () => safeSetState(() {}),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: DsSpacing.xl),
                            child: DsLoading(),
                          );
                        }
                        List<OrderRecord> listViewOrderRecordList =
                            snapshot.data!
                                .where(
                                  (o) => DriverTripActionGates.isActiveListItem(
                                    (o.snapshotData['status_code'] ?? '')
                                        .toString(),
                                    o.halhText,
                                  ),
                                )
                                .toList();

                        if (listViewOrderRecordList.isEmpty) {
                          return DriverEmptyState(
                            title: driverNoOrdersTitle(context),
                            message: driverNoOrdersMessage(context),
                            icon: Icons.assignment_turned_in_outlined,
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: listViewOrderRecordList.length,
                          itemBuilder: (context, listViewIndex) {
                            final listViewOrderRecord =
                                listViewOrderRecordList[listViewIndex];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: DsSpacing.xs),
                              child: FutureBuilder<int>(
                                future: queryChatRecordCount(
                                  queryBuilder: (chatRecord) =>
                                      chatRecord.where(
                                    'idorder',
                                    isEqualTo: listViewOrderRecord.reference,
                                  ),
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return SizedBox(
                                      height: 24,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              colors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  int containerCount = snapshot.data!;

                                  return DriverOrderCardShell(
                                    onTap: () async {
                                      context.pushNamed(
                                        TfaselOrserWidget.routeName,
                                        queryParameters: {
                                          'id': serializeParam(
                                            listViewOrderRecord.reference,
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
                                              width: 60.0,
                                              height: 60.0,
                                              decoration: BoxDecoration(
                                                color: colors.primarySoft,
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                                child: Image(
                                                  fit: BoxFit.cover,
                                                  image: listViewOrderRecord
                                                          .imgProfileClent
                                                          .isNotEmpty
                                                      ? NetworkImage(
                                                          listViewOrderRecord
                                                              .imgProfileClent)
                                                      : const AssetImage(
                                                              'assets/images/logo.png')
                                                          as ImageProvider,
                                                ),
                                              ),
                                            ),
                                            DsSpacing.gapSm,
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    listViewOrderRecord
                                                        .naimUserText,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: typography
                                                        .titleMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colors.textPrimary,
                                                    ),
                                                  ),
                                                  DsSpacing.gapXxs,
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.grid_3x3,
                                                        color: colors
                                                            .textSecondary,
                                                        size: 12.0,
                                                      ),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Flexible(
                                                        child: Text(
                                                          '${listViewOrderRecord.iDorder}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: typography
                                                              .bodySmall
                                                              .copyWith(
                                                            color: colors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          await Clipboard
                                                              .setData(
                                                            ClipboardData(
                                                              text:
                                                                  listViewOrderRecord
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
                                                              content: Text(
                                                                driverTr(
                                                                    context,
                                                                    'Copied'),
                                                                style: typography
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                  color: colors
                                                                      .onPrimary,
                                                                ),
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                milliseconds:
                                                                    4000,
                                                              ),
                                                              backgroundColor:
                                                                  colors
                                                                      .primary,
                                                            ),
                                                          );
                                                        },
                                                        child: Icon(
                                                          Icons.content_copy,
                                                          color: colors
                                                              .textPrimary,
                                                          size: 12.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  DsSpacing.gapXxs,
                                                  Wrap(
                                                    spacing: DsSpacing.md,
                                                    runSpacing: DsSpacing.xxs,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.schedule,
                                                            color: colors
                                                                .textSecondary,
                                                            size: 12.0,
                                                          ),
                                                          const SizedBox(
                                                              width: 4.0),
                                                          Text(
                                                            driverTrNamed(
                                                                context,
                                                                'Hours: {hours}',
                                                                {
                                                                  'hours': listViewOrderRecord
                                                                      .totalTaim
                                                                      .toString()
                                                                }),
                                                            style: typography
                                                                .bodySmall
                                                                .copyWith(
                                                              color: colors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.place,
                                                            color: colors
                                                                .textSecondary,
                                                            size: 16.0,
                                                          ),
                                                          const SizedBox(
                                                              width: 4.0),
                                                          Text(
                                                            driverTrNamed(
                                                                context,
                                                                'Landmarks: {count}',
                                                                {
                                                                  'count': listViewOrderRecord
                                                                      .addCartNumer
                                                                      .toString()
                                                                }),
                                                            style: typography
                                                                .bodySmall
                                                                .copyWith(
                                                              color: colors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Divider(
                                          thickness: 1.0,
                                          color: colors.divider,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'osbf1yq2' /* Total Earnings */,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: typography
                                                        .labelMedium
                                                        .copyWith(
                                                      color:
                                                          colors.textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    formatNumber(
                                                      listViewOrderRecord
                                                          .totalMndob2,
                                                      formatType:
                                                          FormatType.decimal,
                                                      decimalType:
                                                          DecimalType.automatic,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  if (containerCount >= 1)
                                                    FutureBuilder<int>(
                                                      future:
                                                          queryChatRecordCount(
                                                        queryBuilder:
                                                            (chatRecord) =>
                                                                chatRecord
                                                                    .where(
                                                                      'idorder',
                                                                      isEqualTo:
                                                                          listViewOrderRecord
                                                                              .reference,
                                                                    )
                                                                    .where(
                                                                      'user1',
                                                                      isNotEqualTo:
                                                                          currentUserReference,
                                                                    ),
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (!snapshot.hasData) {
                                                          return SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation(
                                                                colors.primary,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        int rowCount =
                                                            snapshot.data!;

                                                        return InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                              ChatWidget
                                                                  .routeName,
                                                              queryParameters: {
                                                                'idorder':
                                                                    serializeParam(
                                                                  listViewOrderRecord
                                                                      .reference,
                                                                  ParamType
                                                                      .DocumentReference,
                                                                ),
                                                                'phoneClent':
                                                                    serializeParam(
                                                                  listViewOrderRecord
                                                                      .phoneNumper,
                                                                  ParamType.int,
                                                                ),
                                                                'iduserclent':
                                                                    serializeParam(
                                                                  listViewOrderRecord
                                                                      .user,
                                                                  ParamType
                                                                      .DocumentReference,
                                                                ),
                                                              }.withoutNulls,
                                                            );
                                                          },
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.chat,
                                                                color: colors
                                                                    .textSecondary,
                                                                size: 16.0,
                                                              ),
                                                              DsSpacing.gapXs,
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'vp3hdudk' /* Chat */,
                                                                ),
                                                                style: typography
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                  color: colors
                                                                      .textPrimary,
                                                                ),
                                                              ),
                                                              if (rowCount >= 1)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                    bottom: 4.0,
                                                                  ),
                                                                  child: Text(
                                                                    containerCount
                                                                        .toString(),
                                                                    style: typography
                                                                        .bodyMedium
                                                                        .copyWith(
                                                                      color: colors
                                                                          .error,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ).animateOnPageLoad(
                                                                    animationsMap[
                                                                        'textOnPageLoadAnimation']!,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ].divide(
                                                  const SizedBox(height: 4.0),
                                                ),
                                              ),
                                            ),
                                            DsButton.primary(
                                              label: FFLocalizations.of(context)
                                                  .getText(
                                                'tiln3xf1' /* Details */,
                                              ),
                                              size: DsButtonSize.sm,
                                              onPressed: () async {
                                                context.pushNamed(
                                                  TfaselOrserWidget.routeName,
                                                  queryParameters: {
                                                    'id': serializeParam(
                                                      listViewOrderRecord
                                                          .reference,
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
                                            "relative",
                                            listViewOrderRecord.dataOrder!,
                                            locale: FFLocalizations.of(context)
                                                .languageCode,
                                          ),
                                          style: typography.labelSmall.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ].divide(const SizedBox(height: 12.0)),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
