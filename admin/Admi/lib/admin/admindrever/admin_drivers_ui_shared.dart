import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Shared Modern Classic Admin widgets for the Drivers module.
class AdminDriverModuleScaffold extends StatelessWidget {
  const AdminDriverModuleScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    this.loadingMessage,
    required this.body,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final bool isLoading;
  /// Shown under the spinner while [isLoading] — never leave a blank white body.
  final String? loadingMessage;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final loadMsg = (loadingMessage ?? '').trim();

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        foregroundColor: theme.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium.override(
                fontFamily: theme.titleMediumFamily,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.titleMediumIsCustom,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              Text(
                subtitle!,
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
      body: isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    if (loadMsg.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadMsg,
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.bodyMediumIsCustom,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : body,
      bottomNavigationBar: bottomBar,
    );
  }
}

class AdminDriverCompactTip extends StatelessWidget {
  const AdminDriverCompactTip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AdminUi.brandTeal.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.labelMedium.override(
                fontFamily: theme.labelMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelMediumIsCustom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDriverFormGrid extends StatelessWidget {
  const AdminDriverFormGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSpacing(children, 12),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i + 1 < children.length) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 14),
              Expanded(child: children[i + 1]),
            ],
          ),
        );
        if (i + 2 < children.length) rows.add(const SizedBox(height: 12));
      } else {
        rows.add(children[i]);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }
}

class AdminDriverStickyActions extends StatelessWidget {
  const AdminDriverStickyActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.primaryLoading = false,
    this.primaryIcon,
    this.showPrimary = true,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;
  final bool primaryLoading;
  final IconData? primaryIcon;
  final bool showPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      elevation: 6,
      color: theme.secondaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: primaryLoading
                    ? null
                    : (onCancel ?? () => Navigator.of(context).maybePop()),
                child: Text(uiTr(context, 'إلغاء')),
              ),
              if (showPrimary) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AdminPrimaryButton(
                    label: primaryLabel,
                    icon: primaryIcon ?? Icons.save_rounded,
                    isLoading: primaryLoading,
                    onPressed: primaryLoading ? null : onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDriverSectionCard extends StatelessWidget {
  const AdminDriverSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AdminUi.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AdminUi.brandTeal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class AdminDriverKvRow extends StatelessWidget {
  const AdminDriverKvRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                color: muted ? theme.secondaryText : theme.primaryText,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ),
          if (copyable && display != '—')
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: uiTr(context, 'نسخ'),
              onPressed: () {
                // Clipboard handled by parent if needed.
              },
            ),
        ],
      ),
    );
  }
}

class AdminDriverAvatar extends StatelessWidget {
  const AdminDriverAvatar({
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
    if (photoUrl.trim().isEmpty) {
      final initials = AdminDriverRow.initialsOf(displayName);
      final theme = FlutterFlowTheme.of(context);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AdminUi.brandTeal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: theme.labelLarge.override(
            fontFamily: theme.labelLargeFamily,
            fontWeight: FontWeight.w800,
            color: AdminUi.brandTeal,
            useGoogleFonts: !theme.labelLargeIsCustom,
          ),
        ),
      );
    }
    return ProfilePhotoImage(
      photoUrl: photoUrl,
      size: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

class AdminDriverProfileHeader extends StatelessWidget {
  const AdminDriverProfileHeader({
    super.key,
    required this.row,
    this.showEmail = true,
    this.showPhone = true,
    this.includeOperationalAxes = true,
  });

  final AdminDriverRow row;
  final bool showEmail;
  final bool showPhone;

  /// When false, connection/availability are owned by a sibling
  /// [AdminDriverOperationalStatus] section (one visual owner per axis).
  final bool includeOperationalAxes;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final email = row.user.email.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminDriverAvatar(
          photoUrl: row.photoUrl,
          displayName: row.displayName,
          size: 56,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.displayName,
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  fontWeight: FontWeight.w800,
                  useGoogleFonts: !theme.titleMediumIsCustom,
                ),
              ),
              if (showEmail && email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
              ],
              if (showPhone) ...[
                const SizedBox(height: 2),
                Text(
                  AdminDriverRow.formatPhoneDisplay(row.phone),
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              AdminDriverStatusStack(
                row: row,
                includeOperationalAxes: includeOperationalAxes,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminDriverStatusStack extends StatelessWidget {
  const AdminDriverStatusStack({
    super.key,
    required this.row,
    this.includeOperationalAxes = true,
  });

  final AdminDriverRow row;
  final bool includeOperationalAxes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _miniBadge(
          context,
          AdminDriverStatusLabels.registrationKind(row.review),
          AdminDriverStatusLabels.registration(context, row.review),
        ),
        _miniBadge(
          context,
          AdminDriverStatusLabels.accountKind(row.accountActive),
          AdminDriverStatusLabels.account(context, row.accountActive),
        ),
        if (includeOperationalAxes &&
            row.connection != AdminDriverConnectionStatus.unknown)
          _miniBadge(
            context,
            AdminDriverStatusLabels.connectionKind(row.connection),
            AdminDriverStatusLabels.connection(context, row.connection),
          ),
        if (includeOperationalAxes &&
            row.availability != AdminDriverAvailabilityStatus.unknown)
          _miniBadge(
            context,
            AdminDriverStatusLabels.availabilityKind(row.availability),
            AdminDriverStatusLabels.availability(context, row.availability),
          ),
      ],
    );
  }

  Widget _miniBadge(BuildContext context, AdminStatusKind kind, String label) {
    return AdminStatusBadgeUnified(kind: kind, label: label);
  }
}

class AdminDriverOperationalStatus extends StatelessWidget {
  const AdminDriverOperationalStatus({super.key, required this.row});

  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (row.connection == AdminDriverConnectionStatus.offline ||
        row.connection == AdminDriverConnectionStatus.unknown) {
      return Text(
        AdminDriverStatusLabels.connection(context, row.connection),
        style: theme.bodySmall.override(
          fontFamily: theme.bodySmallFamily,
          color: theme.secondaryText,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.bodySmallIsCustom,
        ),
      );
    }

    final dotColor = row.connection == AdminDriverConnectionStatus.online
        ? const Color(0xFF00897B)
        : theme.secondaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                AdminDriverStatusLabels.connection(context, row.connection),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ),
          ],
        ),
        if (row.connection == AdminDriverConnectionStatus.online) ...[
          const SizedBox(height: 2),
          Text(
            AdminDriverStatusLabels.availability(context, row.availability),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
        if (row.onActiveTrip)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              uiTr(context, 'في رحلة'),
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: Colors.deepOrange.shade700,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
      ],
    );
  }
}

class AdminDriverRegistrationStatusCell extends StatelessWidget {
  const AdminDriverRegistrationStatusCell({super.key, required this.row});

  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminStatusBadgeUnified(
          kind: AdminDriverStatusLabels.registrationKind(row.review),
          label: AdminDriverStatusLabels.registration(context, row.review),
        ),
        const SizedBox(height: 4),
        AdminStatusBadgeUnified(
          kind: AdminDriverStatusLabels.accountKind(row.accountActive),
          label: AdminDriverStatusLabels.account(context, row.accountActive),
        ),
      ],
    );
  }
}

class AdminDriverEmailLine extends StatelessWidget {
  const AdminDriverEmailLine({super.key, required this.email, this.style});

  final String email;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (email.trim().isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: email,
      waitDuration: const Duration(milliseconds: 400),
      child: Text(
        email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class AdminDriverTechnicalSection extends StatefulWidget {
  const AdminDriverTechnicalSection({super.key, required this.user});

  final UserRecord user;

  @override
  State<AdminDriverTechnicalSection> createState() =>
      _AdminDriverTechnicalSectionState();
}

class _AdminDriverTechnicalSectionState
    extends State<AdminDriverTechnicalSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final data = widget.user.snapshotData;
    return AdminDriverSectionCard(
      title: uiTr(context, 'معلومات تقنية'),
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(_open ? Icons.expand_less : Icons.expand_more, size: 20),
        onPressed: () => setState(() => _open = !_open),
      ),
      children: [
        if (!_open)
          Text(
            uiTr(context, 'اضغط لعرض المعرفات والحقول الداخلية'),
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          )
        else ...[
          AdminDriverKvRow(label: 'UID', value: widget.user.reference.id),
          AdminDriverKvRow(label: 'Auth UID', value: widget.user.uid),
          if (widget.user.driverid.isNotEmpty)
            AdminDriverKvRow(
              label: uiTr(context, 'رقم الهوية'),
              value: widget.user.driverid,
            ),
          AdminDriverKvRow(
            label: 'registration_flow_version',
            value: '${data['registration_flow_version'] ?? '—'}',
            muted: true,
          ),
          AdminDriverKvRow(
            label: 'reviewVersion',
            value: '${data['reviewVersion'] ?? '—'}',
            muted: true,
          ),
        ],
      ],
    );
  }
}
