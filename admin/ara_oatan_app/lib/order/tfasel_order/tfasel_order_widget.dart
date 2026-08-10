import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/order/tfasel_order/toury_order_details_view.dart';
import 'tfasel_order_model.dart';

export 'tfasel_order_model.dart';

/// Active customer order/trip details (`/tfaselOrder`).
class TfaselOrderWidget extends StatefulWidget {
  const TfaselOrderWidget({
    super.key,
    required this.idorder,
  });

  final OrderRecord? idorder;

  static String routeName = 'tfasel_order';
  static String routePath = '/tfaselOrder';

  @override
  State<TfaselOrderWidget> createState() => _TfaselOrderWidgetState();
}

class _TfaselOrderWidgetState extends State<TfaselOrderWidget> {
  late TfaselOrderModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TfaselOrderModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  DocumentReference? get _orderRef =>
      widget.idorder?.reference;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final orderRef = _orderRef;

    if (orderRef == null) {
      return DsScreenShell(
        child: Scaffold(
          backgroundColor: colors.scaffold,
          appBar: DsAppBar(
            title: 'order_details_fallback_title'.tr(),
            leading: DsIconButton(
              icon: DsIcons.back,
              onPressed: () => context.safePop(),
            ),
          ),
          body: DsErrorState(
            title: 'order_details_missing_title'.tr(),
            message: 'order_details_missing_msg'.tr(),
            retryLabel: 'ux_retry'.tr(),
            onRetry: () => context.safePop(),
          ),
        ),
      );
    }

    return DsScreenShell(
      child: StreamBuilder<OrderRecord>(
        stream: OrderRecord.getDocument(orderRef),
        builder: (context, snapshot) {
          // Keep showing content while stream refreshes if we already have data.
          final waitingFirstLoad =
              !snapshot.hasData && snapshot.connectionState == ConnectionState.waiting;

          if (waitingFirstLoad) {
            return Scaffold(
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: 'order_details_fallback_title'.tr(),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: const DsLoading(),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: 'order_details_fallback_title'.tr(),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: DsErrorState(
                title: 'order_details_load_error_title'.tr(),
                message: 'order_details_load_error_msg'.tr(),
                retryLabel: 'ux_retry'.tr(),
                onRetry: () => safeSetState(() {}),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: 'order_details_fallback_title'.tr(),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: DsEmptyState(
                title: 'order_details_missing_title'.tr(),
                message: 'order_details_missing_msg'.tr(),
                icon: Icons.receipt_long_outlined,
              ),
            );
          }

          final order = snapshot.data!;
          final orderId = order.iDorder.toString().trim().isEmpty
              ? order.reference.id
              : order.iDorder.toString();

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: colors.scaffold,
            appBar: DsAppBar(
              title: 'order_details_number'.tr(namedArgs: {'id': orderId}),
              leading: DsIconButton(
                icon: DsIcons.back,
                onPressed: () => context.safePop(),
              ),
            ),
            body: SafeArea(
              top: true,
              child: TouryOrderDetailsView(order: order),
            ),
          );
        },
      ),
    );
  }
}
