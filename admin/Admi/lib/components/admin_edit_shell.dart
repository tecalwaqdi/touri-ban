import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Shared shell for admin edit/create forms (full screen, back + scroll).
class AdminEditScaffold extends StatelessWidget {
  const AdminEditScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    required this.child,
    this.floatingAction,
  });

  final String title;
  final String? subtitle;
  final bool isLoading;
  final Widget child;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: _buildAppBar(context, theme),
        body: const Center(
          child: SpinKitThreeBounce(
            color: AdminUi.brandTeal,
            size: 48,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AdminUi.pagePadding(context).add(
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
              if (floatingAction != null) ...[
                const SizedBox(height: 20),
                floatingAction!,
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    FlutterFlowTheme theme,
  ) {
    return AppBar(
      backgroundColor: AdminUi.brandTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.titleMedium.override(
          fontFamily: theme.titleMediumFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          useGoogleFonts: !theme.titleMediumIsCustom,
        ),
      ),
    );
  }
}

/// Card section inside edit forms.
class AdminEditFormCard extends StatelessWidget {
  const AdminEditFormCard({
    super.key,
    this.sectionTitle,
    required this.children,
  });

  final String? sectionTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: AdminUi.cardDecoration(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sectionTitle != null) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AdminUi.brandTeal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sectionTitle!,
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Tappable row to open a bottom-sheet picker.
class AdminEditPickerRow extends StatelessWidget {
  const AdminEditPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.locked = false,
  });

  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData icon;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final display = value.trim().isNotEmpty ? value : placeholder;
    final isPlaceholder = value.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.labelMedium.override(
            fontFamily: theme.labelMediumFamily,
            color: theme.secondaryText,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelMediumIsCustom,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: locked ? null : onTap,
            borderRadius: BorderRadius.circular(AdminUi.radiusSm),
            child: Ink(
              decoration: BoxDecoration(
                color: locked
                    ? const Color(0xFFF5F5F5)
                    : theme.secondaryBackground,
                borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                border: Border.all(color: theme.alternate),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.touch_app_rounded,
                    size: 18,
                    color: locked
                        ? theme.secondaryText
                        : AdminUi.brandTeal.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: isPlaceholder
                            ? theme.secondaryText
                            : theme.primaryText,
                        fontWeight:
                            isPlaceholder ? FontWeight.w500 : FontWeight.w600,
                        useGoogleFonts: !theme.bodyMediumIsCustom,
                      ),
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_outline : icon,
                    color: theme.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Switch row for activation toggles.
class AdminEditSwitchRow extends StatelessWidget {
  const AdminEditSwitchRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AdminUi.brandTeal,
          ),
        ],
      ),
    );
  }
}

Future<void> showAdminPickerSheet({
  required BuildContext context,
  required Widget child,
  double heightFactor = 0.75,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * heightFactor;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SizedBox(
          height: maxHeight,
          child: child,
        ),
      );
    },
  );
}
