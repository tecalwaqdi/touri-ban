import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'card18_workout_model.dart';
export 'card18_workout_model.dart';

class Card18WorkoutWidget extends StatefulWidget {
  const Card18WorkoutWidget({
    super.key,
    required this.nnn,
  });

  final MkanRecord? nnn;

  @override
  State<Card18WorkoutWidget> createState() => _Card18WorkoutWidgetState();
}

class _Card18WorkoutWidgetState extends State<Card18WorkoutWidget> {
  late Card18WorkoutModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Card18WorkoutModel());

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
    final isDark = context.dsIsDark;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DsSpacing.sm, DsSpacing.xs, 0.0, DsSpacing.xs),
      child: Container(
        width: 220.0,
        height: 350.0,
        decoration: BoxDecoration(
          color: colors.card,
          boxShadow: DsShadows.soft(dark: isDark),
          borderRadius: DsRadius.medium,
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(DsSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: DsRadius.small,
                    child: TouryNetworkImage(
                      url: widget.nnn!.img1,
                      width: double.infinity,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, DsSpacing.xs, 0.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(
                        widget.nnn?.naim,
                        '-',
                      ),
                      style: typography.bodyLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                context.pushNamed(
                  PlacedetailsWidget.routeName,
                  queryParameters: {
                    'mk': serializeParam(
                      widget.nnn?.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              },
              child: Container(
                width: double.infinity,
                height: 44.0,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: DsRadius.mdRadius,
                    bottomRight: DsRadius.mdRadius,
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
                ),
                alignment: const AlignmentDirectional(0.0, 0.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    'vnskola4' /* the details */,
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
