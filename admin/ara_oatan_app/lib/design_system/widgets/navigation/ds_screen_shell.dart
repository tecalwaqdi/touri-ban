import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../extensions/ds_context_extensions.dart';
import '../../theme/ds_theme.dart';

/// Applies Tory Taxi Design System theme for a single screen subtree.
///
/// Use at the root of each redesigned page so DS tokens work even when
/// [DsTheme] is not yet wired into [MaterialApp].
class DsScreenShell extends StatelessWidget {
  const DsScreenShell({
    super.key,
    required this.child,
    this.annotateSystemUi = true,
  });

  final Widget child;
  final bool annotateSystemUi;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dsTheme =
        brightness == Brightness.dark ? DsTheme.dark() : DsTheme.light();

    Widget content = Theme(
      data: dsTheme,
      child: Builder(builder: (context) => child),
    );

    if (!annotateSystemUi) return content;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: content,
    );
  }
}

/// Convenience scaffold chrome using DS tokens.
class DsScreenScaffold extends StatelessWidget {
  const DsScreenScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.scaffoldKey,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: context.dsColors.scaffold,
          appBar: appBar,
          drawer: drawer,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: body,
        ),
      ),
    );
  }
}
