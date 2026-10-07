import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/driver_geo_display.dart';
import '/core/driver_i18n_text.dart';
import '/core/driver_order_match.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_pickup_eta_cache.dart';
import '/core/driver_relative_time.dart';
import '/core/toury_distance_format.dart';
import '/core/toury_money_display.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact professional Available Orders card (Touri Taxi).
class DriverAvailableOrderCard extends StatelessWidget {
  const DriverAvailableOrderCard({
    super.key,
    required this.order,
    required this.driverLocation,
    required this.onAccept,
    this.onTap,
    this.accepting = false,
  });

  final OrderRecord order;
  final LatLng? driverLocation;
  final VoidCallback onAccept;
  final VoidCallback? onTap;
  final bool accepting;

  String _pickupArea(String localeKey, {VillagesRecord? village}) {
    final resolved = driverSearchingAreaLabel(
      localeKey: localeKey,
      namesI18n: village?.namesI18n ?? const {},
      legacyNaim: village?.naim ?? '',
      cachedText: order.villText,
    );
    if (resolved.isNotEmpty) return resolved;
    final label = order.pickupLabel().trim();
    if (label.isNotEmpty && label != '—') {
      final safe = driverSafeCachedGeoLabel(label, localeKey: localeKey);
      if (safe.isEmpty) return '—';
      final parts = safe.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      if (parts.length >= 2) return parts.take(2).join(', ');
      return safe;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final finance = DriverTripFinance.fromOrder(order);
    final payment = DriverPaymentLabels.label(
      order.paymentMethod,
      context: context,
    );
    final rating = order.retengUser;
    final hours = order.totalTaim;
    final landmarks = order.addCartNumer;
    final age = DriverRelativeTime.format(context, order.dataOrder);

    return DsCard(
      elevated: true,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(DsSpacing.sm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primarySoft,
                backgroundImage: order.imgProfileClent.trim().isNotEmpty
                    ? NetworkImage(order.imgProfileClent)
                    : null,
                child: order.imgProfileClent.trim().isEmpty
                    ? Icon(Icons.person_rounded, color: colors.primary, size: 22)
                    : null,
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.naimUserText.trim().isEmpty
                          ? driverTr(context, 'Customer')
                          : order.naimUserText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: colors.warning),
                        const SizedBox(width: 2),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '—',
                          style: typography.labelSmall.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: DsSpacing.sm),
                        Flexible(
                          child: _chip(
                            context,
                            payment,
                            DriverPaymentLabels.isCash(order.paymentMethod)
                                ? colors.success
                                : colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          // Pickup
          _metaRow(
            context,
            icon: Icons.near_me_rounded,
            child: FutureBuilder<DriverPickupEta?>(
              future: DriverPickupEtaCache.forPickup(
                orderId: order.reference.id,
                driver: driverLocation,
                pickup: order.customerPickup,
              ),
              builder: (context, snap) {
                final eta = snap.data;
                String distanceLabel;
                if (eta != null && eta.distanceKm > 0) {
                  distanceLabel = touryFormatDistanceKm(eta.distanceKm);
                  if (eta.durationMinutes > 0) {
                    final etaLabel = DriverRelativeTime.etaMinutes(
                      context,
                      eta.durationMinutes,
                      approximate: eta.approximate,
                    );
                    distanceLabel = '$distanceLabel · $etaLabel';
                  }
                } else {
                  final km = DriverOrderMatch.distanceKm(order, driverLocation);
                  distanceLabel = km == null
                      ? driverTr(context, 'Distance unknown')
                      : touryFormatDistanceKm(km);
                }
                final localeKey = driverActiveContentLocaleKey();
                final villRef = order.vill;
                Widget areaText(String area) {
                  return Text(
                    '$distanceLabel · $area',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  );
                }
                if (villRef == null) {
                  return areaText(_pickupArea(localeKey));
                }
                return StreamBuilder<VillagesRecord>(
                  stream: VillagesRecord.getDocument(villRef),
                  builder: (context, villageSnap) {
                    return areaText(
                      _pickupArea(localeKey, village: villageSnap.data),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          // Trip
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.xxs,
            children: [
              _pill(
                context,
                Icons.schedule_rounded,
                driverTrNamed(context, '{count} hours', {'count': '$hours'}),
              ),
              _pill(
                context,
                Icons.place_outlined,
                driverTrNamed(
                  context,
                  '{count} landmarks',
                  {'count': '$landmarks'},
                ),
              ),
              _pill(
                context,
                Icons.undo_rounded,
                '${driverTr(context, 'return_to_customer_pickup_label')}: ${driverTr(
                  context,
                  order.returnToPickup
                      ? 'return_to_pickup_yes'
                      : 'return_to_pickup_no',
                )}',
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          // Finance + Accept
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverTr(context, 'Your earnings'),
                      style: typography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TouryMoneyAmount(
                      amount: finance.net > 0 ? finance.net : order.totalMndob2,
                      currencyCode: finance.currency,
                      style: typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                    if (age.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        age,
                        style: typography.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              DsButton.success(
                label: driverTr(context, 'Accept'),
                icon: Icons.check_circle_outline,
                loading: accepting,
                enabled: !accepting,
                onPressed: onAccept,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    BuildContext context, {
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.dsColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: child),
      ],
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.scaffold,
        borderRadius: DsRadius.pill,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: typography.labelSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DsRadius.pill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
