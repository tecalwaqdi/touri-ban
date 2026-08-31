import 'package:flutter/material.dart';

import '/admin/admin_suport/admin_support_adapter.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef AdminSupportOpenDetails = void Function(AdminSupportRow row);

class AdminSupportTable extends StatelessWidget {
  const AdminSupportTable({
    super.key,
    required this.rows,
    required this.onOpenDetails,
    required this.canEdit,
    required this.onResolve,
    required this.onClose,
  });

  final List<AdminSupportRow> rows;
  final AdminSupportOpenDetails onOpenDetails;
  final bool canEdit;
  final Future<void> Function(AdminSupportRow) onResolve;
  final Future<void> Function(AdminSupportRow) onClose;

  @override
  Widget build(BuildContext context) {
    final isWide = AdminUi.useTableLayout(context);
    if (isWide) {
      return _WideTable(
        rows: rows,
        onOpenDetails: onOpenDetails,
        canEdit: canEdit,
        onResolve: onResolve,
        onClose: onClose,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _TicketCard(
        row: rows[i],
        onOpenDetails: onOpenDetails,
        canEdit: canEdit,
        onResolve: onResolve,
        onClose: onClose,
      ),
    );
  }
}

class _WideTable extends StatelessWidget {
  const _WideTable({
    required this.rows,
    required this.onOpenDetails,
    required this.canEdit,
    required this.onResolve,
    required this.onClose,
  });

  final List<AdminSupportRow> rows;
  final AdminSupportOpenDetails onOpenDetails;
  final bool canEdit;
  final Future<void> Function(AdminSupportRow) onResolve;
  final Future<void> Function(AdminSupportRow) onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        width: AdminUi.adminTableMinWidth(context) + 200,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _h(uiTr(context, 'رقم التذكرة'), 2, theme),
                  _h(uiTr(context, 'صاحب التذكرة'), 2, theme),
                  _h(uiTr(context, 'النوع'), 1, theme),
                  _h(uiTr(context, 'العنوان'), 2, theme),
                  _h(uiTr(context, 'الحالة'), 2, theme),
                  _h(uiTr(context, 'الحجز'), 1, theme),
                  _h(uiTr(context, 'آخر تحديث'), 2, theme),
                  _h(uiTr(context, 'المسؤول'), 1, theme),
                  _h(uiTr(context, 'إجراءات'), 2, theme),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final row in rows)
              _Row(
                row: row,
                onOpenDetails: onOpenDetails,
                canEdit: canEdit,
                onResolve: onResolve,
                onClose: onClose,
              ),
          ],
        ),
      ),
    );
  }

  Widget _h(String t, int flex, FlutterFlowTheme theme) => Expanded(
        flex: flex,
        child: Text(
          t,
          style: theme.labelLarge.override(
            fontFamily: theme.labelLargeFamily,
            fontWeight: FontWeight.w700,
            color: AdminUi.brandTeal,
            useGoogleFonts: !theme.labelLargeIsCustom,
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.onOpenDetails,
    required this.canEdit,
    required this.onResolve,
    required this.onClose,
  });

  final AdminSupportRow row;
  final AdminSupportOpenDetails onOpenDetails;
  final bool canEdit;
  final Future<void> Function(AdminSupportRow) onResolve;
  final Future<void> Function(AdminSupportRow) onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final idLabel = row.legacyNumericId > 0
        ? '#${row.legacyNumericId}'
        : row.ticketId.substring(0, 8);
    return InkWell(
      onTap: () => onOpenDetails(row),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(idLabel, style: theme.bodySmall)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.ownerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      fontWeight: FontWeight.w600,
                      useGoogleFonts: !theme.bodyMediumIsCustom,
                    ),
                  ),
                  if (row.phoneLabel.isNotEmpty)
                    Text(row.phoneLabel, style: theme.bodySmall),
                ],
              ),
            ),
            Expanded(flex: 1, child: _OwnerTypeBadge(type: row.ownerType)),
            Expanded(
              flex: 2,
              child: Text(
                row.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall,
              ),
            ),
            Expanded(flex: 2, child: _StatusBadge(status: row.displayStatus)),
            Expanded(
              flex: 1,
              child: Text(
                row.hasOrderLink ? row.orderRef!.id.substring(0, 6) : '—',
                style: theme.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.updatedAt != null
                    ? dateTimeFormat('yMMMd', row.updatedAt)
                    : (row.createdAt != null
                        ? dateTimeFormat('yMMMd', row.createdAt)
                        : '—'),
                style: theme.bodySmall,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                row.assignedAdminId.isNotEmpty ? row.assignedAdminId : '—',
                style: theme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: _Actions(
                row: row,
                canEdit: canEdit,
                onOpen: () => onOpenDetails(row),
                onResolve: () => onResolve(row),
                onClose: () => onClose(row),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.row,
    required this.onOpenDetails,
    required this.canEdit,
    required this.onResolve,
    required this.onClose,
  });

  final AdminSupportRow row;
  final AdminSupportOpenDetails onOpenDetails;
  final bool canEdit;
  final Future<void> Function(AdminSupportRow) onResolve;
  final Future<void> Function(AdminSupportRow) onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: () => onOpenDetails(row),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AdminUi.cardDecoration(context, elevated: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.subject,
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                ),
                _StatusBadge(status: row.displayStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text('${row.ownerName} · ${_ownerLabel(context, row.ownerType)}'),
            const SizedBox(height: 6),
            Text(
              row.messagePreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
            const SizedBox(height: 10),
            _Actions(
              row: row,
              canEdit: canEdit,
              onOpen: () => onOpenDetails(row),
              onResolve: () => onResolve(row),
              onClose: () => onClose(row),
            ),
          ],
        ),
      ),
    );
  }
}

String _ownerLabel(BuildContext context, AdminSupportOwnerType type) =>
    switch (type) {
      AdminSupportOwnerType.customer => uiTr(context, 'عميل'),
      AdminSupportOwnerType.driver => uiTr(context, 'مندوب'),
      AdminSupportOwnerType.unknown => uiTr(context, 'غير محدد'),
    };

class _OwnerTypeBadge extends StatelessWidget {
  const _OwnerTypeBadge({required this.type});
  final AdminSupportOwnerType type;

  @override
  Widget build(BuildContext context) {
    final label = _ownerLabel(context, type);
    final kind = switch (type) {
      AdminSupportOwnerType.customer => AdminStatusKind.active,
      AdminSupportOwnerType.driver => AdminStatusKind.pending,
      AdminSupportOwnerType.unknown => AdminStatusKind.unknown,
    };
    return AdminStatusBadgeUnified(kind: kind, label: label);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AdminSupportDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final (kind, label) = switch (status) {
      AdminSupportDisplayStatus.newTicket => (
          AdminStatusKind.draft,
          uiTr(context, 'جديدة'),
        ),
      AdminSupportDisplayStatus.open => (
          AdminStatusKind.pending,
          uiTr(context, 'مفتوحة'),
        ),
      AdminSupportDisplayStatus.inProgress => (
          AdminStatusKind.high,
          uiTr(context, 'قيد المعالجة'),
        ),
      AdminSupportDisplayStatus.waitingUser => (
          AdminStatusKind.medium,
          uiTr(context, 'بانتظار العميل'),
        ),
      AdminSupportDisplayStatus.resolved => (
          AdminStatusKind.completed,
          uiTr(context, 'تم الحل'),
        ),
      AdminSupportDisplayStatus.closed => (
          AdminStatusKind.cancelled,
          uiTr(context, 'مغلقة'),
        ),
      AdminSupportDisplayStatus.unknown => (
          AdminStatusKind.unknown,
          uiTr(context, 'غير معروف'),
        ),
    };
    return AdminStatusBadgeUnified(kind: kind, label: label);
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.row,
    required this.canEdit,
    required this.onOpen,
    required this.onResolve,
    required this.onClose,
  });

  final AdminSupportRow row;
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback onResolve;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 34,
          fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AdminUi.brandTeal),
          onPressed: onOpen,
        ),
        if (canEdit && !row.isTerminal) ...[
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 34,
            fillColor: const Color(0xFFE8F5E9),
            icon: Icon(Icons.check_circle_outline_rounded, color: FlutterFlowTheme.of(context).success, size: 18),
            onPressed: onResolve,
          ),
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 34,
            fillColor: const Color(0xFFFFEBEE),
            icon: Icon(Icons.close_rounded, color: FlutterFlowTheme.of(context).error, size: 18),
            onPressed: onClose,
          ),
        ],
      ],
    );
  }
}
