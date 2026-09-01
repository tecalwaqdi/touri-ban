import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_presentation.dart';
import '/admin/admin_booking_details/admin_booking_details_sections.dart';
import '/backend/schema/order_record.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_journey.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only multi-stop journey timeline for booking details.
class AdminBookingJourneySection extends StatelessWidget {
  const AdminBookingJourneySection({
    super.key,
    required this.order,
  });

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final journey = AdminBookingJourneyView.fromOrder(order);
    final theme = FlutterFlowTheme.of(context);

    if (journey.isEmpty) {
      return AdminBookingDetailsSectionCard(
        title: uiTr(context, 'مسار الرحلة'),
        children: [
          Text(
            uiTr(context, 'لا توجد محطات مسجّلة لهذا الحجز'),
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ],
      );
    }

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'مسار الرحلة'),
      children: [
        if (!journey.hasStopMetadata)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              uiTr(
                context,
                'بيانات تقدم المحطات غير متوفرة — تُعرض المحطات المتاحة فقط',
              ),
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
        ...journey.stops.asMap().entries.map(
              (e) => _StopTile(
                stop: e.value,
                isLast: e.key == journey.stops.length - 1,
              ),
            ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.isLast,
  });

  final AdminBookingJourneyStop stop;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = AdminBookingJourneyView.stateLabelArabic(stop.state);
    final color = _stateColor(stop.state, theme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StopIndicator(
            sequence: stop.index + 1,
            color: color,
            isCurrent: stop.isCurrent,
            showConnector: !isLast,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  stop.name,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight:
                        stop.isCurrent ? FontWeight.w700 : FontWeight.w500,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AdminStatusBadge(
                      label: label,
                      tone: _badgeTone(stop.state),
                    ),
                    if (stop.isReturnDestination)
                      AdminStatusBadge(
                        label: uiTr(context, 'وجهة العودة'),
                        tone: AdminBadgeTone.neutral,
                      ),
                  ],
                ),
                if (stop.visitedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${uiTr(context, 'وقت الزيارة')}: '
                    '${AdminBookingsPresentation.tableDateTimeTooltip(stop.visitedAt)}',
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                    textDirection: ui.TextDirection.ltr,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stateColor(
      AdminBookingJourneyStopState state, FlutterFlowTheme theme) {
    return switch (state) {
      AdminBookingJourneyStopState.visited => theme.success,
      AdminBookingJourneyStopState.current ||
      AdminBookingJourneyStopState.returnLeg =>
        AdminUi.brandTeal,
      AdminBookingJourneyStopState.arrived => const Color(0xFF3949AB),
      AdminBookingJourneyStopState.upcoming => theme.secondaryText,
      AdminBookingJourneyStopState.unknown => theme.alternate,
    };
  }

  AdminBadgeTone _badgeTone(AdminBookingJourneyStopState state) {
    return switch (state) {
      AdminBookingJourneyStopState.visited => AdminBadgeTone.success,
      AdminBookingJourneyStopState.current ||
      AdminBookingJourneyStopState.returnLeg =>
        AdminBadgeTone.info,
      AdminBookingJourneyStopState.arrived => AdminBadgeTone.info,
      AdminBookingJourneyStopState.upcoming => AdminBadgeTone.neutral,
      AdminBookingJourneyStopState.unknown => AdminBadgeTone.warning,
    };
  }
}

class _StopIndicator extends StatelessWidget {
  const _StopIndicator({
    required this.sequence,
    required this.color,
    required this.isCurrent,
    required this.showConnector,
  });

  final int sequence;
  final Color color;
  final bool isCurrent;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isCurrent ? 0.18 : 0.12),
            border: Border.all(
              color: color,
              width: isCurrent ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$sequence',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (showConnector)
          Container(
            width: 2,
            height: 24,
            margin: const EdgeInsets.only(top: 4),
            color: color.withValues(alpha: 0.25),
          ),
      ],
    );
  }
}
