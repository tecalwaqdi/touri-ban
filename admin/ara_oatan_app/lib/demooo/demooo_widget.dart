import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'demooo_model.dart';
export 'demooo_model.dart';

class DemoooWidget extends StatefulWidget {
  const DemoooWidget({super.key});

  static String routeName = 'demooo';
  static String routePath = '/demooo';

  @override
  State<DemoooWidget> createState() => _DemoooWidgetState();
}

class _DemoooWidgetState extends State<DemoooWidget> {
  late DemoooModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DemoooModel());

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

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: FFLocalizations.of(context).getText(
                  'uwfdiwwf' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: DsFadeSlide(
                  child: DsEmptyState(
                    title: FFLocalizations.of(context).getText(
                      'uwfdiwwf' /* Page Title */,
                    ),
                    icon: DsIcons.info,
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
