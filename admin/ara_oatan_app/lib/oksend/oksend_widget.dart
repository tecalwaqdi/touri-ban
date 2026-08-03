import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'oksend_model.dart';

export 'oksend_model.dart';

/// صفحة تم إرسال طلبك بنجاح مع زر إستعراض طلبي
class OksendWidget extends StatefulWidget {
  const OksendWidget({super.key});

  static String routeName = 'oksend';
  static String routePath = '/oksend';

  @override
  State<OksendWidget> createState() => _OksendWidgetState();
}

class _OksendWidgetState extends State<OksendWidget> {
  late OksendModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OksendModel());

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
              body: SafeArea(
                top: true,
                child: DsScaleFade(
                  child: DsSuccessState(
                    title: FFLocalizations.of(context).getText(
                      'qfk6mdxe' /* Your request has been successf... */,
                    ),
                    message: FFLocalizations.of(context).getText(
                      'sjwiiogz' /* You can track the status of yo... */,
                    ),
                    action: DsButton.primary(
                      label: FFLocalizations.of(context).getText(
                        'eahtmp01' /* View Orders */,
                      ),
                      icon: DsIcons.bookings,
                      size: DsButtonSize.lg,
                      onPressed: () async {
                        context.pushNamed(
                          List22TaskOverviewResponsiveWidget.routeName,
                        );
                      },
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
