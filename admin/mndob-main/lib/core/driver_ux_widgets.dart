import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/core/driver_design_system.dart';
import '/core/driver_i18n.dart';
import '/design_system/design_system.dart';

/// مساحة أفقية موحّدة للشاشات الرئيسية.
class DriverPagePadding extends StatelessWidget {
  const DriverPagePadding({
    super.key,
    required this.child,
    this.horizontal = DsSpacing.md,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double horizontal;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
      child: child,
    );
  }
}

/// شريط علوي بسيط بهوية توري.
class DriverMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DriverMainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return AppBar(
      title: Text(
        title,
        style: typography.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      leading: leading,
      actions: actions,
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}

/// حالة فارغة موحّدة — تغليف [DsEmptyState] مع API المندوب.
class DriverEmptyState extends StatelessWidget {
  const DriverEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      title: title,
      message: message,
      icon: icon,
      action: actionLabel == null || onAction == null
          ? null
          : DsButton.primary(
              label: actionLabel!,
              icon: Icons.refresh_rounded,
              onPressed: onAction,
              expanded: true,
            ),
    );
  }
}

/// زر أساسي بهوية توري — تغليف [DsButton.primary].
class DriverGradientButton extends StatelessWidget {
  const DriverGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return DsButton.primary(
      label: label,
      onPressed: onPressed,
      icon: icon,
      expanded: expanded,
      size: height >= 52 ? DsButtonSize.lg : DsButtonSize.md,
    );
  }
}

/// صورة شبكة مع بديل آمن.
class DriverNetworkImage extends StatelessWidget {
  const DriverNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.person_rounded,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final clean = (url ?? '').trim();
    final placeholder = Container(
      width: width,
      height: height,
      color: colors.primarySoft,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: colors.primaryStrong),
    );

    Widget child;
    if (clean.isEmpty ||
        !(clean.startsWith('http') || clean.startsWith('data:'))) {
      child = placeholder;
    } else {
      child = CachedNetworkImage(
        imageUrl: clean,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// بطاقة طلب موحّدة لقوائم المندوب.
class DriverOrderCardShell extends StatelessWidget {
  const DriverOrderCardShell({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      elevated: true,
      padding: DsSpacing.cardPadding,
      child: child,
    );
  }
}

String driverNoOrdersTitle(BuildContext context) =>
    driverTr(context, 'No orders');

String driverNoOrdersMessage(BuildContext context) =>
    driverTr(context, 'New orders will appear here when available');

/// Attractive searching panel while waiting for open pool orders.
class DriverSearchingOrdersPanel extends StatelessWidget {
  const DriverSearchingOrdersPanel({
    super.key,
    this.areaName = '',
    this.isOnline = true,
    this.onGoOnline,
  });

  final String areaName;
  final bool isOnline;
  final VoidCallback? onGoOnline;

  @override
  Widget build(BuildContext context) {
    final teal = DriverBrand.teal;
    final title = isOnline
        ? driverTrNamed(
            context,
            'Searching for trips in {area}',
            {'area': areaName.trim().isEmpty ? '…' : areaName.trim()},
          )
        : driverTr(context, 'Go online to receive requests.');
    final subtitle = isOnline
        ? driverTr(
            context,
            'New orders will appear here when available',
          )
        : driverTr(
            context,
            'To receive orders, activate online mode now.',
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PulseRing(color: teal.withValues(alpha: 0.12), size: 140)
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.15, 1.15),
                      duration: 1600.ms,
                      curve: Curves.easeOut,
                    )
                    .fade(begin: 0.9, end: 0.2, duration: 1600.ms),
                _PulseRing(color: teal.withValues(alpha: 0.22), size: 100)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.06, 1.06),
                      duration: 1200.ms,
                    ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DriverBrand.softGradient,
                    boxShadow: [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.radar_rounded
                        : Icons.power_settings_new_rounded,
                    color: teal,
                    size: 34,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .rotate(begin: -0.03, end: 0.03, duration: 1800.ms),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DriverBrand.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 13,
              height: 1.4,
              color: DriverBrand.textSecondaryColor(context),
            ),
          ),
          if (!isOnline && onGoOnline != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onGoOnline,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  driverTr(context, 'Connect to receive orders'),
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
