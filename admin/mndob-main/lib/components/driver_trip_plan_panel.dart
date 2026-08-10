import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/backend/schema/structs/amakn_coistm_struct.dart';
import '/core/driver_i18n.dart';
import '/core/driver_map_actions.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_order_meta.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// مخطط رحلة احترافي للمندوب: خط زمني + توجيه خرائط + تأكيد زيارة.
class DriverTripPlanPanel extends StatefulWidget {
  const DriverTripPlanPanel({
    super.key,
    required this.order,
  });

  final OrderRecord order;

  @override
  State<DriverTripPlanPanel> createState() => _DriverTripPlanPanelState();
}

class _DriverTripPlanPanelState extends State<DriverTripPlanPanel> {
  final Set<int> _visitedStopIndexes = {};

  OrderRecord get order => widget.order;

  String _stopTitle(BuildContext context, AmaknCoistmStruct stop) {
    final naim = stop.naim.trim();
    if (naim.isNotEmpty) return naim;
    final address = stop.address.trim();
    if (address.isNotEmpty) return address;
    return driverTr(context, 'Unspecified location');
  }

  LatLng? _stopLoc(AmaknCoistmStruct stop) => stop.loceshn;

  Future<void> _openMap(LatLng? loc, String title) async {
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driverTr(context, 'No location on the map')),
        ),
      );
      return;
    }
    await DriverNavigationService.openGoogleMapsMarker(loc, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final stops = order.listAmakn.toList();
    final pickup = order.customerPickup;
    final hours = order.totalTaim;
    final stopCount = stops.isNotEmpty ? stops.length : order.addCartNumer;

    final steps = <_TripStep>[
      _TripStep(
        kind: _StepKind.pickup,
        title: driverTr(context, 'Go to customer location'),
        subtitle: order.pickupLabel(),
        location: pickup,
        icon: Icons.home_work_rounded,
      ),
      for (var i = 0; i < stops.length; i++)
        _TripStep(
          kind: _StepKind.stop,
          title: driverTrNamed(
            context,
            'Go to {name}',
            {'name': _stopTitle(context, stops[i])},
          ),
          subtitle: () {
            final a = stops[i].address.trim();
            return a.isNotEmpty && a != _stopTitle(context, stops[i]) ? a : null;
          }(),
          location: _stopLoc(stops[i]),
          icon: Icons.place_rounded,
          stopIndex: i,
        ),
      _TripStep(
        kind: _StepKind.returnPickup,
        title: driverTr(context, 'End of trip — return to customer'),
        subtitle: order.pickupLabel(),
        location: pickup,
        icon: Icons.flag_rounded,
      ),
    ];

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
              Container(
                padding: const EdgeInsets.all(DsSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.small,
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: colors.primaryStrong,
                  size: 22,
                ),
              ),
              DsSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverTr(context, 'Trip plan'),
                      style: typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driverTrNamed(
                        context,
                        '{count} places for {hours} hours',
                        {
                          'count': '$stopCount',
                          'hours': '$hours',
                        },
                      ),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DsButton.text(
                label: driverTr(context, 'Route'),
                icon: Icons.directions_rounded,
                onPressed: () {
                  final loc = order.driverLivePosition;
                  DriverNavigationService.openOrderRoute(
                    waypoints: order.routeWaypoints(driverOverride: loc),
                    driverOrigin: loc,
                    orderRef: order.reference,
                  );
                },
              ),
            ],
          ),
          DsSpacing.gapSm,
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            final visited = step.stopIndex != null &&
                _visitedStopIndexes.contains(step.stopIndex);
            return _TimelineTile(
              step: step,
              isLast: isLast,
              visited: visited,
              onOpenMap: () => _openMap(step.location, step.title),
              onMarkVisited: step.stopIndex == null
                  ? null
                  : () {
                      setState(() => _visitedStopIndexes.add(step.stopIndex!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(driverTr(context, 'Visit confirmed')),
                          backgroundColor: colors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              onFocusInApp: step.location == null
                  ? null
                  : () => DriverMapActions.focusLocationHint(
                        context,
                        step.location,
                        title: step.title,
                      ),
            );
          }),
        ],
      ),
    );
  }
}

enum _StepKind { pickup, stop, returnPickup }

class _TripStep {
  const _TripStep({
    required this.kind,
    required this.title,
    required this.icon,
    this.subtitle,
    this.location,
    this.stopIndex,
  });

  final _StepKind kind;
  final String title;
  final String? subtitle;
  final LatLng? location;
  final IconData icon;
  final int? stopIndex;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.isLast,
    required this.visited,
    required this.onOpenMap,
    this.onMarkVisited,
    this.onFocusInApp,
  });

  final _TripStep step;
  final bool isLast;
  final bool visited;
  final VoidCallback onOpenMap;
  final VoidCallback? onMarkVisited;
  final VoidCallback? onFocusInApp;

  Color _accent(BuildContext context) {
    final colors = context.dsColors;
    switch (step.kind) {
      case _StepKind.pickup:
        return colors.primaryStrong;
      case _StepKind.stop:
        return visited ? colors.success : colors.error;
      case _StepKind.returnPickup:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final accent = _accent(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: visited
                        ? colors.success.withValues(alpha: 0.15)
                        : accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1.5),
                  ),
                  child: Icon(
                    visited ? Icons.check_rounded : step.icon,
                    size: 14,
                    color: accent,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.border.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          DsSpacing.gapSm,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : DsSpacing.sm),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  DsSpacing.sm,
                  DsSpacing.sm,
                  DsSpacing.sm,
                  DsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: DsRadius.small,
                  border: Border.all(
                    color: visited
                        ? colors.success.withValues(alpha: 0.35)
                        : colors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: typography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (step.subtitle != null &&
                        step.subtitle!.trim().isNotEmpty &&
                        step.subtitle != '—') ...[
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    DsSpacing.gapXs,
                    Wrap(
                      spacing: DsSpacing.xs,
                      runSpacing: DsSpacing.xs,
                      children: [
                        _ActionChip(
                          label: driverTr(context, 'Map view'),
                          icon: Icons.map_rounded,
                          foreground: colors.primaryStrong,
                          background: colors.primarySoft,
                          onTap: onOpenMap,
                        ),
                        if (onFocusInApp != null)
                          _ActionChip(
                            label: driverTr(context, 'In-app'),
                            icon: Icons.my_location_rounded,
                            foreground: colors.textSecondary,
                            background: colors.border.withValues(alpha: 0.45),
                            onTap: onFocusInApp!,
                          ),
                        if (onMarkVisited != null)
                          _ActionChip(
                            label: visited
                                ? driverTr(context, 'Visited')
                                : driverTr(context, 'Done'),
                            icon: Icons.done_rounded,
                            foreground: visited
                                ? colors.success
                                : colors.textPrimary,
                            background: visited
                                ? colors.success.withValues(alpha: 0.15)
                                : colors.card,
                            bordered: !visited,
                            onTap: visited ? null : onMarkVisited,
                          ),
                      ],
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.bordered = false,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback? onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Material(
      color: background,
      borderRadius: DsRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.pill,
        child: Container(
          padding: DsSpacing.chipPadding,
          decoration: BoxDecoration(
            borderRadius: DsRadius.pill,
            border: bordered ? Border.all(color: colors.border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
