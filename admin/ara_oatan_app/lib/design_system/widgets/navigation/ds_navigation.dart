import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DsAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        DsConstants.appBarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  style: typography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                )),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: bottom,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }
}

class DsBottomNavItem {
  const DsBottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class DsBottomNav extends StatelessWidget {
  const DsBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<DsBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: colors.navigation,
      indicatorColor: colors.selected,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          ),
      ],
    );
  }
}

class DsDrawer extends StatelessWidget {
  const DsDrawer({
    super.key,
    required this.header,
    required this.items,
    this.footer,
  });

  final Widget header;
  final List<Widget> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: DsSpacing.pagePadding,
              child: header,
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
                children: items,
              ),
            ),
            if (footer != null) ...[
              const Divider(),
              Padding(
                padding: DsSpacing.pagePadding,
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DsDrawerItem extends StatelessWidget {
  const DsDrawerItem({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colors.primary : colors.icon,
      ),
      title: Text(
        label,
        style: typography.titleSmall.copyWith(
          color: selected ? colors.primary : colors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: colors.selected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onTap: onTap,
    );
  }
}
