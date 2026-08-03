import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'home_plus_model.dart';
export 'home_plus_model.dart';

class HomePlusWidget extends StatefulWidget {
  const HomePlusWidget({super.key});

  static String routeName = 'HomePlus';
  static String routePath = '/homePlus';

  @override
  State<HomePlusWidget> createState() => _HomePlusWidgetState();
}

class _HomePlusWidgetState extends State<HomePlusWidget> {
  late HomePlusModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePlusModel());

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
                  'ttsf2ta8' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
                actions: const [],
              ),
              body: SafeArea(
                top: true,
                child: DsFadeSlide(
                  child: DsEmptyState(
                    title: FFLocalizations.of(context).getText(
                      'ttsf2ta8' /* Page Title */,
                    ),
                    icon: DsIcons.home,
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
