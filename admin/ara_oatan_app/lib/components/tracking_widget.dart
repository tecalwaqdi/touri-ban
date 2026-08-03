import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'tracking_model.dart';
export 'tracking_model.dart';

/// التتبع
class TrackingWidget extends StatefulWidget {
  const TrackingWidget({
    super.key,
    required this.idorder,
  });

  final DocumentReference? idorder;

  @override
  State<TrackingWidget> createState() => _TrackingWidgetState();
}

class _TrackingWidgetState extends State<TrackingWidget> {
  late TrackingModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackingModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
