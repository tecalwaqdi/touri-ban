import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Unified status badges across the admin panel.
enum AdminStatusKind {
  active,
  inactive,
  unknown,
  completed,
  cancelled,
  expired,
  paid,
  pending,
  cashCollected,
  draft,
  locked,
  partiallyPaid,
  settled,
  voided,
  high,
  derived,
  incomplete,
  critical,
  highSeverity,
  medium,
  low,
}

class AdminStatusBadgeUnified extends StatelessWidget {
  const AdminStatusBadgeUnified({
    super.key,
    required this.kind,
    this.label,
  });

  final AdminStatusKind kind;
  final String? label;

  static AdminStatusKind? fromRaw(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    switch (s) {
      case 'active':
      case 'activated':
        return AdminStatusKind.active;
      case 'inactive':
      case 'deactivated':
        return AdminStatusKind.inactive;
      case 'completed':
      case 'trip_completed':
        return AdminStatusKind.completed;
      case 'cancelled':
      case 'canceled':
        return AdminStatusKind.cancelled;
      case 'expired':
        return AdminStatusKind.expired;
      case 'paid':
      case 'captured':
        return AdminStatusKind.paid;
      case 'pending':
      case 'pending_cash':
      case 'unpaid':
        return AdminStatusKind.pending;
      case 'cash_collected':
      case 'cashcollected':
        return AdminStatusKind.cashCollected;
      case 'draft':
        return AdminStatusKind.draft;
      case 'locked':
        return AdminStatusKind.locked;
      case 'partially_paid':
      case 'partiallypaid':
        return AdminStatusKind.partiallyPaid;
      case 'settled':
        return AdminStatusKind.settled;
      case 'voided':
        return AdminStatusKind.voided;
      case 'high':
        return AdminStatusKind.high;
      case 'derived':
        return AdminStatusKind.derived;
      case 'incomplete':
        return AdminStatusKind.incomplete;
      case 'critical':
        return AdminStatusKind.critical;
      case 'medium':
        return AdminStatusKind.medium;
      case 'low':
        return AdminStatusKind.low;
      default:
        return s.isEmpty ? null : AdminStatusKind.unknown;
    }
  }

  String _defaultLabel(BuildContext context) {
    switch (kind) {
      case AdminStatusKind.active:
        return uiTr(context, 'Active');
      case AdminStatusKind.inactive:
        return uiTr(context, 'Inactive');
      case AdminStatusKind.unknown:
        return uiTr(context, 'Unknown');
      case AdminStatusKind.completed:
        return uiTr(context, 'Completed');
      case AdminStatusKind.cancelled:
        return uiTr(context, 'Cancelled');
      case AdminStatusKind.expired:
        return uiTr(context, 'Expired');
      case AdminStatusKind.paid:
        return uiTr(context, 'Paid');
      case AdminStatusKind.pending:
        return uiTr(context, 'Pending');
      case AdminStatusKind.cashCollected:
        return uiTr(context, 'Cash Collected');
      case AdminStatusKind.draft:
        return uiTr(context, 'Draft');
      case AdminStatusKind.locked:
        return uiTr(context, 'Locked');
      case AdminStatusKind.partiallyPaid:
        return uiTr(context, 'Partially Paid');
      case AdminStatusKind.settled:
        return uiTr(context, 'Settled');
      case AdminStatusKind.voided:
        return uiTr(context, 'Voided');
      case AdminStatusKind.high:
        return 'HIGH';
      case AdminStatusKind.derived:
        return 'DERIVED';
      case AdminStatusKind.incomplete:
        return 'INCOMPLETE';
      case AdminStatusKind.critical:
        return 'Critical';
      case AdminStatusKind.highSeverity:
        return 'High';
      case AdminStatusKind.medium:
        return 'Medium';
      case AdminStatusKind.low:
        return 'Low';
    }
  }

  (Color, Color) _colors(FlutterFlowTheme theme) {
    switch (kind) {
      case AdminStatusKind.active:
      case AdminStatusKind.completed:
      case AdminStatusKind.paid:
      case AdminStatusKind.cashCollected:
      case AdminStatusKind.settled:
      case AdminStatusKind.high:
        return (const Color(0xFF0F7A4A), Colors.white);
      case AdminStatusKind.pending:
      case AdminStatusKind.draft:
      case AdminStatusKind.derived:
      case AdminStatusKind.medium:
      case AdminStatusKind.partiallyPaid:
        return (const Color(0xFFB06A00), Colors.white);
      case AdminStatusKind.cancelled:
      case AdminStatusKind.expired:
      case AdminStatusKind.voided:
      case AdminStatusKind.inactive:
      case AdminStatusKind.critical:
      case AdminStatusKind.incomplete:
        return (theme.error, Colors.white);
      case AdminStatusKind.locked:
      case AdminStatusKind.highSeverity:
        return (AdminUi.brandTeal, Colors.white);
      case AdminStatusKind.low:
      case AdminStatusKind.unknown:
        return (theme.secondaryText, Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final (bg, fg) = _colors(theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label ?? _defaultLabel(context),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'cairo',
        ),
      ),
    );
  }
}
