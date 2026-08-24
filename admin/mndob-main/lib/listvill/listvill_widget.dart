import '/components/villmndob_widget.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'listvill_model.dart';
export 'listvill_model.dart';

/// قائمة مدن العمل
class ListvillWidget extends StatefulWidget {
  const ListvillWidget({super.key});

  static String routeName = 'listvill';
  static String routePath = '/listvill';

  @override
  State<ListvillWidget> createState() => _ListvillWidgetState();
}

class _ListvillWidgetState extends State<ListvillWidget> {
  late ListvillModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListvillModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: colors.scaffold,
            appBar: DriverMainAppBar(
              title: FFLocalizations.of(context).getText(
                '95qjz8fm' /* Page Title */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: DriverContentWidth(
                child: DriverPagePadding(
                  child: DsCard(
                    elevated: true,
                    padding: EdgeInsets.zero,
                    child: wrapWithModel(
                      model: _model.villmndobModel,
                      updateCallback: () => safeSetState(() {}),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.75,
                        child: const VillmndobWidget(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
