import '/backend/schema/order_record.dart';
import '/core/toury_system_status_codes.dart';

/// Resolves admin booking status display labels.
///
/// Preference order: machine `status_code` first, then legacy Arabic `halh_text`.
/// Arabic map is the temporary admin display surface (not i18n keys yet).
abstract final class AdminBookingStatusLabel {
  AdminBookingStatusLabel._();

  /// Canonical / aliased `status_code` → Arabic badge label.
  static const Map<String, String> codeToArabic = {
    TourySystemStatusCodes.pendingDriver: 'بإنتظار قبول المندوب',
    TourySystemStatusCodes.legacyAwaitingDriver: 'بإنتظار قبول المندوب',
    'pending': 'بإنتظار قبول المندوب',
    'payment_pending': 'بإنتظار قبول المندوب',
    'draft': 'بإنتظار قبول المندوب',
    'payment': 'بإنتظار قبول المندوب',
    TourySystemStatusCodes.driverAssigned: 'مقبول',
    TourySystemStatusCodes.driverArriving: 'مقبول',
    TourySystemStatusCodes.driverArrived: 'وصل المندوب',
    TourySystemStatusCodes.tripStarted: 'تم البدء في الرحلة',
    TourySystemStatusCodes.tripInProgress: 'تم البدء في الرحلة',
    TourySystemStatusCodes.completed: 'مكتمل',
    TourySystemStatusCodes.legacyTripCompleted: 'مكتمل',
    TourySystemStatusCodes.cancelledByAdmin: 'ملغي',
    TourySystemStatusCodes.cancelledByCustomer: 'ملغي',
    TourySystemStatusCodes.cancelledByDriver: 'ملغي',
    TourySystemStatusCodes.legacyCancelled: 'ملغي',
    TourySystemStatusCodes.legacyCanceled: 'ملغي',
    TourySystemStatusCodes.expired: 'ملغي',
  };

  /// Legacy Arabic (and close variants) → normalized Arabic badge label.
  static const Map<String, String> legacyArabicToArabic = {
    'بإنتظار قبول المندوب': 'بإنتظار قبول المندوب',
    'بانتظار قبول المندوب': 'بإنتظار قبول المندوب',
    'بانتظار قبول السائق': 'بإنتظار قبول المندوب',
    'مقبول': 'مقبول',
    'وصل المندوب': 'وصل المندوب',
    'وصل السائق': 'وصل المندوب',
    'تم البدء في الرحلة': 'تم البدء في الرحلة',
    'بدأت الرحلة': 'تم البدء في الرحلة',
    'مكتمل': 'مكتمل',
    'مكتملة': 'مكتمل',
    'ملغي': 'ملغي',
    'ملغى': 'ملغي',
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
        return 'ملغي';
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

  /// Color bucket aligned with list badge matching (pending / accepted / canceled).
  static AdminBookingStatusTone toneOf(OrderRecord order) {
    final code = codeOf(order);
    final label = of(order);

    if (code == TourySystemStatusCodes.cancelledByAdmin ||
        code == TourySystemStatusCodes.legacyCancelled ||
        code == TourySystemStatusCodes.legacyCanceled ||
        code.startsWith('cancelled') ||
        code.startsWith('canceled') ||
        label == 'ملغي') {
      return AdminBookingStatusTone.canceled;
    }

    if (code == TourySystemStatusCodes.pendingDriver ||
        code == 'awaiting_driver' ||
        code == 'pending' ||
        code == 'payment_pending' ||
        code == 'draft' ||
        code == 'payment' ||
        label == 'بإنتظار قبول المندوب') {
      return AdminBookingStatusTone.pendingDriver;
    }

    if (code == TourySystemStatusCodes.driverAssigned ||
        code == TourySystemStatusCodes.driverArrived ||
        code == TourySystemStatusCodes.tripStarted ||
        code == TourySystemStatusCodes.tripInProgress ||
        label == 'مقبول' ||
        label == 'وصل المندوب' ||
        label == 'تم البدء في الرحلة') {
      return AdminBookingStatusTone.accepted;
    }

    if (code == TourySystemStatusCodes.completed ||
        code == TourySystemStatusCodes.legacyTripCompleted ||
        label == 'مكتمل') {
      return AdminBookingStatusTone.completed;
    }

    return AdminBookingStatusTone.unknown;
  }
}

enum AdminBookingStatusTone {
  pendingDriver,
  accepted,
  completed,
  canceled,
  unknown,
}
