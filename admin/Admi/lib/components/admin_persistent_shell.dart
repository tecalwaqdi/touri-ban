import 'package:flutter/material.dart';

import '/backend/admin_auth_session_owner.dart';
import '/backend/admin_perf_trace.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_shell_scope.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Authenticated panel chrome mounted once; [child] is the GoRouter outlet.
class AdminPersistentShell extends StatefulWidget {
  const AdminPersistentShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminPersistentShell> createState() => _AdminPersistentShellState();
}

class _AdminPersistentShellState extends State<AdminPersistentShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    AdminAuthSessionOwner.ensureStarted();
    AdminPerfTrace.shellMount();
  }

  @override
  void dispose() {
    AdminPerfTrace.shellDispose();
    _menu2Model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellScope(
      child: AdminLayoutWidget(
        scaffoldKey: _scaffoldKey,
        menu2Model: _menu2Model,
        updateCallback: () {
          if (mounted) setState(() {});
        },
        padContent: false,
        forceFullChrome: true,
        child: widget.child,
      ),
    );
  }
}
