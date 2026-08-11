import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'msg_no_adresd_model.dart';

export 'msg_no_adresd_model.dart';

/// إشعار لم يتم إضافة عناوين رسالة
class MsgNoAdresdWidget extends StatefulWidget {
  const MsgNoAdresdWidget({super.key});

  static String routeName = 'msg_no_adresd';
  static String routePath = '/msgNoAdresd';

  @override
  State<MsgNoAdresdWidget> createState() => _MsgNoAdresdWidgetState();
}

class _MsgNoAdresdWidgetState extends State<MsgNoAdresdWidget> {
  late MsgNoAdresdModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MsgNoAdresdModel());

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
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: FFLocalizations.of(context).getText(
                  '33gqwkhk' /* الإشعارات */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () {
                    context.safePop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: DsFadeSlide(
                  child: DsEmptyState(
                    icon: Icons.location_off_rounded,
                    title: FFLocalizations.of(context).getText(
                      'vme17tdg' /* لم يتم إضافة أي عناوين */,
                    ),
                    message: FFLocalizations.of(context).getText(
                      'yrkeiz97' /* قم بإضافة عنوان جديد للمتابعة */,
                    ),
                    action: DsButton.primary(
                      label: FFLocalizations.of(context).getText(
                        'hy0wvvcv' /* إضافة عنوان جديد */,
                      ),
                      icon: Icons.add_location_alt_rounded,
                      size: DsButtonSize.lg,
                      expanded: true,
                      onPressed: () {
                        debugPrint('Button pressed ...');
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
