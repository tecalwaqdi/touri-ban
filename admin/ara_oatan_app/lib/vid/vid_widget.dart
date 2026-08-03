import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vid_model.dart';
export 'vid_model.dart';

/// قائمة المدن
class VidWidget extends StatefulWidget {
  const VidWidget({super.key});

  static String routeName = 'vid';
  static String routePath = '/vid';

  @override
  State<VidWidget> createState() => _VidWidgetState();
}

class _VidWidgetState extends State<VidWidget> {
  late VidModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VidModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
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
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: DsSpacing.md),
                        child: DsSectionHeader(
                          title: FFLocalizations.of(context).getText(
                            'v7jtmq42' /* List of regions */,
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xs),
                      _buildVillagesList(context),
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

  Widget _buildVillagesList(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return StreamBuilder<List<VillagesRecord>>(
      stream: queryVillagesRecord(
        queryBuilder: (villagesRecord) => villagesRecord
            .where(
              'cities',
              isEqualTo: FFAppState().mdenh,
            )
            .where(
              'acctev',
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
        List<VillagesRecord> columnVillagesRecordList = snapshot.data!;

        if (columnVillagesRecordList.isEmpty) {
          return DsEmptyState(
            title: FFLocalizations.of(context).getText(
              'v7jtmq42' /* List of regions */,
            ),
            icon: DsIcons.location,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children:
                List.generate(columnVillagesRecordList.length, (columnIndex) {
              final columnVillagesRecord =
                  columnVillagesRecordList[columnIndex];
              return DsFadeSlide(
                delay: Duration(milliseconds: 40 * columnIndex.clamp(0, 8)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                  child: DsCard(
                    elevated: true,
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(DsSpacing.md),
                          child: Text(
                            columnVillagesRecord.naim,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            FFAppState().vil = columnVillagesRecord.reference;
                            safeSetState(() {});

                            context.pushNamed(ListWidget.routeName);
                          },
                          child: Container(
                            width: double.infinity,
                            height: DsConstants.buttonHeightMd,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: const BorderRadius.vertical(
                                bottom: DsRadius.lgRadius,
                              ),
                            ),
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                '9wrud4dx' /* Specify the region */,
                              ),
                              style: typography.labelLarge.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
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
    );
  }
}
