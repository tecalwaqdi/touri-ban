import '/backend/schema/order_record.dart';
import '/core/toury_system_status_codes.dart';

/// Resolves admin booking status display labels.
///
/// Preference order: machine `status_code` first, then legacy Arabic `halh_text`.
/// Arabic map is the temporary admin display surface (not i18n keys yet).
abstract final class AdminBookingStatusLabel {
  AdminBookingStatusLabel._();

  /// Canonical / aliased `status_code` → Arabic badge label (granular lifecycle).
  static const Map<String, String> codeToArabic = {
    TourySystemStatusCodes.pendingDriver: 'بانتظار قبول مندوب',
    TourySystemStatusCodes.legacyAwaitingDriver: 'بانتظار قبول مندوب',
    'pending': 'قيد الانتظار',
    'payment_pending': 'قيد الانتظار',
    'draft': 'قيد الانتظار',
    'payment': 'قيد الانتظار',
    TourySystemStatusCodes.driverAssigned: 'تم إسناد مندوب',
    TourySystemStatusCodes.driverArriving: 'المندوب في الطريق',
    TourySystemStatusCodes.driverArrived: 'وصل لنقطة الانطلاق',
    TourySystemStatusCodes.tripStarted: 'الرحلة بدأت',
    TourySystemStatusCodes.tripInProgress: 'الرحلة بدأت',
    TourySystemStatusCodes.completed: 'مكتملة',
    TourySystemStatusCodes.legacyTripCompleted: 'مكتملة',
    TourySystemStatusCodes.cancelledByAdmin: 'ملغية',
    TourySystemStatusCodes.cancelledByCustomer: 'ملغية',
    TourySystemStatusCodes.cancelledByDriver: 'ملغية',
    TourySystemStatusCodes.legacyCancelled: 'ملغية',
    TourySystemStatusCodes.legacyCanceled: 'ملغية',
    TourySystemStatusCodes.expired: 'منتهية الصلاحية',
  };

  /// Legacy Arabic (and close variants) → normalized Arabic badge label.
  static const Map<String, String> legacyArabicToArabic = {
    'بإنتظار قبول المندوب': 'بانتظار قبول مندوب',
    'بانتظار قبول المندوب': 'بانتظار قبول مندوب',
    'بانتظار قبول السائق': 'بانتظار قبول مندوب',
    'قيد الانتظار': 'قيد الانتظار',
    'مقبول': 'تم إسناد مندوب',
    'تم إسناد مندوب': 'تم إسناد مندوب',
    'المندوب في الطريق': 'المندوب في الطريق',
    'وصل المندوب': 'وصل لنقطة الانطلاق',
    'وصل السائق': 'وصل لنقطة الانطلاق',
    'وصل لنقطة الانطلاق': 'وصل لنقطة الانطلاق',
    'تم البدء في الرحلة': 'الرحلة بدأت',
    'بدأت الرحلة': 'الرحلة بدأت',
    'الرحلة بدأت': 'الرحلة بدأت',
    'مكتمل': 'مكتملة',
    'مكتملة': 'مكتملة',
    'ملغي': 'ملغية',
    'ملغى': 'ملغية',
    'ملغية': 'ملغية',
    'منتهية الصلاحية': 'منتهية الصلاحية',
    'منتهي': 'منتهية الصلاحية',
  };

  static String _rawStatusCode(OrderRecord order) {
    final raw = order.snapshotData['status_code'];
    return (raw ?? '').toString().trim();
  }

  /// Normalized machine code used for color buckets (empty if unknown).
  static String resolveCode({
    String? statusCode,
    String? halhText,
  }) {
    final code = (statusCode ?? '').trim().toLowerCase();
    if (code.isNotEmpty) {
      if (codeToArabic.containsKey(code)) return code;
      if (code.startsWith('cancelled') || code.startsWith('canceled')) {
        return TourySystemStatusCodes.legacyCancelled;
      }
      return code;
    }

    final halh = (halhText ?? '').trim();
    if (halh.isEmpty) return '';

    final normalizedLabel = legacyArabicToArabic[halh];
    if (normalizedLabel == null) {
      final asCode = codeToArabic.containsKey(halh.toLowerCase())
          ? halh.toLowerCase()
          : '';
      return asCode;
    }

    for (final entry in codeToArabic.entries) {
      if (entry.value == normalizedLabel) return entry.key;
    }
    return '';
  }

  /// Arabic label for badges / detail chips.
  static String arabic({
    String? statusCode,
    String? halhText,
  }) {
    final code = (statusCode ?? '').trim().toLowerCase();
    if (code.isNotEmpty) {
      final fromCode = codeToArabic[code];
      if (fromCode != null) return fromCode;
      if (code.startsWith('cancelled') || code.startsWith('canceled')) {
        return 'ملغية';
      }
      if (code == TourySystemStatusCodes.expired) {
        return 'منتهية الصلاحية';
      }
    }

    final halh = (halhText ?? '').trim();
    if (halh.isEmpty) return '';
    return legacyArabicToArabic[halh] ?? halh;
  }

  static String of(OrderRecord order) => arabic(
        statusCode: _rawStatusCode(order),
        halhText: order.halhText,
      );

  static String codeOf(OrderRecord order) => resolveCode(
        statusCode: _rawStatusCode(order),
        halhText: order.halhText,
      );

  /// Color bucket for badges (granular lifecycle groups).
  static AdminBookingStatusTone toneOf(OrderRecord order) {
    final code = codeOf(order);
    final label = of(order);

    if (code == TourySystemStatusCodes.expired ||
        label == 'منتهية الصلاحية') {
      return AdminBookingStatusTone.expired;
    }

    if (code == TourySystemStatusCodes.cancelledByAdmin ||
        code == TourySystemStatusCodes.cancelledByCustomer ||
        code == TourySystemStatusCodes.cancelledByDriver ||
        code == TourySystemStatusCodes.legacyCancelled ||
        code == TourySystemStatusCodes.legacyCanceled ||
        code.startsWith('cancelled') ||
        code.startsWith('canceled') ||
        label == 'ملغية') {
      return AdminBookingStatusTone.canceled;
    }

    if (code == TourySystemStatusCodes.pendingDriver ||
        code == TourySystemStatusCodes.legacyAwaitingDriver ||
        code == 'pending' ||
        code == 'payment_pending' ||
        code == 'draft' ||
        code == 'payment' ||
        label == 'بانتظار قبول مندوب' ||
        label == 'قيد الانتظار') {
      return AdminBookingStatusTone.pending;
    }

    if (code == TourySystemStatusCodes.driverAssigned) {
      return AdminBookingStatusTone.assigned;
    }

    if (code == TourySystemStatusCodes.driverArriving) {
      return AdminBookingStatusTone.onTheWay;
    }

    if (code == TourySystemStatusCodes.driverArrived ||
        label == 'وصل لنقطة الانطلاق') {
      return AdminBookingStatusTone.arrived;
    }

    if (code == TourySystemStatusCodes.tripStarted ||
        code == TourySystemStatusCodes.tripInProgress ||
        label == 'الرحلة بدأت') {
      return AdminBookingStatusTone.inTrip;
    }

    if (code == TourySystemStatusCodes.completed ||
        code == TourySystemStatusCodes.legacyTripCompleted ||
        label == 'مكتملة') {
      return AdminBookingStatusTone.completed;
    }

    // Legacy "مقبول" without finer code → assigned bucket.
    if (label == 'تم إسناد مندوب') {
      return AdminBookingStatusTone.assigned;
    }

    return AdminBookingStatusTone.unknown;
  }

  /// True when cancel action is still meaningful.
  static bool isTerminal(OrderRecord order) {
    final tone = toneOf(order);
    return tone == AdminBookingStatusTone.completed ||
        tone == AdminBookingStatusTone.canceled ||
        tone == AdminBookingStatusTone.expired;
  }
}

enum AdminBookingStatusTone {
  pending,
  assigned,
  onTheWay,
  arrived,
  inTrip,
  completed,
  canceled,
  expired,
  unknown,
}
