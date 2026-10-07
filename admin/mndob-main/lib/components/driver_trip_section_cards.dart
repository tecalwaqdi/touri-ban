import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/toury_money_display.dart';
import '/core/toury_system_status_codes.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Localized booking status: raw → canonical → key → locale. Never shows Arabic/raw.
String driverLocalizedBookingStatus(BuildContext context, OrderRecord order) {
  final code = DriverTripActionGates.codeOf(order.snapshotData, order.halhText);
  var key = TourySystemStatusCodes.displayHalhKeyForCode(code);
  if (key.isEmpty) {
    final fromHalh = TourySystemStatusCodes.fromHalhText(order.halhText);
    key = TourySystemStatusCodes.displayHalhKeyForCode(fromHalh);
  }
  if (key.isEmpty) return driverTr(context, 'Pending');
  return driverTr(context, key);
}

String driverLocalizedPaymentStatus(BuildContext context, OrderRecord order) {
  final status = DriverPaymentStatusMapper.normalizeStatus(order);
  return driverTr(context, DriverPaymentStatusMapper.displayKey(status));
}

/// Compact financial summary — amounts from order; currency from order/country.
class DriverTripFinanceSummaryCard extends StatelessWidget {
  const DriverTripFinanceSummaryCard({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final finance = DriverTripFinance.fromOrder(order);

    return DsCard(
      margin: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.xs,
        DsSpacing.md,
        DsSpacing.xs,
      ),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                driverTr(context, 'Financial summary'),
                style: typography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          _moneyLine(
            context,
            driverTr(context, 'Total Trip Amount:'),
            finance.gross > 0 ? finance.gross : order.total,
            finance.currency,
          ),
          _moneyLine(
            context,
            driverTr(context, 'Your earnings'),
            finance.net > 0 ? finance.net : order.totalMndob2,
            finance.currency,
            emphasize: true,
          ),
          _moneyLine(
            context,
            driverTr(context, 'App Commission & Taxes:'),
            finance.commission + finance.tax > 0
                ? finance.commission + finance.tax
                : order.totalApp + order.totalVat,
            finance.currency,
            danger: true,
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            driverLocalizedPaymentStatus(context, order),
            style: typography.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyLine(
    BuildContext context,
    String label,
    double amount,
    String currency, {
    bool emphasize = false,
    bool danger = false,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final color = danger
        ? colors.error
        : emphasize
            ? colors.success
            : colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
          TouryMoneyAmount(
            amount: amount,
            currencyCode: currency,
            style: typography.bodyMedium.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Support CTA under trip details.
class DriverTripSupportCard extends StatelessWidget {
  const DriverTripSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      margin: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.xs,
        DsSpacing.md,
        DsSpacing.md,
      ),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.support_agent_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverTr(context, 'Support'),
                  style: typography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  driverTr(context, 'Have a problem? Contact us directly.'),
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          DsButton.text(
            label: driverTr(context, 'Contact support'),
            onPressed: () => context.pushNamed(SuportWidget.routeName),
          ),
        ],
      ),
    );
  }
}

/// Compact route summary strip for trip details hierarchy.
class DriverTripRouteSummaryCard extends StatelessWidget {
  const DriverTripRouteSummaryCard({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final stops = order.listAmakn.length;
    final hours = order.totalTaim;

    return DsCard(
      margin: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.xs,
        DsSpacing.md,
        DsSpacing.xs,
      ),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            driverTr(context, 'Route summary'),
            style: typography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _line(context, driverTr(context, 'Pickup point'), order.pickupLabel()),
          _line(
            context,
            driverTr(context, 'Destination'),
            order.destinationLabel(),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                driverTrNamed(context, '{count} hours', {'count': '$hours'}),
                style: typography.labelMedium.copyWith(color: colors.textSecondary),
              ),
              Text(
                '·',
                style: typography.labelMedium.copyWith(color: colors.textSecondary),
              ),
              Text(
                driverTrNamed(
                  context,
                  '{count} landmarks',
                  {'count': '${stops > 0 ? stops : order.addCartNumer}'},
                ),
                style: typography.labelMedium.copyWith(color: colors.textSecondary),
              ),
              Text(
                '·',
                style: typography.labelMedium.copyWith(color: colors.textSecondary),
              ),
              Text(
                driverTr(
                  context,
                  order.returnToPickup
                      ? 'return_to_pickup_yes'
                      : 'return_to_pickup_no',
                ),
                style: typography.labelMedium.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: typography.labelSmall.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip under the app bar.
class DriverTripStatusChip extends StatelessWidget {
  const DriverTripStatusChip({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final label = driverLocalizedBookingStatus(context, order);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.xs,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: DsRadius.pill,
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: typography.labelLarge.copyWith(
              color: colors.primaryStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
