import '/backend/backend.dart';
import '/core/toury_mkan_i18n.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'locesh_tf_model.dart';
export 'locesh_tf_model.dart';

class LoceshTfWidget extends StatefulWidget {
  const LoceshTfWidget({
    super.key,
    required this.mkann,
  });

  final MkanRecord? mkann;

  @override
  State<LoceshTfWidget> createState() => _LoceshTfWidgetState();
}

class _LoceshTfWidgetState extends State<LoceshTfWidget> {
  late LoceshTfModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoceshTfModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Align(
      alignment: const AlignmentDirectional(0.0, -1.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Align(
            alignment: const AlignmentDirectional(0.0, 1.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surface,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0, DsSpacing.sm, 0.0, DsSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120.0,
                      decoration: const BoxDecoration(),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            DsSpacing.sm, DsSpacing.xs, DsSpacing.sm, DsSpacing.xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      DsSpacing.sm, 0.0, 0.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: DsRadius.extraSmall,
                                        child: TouryNetworkImage(
                                          url: widget.mkann!.img1,
                                          width: 111.0,
                                          height: 366.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 60.0,
                      decoration: const BoxDecoration(),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            DsSpacing.sm, DsSpacing.xs, DsSpacing.sm, DsSpacing.xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    DsSpacing.sm, 0.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                      valueOrDefault<String>(
                                        widget.mkann == null
                                            ? null
                                            : touryMkanName(
                                                context, widget.mkann!),
                                        '-',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.labelLarge.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
