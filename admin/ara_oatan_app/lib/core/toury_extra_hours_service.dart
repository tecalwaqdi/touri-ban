import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/api_requests/api_manager.dart';
import '/backend/cloud_functions/cloud_functions.dart';

/// Eligibility mirrors the existing extra-hours callable. The server repeats
/// these checks against the latest order inside its transaction.
bool touryCanExtendOrder(Map<String, dynamic> order, String uid) {
  final owner = order['USER'];
  final ownerPath = owner is DocumentReference ? owner.path : owner?.toString();
  if (uid.isEmpty || ownerPath != 'user/$uid') return false;
  var status = (order['status_code'] ?? '').toString().toLowerCase();
  if (status.isEmpty) {
    status = const {
          'مقبول': 'driver_assigned',
          'وصل المندوب': 'driver_arrived',
          'تم البدء في الرحلة': 'trip_in_progress',
        }[order['halh_text']] ??
        '';
  }
  if (!const {
    'driver_assigned',
    'driver_arriving',
    'driver_arrived',
    'trip_started',
    'trip_in_progress',
  }.contains(status)) {
    return false;
  }
  if (order['mndob_user'] == null ||
      order['completedAt'] != null ||
      order['cancelledAt'] != null ||
      order['financial_snapshot'] != null ||
      order['settlement_id'] != null ||
      const {'completed', 'cancelled', 'canceled'}.contains(
        (order['halhOrderMndob'] ?? '').toString().toLowerCase(),
      )) {
    return false;
  }
  final method = (order['PaymentMethod'] ?? '').toString().toLowerCase();
  final payment = (order['payment_status'] ?? '').toString().toLowerCase();
  return (method == 'cash' &&
          const {'pending_cash', 'cash_pending', 'cash_due'}
              .contains(payment)) ||
      (method == 'onlinepayment' &&
          const {'paid', 'captured'}.contains(payment));
}

class TouryExtraHoursQuote {
  const TouryExtraHoursQuote(this.data);
  final Map<String, dynamic> data;
  int number(String key) => (data[key] as num).toInt();
  int get hours => number('extraHours');
  int get currentHours => number('currentHours');
  int get newHours => number('newHours');
  String get currency => data['currency'] as String;
  String get token => data['quoteToken'] as String;
  bool get isCash => data['method'] == 'cash';
  String? get resumeSessionId => data['resumeSessionId'] as String?;
  String money(String key) {
    final factor = number('factor');
    return '${(number(key) / factor).toStringAsFixed(factor == 1000 ? 3 : 2)} $currency';
  }
}

class TouryExtraHoursException implements Exception {
  const TouryExtraHoursException(this.code);
  final String code;
}

class TouryExtraHoursService {
  static Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await makeCloudCall(name, data);
    if (result.containsKey('error')) {
      final details = result['details'];
      throw TouryExtraHoursException(details is Map && details['code'] is String
          ? details['code'] as String
          : result['error'].toString());
    }
    return result;
  }

  Future<TouryExtraHoursQuote> quote(
          DocumentReference order, int hours) async =>
      TouryExtraHoursQuote(await _call('getExtraHoursQuote', {
        'orderPath': order.path,
        'extraHours': hours,
      }));

  Future<Map<String, dynamic>> addCash(
    DocumentReference order,
    TouryExtraHoursQuote quote,
    String requestKey,
  ) =>
      _call('addCashExtraHours', {
        'orderPath': order.path,
        'extraHours': quote.hours,
        'quoteToken': quote.token,
        'idempotencyKey': requestKey,
      });

  /// ExtraHours already uses Firebase N-Genius callables. Creation,
  /// verification and finalization must all stay on that same backend.
  Future<ApiCallResponse> createPayment(
    DocumentReference order,
    TouryExtraHoursQuote quote,
    String requestKey,
  ) async =>
      ApiCallResponse(
          await _call('createNGeniusPayment', {
            'paymentPurpose': 'extra_hours',
            'orderPath': order.path,
            'extraHours': quote.hours,
            'quoteToken': quote.token,
            'idempotencyKey': requestKey,
            'description': 'Touri-extra-hours-${order.id}',
          }),
          const {},
          200);
}
