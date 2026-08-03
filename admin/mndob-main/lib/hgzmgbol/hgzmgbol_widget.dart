import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'hgzmgbol_model.dart';
export 'hgzmgbol_model.dart';

class HgzmgbolWidget extends StatefulWidget {
  const HgzmgbolWidget({super.key});

  static String routeName = 'hgzmgbol';
  static String routePath = '/hgzmgbol';

  @override
  State<HgzmgbolWidget> createState() => _HgzmgbolWidgetState();
}

class _HgzmgbolWidgetState extends State<HgzmgbolWidget> {
  late HgzmgbolModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HgzmgbolModel());

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
          TfaselCopyWidget.routeName,
          queryParameters: {
            'idorder': serializeParam(
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
                  text: FFLocalizations.of(context).getText('hdaiynu7' /*    */),
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
                    'bpdu8zit' /*  -destinations */,
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
                    '51s9tp7q' /*    -Hours  */,
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
                    '9sco8cez' /*  R.S  */,
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
                  '0p9o2sn0' /* New requests */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: Stack(
                  children: [
                    if (valueOrDefault<bool>(
                            currentUserDocument?.actevMndob, false) ==
                        true)
                      AuthUserStreamWidget(
                        builder: (context) => StreamBuilder<List<OrderRecord>>(
                          stream: queryOrderRecord(
                            queryBuilder: (orderRecord) => orderRecord
                                .where(
                                  'halh_text',
                                  isEqualTo: 'مقبول',
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
                                  '0p9o2sn0' /* New requests */,
                                ),
                                icon: Icons.inbox_outlined,
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
                              'kkx0okx7' /* Your account is inactive. */,
                            ),
                            message: '',
                            tone: DsInfoTone.error,
                            icon: Icons.block_rounded,
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
