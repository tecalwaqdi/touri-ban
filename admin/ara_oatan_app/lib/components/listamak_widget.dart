import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/toury_landmark_cart.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'listamak_model.dart';
export 'listamak_model.dart';

/// قائمة الاماكن المضافة
class ListamakWidget extends StatefulWidget {
  const ListamakWidget({super.key});

  @override
  State<ListamakWidget> createState() => _ListamakWidgetState();
}

class _ListamakWidgetState extends State<ListamakWidget> {
  late ListamakModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListamakModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Stack(
      children: [
        Builder(
          builder: (context) {
            final mkss = FFAppState().cartmkss.toList();

            return ListView.separated(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DsSpacing.sm,
                DsSpacing.sm,
                DsSpacing.sm,
                72,
              ),
              itemCount: mkss.length,
              separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.sm),
              itemBuilder: (context, mkssIndex) {
                final mkssItem = mkss[mkssIndex];
                return DsCard(
                  elevated: true,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DsSpacing.md,
                    DsSpacing.sm + 2,
                    DsSpacing.sm,
                    DsSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: DsRadius.medium,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${mkssIndex + 1}',
                          style: typography.titleSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Text(
                          mkssItem.naim,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.titleSmall.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.xs),
                      Material(
                        color: colors.error.withValues(alpha: 0.10),
                        borderRadius: DsRadius.medium,
                        child: InkWell(
                          borderRadius: DsRadius.medium,
                          onTap: () async {
                            touryRemoveLandmarkFromCart(
                              context: context,
                              item: mkssItem,
                              onChanged: () => safeSetState(() {}),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: colors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'landmark_remove'.tr(),
                                  style: typography.labelMedium.copyWith(
                                    color: colors.error,
                                    fontWeight: FontWeight.w700,
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
              },
            );
          },
        ),
        Align(
          alignment: const AlignmentDirectional(0.07, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.md),
            child: DsButton.primary(
              label: FFLocalizations.of(context).getText(
                'uakk50nl' /* Book now */,
              ),
              icon: Icons.done,
              size: DsButtonSize.sm,
              onPressed: () async {
                context.pushNamed(DemoDWidget.routeName);
              },
            ),
          ),
        ),
      ],
    );
  }
}
