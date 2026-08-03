import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'mndob_model.dart';
export 'mndob_model.dart';

class MndobWidget extends StatefulWidget {
  const MndobWidget({super.key});

  static String routeName = 'mndob';
  static String routePath = '/mndob';

  @override
  State<MndobWidget> createState() => _MndobWidgetState();
}

class _MndobWidgetState extends State<MndobWidget> {
  late MndobModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MndobModel());

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
                  'adgdgwm4' /* Page Title */,
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
                      'adgdgwm4' /* Page Title */,
                    ),
                    icon: DsIcons.profile,
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
