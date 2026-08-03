import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'not_addresses_model.dart';

export 'not_addresses_model.dart';

/// A message stating that the user has not added any addresses
class NotAddressesWidget extends StatefulWidget {
  const NotAddressesWidget({super.key});

  @override
  State<NotAddressesWidget> createState() => _NotAddressesWidgetState();
}

class _NotAddressesWidgetState extends State<NotAddressesWidget> {
  late NotAddressesModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotAddressesModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: DsEmptyState(
        title: FFLocalizations.of(context).getText(
          'clz0j4ow' /* No Addresses Found */,
        ),
        message: FFLocalizations.of(context).getText(
          'wzjesk7u' /* You haven't added any addresse... */,
        ),
        icon: Icons.location_off_rounded,
      ),
    );
  }
}
