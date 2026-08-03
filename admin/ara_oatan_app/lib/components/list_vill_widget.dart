import '/backend/backend.dart';
import '/core/toury_geo_content_i18n.dart';
import '/core/toury_firestore_cache.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'list_vill_model.dart';
export 'list_vill_model.dart';

class ListVillWidget extends StatefulWidget {
  const ListVillWidget({super.key});

  @override
  State<ListVillWidget> createState() => _ListVillWidgetState();
}

class _ListVillWidgetState extends State<ListVillWidget> {
  late ListVillModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListVillModel());
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
    final regionRef = context.select<FFAppState, DocumentReference?>(
      (s) => s.ShrekNRegionRev,
    );
    if (regionRef == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<VillagesRecord>>(
            stream: TouryFirestoreCache.villagesStream(
              cacheKey: 'city:${regionRef.path}',
              queryBuilder: (villagesRecord) => villagesRecord
                  .where(
                    'acctev',
                    isEqualTo: true,
                  )
                  .where(
                    'cities',
                    isEqualTo: regionRef,
                  )
                  .orderBy('naim'),
            ),
            builder: (context, snapshot) {
              // Customize what your widget looks like when it's loading.
              if (!snapshot.hasData) {
                return const DsLoading(size: 28);
              }
              List<VillagesRecord> listViewVillagesRecordList = snapshot.data!;

              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: listViewVillagesRecordList.length,
                itemBuilder: (context, listViewIndex) {
                  final listViewVillagesRecord =
                      listViewVillagesRecordList[listViewIndex];
                  return InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      FFAppState().ShrekNCite =
                          listViewVillagesRecord.reference;
                      FFAppState().ShrekNCiteText =
                          touryVillageName(context, listViewVillagesRecord);
                      safeSetState(() {});
                      Navigator.pop(context);
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                          touryVillageName(context, listViewVillagesRecord),
                          style: typography.titleLarge.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          FFLocalizations.of(context).getText(
                            'wgbjmhxo' /* Select  */,
                          ),
                          style: typography.labelMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.select_all,
                          color: colors.textSecondary,
                          size: 24.0,
                        ),
                        tileColor: colors.surface,
                        dense: false,
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(
                            DsSpacing.sm, 0.0, DsSpacing.sm, 0.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: DsRadius.extraSmall,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}
