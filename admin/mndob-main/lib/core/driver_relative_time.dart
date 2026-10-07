import 'package:flutter/material.dart';

import '/core/driver_i18n.dart';

/// Locale-aware relative time — no English grammar concatenation.
///
/// Uses plural keys for 1 / 2 / 5+ minutes and 1 / 2 / 3+ hours so Arabic
/// (and other langs) can supply dual/plural forms without English templates.
abstract final class DriverRelativeTime {
  DriverRelativeTime._();

  static String format(
    BuildContext? context,
    DateTime? when, {
    DateTime? now,
  }) {
    if (when == null) return '';
    final n = now ?? DateTime.now();
    var diff = n.difference(when);
    if (diff.isNegative) diff = Duration.zero;

    final totalMinutes = diff.inMinutes;
    if (totalMinutes < 1) {
      return driverTr(context, 'Just now');
    }
    if (totalMinutes < 60) {
      return _minutesAgo(context, totalMinutes);
    }
    final hours = diff.inHours;
    if (hours < 24) {
      return _hoursAgo(context, hours);
    }
    final days = diff.inDays;
    if (days == 1) {
      return driverTr(context, '1 day ago');
    }
    if (days == 2) {
      return driverTr(context, '2 days ago');
    }
    return driverTrNamed(context, '{count} days ago', {'count': '$days'});
  }

  static String _minutesAgo(BuildContext? context, int minutes) {
    if (minutes == 1) {
      return driverTr(context, '1 minute ago');
    }
    if (minutes == 2) {
      return driverTr(context, '2 minutes ago');
    }
    return driverTrNamed(
      context,
      '{count} minutes ago',
      {'count': '$minutes'},
    );
  }

  static String _hoursAgo(BuildContext? context, int hours) {
    if (hours == 1) {
      return driverTr(context, '1 hour ago');
    }
    if (hours == 2) {
      return driverTr(context, '2 hours ago');
    }
    return driverTrNamed(
      context,
      '{count} hours ago',
      {'count': '$hours'},
    );
  }

  /// ETA / remaining phrasing without English concat.
  static String etaMinutes(BuildContext? context, int minutes, {bool approximate = false}) {
    final base = minutes <= 0
        ? driverTr(context, 'ETA')
        : driverTrNamed(context, 'ETA ~ {min} min', {'min': '$minutes'});
    if (!approximate) return base;
    return driverTrNamed(context, 'Approximately {value}', {'value': base});
  }

  static String remaining(BuildContext? context, String timeLabel) {
    return driverTrNamed(context, '{time} remaining', {'time': timeLabel});
  }

  static String waiting(BuildContext? context, String timeLabel) {
    return driverTrNamed(context, 'Waiting {time}', {'time': timeLabel});
  }
}
