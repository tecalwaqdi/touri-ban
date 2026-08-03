import '/backend/backend.dart';
import '/core/toury_geo_content_i18n.dart';
import '/core/toury_firestore_cache.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'list_region_model.dart';
export 'list_region_model.dart';

class ListRegionWidget extends StatefulWidget {
  const ListRegionWidget({super.key});

  @override
  State<ListRegionWidget> createState() => _ListRegionWidgetState();
}

class _ListRegionWidgetState extends State<ListRegionWidget> {
  late ListRegionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListRegionModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    final countryRef = context.select<FFAppState, DocumentReference?>(
      (s) => s.ShrekNCountry,
    );
    if (countryRef == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<CitiesRecord>>(
      stream: TouryFirestoreCache.citiesStream(
        cacheKey: 'country:${countryRef.path}',
        queryBuilder: (citiesRecord) => citiesRecord
            .where(
              'dolh',
              isEqualTo: countryRef,
            )
            .orderBy('naim'),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsLoading();
        }
        List<CitiesRecord> columnCitiesRecordList = snapshot.data!;

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: List.generate(columnCitiesRecordList.length, (columnIndex) {
            final columnCitiesRecord = columnCitiesRecordList[columnIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.xs),
              child: DsCard(
                onTap: () async {
                  FFAppState().ShrekNRegionText =
                      touryCityName(context, columnCitiesRecord);
                  FFAppState().ShrekNRegionRev = columnCitiesRecord.reference;
                  safeSetState(() {});
                  Navigator.pop(context);
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.sm,
                  vertical: DsSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            touryCityName(context, columnCitiesRecord),
                            style: typography.titleLarge.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            FFLocalizations.of(context).getText(
                              'wdg29lkf' /* Select  */,
                            ),
                            style: typography.labelMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.select_all,
                      color: colors.iconMuted,
                      size: DsIcons.lg,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
