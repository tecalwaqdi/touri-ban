import '/core/toury_mkan_i18n.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'list3_model.dart';
export 'list3_model.dart';

class List3Widget extends StatefulWidget {
  const List3Widget({super.key});

  static String routeName = 'list3';
  static String routePath = '/list3';

  @override
  State<List3Widget> createState() => _List3WidgetState();
}

class _List3WidgetState extends State<List3Widget> {
  late List3Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => List3Model());

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
                title: FFLocalizations.of(context).getText(
                  'blsk6xdf' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
                actions: const [],
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.xs,
                        ),
                        child: FutureBuilder<int>(
                          future: queryMkanRecordCount(
                            queryBuilder: (mkanRecord) => mkanRecord
                                .where(
                                  'ismzod',
                                  isEqualTo: true,
                                )
                                .where(
                                  'isShrek',
                                  isEqualTo: true,
                                ),
                          ),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(DsSpacing.md),
                                child: DsLoading(size: 20),
                              );
                            }
                            int rowCount = snapshot.data!;

                            return DsStatisticsCard(
                              label: FFLocalizations.of(context).getText(
                                'blsk6xdf' /* Page Title */,
                              ),
                              value: rowCount.toString(),
                              icon: DsIcons.location,
                            );
                          },
                        ),
                      ),
                      StreamBuilder<List<MkanRecord>>(
                        stream: queryMkanRecord(
                          queryBuilder: (mkanRecord) => mkanRecord
                              .where(
                                'ismzod',
                                isEqualTo: true,
                              )
                              .where(
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
                          List<MkanRecord> listViewMkanRecordList =
                              snapshot.data!;

                          if (listViewMkanRecordList.isEmpty) {
                            return DsEmptyState(
                              title: FFLocalizations.of(context).getText(
                                'blsk6xdf' /* Page Title */,
                              ),
                              icon: DsIcons.location,
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.xs,
                              DsSpacing.md,
                              DsSpacing.massive,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: listViewMkanRecordList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: DsSpacing.sm),
                            itemBuilder: (context, listViewIndex) {
                              final listViewMkanRecord =
                                  listViewMkanRecordList[listViewIndex];
                              return DsFadeSlide(
                                delay: Duration(
                                  milliseconds:
                                      40 * listViewIndex.clamp(0, 8),
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
                                                  context, listViewMkanRecord),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.titleMedium
                                                  .copyWith(
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: DsSpacing.xxs),
                                            Text(
                                              touryMkanDescription(
                                                  context, listViewMkanRecord),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.bodySmall
                                                  .copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: DsSpacing.sm),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: colors.iconMuted,
                                        size: DsConstants.iconMd,
                                      ),
                                    ],
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
          );
        },
      ),
    );
  }
}
