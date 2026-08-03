import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'listtypecar_model.dart';
export 'listtypecar_model.dart';

class ListtypecarWidget extends StatefulWidget {
  const ListtypecarWidget({super.key});

  @override
  State<ListtypecarWidget> createState() => _ListtypecarWidgetState();
}

class _ListtypecarWidgetState extends State<ListtypecarWidget> {
  late ListtypecarModel _model;
  late final Future<List<TypeCarRecord>> _carsFuture;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListtypecarModel());
    _carsFuture = queryListCacheFirst(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: (q) =>
          q.where('actev', isEqualTo: true).orderBy('sr'),
      limit: 80,
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
    return FutureBuilder<List<TypeCarRecord>>(
      future: _carsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'تعذر تحميل أنواع السيارات',
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
        List<TypeCarRecord> listViewTypeCarRecordList = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: listViewTypeCarRecordList.length,
          itemBuilder: (context, listViewIndex) {
            final listViewTypeCarRecord =
                listViewTypeCarRecordList[listViewIndex];
            return InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                FFAppState().RefTepeCar = listViewTypeCarRecord.reference;
                FFAppState().typeCarText = listViewTypeCarRecord.naim;
                safeSetState(() {});
                Navigator.pop(context);
              },
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(
                    listViewTypeCarRecord.naim,
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).titleLargeFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts:
                              !FlutterFlowTheme.of(context).titleLargeIsCustom,
                        ),
                  ),
                  subtitle: Text(
                    formatNumber(
                      listViewTypeCarRecord.sr,
                      formatType: FormatType.decimal,
                      decimalType: DecimalType.automatic,
                      currency: 'ريال ',
                    ),
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
