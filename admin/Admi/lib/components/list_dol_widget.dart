import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_region_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'list_dol_model.dart';
export 'list_dol_model.dart';

class ListDolWidget extends StatefulWidget {
  const ListDolWidget({super.key});

  @override
  State<ListDolWidget> createState() => _ListDolWidgetState();
}

class _ListDolWidgetState extends State<ListDolWidget> {
  late ListDolModel _model;
  late final Future<List<CountriesRecord>> _countriesFuture;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListDolModel());
    _countriesFuture = queryListCacheFirst(
      CountriesRecord.collection,
      CountriesRecord.fromSnapshot,
      queryBuilder: (q) => q.orderBy('naim'),
      limit: kAdminPickerLimit,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 4.0,
                color: Color(0x1A000000),
                offset: Offset(
                  0.0,
                  2.0,
                ),
                spreadRadius: 0.0,
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            child: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'owx1rxme' /* Select Your Country */,
                    ),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).headlineSmallFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts: !FlutterFlowTheme.of(context)
                              .headlineSmallIsCustom,
                        ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'orswrk5u' /* Choose from the list of availa... */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).bodyMediumFamily,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          useGoogleFonts:
                              !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                        ),
                  ),
                  FutureBuilder<List<CountriesRecord>>(
                    future: _countriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'تعذر تحميل الدول',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 55.0,
                            height: 55.0,
                            child: SpinKitThreeBounce(
                              color: FlutterFlowTheme.of(context).primary,
                              size: 55.0,
                            ),
                          ),
                        );
                      }
                      List<CountriesRecord> listViewCountriesRecordList =
                          snapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: listViewCountriesRecordList.length,
                        itemBuilder: (context, listViewIndex) {
                          final listViewCountriesRecord =
                              listViewCountriesRecordList[listViewIndex];
                          return InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              clearRegionAndCitySelection();
                              FFAppState().RevDolh =
                                  listViewCountriesRecord.reference;
                              FFAppState().RevdolhTEXT =
                                  listViewCountriesRecord.naim;
                              safeSetState(() {});
                              Navigator.pop(context);
                            },
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Text(
                                  listViewCountriesRecord.naim,
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleLargeIsCustom,
                                      ),
                                ),
                                subtitle: Text(
                                  listViewCountriesRecord.osf,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                tileColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                dense: false,
                                contentPadding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 12.0, 0.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ].divide(SizedBox(height: 12.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
