from pathlib import Path

path = Path(r"d:\Projects\ara\admin\ara_oatan_app\lib\app\citie2\citie2_widget.dart")
text = path.read_text(encoding="utf-8")

# Replace hero + map + regions stream opening through snapshot.hasData check
old_start = """                SizedBox(
                  width: double.infinity,
                  height: TouryLayout.countryHeroHeight(context),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.coun != null)
                        TouryCountryHeroBanner(
                          countryRef: widget.coun!,
                          height: TouryLayout.countryHeroHeight(context),
                        )
                      else
                        TouryNetworkImage(
                          url: widget.imgDolh,
                          width: double.infinity,
                          height: TouryLayout.countryHeroHeight(context),
                          fit: BoxFit.cover,
                        ),"""

if old_start not in text:
    raise SystemExit("hero start not found")

# Replace from hero SizedBox through query builder - keep list item UI
old_query = """                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0, 16.0, 0.0, 52.0),
                  child: StreamBuilder<List<CitiesRecord>>(
                    stream: queryCitiesRecord(
                      queryBuilder: (citiesRecord) => citiesRecord
                          .where(
                            'dolh',
                            isEqualTo: widget.coun,
                          )
                          .where(
                            'acctev',
                            isEqualTo: true,
                          )
                          .orderBy('sorting'),
                    ),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: SpinKitChasingDots(
                              color: FlutterFlowTheme.of(context).primary,
                              size: 50.0,
                            ),
                          ),
                        );
                      }
                      List<CitiesRecord> columnCitiesRecordList =
                          snapshot.data!;

                      return Column("""

if old_query not in text:
    raise SystemExit("query block not found")

new_prefix = r'''                SizedBox(
                  width: double.infinity,
                  height: TouryLayout.countryHeroHeight(context),
                  child: InkWell(
                    onTap: _openCountryPicker,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_activeCountryRef != null)
                          TouryCountryHeroBanner(
                            countryRef: _activeCountryRef!,
                            height: TouryLayout.countryHeroHeight(context),
                          )
                        else
                          TouryNetworkImage(
                            url: _activeCountryImg ?? widget.imgDolh,
                            width: double.infinity,
                            height: TouryLayout.countryHeroHeight(context),
                            fit: BoxFit.cover,
                          ),
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0x9A1D2428),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 64.0, 16.0, 12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 80.h),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          valueOrDefault<String>(
                                            _activeCountryName ?? widget.naim,
                                            '-',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .displaySmall
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .displaySmallFamily,
                                                color: Colors.white,
                                                fontSize: 18.0,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(context)
                                                        .displaySmallIsCustom,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'tap_to_change_country'.tr(),
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodySmallFamily,
                                        color: Colors.white70,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodySmallIsCustom,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_activeCountryRef != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0,
                      16.0,
                      16.0,
                      0.0,
                    ),
                    child: FutureBuilder<CountriesRecord>(
                      future:
                          CountriesRecord.getDocumentOnce(_activeCountryRef!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text('loading_country_map'.tr()),
                          );
                        }
                        final country = snapshot.data!;
                        final center = _resolveCountryMapCenter(country);
                        final iso = TouryCountryRegistry.normalizeIso(
                                country.isoCode) ??
                            TouryCountryRegistry.normalizeIso(
                                country.reference.id) ??
                            _activeCountryIso;
                        if (center == null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('country_map_missing_center'.tr()),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'country_map'.tr(),
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .titleMediumFamily,
                                    fontWeight: FontWeight.w700,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .titleMediumIsCustom,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TouryMapPanel(
                              key: ValueKey(
                                  'country-map-$iso-${country.reference.id}'),
                              controller: _countryMapController,
                              initialLocation: center,
                              countryIso2: iso,
                              height: 220,
                              initialZoom: _countryMapZoom(country),
                              showCenterPin: false,
                              showMyLocation: false,
                              borderRadius: 8,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 16.0, 0.0, 0.0),
                  child: Text(
                    "List of regions".tr(),
                    style: FlutterFlowTheme.of(context).labelLarge.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).labelLargeFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts:
                              !FlutterFlowTheme.of(context).labelLargeIsCustom,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0, 16.0, 0.0, 52.0),
                  child: _activeCountryRef == null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('select_country_manual'.tr()),
                        )
                      : StreamBuilder<List<CitiesRecord>>(
                          stream: queryCitiesRecord(
                            queryBuilder: (citiesRecord) {
                              final refs = TouryCountryRegistry
                                  .regionCountryRefs(_activeCountryRef!);
                              return citiesRecord
                                  .whereIn('dolh', refs)
                                  .where('acctev', isEqualTo: true)
                                  .orderBy('sorting');
                            },
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text('regions_load_error'.tr()),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () => safeSetState(() {}),
                                      child: Text('retry'.tr()),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: SpinKitChasingDots(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 50.0,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('loading_regions'.tr()),
                                  ],
                                ),
                              );
                            }
                            List<CitiesRecord> columnCitiesRecordList =
                                snapshot.data!;
                            final seen = <String>{};
                            columnCitiesRecordList =
                                columnCitiesRecordList.where((r) {
                              final key = r.naim.trim().toLowerCase();
                              if (key.isEmpty) return true;
                              if (seen.contains(key)) return false;
                              seen.add(key);
                              return true;
                            }).toList();
                            if (columnCitiesRecordList.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text('regions_empty'.tr()),
                              );
                            }

                            return Column('''

# Find slice from first SizedBox hero to old_query inclusive, replace
idx_hero = text.index(old_start)
idx_query = text.index(old_query)
# Also need to remove the old hero+map+list header that sits between hero start and query
# Actually old_start is only first part of hero; we need to cut from old_start through end of old_query
end = idx_query + len(old_query)
new_text = text[:idx_hero] + new_prefix + text[end:]

# Remove leftover old hero middle (Container overlay etc) — check if orphaned
# After replacement, there should be no duplicate "if (widget.coun != null)" map block
if "isEqualTo: widget.coun" in new_text:
    raise SystemExit("old query still present")
if "if (widget.coun != null)" in new_text and "TouryCountryHeroBanner" in new_text[new_text.index("TouryCountryHeroBanner")-200:new_text.index("TouryCountryHeroBanner")+50]:
    # may still have widget.coun elsewhere - ok
    pass

# Fix StreamBuilder closing parens: we added ternary so need one more closing paren before Padding ends
# Original: child: StreamBuilder(...),  then ), for Padding
# Now: child: _activeCountryRef == null ? ... : StreamBuilder(...),  — StreamBuilder still closes with ), then need )
# Look at closing after list generate

path.write_text(new_text, encoding="utf-8")
print("patched ok, length", len(new_text))
# verify balance around the regions section
snippet = new_text[idx_hero:idx_hero+500]
print(snippet[:200])

