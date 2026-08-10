import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'delet_model.dart';
export 'delet_model.dart';

class DeletWidget extends StatefulWidget {
  const DeletWidget({super.key});

  static String routeName = 'delet';
  static String routePath = '/delet';

  @override
  State<DeletWidget> createState() => _DeletWidgetState();
}

class _DeletWidgetState extends State<DeletWidget> {
  late DeletModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeletModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: FFLocalizations.of(context).getText(
          'pvndpjv4' /* Page Title */,
        ),
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.safePop(),
        ),
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: DsSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              DsFadeSlide(
                child: DsCard(
                  elevated: true,
                  padding: const EdgeInsets.all(DsSpacing.xl),
                  child: DsButton.primary(
                    expanded: true,
                    size: DsButtonSize.lg,
                    label: FFLocalizations.of(context).getText(
                      '9b2nqkbg' /* Button */,
                    ),
                    onPressed: () {
                      print('Button pressed ...');
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
