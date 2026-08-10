import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hgzmktml_model.dart';
export 'hgzmktml_model.dart';

class HgzmktmlWidget extends StatefulWidget {
  const HgzmktmlWidget({super.key});

  static String routeName = 'hgzmktml';
  static String routePath = '/hgzmktml';

  @override
  State<HgzmktmlWidget> createState() => _HgzmktmlWidgetState();
}

class _HgzmktmlWidgetState extends State<HgzmktmlWidget> {
  late HgzmktmlModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HgzmktmlModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _orderCard(BuildContext context, OrderRecord order) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            textScaler: MediaQuery.of(context).textScaler,
            text: TextSpan(
              children: [
                TextSpan(
                  text: order.naimUserText,
                  style: typography.titleMedium.copyWith(
                    color: colors.primaryStrong,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: FFLocalizations.of(context).getText('b8uuolxj' /*    */),
                ),
                TextSpan(
                  text: dateTimeFormat(
                    'relative',
                    order.dataOrder!,
                    locale: FFLocalizations.of(context).languageCode,
                  ),
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          DsSpacing.gapSm,
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: order.addCartNumer.toString(),
                  style: typography.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: FFLocalizations.of(context).getText(
                    'z0fe4fs9' /*  -destinations */,
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          DsSpacing.gapSm,
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: order.totalTaim.toString(),
                  style: typography.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: FFLocalizations.of(context).getText(
                    'bw7me4da' /*    -Hours  */,
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: order.total.toString(),
                  style: typography.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: FFLocalizations.of(context).getText(
                    'fo2hdffy' /*  R.S  */,
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: FFLocalizations.of(context).getText(
                  'zp7s0q7u' /* Completed */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: Stack(
                  children: [
                    if ((valueOrDefault<bool>(
                                currentUserDocument?.actevMndob, false) ==
                            true) &&
                        (FFAppState().okDRIVER == false))
                      AuthUserStreamWidget(
                        builder: (context) => StreamBuilder<List<OrderRecord>>(
                          stream: queryOrderRecord(
                            queryBuilder: (orderRecord) => orderRecord
                                .where(
                                  'halh_text',
                                  isEqualTo: 'مكتملة',
                                )
                                .where(
                                  'mndob_user',
                                  isEqualTo: currentUserReference,
                                )
                                .orderBy('data_order', descending: true),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const DsLoading();
                            }
                            List<OrderRecord> listViewOrderRecordList =
                                snapshot.data!;

                            if (listViewOrderRecordList.isEmpty) {
                              return DsEmptyState(
                                title: FFLocalizations.of(context).getText(
                                  'zp7s0q7u' /* Completed */,
                                ),
                                icon: Icons.check_circle_outline_rounded,
                              );
                            }

                            return ListView.separated(
                              padding: DsSpacing.pagePadding,
                              itemCount: listViewOrderRecordList.length,
                              separatorBuilder: (_, __) => DsSpacing.gapSm,
                              itemBuilder: (context, listViewIndex) {
                                return _orderCard(
                                  context,
                                  listViewOrderRecordList[listViewIndex],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    if (valueOrDefault<bool>(
                            currentUserDocument?.actevMndob, false) ==
                        false)
                      Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: Padding(
                          padding: DsSpacing.pagePadding,
                          child: DsInformationCard(
                            title: FFLocalizations.of(context).getText(
                              'd4nr29xa' /* Your account is inactive. */,
                            ),
                            message: '',
                            tone: DsInfoTone.error,
                            icon: Icons.block_rounded,
                          ),
                        ),
                      ),
                    if (FFAppState().okDRIVER == true)
                      Align(
                        alignment: AlignmentDirectional.center,
                        child: Padding(
                          padding: DsSpacing.pagePadding,
                          child: DsInformationCard(
                            title: FFLocalizations.of(context).getText(
                              'aoy8mqp6' /* You cannot accept new bookings... */,
                            ),
                            message: '',
                            tone: DsInfoTone.warning,
                            icon: Icons.info_outline_rounded,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
