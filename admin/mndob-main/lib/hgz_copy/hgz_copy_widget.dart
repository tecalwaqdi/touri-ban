import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'hgz_copy_model.dart';
export 'hgz_copy_model.dart';

class HgzCopyWidget extends StatefulWidget {
  const HgzCopyWidget({super.key});

  static String routeName = 'hgzCopy';
  static String routePath = '/hgzCopy';

  @override
  State<HgzCopyWidget> createState() => _HgzCopyWidgetState();
}

class _HgzCopyWidgetState extends State<HgzCopyWidget> {
  late HgzCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HgzCopyModel());

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
                  '149brpxm' /* Accepted requests */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: StreamBuilder<List<OrderRecord>>(
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
                        .orderBy('data_order'),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const DsLoading();
                    }
                    List<OrderRecord> listViewOrderRecordList = snapshot.data!;

                    if (listViewOrderRecordList.isEmpty) {
                      return const DsEmptyState(
                        title: 'No accepted requests',
                        icon: Icons.inbox_outlined,
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
                                        color: colors.primary,
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
