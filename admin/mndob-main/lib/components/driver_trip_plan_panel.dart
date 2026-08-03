import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/backend/schema/structs/amakn_coistm_struct.dart';
import '/core/driver_design_system.dart';
import '/core/driver_map_actions.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_order_meta.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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

  String _stopTitle(AmaknCoistmStruct stop) {
    final naim = stop.naim.trim();
    if (naim.isNotEmpty) return naim;
    final address = stop.address.trim();
    if (address.isNotEmpty) return address;
    return 'موقع غير محدد';
  }

  LatLng? _stopLoc(AmaknCoistmStruct stop) => stop.loceshn;

  Future<void> _openMap(LatLng? loc, String title) async {
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يتوفر موقع على الخريطة')),
      );
      return;
    }
    await DriverNavigationService.openGoogleMapsMarker(loc, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final stops = order.listAmakn.toList();
    final pickup = order.customerPickup;
    final hours = order.totalTaim;
    final stopCount = stops.isNotEmpty ? stops.length : order.addCartNumer;

    final steps = <_TripStep>[
      _TripStep(
        kind: _StepKind.pickup,
        title: 'الذهاب إلى موقع العميل',
        subtitle: order.pickupLabel(),
        location: pickup,
        icon: Icons.home_work_rounded,
      ),
      for (var i = 0; i < stops.length; i++)
        _TripStep(
          kind: _StepKind.stop,
          title: 'الذهاب إلى ${_stopTitle(stops[i])}',
          subtitle: () {
            final a = stops[i].address.trim();
            return a.isNotEmpty && a != _stopTitle(stops[i]) ? a : null;
          }(),
          location: _stopLoc(stops[i]),
          icon: Icons.place_rounded,
          stopIndex: i,
        ),
      _TripStep(
        kind: _StepKind.returnPickup,
        title: 'نهاية الرحلة — العودة لموقع العميل',
        subtitle: order.pickupLabel(),
        location: pickup,
        icon: Icons.flag_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: DriverBrand.cardDecoration(context, elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DriverBrand.tealLight,
                  borderRadius: BorderRadius.circular(DriverBrand.radiusSm),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: DriverBrand.tealDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مخطط الرحلة',
                      style: theme.titleMedium.override(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.w700,
                        color: DriverBrand.textPrimaryColor(context),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stopCount مكان · $hours ساعة',
                      style: theme.bodySmall.override(
                        fontFamily: 'cairo',
                        color: DriverBrand.textSecondaryColor(context),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final loc = order.driverLivePosition;
                  DriverNavigationService.openOrderRoute(
                    waypoints: order.routeWaypoints(driverOverride: loc),
                    driverOrigin: loc,
                    orderRef: order.reference,
                  );
                },
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('المسار'),
                style: TextButton.styleFrom(
                  foregroundColor: DriverBrand.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                          content: const Text('تم تأكيد الزيارة'),
                          backgroundColor: DriverBrand.success,
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

  Color get _accent {
    switch (step.kind) {
      case _StepKind.pickup:
        return DriverBrand.tealDark;
      case _StepKind.stop:
        return visited ? DriverBrand.success : DriverBrand.partnerRed;
      case _StepKind.returnPickup:
        return DriverBrand.tealDeeper;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
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
                        ? DriverBrand.success.withValues(alpha: 0.15)
                        : _accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent, width: 1.5),
                  ),
                  child: Icon(
                    visited ? Icons.check_rounded : step.icon,
                    size: 14,
                    color: _accent,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: DriverBrand.border.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: DriverBrand.surfaceColor(context),
                  borderRadius: BorderRadius.circular(DriverBrand.radiusSm),
                  border: Border.all(
                    color: visited
                        ? DriverBrand.success.withValues(alpha: 0.35)
                        : DriverBrand.borderColor(context),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.bodyMedium.override(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.w700,
                        color: DriverBrand.textPrimaryColor(context),
                        letterSpacing: 0,
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
                        style: theme.bodySmall.override(
                          fontFamily: 'cairo',
                          color: DriverBrand.textSecondaryColor(context),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionChip(
                          label: 'خريطة',
                          icon: Icons.map_rounded,
                          foreground: DriverBrand.tealDark,
                          background: DriverBrand.tealLight,
                          onTap: onOpenMap,
                        ),
                        if (onFocusInApp != null)
                          _ActionChip(
                            label: 'داخل التطبيق',
                            icon: Icons.my_location_rounded,
                            foreground: DriverBrand.textSecondary,
                            background: DriverBrand.border.withValues(alpha: 0.45),
                            onTap: onFocusInApp!,
                          ),
                        if (onMarkVisited != null)
                          _ActionChip(
                            label: visited ? 'تمت الزيارة' : 'تم',
                            icon: Icons.done_rounded,
                            foreground: visited
                                ? DriverBrand.success
                                : DriverBrand.textPrimary,
                            background: visited
                                ? DriverBrand.success.withValues(alpha: 0.15)
                                : Colors.white,
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: bordered
                ? Border.all(color: DriverBrand.border)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 12,
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
