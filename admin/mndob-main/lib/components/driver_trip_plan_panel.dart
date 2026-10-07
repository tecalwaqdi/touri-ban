import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/backend/schema/structs/amakn_coistm_struct.dart';
import '/core/driver_map_actions.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_tracking_phase.dart';
import '/core/driver_trip_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Trip plan: legs 1 Driver→pickup, 2 Pickup→L1, 3 landmarks, 4 optional return.
/// Visual states: completed / current / future from tracking phase.
class DriverTripPlanPanel extends StatefulWidget {
  const DriverTripPlanPanel({
    super.key,
    required this.order,
  });

  final OrderRecord order;

  @override
  State<DriverTripPlanPanel> createState() => _DriverTripPlanPanelState();
}

enum _LegVisual { completed, current, future }

class _DriverTripPlanPanelState extends State<DriverTripPlanPanel> {
  final Set<int> _visitedStopIndexes = {};
  bool _markingVisit = false;

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
        SnackBar(content: Text(driverTr(context, 'No location on the map'))),
      );
      return;
    }
    await DriverNavigationService.openGoogleMapsMarker(loc, title: title);
  }

  Future<void> _markVisited(int stopIndex) async {
    if (_markingVisit) return;
    final stops = order.listAmakn.toList();
    if (stopIndex < 0 || stopIndex >= stops.length) return;
    if (stops[stopIndex].okdone || _visitedStopIndexes.contains(stopIndex)) {
      return;
    }

    setState(() {
      _markingVisit = true;
      _visitedStopIndexes.add(stopIndex);
    });

    try {
      await DriverTripService.markStopVisited(
        order: order,
        stopIndex: stopIndex,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driverTr(context, 'Visit confirmed')),
          backgroundColor: context.dsColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _visitedStopIndexes.remove(stopIndex));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            driverTr(context, 'Something went wrong. Please try again.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _markingVisit = false);
    }
  }

  /// Index of the current leg within [steps].
  int _currentLegIndex(List<_TripStep> steps) {
    final phase = order.trackingPhase;
    if (phase == DriverTrackingPhase.completed ||
        phase == DriverTrackingPhase.returnedToPickup) {
      return steps.length; // all done
    }
    if (phase == DriverTrackingPhase.toPickup) return 0;
    if (phase == DriverTrackingPhase.returningToPickup) {
      final i = steps.indexWhere((s) => s.kind == _StepKind.returnPickup);
      return i >= 0 ? i : steps.length - 1;
    }
    // to_destination / at_destination: first incomplete stop, else last stop.
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.kind == _StepKind.pickup) continue;
      if (s.kind == _StepKind.returnPickup) continue;
      final idx = s.stopIndex;
      if (idx == null) continue;
      final done = order.listAmakn[idx].okdone ||
          _visitedStopIndexes.contains(idx);
      if (!done) return i;
    }
    if (phase == DriverTrackingPhase.atDestination) {
      final i = steps.indexWhere((s) => s.kind == _StepKind.returnPickup);
      return i >= 0 ? i : steps.length;
    }
    // All stops done, still to_destination → treat last stop as current.
    final lastStop = steps.lastIndexWhere((s) => s.kind == _StepKind.stop);
    return lastStop >= 0 ? lastStop : 0;
  }

  _LegVisual _visualFor(int index, int current) {
    if (index < current) return _LegVisual.completed;
    if (index == current) return _LegVisual.current;
    return _LegVisual.future;
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
        legNumber: 1,
        title: driverTr(context, 'Go to customer location'),
        subtitle: order.pickupLabel(),
        location: pickup,
        icon: Icons.home_work_rounded,
      ),
      for (var i = 0; i < stops.length; i++)
        _TripStep(
          kind: _StepKind.stop,
          legNumber: i + 2,
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
      if (order.returnToPickup)
        _TripStep(
          kind: _StepKind.returnPickup,
          legNumber: stops.length + 2,
          title: driverTr(context, 'return_to_customer_pickup'),
          subtitle: order.pickupLabel(),
          location: order.originalPickupSnapshot ?? pickup,
          icon: Icons.flag_rounded,
        ),
    ];

    final currentIdx = _currentLegIndex(steps);

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
                        {'count': '$stopCount', 'hours': '$hours'},
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
            final stopIdx = step.stopIndex;
            final visited = stopIdx != null &&
                (stops[stopIdx].okdone ||
                    _visitedStopIndexes.contains(stopIdx));
            final visual = visited && step.kind == _StepKind.stop
                ? _LegVisual.completed
                : _visualFor(index, currentIdx);
            // Pickup completed once past to_pickup.
            final pickupDone = step.kind == _StepKind.pickup &&
                order.trackingPhase != DriverTrackingPhase.toPickup &&
                order.trackingPhase != DriverTrackingPhase.completed;
            final effective = pickupDone
                ? (order.trackingPhase == DriverTrackingPhase.toPickup
                    ? _LegVisual.current
                    : _LegVisual.completed)
                : visual;
            final returnDone = step.kind == _StepKind.returnPickup &&
                (order.trackingPhase == DriverTrackingPhase.returnedToPickup ||
                    order.trackingPhase == DriverTrackingPhase.completed);
            final finalVisual = returnDone ? _LegVisual.completed : effective;

            return _TimelineTile(
              step: step,
              isLast: isLast,
              visual: finalVisual,
              visited: visited || finalVisual == _LegVisual.completed,
              onOpenMap: () => _openMap(step.location, step.title),
              onMarkVisited: stopIdx == null ||
                      visited ||
                      _markingVisit ||
                      finalVisual != _LegVisual.current
                  ? null
                  : () => _markVisited(stopIdx),
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
    required this.legNumber,
    required this.title,
    required this.icon,
    this.subtitle,
    this.location,
    this.stopIndex,
  });

  final _StepKind kind;
  final int legNumber;
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
    required this.visual,
    required this.visited,
    required this.onOpenMap,
    this.onMarkVisited,
    this.onFocusInApp,
  });

  final _TripStep step;
  final bool isLast;
  final _LegVisual visual;
  final bool visited;
  final VoidCallback onOpenMap;
  final VoidCallback? onMarkVisited;
  final VoidCallback? onFocusInApp;

  Color _accent(BuildContext context) {
    final colors = context.dsColors;
    switch (visual) {
      case _LegVisual.completed:
        return colors.success;
      case _LegVisual.current:
        return colors.primaryStrong;
      case _LegVisual.future:
        return colors.textSecondary.withValues(alpha: 0.55);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final accent = _accent(context);
    final muted = visual == _LegVisual.future;

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
                    color: visual == _LegVisual.completed
                        ? colors.success.withValues(alpha: 0.15)
                        : visual == _LegVisual.current
                            ? colors.primarySoft
                            : colors.border.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent,
                      width: visual == _LegVisual.current ? 2.2 : 1.5,
                    ),
                  ),
                  child: visual == _LegVisual.completed
                      ? Icon(Icons.check_rounded, size: 14, color: accent)
                      : Center(
                          child: Text(
                            '${step.legNumber}',
                            style: typography.labelSmall.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: visual == _LegVisual.completed
                          ? colors.success.withValues(alpha: 0.45)
                          : colors.border.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          DsSpacing.gapSm,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : DsSpacing.sm),
              child: Opacity(
                opacity: muted ? 0.55 : 1,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.sm,
                    DsSpacing.sm,
                    DsSpacing.sm,
                    DsSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: visual == _LegVisual.current
                        ? colors.primarySoft.withValues(alpha: 0.35)
                        : colors.scaffold,
                    borderRadius: DsRadius.small,
                    border: Border.all(
                      color: visual == _LegVisual.completed
                          ? colors.success.withValues(alpha: 0.35)
                          : visual == _LegVisual.current
                              ? colors.primary.withValues(alpha: 0.45)
                              : colors.border,
                      width: visual == _LegVisual.current ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: typography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (visual == _LegVisual.current)
                            Text(
                              driverTr(context, 'Current'),
                              style: typography.labelSmall.copyWith(
                                color: colors.primaryStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (visual == _LegVisual.completed)
                            Text(
                              driverTr(context, 'Done'),
                              style: typography.labelSmall.copyWith(
                                color: colors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
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
                              background:
                                  colors.border.withValues(alpha: 0.45),
                              onTap: onFocusInApp!,
                            ),
                          if (onMarkVisited != null)
                            _ActionChip(
                              label: driverTr(context, 'Arrived landmark'),
                              icon: Icons.done_rounded,
                              foreground: colors.textPrimary,
                              background: colors.card,
                              bordered: true,
                              onTap: onMarkVisited,
                            ),
                        ],
                      ),
                    ],
                  ),
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
