import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'list_v_model.dart';
export 'list_v_model.dart';

class ListVWidget extends StatefulWidget {
  const ListVWidget({super.key});

  @override
  State<ListVWidget> createState() => _ListVWidgetState();
}

class _ListVWidgetState extends State<ListVWidget> {
  late ListVModel _model;
  late final Future<List<VillagesRecord>> _villagesFuture;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListVModel());
    _villagesFuture = queryListCacheFirst(
      VillagesRecord.collection,
      VillagesRecord.fromSnapshot,
      queryBuilder: (q) => q.where('acctev', isEqualTo: true),
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
    return FutureBuilder<List<VillagesRecord>>(
      future: _villagesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'تعذر تحميل المدن',
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
        List<VillagesRecord> listViewVillagesRecordList = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
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
                FFAppState().RevciteTEXT = listViewVillagesRecord.naim;
                FFAppState().REvCITE = listViewVillagesRecord.reference;
                if (listViewVillagesRecord.hasCities()) {
                  FFAppState().Revreg = listViewVillagesRecord.cities;
                }
                if (listViewVillagesRecord.hasDolh()) {
                  FFAppState().RevDolh = listViewVillagesRecord.dolh;
                }
                safeSetState(() {});
                Navigator.pop(context);
              },
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(
                    listViewVillagesRecord.naim,
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).titleLargeFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts:
                              !FlutterFlowTheme.of(context).titleLargeIsCustom,
                        ),
                  ),
                  subtitle: Text(
                    listViewVillagesRecord.osf,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).labelMediumFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts:
                              !FlutterFlowTheme.of(context).labelMediumIsCustom,
                        ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24.0,
                  ),
                  tileColor: FlutterFlowTheme.of(context).secondaryBackground,
                  dense: false,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
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
