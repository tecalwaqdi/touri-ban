import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef AdminDriverToggle = Future<void> Function(
  UserRecord user, {
  required bool activate,
});

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
        final minWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminStatusBadgeUnified(
                    kind: AdminDriverStatusLabels.registrationKind(row.review),
                    label: AdminDriverStatusLabels.registration(
                      context,
                      row.review,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AdminStatusBadgeUnified(
                    kind: AdminDriverStatusLabels.accountKind(row.accountActive),
                    label: AdminDriverStatusLabels.account(
                      context,
                      row.accountActive,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                AdminDriverStatusLabels.operationalLine(context, row),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ),
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
    return Row(
      children: [
        ProfilePhotoImage(
          photoUrl: row.photoUrl,
          size: 40,
          borderRadius: BorderRadius.circular(20),
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
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _icon(
          context,
          tip: uiTr(context, 'عرض'),
          icon: Icons.visibility_outlined,
          color: AdminUi.brandTeal,
          onTap: () => onOpenDetails(row.user),
        ),
        _icon(
          context,
          tip: uiTr(context, 'تعديل'),
          icon: Icons.edit_outlined,
          color: Colors.blue.shade700,
          onTap: () => onEdit(row.user),
        ),
        _icon(
          context,
          tip: uiTr(context, 'مراجعة التسجيل'),
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => onReview(row.user),
        ),
        _icon(
          context,
          tip: uiTr(context, 'الوثائق'),
          icon: Icons.folder_open_outlined,
          color: const Color(0xFFEF6C00),
          onTap: () => onDocuments(row.user),
        ),
        PopupMenuButton<String>(
          tooltip: uiTr(context, 'المزيد'),
          onSelected: (v) async {
            switch (v) {
              case 'approve':
              case 'reject':
              case 'needs':
                onReview(row.user);
                break;
              case 'suspend':
                await onToggle(row.user, activate: false);
                break;
              case 'activate':
                await onToggle(row.user, activate: true);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'approve',
              child: Text(uiTr(context, 'اعتماد')),
            ),
            PopupMenuItem(
              value: 'reject',
              child: Text(uiTr(context, 'رفض')),
            ),
            PopupMenuItem(
              value: 'needs',
              child: Text(uiTr(context, 'طلب تعديلات')),
            ),
            PopupMenuItem(
              value: row.accountActive ? 'suspend' : 'activate',
              child: Text(
                row.accountActive
                    ? uiTr(context, 'إيقاف الحساب')
                    : uiTr(context, 'تفعيل الحساب'),
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.more_vert_rounded, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _icon(
    BuildContext context, {
    required String tip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AdminStatusBadgeUnified(
                    kind: AdminDriverStatusLabels.registrationKind(row.review),
                    label: AdminDriverStatusLabels.registration(
                      context,
                      row.review,
                    ),
                  ),
                  AdminStatusBadgeUnified(
                    kind: AdminDriverStatusLabels.accountKind(row.accountActive),
                    label: AdminDriverStatusLabels.account(
                      context,
                      row.accountActive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(AdminDriverStatusLabels.operationalLine(context, row)),
            ],
          ),
        ),
      ),
    );
  }
}
