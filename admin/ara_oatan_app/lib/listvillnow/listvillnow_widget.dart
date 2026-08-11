import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/toury_geo_display.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'listvillnow_model.dart';

export 'listvillnow_model.dart';

class ListvillnowWidget extends StatefulWidget {
  const ListvillnowWidget({super.key});

  static String routeName = 'Listvillnow';
  static String routePath = '/listvillnow';

  @override
  State<ListvillnowWidget> createState() => _ListvillnowWidgetState();
}

class _ListvillnowWidgetState extends State<ListvillnowWidget> {
  late ListvillnowModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListvillnowModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _selectVillage(VillagesRecord record) {
    FFAppState().villnow = record.reference;
    FFAppState().villtextnow = touryLocalizedVillageLabel(record);
    FFAppState().update(() {});

    context.pushNamed(Checkout66Widget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final countryRef =
        context.select<FFAppState, DocumentReference?>((s) => s.dolh);

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
                title: FFLocalizations.of(context).getText(
                  '63p4f0ub' /* Current city of residence */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.sm,
                        DsSpacing.md,
                        DsSpacing.xs,
                      ),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'tgts4qua' /* Manage your team below. */,
                        ),
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<VillagesRecord>>(
                        stream: countryRef == null
                            ? Stream.value(const <VillagesRecord>[])
                            : TouryFirestoreCache.villagesStream(
                                cacheKey: 'country:${countryRef.path}',
                                queryBuilder: (villagesRecord) => villagesRecord
                                    .where(
                                      'dolh',
                                      isEqualTo: countryRef,
                                    )
                                    .where(
                                      'acctev',
                                      isEqualTo: true,
                                    ),
                              ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return const DsLoading();
                          }
                          List<VillagesRecord> listViewVillagesRecordList =
                              snapshot.data!;

                          if (listViewVillagesRecordList.isEmpty) {
                            return DsEmptyState(
                              icon: DsIcons.location,
                              title: FFLocalizations.of(context).getText(
                                '63p4f0ub' /* Current city of residence */,
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.xs,
                              DsSpacing.md,
                              DsSpacing.xl,
                            ),
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: listViewVillagesRecordList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: DsSpacing.sm),
                            itemBuilder: (context, listViewIndex) {
                              final listViewVillagesRecord =
                                  listViewVillagesRecordList[listViewIndex];
                              return DsFadeSlide(
                                delay: Duration(
                                  milliseconds: 40 * listViewIndex,
                                ),
                                child: _VillageTile(
                                  record: listViewVillagesRecord,
                                  onTap: () =>
                                      _selectVillage(listViewVillagesRecord),
                                ),
                              );
                            },
                          );
                        },
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

/// Single selectable city row with a cached thumbnail.
class _VillageTile extends StatelessWidget {
  const _VillageTile({
    required this.record,
    required this.onTap,
  });

  final VillagesRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final label = touryLocalizedVillageLabel(record);

    return DsCard(
      onTap: onTap,
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarLg,
            height: DsConstants.avatarLg,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: ClipOval(
              child: TouryNetworkImage(
                url: record.img,
                documentId: record.reference.id,
                placeName: label,
                latitude: record.latLing?.latitude,
                longitude: record.latLing?.longitude,
                width: DsConstants.avatarLg,
                height: DsConstants.avatarLg,
                fit: BoxFit.cover,
                fallbackAsset: kTouryImageFallback,
                useBrandedFallback: true,
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.iconMuted,
            size: DsIcons.md,
          ),
        ],
      ),
    );
  }
}
