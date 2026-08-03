import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'dfddf_model.dart';
export 'dfddf_model.dart';

class DfddfWidget extends StatefulWidget {
  const DfddfWidget({super.key});

  static String routeName = 'dfddf';
  static String routePath = '/dfddf';

  @override
  State<DfddfWidget> createState() => _DfddfWidgetState();
}

class _DfddfWidgetState extends State<DfddfWidget> {
  late DfddfModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DfddfModel());

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
          return DsScreenScaffold(
            scaffoldKey: scaffoldKey,
            appBar: DsAppBar(
              automaticallyImplyLeading: true,
              title: FFLocalizations.of(context).getText(
                'vpmhafpj' /* Page Title */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: Padding(
                padding: DsSpacing.pagePadding,
                child: DsEmptyState(
                  title: FFLocalizations.of(context).getText(
                    'vpmhafpj' /* Page Title */,
                  ),
                  message: 'No content yet',
                  icon: Icons.dashboard_outlined,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
