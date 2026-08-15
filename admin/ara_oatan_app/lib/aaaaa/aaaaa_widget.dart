import 'package:ara_oatan_app/core/custom_text_tr.dart';
import 'package:easy_localization/easy_localization.dart';

import '/core/toury_mkan_i18n.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'aaaaa_model.dart';
export 'aaaaa_model.dart';

class AaaaaWidget extends StatefulWidget {
  const AaaaaWidget({super.key});

  static String routeName = 'aaaaa';
  static String routePath = '/aaaaa';

  @override
  State<AaaaaWidget> createState() => _AaaaaWidgetState();
}

class _AaaaaWidgetState extends State<AaaaaWidget> {
  late AaaaaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AaaaaModel());

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
                titleWidget: AppText(
                  'page_Title',
                  style: typography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                leading: DsBackButton(
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      StreamBuilder<List<MkanRecord>>(
                        stream: queryMkanRecord(
                          queryBuilder: (mkanRecord) => mkanRecord.where(
                            'isShrek',
                            isEqualTo: true,
                          ),
                        ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(DsSpacing.xl),
                              child: DsLoading(),
                            );
                          }
                          List<MkanRecord> columnMkanRecordList =
                              snapshot.data!;

                          if (columnMkanRecordList.isEmpty) {
                            return DsEmptyState(
                              title: 'page_Title'.tr(),
                              icon: DsIcons.location,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                              vertical: DsSpacing.xs,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: List.generate(
                                  columnMkanRecordList.length, (columnIndex) {
                                final columnMkanRecord =
                                    columnMkanRecordList[columnIndex];
                                return DsFadeSlide(
                                  delay: Duration(
                                    milliseconds:
                                        40 * columnIndex.clamp(0, 8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: DsSpacing.sm,
                                    ),
                                    child: DsCard(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  touryMkanName(
                                                      context,
                                                      columnMkanRecord),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: typography.titleMedium
                                                      .copyWith(
                                                    color: colors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: DsSpacing.xxs,
                                                ),
                                                Text(
                                                  columnMkanRecord.pdf,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: typography.bodySmall
                                                      .copyWith(
                                                    color:
                                                        colors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: DsSpacing.sm),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: colors.iconMuted,
                                            size: DsIcons.md,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: DsSpacing.massive),
                    ],
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
