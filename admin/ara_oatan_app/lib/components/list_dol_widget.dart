import '/backend/backend.dart';
import '/core/toury_geo_content_i18n.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'list_dol_model.dart';
export 'list_dol_model.dart';

class ListDolWidget extends StatefulWidget {
  const ListDolWidget({super.key});

  @override
  State<ListDolWidget> createState() => _ListDolWidgetState();
}

class _ListDolWidgetState extends State<ListDolWidget> {
  late ListDolModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListDolModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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

    return StreamBuilder<List<CountriesRecord>>(
      stream: queryCountriesRecord(
        queryBuilder: (countriesRecord) => countriesRecord
            .where(
              'acctev',
              isEqualTo: true,
            )
            .orderBy('num_trteb'),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsLoading();
        }
        List<CountriesRecord> columnCountriesRecordList = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children:
                List.generate(columnCountriesRecordList.length, (columnIndex) {
              final columnCountriesRecord =
                  columnCountriesRecordList[columnIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.xs),
                child: DsCard(
                  onTap: () async {
                    FFAppState().ShrekNCountry =
                        columnCountriesRecord.reference;
                    FFAppState().ShrekNCountryText =
                        touryCountryDisplayName(
                            context, columnCountriesRecord);
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
                              touryCountryDisplayName(
                                  context, columnCountriesRecord),
                              style: typography.titleLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'wjuj6zkt' /* Select the country */,
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
          ),
        );
      },
    );
  }
}
