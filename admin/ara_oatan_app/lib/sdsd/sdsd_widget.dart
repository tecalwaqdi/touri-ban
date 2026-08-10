import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'sdsd_model.dart';
export 'sdsd_model.dart';

/// Create a FlutterFlow page titled "Success Partner Registration" with the
/// following elements:
///
/// - At the top, a welcoming headline: "Welcome to Become a Success Partner"
/// - Below the headline, a short paragraph explaining the benefits:
///   "Join us as a Success Partner to enhance our service quality and
/// accelerate outreach, whether you are a government entity, a company, or an
/// individual."
/// - Use clear and friendly language.
///
/// - Add a visually appealing icon or illustration related to partnership or
/// growth near the text.
/// - Below the explanation, include a prominent button labeled "Register
/// Now".
/// - The page design should be clean, professional, and inviting, with
/// sufficient padding and modern typography.
/// - Use soft background colors and rounded corners for a friendly look.
/// - Center all content vertically and horizontally on the page.
class SdsdWidget extends StatefulWidget {
  const SdsdWidget({super.key});

  static String routeName = 'sdsd';
  static String routePath = '/sdsd';

  @override
  State<SdsdWidget> createState() => _SdsdWidgetState();
}

class _SdsdWidgetState extends State<SdsdWidget> {
  late SdsdModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SdsdModel());

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
                  'o0w2rk44' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
                actions: const [],
              ),
              body: SafeArea(
                top: true,
                child: DsFadeSlide(
                  child: DsEmptyState(
                    title: FFLocalizations.of(context).getText(
                      'o0w2rk44' /* Page Title */,
                    ),
                    icon: Icons.handshake_outlined,
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
