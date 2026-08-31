import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/admin/adminuser/admin_customers_adapter.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef AdminCustomerToggle = Future<void> Function(
  UserRecord user, {
  required bool activate,
});

typedef AdminCustomerOpen = void Function(UserRecord user);

class AdminCustomersTable extends StatelessWidget {
  const AdminCustomersTable({
    super.key,
    required this.rows,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final List<AdminCustomerRow> rows;
  final AdminCustomerToggle onToggle;
  final AdminCustomerOpen onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final isWide = AdminUi.useTableLayout(context);
    if (isWide) {
      return _DesktopTable(
        rows: rows,
        onToggle: onToggle,
        onOpenDetails: onOpenDetails,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _MobileCard(
        row: rows[i],
        onToggle: onToggle,
        onOpenDetails: onOpenDetails,
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.rows,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final List<AdminCustomerRow> rows;
  final AdminCustomerToggle onToggle;
  final AdminCustomerOpen onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  uiTr(context, 'المستخدم'),
                  style: _headerStyle(theme),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  uiTr(context, 'رقم الهاتف'),
                  style: _headerStyle(theme),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  uiTr(context, 'الحالة'),
                  style: _headerStyle(theme),
                ),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  uiTr(context, 'الإجراءات'),
                  style: _headerStyle(theme),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.alternate.withValues(alpha: 0.6)),
        for (final row in rows)
          _DesktopRow(
            row: row,
            onToggle: onToggle,
            onOpenDetails: onOpenDetails,
          ),
      ],
    );
  }

  TextStyle _headerStyle(FlutterFlowTheme theme) => theme.labelMedium.override(
        fontFamily: theme.labelMediumFamily,
        fontWeight: FontWeight.w600,
        color: theme.secondaryText,
        useGoogleFonts: !theme.labelMediumIsCustom,
      );
}

class _DesktopRow extends StatefulWidget {
  const _DesktopRow({
    required this.row,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final AdminCustomerRow row;
  final AdminCustomerToggle onToggle;
  final AdminCustomerOpen onOpenDetails;

  @override
  State<_DesktopRow> createState() => _DesktopRowState();
}

class _DesktopRowState extends State<_DesktopRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover
            ? theme.alternate.withValues(alpha: 0.22)
            : Colors.transparent,
        child: InkWell(
          onTap: () => widget.onOpenDetails(widget.row.user),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.alternate.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _UserIdentityCell(row: widget.row),
                ),
                Expanded(
                  flex: 3,
                  child: _PhoneCell(row: widget.row),
                ),
                Expanded(
                  flex: 2,
                  child: _StatusBadge(row: widget.row),
                ),
                SizedBox(
                  width: 88,
                  child: _ActionsMenu(
                    row: widget.row,
                    onToggle: widget.onToggle,
                    onOpenDetails: widget.onOpenDetails,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.row,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final AdminCustomerRow row;
  final AdminCustomerToggle onToggle;
  final AdminCustomerOpen onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onOpenDetails(row.user),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.alternate.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCustomerAvatar(
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
                    if (row.email != '—') ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Text(
                          row.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _PhoneCell(row: row, compact: true),
                    const SizedBox(height: 6),
                    _StatusBadge(row: row),
                  ],
                ),
              ),
              _ActionsMenu(
                row: row,
                onToggle: onToggle,
                onOpenDetails: onOpenDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.row});
  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        AdminCustomerAvatar(
          photoUrl: row.photoUrl,
          displayName: row.displayName,
          size: 38,
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
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
              if (row.email != '—') ...[
                const SizedBox(height: 2),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      row.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PhoneCell extends StatelessWidget {
  const _PhoneCell({required this.row, this.compact = false});
  final AdminCustomerRow row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final display = AdminCustomerRow.formatPhoneDisplay(row.phone);
    if (display == '—') {
      return Text(
        '—',
        style: theme.bodySmall.override(
          fontFamily: theme.bodySmallFamily,
          color: theme.secondaryText,
          useGoogleFonts: !theme.bodySmallIsCustom,
        ),
      );
    }
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Flexible(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  fontWeight: FontWeight.w500,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ),
          ),
        ),
        if (!compact && row.phone != '—')
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: uiTr(context, 'نسخ'),
            icon: Icon(Icons.copy_rounded, size: 14, color: theme.secondaryText),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: row.phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(uiTr(context, 'تم النسخ')),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.row});
  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final (label, bg, fg) = switch (row.accountStatus) {
      AdminCustomerAccountStatus.active => (
          uiTr(context, 'نشط'),
          theme.success.withValues(alpha: 0.12),
          theme.success,
        ),
      AdminCustomerAccountStatus.suspended => (
          uiTr(context, 'موقوف'),
          theme.error.withValues(alpha: 0.1),
          theme.error,
        ),
      AdminCustomerAccountStatus.unknown => (
          uiTr(context, 'غير محدد'),
          theme.alternate.withValues(alpha: 0.35),
          theme.secondaryText,
        ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: fg,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.row,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final AdminCustomerRow row;
  final AdminCustomerToggle onToggle;
  final AdminCustomerOpen onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: uiTr(context, 'عرض التفاصيل'),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: () => onOpenDetails(row.user),
          icon: Icon(
            Icons.visibility_outlined,
            size: 18,
            color: AdminUi.brandTeal,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: uiTr(context, 'المزيد'),
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert_rounded, size: 18, color: theme.secondaryText),
          onSelected: (v) {
            switch (v) {
              case 'view':
                onOpenDetails(row.user);
              case 'suspend':
                onToggle(row.user, activate: false);
              case 'activate':
                onToggle(row.user, activate: true);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'view',
              child: Text(uiTr(context, 'عرض التفاصيل')),
            ),
            if (row.accountStatus != AdminCustomerAccountStatus.suspended)
              PopupMenuItem(
                value: 'suspend',
                child: Text(
                  uiTr(context, 'إيقاف الحساب'),
                  style: TextStyle(color: theme.error),
                ),
              )
            else
              PopupMenuItem(
                value: 'activate',
                child: Text(
                  uiTr(context, 'تنشيط الحساب'),
                  style: TextStyle(color: theme.success),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Avatar with [ProfilePhotoImage] or initials placeholder.
class AdminCustomerAvatar extends StatelessWidget {
  const AdminCustomerAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.size = 40,
  });

  final String photoUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (photoUrl.trim().isEmpty) {
      final initials = AdminCustomerRow.initialsOf(displayName);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AdminUi.brandTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: AdminUi.brandTeal.withValues(alpha: 0.18),
          ),
        ),
        alignment: Alignment.center,
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.brandTeal,
                  useGoogleFonts: !theme.labelMediumIsCustom,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.48,
                color: AdminUi.brandTeal.withValues(alpha: 0.7),
              ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: ProfilePhotoImage(photoUrl: photoUrl, size: size),
    );
  }
}
