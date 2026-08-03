import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'panel_model.dart';
export 'panel_model.dart';

/// Top Section:
///
/// A centered button at the top labeled: "Add New Landmark".
///
/// Main Section:
///
/// A table displaying the list of added landmarks with the following
/// features:
/// Search Bar: To filter landmarks by keyword.
/// Sorting Options: To organize landmarks by criteria like name, country, or
/// city.
/// Table columns include:
/// Landmark Image
/// Landmark Name
/// Country
/// City
/// Edit Button
/// Delete Button
/// Does this structure meet your needs? Let me know if you need any
/// refinements!
class PanelWidget extends StatefulWidget {
  const PanelWidget({super.key});

  static String routeName = 'panel';
  static String routePath = '/panel';

  @override
  State<PanelWidget> createState() => _PanelWidgetState();
}

class _PanelWidgetState extends State<PanelWidget> {
  late PanelModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PanelModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = FFLocalizations.of(context).getText(
      'dshasjqu' /* Page Title */,
    );

    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: title,
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () async {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        top: true,
        child: DsFadeSlide(
          child: DsEmptyState(
            title: title,
            icon: DsIcons.location,
          ),
        ),
      ),
    );
  }
}
