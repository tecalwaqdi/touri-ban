import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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
        Stack(
          children: [
            Builder(
              builder: (context) {
                final mkss = FFAppState().cartmkss.toList();

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: List.generate(mkss.length, (mkssIndex) {
                      final mkssItem = mkss[mkssIndex];
                      return ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                DsSpacing.sm, 6.0, DsSpacing.sm, 6.0),
                            child: DsCard(
                              elevated: true,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  DsSpacing.sm, 10.0, DsSpacing.xs, 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      borderRadius: DsRadius.extraSmall,
                                    ),
                                    child: Icon(
                                      Icons.place_rounded,
                                      color: colors.primary,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      mkssItem.naim,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.labelLarge.copyWith(
                                        color: colors.textPrimary,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      borderRadius: DsRadius.extraSmall,
                                      border: Border.all(
                                        color: colors.error,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: DsIconButton(
                                      icon: Icons.delete_outline_rounded,
                                      foreground: colors.error,
                                      size: 20.0,
                                      onPressed: () async {
                                        FFAppState()
                                            .removeFromCartmkss(mkssItem);
                                        FFAppState().addcart =
                                            FFAppState().addcart + -1;
                                        safeSetState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        ),
        Align(
          alignment: const AlignmentDirectional(0.07, 1.0),
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
      ],
    );
  }
}
