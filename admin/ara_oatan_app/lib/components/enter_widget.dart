import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'enter_model.dart';
export 'enter_model.dart';

class EnterWidget extends StatefulWidget {
  const EnterWidget({super.key});

  @override
  State<EnterWidget> createState() => _EnterWidgetState();
}

class _EnterWidgetState extends State<EnterWidget> {
  late EnterModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EnterModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: DsRadius.small,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: DsRadius.small,
          child: const TouryNetworkImage(
            url: '',
            width: 200.0,
            height: 145.0,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
