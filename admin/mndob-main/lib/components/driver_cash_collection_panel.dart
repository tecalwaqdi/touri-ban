import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/order_record.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_trip_completion.dart';
import '/core/driver_trip_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Explicit cash collection CTA after trip completion — never auto-invoked.
class DriverCashCollectionPanel extends StatefulWidget {
  const DriverCashCollectionPanel({
    super.key,
    required this.order,
    this.onChanged,
  });

  final OrderRecord order;
  final VoidCallback? onChanged;

  @override
  State<DriverCashCollectionPanel> createState() =>
      _DriverCashCollectionPanelState();
}

class _DriverCashCollectionPanelState extends State<DriverCashCollectionPanel> {
  bool _busy = false;

  bool get _visible {
    final order = widget.order;
    if (order.mndobUser?.path != currentUserReference?.path) return false;
    if (!DriverPaymentLabels.isCash(
      order.paymentMethod,
      fallbackRaw: order.snapshotData['PaymentMethod']?.toString(),
    )) {
      return false;
    }
    if (!DriverTripCompletion.isCompleted(order)) return false;
    return DriverPaymentStatusMapper.isCashCollectionPending(order);
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await DriverTripService.confirmCashCollection(
        order: widget.order,
      );
      if (!mounted) return;
      if (result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driverTr(
                context,
                result.code == 'ALREADY_COLLECTED'
                    ? 'Cash was already confirmed.'
                    : 'Cash collection confirmed.',
              ),
            ),
          ),
        );
        widget.onChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driverTr(
                context,
                result.message ??
                    DriverTripService.messageForCode(
                      result.code ?? 'BOOKING_SERVICE_UNAVAILABLE',
                    ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.sm,
        DsSpacing.xxs,
        DsSpacing.sm,
        DsSpacing.xs,
      ),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: colors.warning, size: 22),
                DsSpacing.gapSm,
                Expanded(
                  child: Text(
                    driverTr(context, 'Awaiting cash collection confirmation'),
                    style: typography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            DsSpacing.gapXs,
            Text(
              driverTr(
                context,
                'Confirm you collected cash from the customer?',
              ),
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            DsSpacing.gapSm,
            DsButton.success(
              label: driverTr(context, 'Confirm cash received'),
              icon: Icons.check_circle_outline,
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
