import 'package:easy_localization/easy_localization.dart';

/// Locale-aware relative time for the customer app (no English grammar concat).
abstract final class TouryRelativeTime {
  TouryRelativeTime._();

  static String format(DateTime? when, {DateTime? now}) {
    if (when == null) return '';
    final n = now ?? DateTime.now();
    var diff = n.difference(when);
    if (diff.isNegative) diff = Duration.zero;

    final totalMinutes = diff.inMinutes;
    if (totalMinutes < 1) return 'Just now'.tr();
    if (totalMinutes < 60) return _minutesAgo(totalMinutes);
    final hours = diff.inHours;
    if (hours < 24) return _hoursAgo(hours);
    final days = diff.inDays;
    if (days == 1) return '1 day ago'.tr();
    if (days == 2) return '2 days ago'.tr();
    return '{count} days ago'.tr(namedArgs: {'count': '$days'});
  }

  static String _minutesAgo(int minutes) {
    if (minutes == 1) return '1 minute ago'.tr();
    if (minutes == 2) return '2 minutes ago'.tr();
    return '{count} minutes ago'.tr(namedArgs: {'count': '$minutes'});
  }

  static String _hoursAgo(int hours) {
    if (hours == 1) return '1 hour ago'.tr();
    if (hours == 2) return '2 hours ago'.tr();
    return '{count} hours ago'.tr(namedArgs: {'count': '$hours'});
  }
}
