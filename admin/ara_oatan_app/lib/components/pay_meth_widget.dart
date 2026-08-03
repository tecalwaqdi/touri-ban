import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'pay_meth_model.dart';
export 'pay_meth_model.dart';

///  طرق الدفع كقائمة ومكتوب بجانبها (قريبا ): فيزا  ابل باي) stc pay   نقدآ
class PayMethWidget extends StatefulWidget {
  const PayMethWidget({super.key});

  @override
  State<PayMethWidget> createState() => _PayMethWidgetState();
}

class _PayMethWidgetState extends State<PayMethWidget> {
  late PayMethModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PayMethModel());

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

    return DsCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              'u0j8lddj' /* Payment Methods */,
            ),
            style: typography.headlineSmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          DsCard(
            onTap: () async {
              FFAppState().payth = 'نقدي';
              FFAppState().update(() {});
              Navigator.pop(context);
            },
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: colors.icon,
                      size: DsIcons.lg,
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Text(
                      FFLocalizations.of(context).getText(
                        'shd52l15' /* Cash */,
                      ),
                      style: typography.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.done_sharp,
                  color: colors.icon,
                  size: DsIcons.lg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
