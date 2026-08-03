import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_cache_picker.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Clears dependent location picks when the country changes.
void clearRegionAndCitySelection() {
  FFAppState().Revreg = null;
  FFAppState().RevRegTEXT = '';
  FFAppState().REvCITE = null;
  FFAppState().RevciteTEXT = '';
}

/// Clears city pick when the region changes.
void clearCitySelection() {
  FFAppState().REvCITE = null;
  FFAppState().RevciteTEXT = '';
}

/// Picker for countries ([CountriesRecord]) — sets [FFAppState().RevDolh].
class AdminCountryPickerSheet extends StatelessWidget {
  const AdminCountryPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            appTr(context, 'adm_pick_country'),
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              fontWeight: FontWeight.w700,
              color: AdminUi.brandTeal,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AdminCacheRecordList<CountriesRecord>(
            query: CountriesRecord.collection,
            recordBuilder: CountriesRecord.fromSnapshot,
            queryBuilder: (q) => q.orderBy('naim'),
            searchHint: appTr(context, 'adm_search_country'),
            emptyMessage: appTr(context, 'adm_no_countries'),
            filter: (country, q) =>
                country.naim.toLowerCase().contains(q) ||
                country.osf.toLowerCase().contains(q),
            itemBuilder: (context, country) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    side: BorderSide(color: theme.alternate),
                  ),
                  tileColor: theme.secondaryBackground,
                  leading: CircleAvatar(
                    backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.public_rounded,
                      color: AdminUi.brandTeal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    country.naim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: country.osf.isNotEmpty
                      ? Text(
                          country.osf,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    clearRegionAndCitySelection();
                    FFAppState().RevDolh = country.reference;
                    FFAppState().RevdolhTEXT = country.naim;
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Picker for regions ([CitiesRecord]) — sets [FFAppState().Revreg].
class AdminRegionPickerSheet extends StatelessWidget {
  const AdminRegionPickerSheet({
    super.key,
    this.countryRef,
  });

  final DocumentReference? countryRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final country =
        countryRef ?? FFAppState().RevDolh ?? AdminCountryScope.activeCountryRef;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appTr(context, 'adm_pick_region'),
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.brandTeal,
                  useGoogleFonts: !theme.titleMediumIsCustom,
                ),
              ),
              if (country == null) ...[
                const SizedBox(height: 6),
                Text(
                  appTr(context, 'adm_pick_country_filter_regions'),
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: country == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      appTr(context, 'adm_no_regions_pick_country'),
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium,
                    ),
                  ),
                )
              : AdminCacheRecordList<CitiesRecord>(
                  query: CitiesRecord.collection,
                  recordBuilder: CitiesRecord.fromSnapshot,
                  queryBuilder: (q) => q
                      .where('acctev', isEqualTo: true)
                      .where('dolh', isEqualTo: country),
                  searchHint: appTr(context, 'adm_search_region'),
                  emptyMessage: appTr(context, 'adm_no_regions_country'),
                  filter: (region, q) =>
                      region.naim.toLowerCase().contains(q) ||
                      region.osf.toLowerCase().contains(q),
                  itemBuilder: (context, region) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AdminUi.radiusSm),
                          side: BorderSide(color: theme.alternate),
                        ),
                        tileColor: theme.secondaryBackground,
                        leading: CircleAvatar(
                          backgroundColor:
                              AdminUi.brandTeal.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.filter_hdr_rounded,
                            color: AdminUi.brandTeal,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          region.naim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: region.osf.isNotEmpty
                            ? Text(
                                region.osf,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () async {
                          clearCitySelection();
                          FFAppState().Revreg = region.reference;
                          FFAppState().RevRegTEXT = region.naim;
                          if (region.dolh != null) {
                            FFAppState().RevDolh = region.dolh;
                            try {
                              final countryDoc =
                                  await CountriesRecord.getDocumentOnce(
                                region.dolh!,
                              );
                              FFAppState().RevdolhTEXT = countryDoc.naim;
                            } catch (_) {}
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Picker for cities ([VillagesRecord]) — sets [FFAppState().REvCITE].
class AdminCityPickerSheet extends StatelessWidget {
  const AdminCityPickerSheet({
    super.key,
    this.regionRef,
    this.countryRef,
  });

  final DocumentReference? regionRef;
  final DocumentReference? countryRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final region = regionRef ?? FFAppState().Revreg;
    final country =
        countryRef ?? FFAppState().RevDolh ?? AdminCountryScope.activeCountryRef;
    final scopedToCountry = AdminRoleService.isCountryAgent ||
        AdminCountryScope.hasActiveCountryScope ||
        country != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appTr(context, 'adm_pick_city'),
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.brandTeal,
                  useGoogleFonts: !theme.titleMediumIsCustom,
                ),
              ),
              if (region == null && scopedToCountry && country != null) ...[
                const SizedBox(height: 6),
                Text(
                  appTr(context, 'adm_agent_cities_only'),
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
              ] else if (region == null) ...[
                const SizedBox(height: 6),
                Text(
                  appTr(context, 'adm_region_filter_cities'),
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AdminCacheRecordList<VillagesRecord>(
            query: VillagesRecord.collection,
            recordBuilder: VillagesRecord.fromSnapshot,
            queryBuilder: (q) => AdminCountryScope.applyVillagePickerQuery(
              q as Query<Map<String, dynamic>>,
              regionRef: region,
              countryRef: country,
            ),
            searchHint: appTr(context, 'adm_search_city'),
            emptyMessage: region == null
                ? (scopedToCountry
                    ? appTr(context, 'adm_no_cities_agent_country')
                    : appTr(context, 'adm_no_cities'))
                : appTr(context, 'adm_no_cities_in_region'),
            filter: (city, q) =>
                city.naim.toLowerCase().contains(q) ||
                city.osf.toLowerCase().contains(q),
            itemBuilder: (context, city) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    side: BorderSide(color: theme.alternate),
                  ),
                  tileColor: theme.secondaryBackground,
                  leading: CircleAvatar(
                    backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AdminUi.brandTeal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    city.naim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: city.osf.isNotEmpty
                      ? Text(
                          city.osf,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    FFAppState().REvCITE = city.reference;
                    FFAppState().RevciteTEXT = city.naim;
                    if (city.cities != null) {
                      FFAppState().Revreg = city.cities;
                    }
                    if (city.dolh != null) {
                      FFAppState().RevDolh = city.dolh;
                    }
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Picker for driver work city — sets [FFAppState().workcite].
class AdminWorkCityPickerSheet extends StatelessWidget {
  const AdminWorkCityPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            appTr(context, 'adm_pick_work_city'),
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              fontWeight: FontWeight.w700,
              color: AdminUi.brandTeal,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AdminCacheRecordList<VillagesRecord>(
            query: VillagesRecord.collection,
            recordBuilder: VillagesRecord.fromSnapshot,
            queryBuilder: (q) {
              var query =
                  (q as Query<Map<String, dynamic>>).where('acctev', isEqualTo: true);
              final country = AdminCountryScope.activeCountryRef;
              if (country != null) {
                query = query.where('dolh', isEqualTo: country);
              }
              return query;
            },
            searchHint: appTr(context, 'adm_search_work_city'),
            emptyMessage: appTr(context, 'adm_no_cities'),
            filter: (city, q) => city.naim.toLowerCase().contains(q),
            itemBuilder: (context, city) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    side: BorderSide(color: theme.alternate),
                  ),
                  tileColor: theme.secondaryBackground,
                  leading: CircleAvatar(
                    backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AdminUi.brandTeal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    city.naim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    FFAppState().workcite = city.reference;
                    FFAppState().workciteText = city.naim;
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Picker for car types — sets [FFAppState().RefTepeCar].
class AdminTypeCarPickerSheet extends StatelessWidget {
  const AdminTypeCarPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            appTr(context, 'adm_pick_car_type'),
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              fontWeight: FontWeight.w700,
              color: AdminUi.brandTeal,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AdminCacheRecordList<TypeCarRecord>(
            query: TypeCarRecord.collection,
            recordBuilder: TypeCarRecord.fromSnapshot,
            queryBuilder: (q) => q.where('actev', isEqualTo: true),
            searchHint: appTr(context, 'adm_search_car_type'),
            emptyMessage: appTr(context, 'adm_no_car_types'),
            filter: (type, q) => type.naim.toLowerCase().contains(q),
            itemBuilder: (context, type) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    side: BorderSide(color: theme.alternate),
                  ),
                  tileColor: theme.secondaryBackground,
                  leading: CircleAvatar(
                    backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: AdminUi.brandTeal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    type.naim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    appTrFormat(context, 'adm_price_per_hour', type.sr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    FFAppState().RefTepeCar = type.reference;
                    FFAppState().typeCarText = type.naim;
                    FFAppState().srtypecar = type.sr;
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
