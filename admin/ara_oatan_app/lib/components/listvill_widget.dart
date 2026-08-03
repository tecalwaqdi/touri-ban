import '/backend/backend.dart';
import '/core/toury_geo_display.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'listvill_model.dart';
export 'listvill_model.dart';

class ListvillWidget extends StatefulWidget {
  const ListvillWidget({super.key});

  @override
  State<ListvillWidget> createState() => _ListvillWidgetState();
}

class _ListvillWidgetState extends State<ListvillWidget> {
  late ListvillModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListvillModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: StreamBuilder<List<VillagesRecord>>(
          stream: queryVillagesRecord(
            queryBuilder: (villagesRecord) => villagesRecord
                .where(
                  'acctev',
                  isEqualTo: true,
                )
                .orderBy('naim'),
          ),
          builder: (context, snapshot) {
            // Customize what your widget looks like when it's loading.
            if (!snapshot.hasData) {
              return const DsLoading(size: 50);
            }
            List<VillagesRecord> columnVillagesRecordList = snapshot.data!;

            return SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(columnVillagesRecordList.length,
                    (columnIndex) {
                  final columnVillagesRecord =
                      columnVillagesRecordList[columnIndex];
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          FFAppState().adressVillTEXT =
                              touryLocalizedVillageLabel(
                            columnVillagesRecord,
                          );
                          FFAppState().adressVillRev =
                              columnVillagesRecord.reference;
                          safeSetState(() {});
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 70.0,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: DsRadius.extraSmall,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(DsSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        touryLocalizedVillageLabel(
                                          columnVillagesRecord,
                                        ),
                                        style: typography.bodyLarge.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80.0,
                                  child: DsButton.primary(
                                    label: FFLocalizations.of(context).getText(
                                      'pu4yrzht' /* Select */,
                                    ),
                                    size: DsButtonSize.sm,
                                    onPressed: () async {
                                      FFAppState().adressVillTEXT =
                                          touryLocalizedVillageLabel(
                                        columnVillagesRecord,
                                      );
                                      FFAppState().adressVillRev =
                                          columnVillagesRecord.reference;
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ].divide(DsSpacing.gapSm),
                            ),
                          ),
                        ),
                      ),
                    ].divide(DsSpacing.gapSm),
                  );
                }).divide(DsSpacing.gapMd),
              ),
            );
          },
        ),
      ),
    );
  }
}
