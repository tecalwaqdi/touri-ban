import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef AdminDriverToggle =
    Future<void> Function(UserRecord user, {required bool activate});

typedef AdminDriverOpenDetails = void Function(UserRecord user);

/// Drivers table + mobile cards (drivers-only).
class AdminDriversTable extends StatelessWidget {
  const AdminDriversTable({
    super.key,
    required this.rows,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final List<AdminDriverRow> rows;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

  @override
  Widget build(BuildContext context) {
    final isWide = AdminUi.useTableLayout(context);
    if (isWide) {
      return _WideTable(
        rows: rows,
        onToggle: onToggle,
        onOpenDetails: onOpenDetails,
        onEdit: onEdit,
        onReview: onReview,
        onDocuments: onDocuments,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _DriverCard(
        row: rows[i],
        onToggle: onToggle,
        onOpenDetails: onOpenDetails,
        onEdit: onEdit,
        onReview: onReview,
        onDocuments: onDocuments,
      ),
    );
  }
}

class _WideTable extends StatelessWidget {
  const _WideTable({
    required this.rows,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final List<AdminDriverRow> rows;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth < 980
            ? 980.0
            : constraints.maxWidth;
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minWidth,
              child: Column(
                children: [
                  _Header(theme: theme),
                  ...rows.map(
                    (row) => _DataRow(
                      row: row,
                      theme: theme,
                      onToggle: onToggle,
                      onOpenDetails: onOpenDetails,
                      onEdit: onEdit,
                      onReview: onReview,
                      onDocuments: onDocuments,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {int flex = 2}) => Expanded(
      flex: flex,
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.labelLarge.override(
          fontFamily: theme.labelLargeFamily,
          fontWeight: FontWeight.w800,
          color: AdminUi.brandTeal,
          useGoogleFonts: !theme.labelLargeIsCustom,
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          cell(uiTr(context, 'المندوب'), flex: 3),
          cell(uiTr(context, 'الهاتف')),
          cell(uiTr(context, 'المدينة')),
          cell(uiTr(context, 'المركبة'), flex: 3),
          cell(uiTr(context, 'التسجيل')),
          cell(uiTr(context, 'الحالة التشغيلية'), flex: 2),
          cell(uiTr(context, 'الرحلات')),
          cell(uiTr(context, 'الإجراءات'), flex: 2),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.theme,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final AdminDriverRow row;
  final FlutterFlowTheme theme;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onOpenDetails(row.user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.55)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: _DriverIdentity(row: row)),
            Expanded(flex: 2, child: _text(theme, row.phone, mono: true)),
            Expanded(flex: 2, child: _text(theme, row.city)),
            Expanded(flex: 3, child: _VehicleCell(row: row)),
            Expanded(
              flex: 2,
              child: AdminDriverRegistrationStatusCell(row: row),
            ),
            Expanded(flex: 2, child: AdminDriverOperationalStatus(row: row)),
            Expanded(flex: 2, child: _text(theme, row.tripsLabel)),
            Expanded(
              flex: 2,
              child: _Actions(
                row: row,
                onToggle: onToggle,
                onOpenDetails: onOpenDetails,
                onEdit: onEdit,
                onReview: onReview,
                onDocuments: onDocuments,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _text(FlutterFlowTheme theme, String v, {bool mono = false}) {
    return Text(
      v,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.bodyMedium.override(
        fontFamily: theme.bodyMediumFamily,
        useGoogleFonts: !theme.bodyMediumIsCustom,
      ),
    );
  }
}

class _DriverIdentity extends StatelessWidget {
  const _DriverIdentity({required this.row});
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final email = row.user.email.trim();
    return Row(
      children: [
        AdminDriverAvatar(
          photoUrl: row.photoUrl,
          displayName: row.displayName,
          size: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleSmall.override(
                  fontFamily: theme.titleSmallFamily,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.titleSmallIsCustom,
                ),
              ),
              if (email.isNotEmpty)
                AdminDriverEmailLine(
                  email: email,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                )
              else
                Text(
                  row.secondaryLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleCell extends StatelessWidget {
  const _VehicleCell({required this.row});
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final v = row.vehicle;
    if (v.isLegacyIncomplete) {
      return Text(
        v.missingLabel(context),
        style: theme.bodySmall.override(
          fontFamily: theme.bodySmallFamily,
          color: theme.secondaryText,
          useGoogleFonts: !theme.bodySmallIsCustom,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v.titleLine.isNotEmpty)
          Text(
            v.titleLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              fontWeight: FontWeight.w600,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        if (v.classLine.isNotEmpty)
          Text(
            v.classLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        if (v.plate.isNotEmpty)
          Text(
            v.plateLine(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.row,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final AdminDriverRow row;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

  @override
  Widget build(BuildContext context) {
    final showReview =
        row.review == AdminDriverReviewBucket.pendingReview ||
        row.review == AdminDriverReviewBucket.needsChanges;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: uiTr(context, 'عرض التفاصيل'),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: AdminUi.brandTeal,
            onPressed: () => onOpenDetails(row.user),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: uiTr(context, 'إجراءات'),
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                onEdit(row.user);
              case 'docs':
                onDocuments(row.user);
              case 'review':
                onReview(row.user);
              case 'deactivate':
                await onToggle(row.user, activate: false);
              case 'activate':
                await onToggle(row.user, activate: true);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(uiTr(context, 'تعديل'))),
            PopupMenuItem(value: 'docs', child: Text(uiTr(context, 'الوثائق'))),
            if (showReview)
              PopupMenuItem(
                value: 'review',
                child: Text(uiTr(context, 'مراجعة التسجيل')),
              ),
            PopupMenuItem(
              value: row.accountActive ? 'deactivate' : 'activate',
              child: Text(
                row.accountActive
                    ? appTr(context, 'adm_drv_deactivate_action')
                    : uiTr(context, 'تفعيل الحساب'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.row,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final AdminDriverRow row;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onOpenDetails(row.user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _DriverIdentity(row: row)),
                  _Actions(
                    row: row,
                    onToggle: onToggle,
                    onOpenDetails: onOpenDetails,
                    onEdit: onEdit,
                    onReview: onReview,
                    onDocuments: onDocuments,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('${uiTr(context, 'الهاتف')}: ${row.phone}'),
              Text('${uiTr(context, 'المدينة')}: ${row.city}'),
              const SizedBox(height: 6),
              _VehicleCell(row: row),
              const SizedBox(height: 8),
              AdminDriverRegistrationStatusCell(row: row),
              const SizedBox(height: 6),
              AdminDriverOperationalStatus(row: row),
            ],
          ),
        ),
      ),
    );
  }
}
