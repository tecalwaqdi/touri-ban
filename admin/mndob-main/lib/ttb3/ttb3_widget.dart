import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'ttb3_model.dart';
export 'ttb3_model.dart';

class Ttb3Widget extends StatefulWidget {
  const Ttb3Widget({
    super.key,
    required this.ido,
  });

  final DocumentReference? ido;

  static String routeName = 'ttb3';
  static String routePath = '/ttb3';

  @override
  State<Ttb3Widget> createState() => _Ttb3WidgetState();
}

class _Ttb3WidgetState extends State<Ttb3Widget> {
  late Ttb3Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Ttb3Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(widget!.ido!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const DsScreenShell(
            child: DsScreenScaffold(
              body: DsLoading(message: 'Loading trip...'),
            ),
          );
        }

        final ttb3OrderRecord = snapshot.data!;

        return DsScreenShell(
          child: Builder(
            builder: (context) {
              final colors = context.dsColors;

              return DsScreenScaffold(
                scaffoldKey: scaffoldKey,
                resizeToAvoidBottomInset: false,
                appBar: DsAppBar(
                  automaticallyImplyLeading: true,
                  title: FFLocalizations.of(context).getText(
                    '9vw9ln2p' /* Page Title */,
                  ),
                ),
                body: SafeArea(
                  top: true,
                  child: DsCard(
                    margin: DsSpacing.pagePadding,
                    padding: EdgeInsets.zero,
                    elevated: true,
                    child: ClipRRect(
                      borderRadius: DsRadius.large,
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.sizeOf(context).height * 0.72,
                        child: Stack(
                          children: [
                            FlutterFlowGoogleMap(
                              controller: _model.googleMapsController,
                              onCameraIdle: (latLng) =>
                                  _model.googleMapsCenter = latLng,
                              initialLocation: _model.googleMapsCenter ??=
                                  ttb3OrderRecord.mapuser!,
                              markerColor: GoogleMarkerColor.violet,
                              mapType: MapType.normal,
                              style: GoogleMapStyle.standard,
                              initialZoom: 18.0,
                              allowInteraction: true,
                              allowZoom: true,
                              showZoomControls: true,
                              showLocation: true,
                              showCompass: false,
                              showMapToolbar: false,
                              showTraffic: false,
                              centerMapOnMarkerTap: true,
                              mapTakesGesturePreference: false,
                            ),
                            Align(
                              alignment: AlignmentDirectional.center,
                              child: PointerInterceptor(
                                intercepting: isWeb,
                                child: Icon(
                                  Icons.directions_car_sharp,
                                  color: colors.error,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
