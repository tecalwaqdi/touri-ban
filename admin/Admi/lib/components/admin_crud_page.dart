import 'package:flutter/material.dart';

import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Shared CRUD list shell: layout + header + filter bar + body.
class AdminCrudPage extends StatefulWidget {
  const AdminCrudPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.searchHint = 'بحث…',
    this.onSearchChanged,
    this.searchController,
    this.filterChips = const [],
    this.padContent = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? actions;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final List<Widget> filterChips;
  final bool padContent;

  @override
  State<AdminCrudPage> createState() => _AdminCrudPageState();
}

class _AdminCrudPageState extends State<AdminCrudPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: widget.title,
      padContent: widget.padContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            trailing: widget.actions,
          ),
          if (widget.onSearchChanged != null ||
              widget.filterChips.isNotEmpty)
            AdminFilterBar(
              controller: widget.searchController,
              hint: uiTr(context, widget.searchHint),
              onChanged: widget.onSearchChanged,
              chips: widget.filterChips,
            ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
