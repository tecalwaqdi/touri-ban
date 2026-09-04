import '/components/admin_theme_toggle.dart';
import '/components/admin_ui.dart';
import '/core/admin_shell_rules.dart';
import 'menu2_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Responsive admin shell: permanent sidebar on wide screens, drawer on phones.
class AdminLayoutWidget extends StatelessWidget {
  const AdminLayoutWidget({
    super.key,
    required this.scaffoldKey,
    required this.menu2Model,
    required this.updateCallback,
    required this.child,
    this.title,
    this.padContent = true,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Menu2Model menu2Model;
  final VoidCallback updateCallback;
  final Widget child;
  final String? title;
  final bool padContent;

  Widget _buildMenu(BuildContext context) {
    return wrapWithModel(
      model: menu2Model,
      updateCallback: updateCallback,
      child: const Menu2Widget(),
    );
  }

  double _sidebarWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Keep content usable at 1280×800 / tablet landscape with inline sidebar.
    if (w >= 1400) return 280;
    if (w >= 1280) return 260;
    if (w >= 1100) return 240;
    return 220;
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: _sidebarWidth(context),
      height: double.infinity,
      decoration: AdminUi.sidebarGradient(),
      child: _buildMenu(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final inlineSidebar = showAdminInlineSidebar(context);
    final width = MediaQuery.sizeOf(context).width;
    final pageTitle = title ??
        FFLocalizations.of(context).getText(
          'hrrt489c' /* Admin */,
        );
    final contentMax = AdminShellRules.contentMaxWidth(width);

    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.primaryBackground,
      appBar: inlineSidebar
          ? null
          : AppBar(
              backgroundColor: AdminUi.brandTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                  useGoogleFonts: !theme.titleMediumIsCustom,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              actions: const [
                AdminThemeToggle(compact: true, onTealChrome: true),
                SizedBox(width: 4),
              ],
            ),
      drawer: inlineSidebar
          ? null
          : Drawer(
              width: _sidebarWidth(context),
              elevation: 8,
              child: _buildSidebar(context),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inlineSidebar) _buildSidebar(context),
          Expanded(
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: ColoredBox(
                color: theme.primaryBackground,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMax),
                    child: RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: padContent
                                ? Padding(
                                    padding: AdminUi.pagePadding(context),
                                    child: child,
                                  )
                                : child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
