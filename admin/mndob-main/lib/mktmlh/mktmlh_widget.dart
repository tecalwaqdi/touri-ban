import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'mktmlh_model.dart';
export 'mktmlh_model.dart';

class MktmlhWidget extends StatefulWidget {
  const MktmlhWidget({super.key});

  static String routeName = 'mktmlh';
  static String routePath = '/mktmlh';

  @override
  State<MktmlhWidget> createState() => _MktmlhWidgetState();
}

class _MktmlhWidgetState extends State<MktmlhWidget> {
  late MktmlhModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MktmlhModel());

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
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: FFLocalizations.of(context).getText(
                  'h2tehj88' /* completed */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: StreamBuilder<List<OrderRecord>>(
                  stream: queryOrderRecord(
                    queryBuilder: (orderRecord) => orderRecord
                        .where(
                          'status_code',
                          isEqualTo: 'completed',
                        )
                        .where(
                          'mndob_user',
                          isEqualTo: currentUserReference,
                        )
                        .orderBy('data_order'),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const DsLoading();
                    }
                    List<OrderRecord> listViewOrderRecordList = snapshot.data!;

                    if (listViewOrderRecordList.isEmpty) {
                      return DsEmptyState(
                        title: FFLocalizations.of(context).getText(
                          'h2tehj88' /* completed */,
                        ),
                        icon: Icons.check_circle_outline_rounded,
                      );
                    }

                    return ListView.separated(
                      padding: DsSpacing.pagePadding,
                      itemCount: listViewOrderRecordList.length,
                      separatorBuilder: (_, __) => DsSpacing.gapSm,
                      itemBuilder: (context, listViewIndex) {
                        final listViewOrderRecord =
                            listViewOrderRecordList[listViewIndex];

                        return DsCard(
                          onTap: () async {
                            context.pushNamed(
                              TfaselCopyWidget.routeName,
                              queryParameters: {
                                'idorder': serializeParam(
                                  listViewOrderRecord.reference,
                                  ParamType.DocumentReference,
                                ),
                              }.withoutNulls,
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listViewOrderRecord.naimUserText,
                                      style: typography.titleMedium.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    DsSpacing.gapXxs,
                                    Text(
                                      dateTimeFormat(
                                        'relative',
                                        listViewOrderRecord.dataOrder!,
                                        locale: FFLocalizations.of(context)
                                                .languageShortCode ??
                                            FFLocalizations.of(context)
                                                .languageCode,
                                      ),
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.iconMuted,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
