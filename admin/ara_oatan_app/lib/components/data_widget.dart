import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'data_model.dart';
export 'data_model.dart';

class DataWidget extends StatefulWidget {
  const DataWidget({super.key});

  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  late DataModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DataModel());

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: DsRadius.medium,
        border: Border.all(
          color: colors.border,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        'bnkee1xl' /* Select Travel Date */,
                      ),
                      style: typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'ye9vkch3' /* Choose your preferred departur... */,
                      ),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.calendar_today,
                  color: colors.primary,
                  size: 24.0,
                ),
              ],
            ),
            Container(
              width: double.infinity,
              height: 1.0,
              decoration: BoxDecoration(
                color: colors.divider,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText(
                          '44p4lht3' /* Selected Date */,
                        ),
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          '9ejldyvr' /* March 15, 2024 */,
                        ),
                        style: typography.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120.0,
                  child: DsButton.primary(
                    label: FFLocalizations.of(context).getText(
                      'y7veh8du' /* Change Date */,
                    ),
                    size: DsButtonSize.sm,
                    onPressed: () {
                      print('Button pressed ...');
                    },
                  ),
                ),
              ].divide(DsSpacing.gapXs),
            ),
          ].divide(const SizedBox(height: DsSpacing.sm)),
        ),
      ),
    );
  }
}
