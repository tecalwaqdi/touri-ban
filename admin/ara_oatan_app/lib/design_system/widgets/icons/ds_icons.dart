import 'package:flutter/material.dart';

import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';

/// Icon size / color helpers using Material rounded symbols.
///
/// Prefer [Icons.*_rounded] / [Icons.*_outlined] for a consistent 2026 look.
abstract final class DsIcons {
  static const double xs = DsConstants.iconXs;
  static const double sm = DsConstants.iconSm;
  static const double md = DsConstants.iconMd;
  static const double lg = DsConstants.iconLg;
  static const double xl = DsConstants.iconXl;

  // Semantic aliases used across ride / wallet flows.
  static const IconData home = Icons.home_rounded;
  static const IconData bookings = Icons.receipt_long_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData wallet = Icons.account_balance_wallet_rounded;
  static const IconData car = Icons.directions_car_rounded;
  static const IconData map = Icons.map_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData chat = Icons.chat_bubble_outline_rounded;
  static const IconData support = Icons.support_agent_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData notification = Icons.notifications_none_rounded;
  static const IconData payment = Icons.credit_card_rounded;
  static const IconData success = Icons.check_circle_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
}

class DsIcon extends StatelessWidget {
  const DsIcon(
    this.icon, {
    super.key,
    this.size = DsIcons.md,
    this.color,
    this.muted = false,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    return Icon(
      icon,
      size: size,
      color: color ?? (muted ? colors.iconMuted : colors.icon),
    );
  }
}
