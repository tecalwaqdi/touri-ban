import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'nodata_model.dart';

export 'nodata_model.dart';

class NodataWidget extends StatefulWidget {
  const NodataWidget({super.key});

  @override
  State<NodataWidget> createState() => _NodataWidgetState();
}

class _NodataWidgetState extends State<NodataWidget> {
  late NodataModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NodataModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      title: FFLocalizations.of(context).getText(
        'zk2cl9lt' /* لم يتم العثور على بيانات */,
      ),
      icon: Icons.error_outline_rounded,
    );
  }
}
