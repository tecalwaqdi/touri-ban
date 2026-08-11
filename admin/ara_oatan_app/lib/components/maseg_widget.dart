import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'maseg_model.dart';
export 'maseg_model.dart';

class MasegWidget extends StatefulWidget {
  const MasegWidget({
    super.key,
    required this.naim,
  });

  final String? naim;

  @override
  State<MasegWidget> createState() => _MasegWidgetState();
}

class _MasegWidgetState extends State<MasegWidget> {
  late MasegModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MasegModel());

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
    final typography = DsTypography.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.success,
              borderRadius: DsRadius.medium,
              boxShadow: DsShadows.soft(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  DsIcons.success,
                  color: colors.onSuccess,
                  size: DsIcons.md,
                ),
                const SizedBox(width: DsSpacing.sm),
                Flexible(
                  child: Text(
                    FFLocalizations.of(context).getText(
                      'y7mh462y' /* تمت الإضافة بنجاح */,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyMedium.copyWith(
                      color: colors.onSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: DsSpacing.xs),
                Text(
                  valueOrDefault<String>(
                    widget.naim,
                    'رحلة',
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSuccess,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
