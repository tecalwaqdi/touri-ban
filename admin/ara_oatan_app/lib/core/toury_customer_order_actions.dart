import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/core/toury_order_meta.dart';
import '/core/toury_payment_flags.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Customer-facing cancel + navigation helpers for order details.
abstract final class TouryCustomerOrderActions {
  TouryCustomerOrderActions._();

  static Future<void> writeCancelled(DocumentReference ref) async {
    await ref.update(createOrderRecordData(
      halhOrder: Halh.Canceled,
      halhText: 'ملغي',
      notSestem: 'تم إلغاء الطلب من قبل العميل',
    ));
    await ref.set(
      {
        'status_code': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'customer',
        'cancelReason': 'customer_cancelled',
        'ActiveOrder': false,
        'ALLNOW': false,
      },
      SetOptions(merge: true),
    );
  }

  /// Returns null on success, or an error message.
  static Future<String?> cancelOrder(OrderRecord order) async {
    if (!order.canCancelByCustomer) {
      return 'لا يمكن إلغاء الطلب في هذه المرحلة';
    }

    final isOnline = order.paymentMethod == PaymentMethod.OnlinePayment &&
        !TouryPaymentFlags.cashOnlyMode;
    final gatewayId = order.paymentGatewayOrderId.trim();

    if (isOnline && gatewayId.isNotEmpty) {
      final refund = await NGeniusPaymentRefundCall.call(id: gatewayId);
      if (!(refund.succeeded ?? false)) {
        return 'تعذر استرجاع الدفعة. تواصل مع الدعم أو حاول لاحقاً';
      }
    }

    try {
      await writeCancelled(order.reference);
      return null;
    } on FirebaseException catch (e) {
      return 'فشل الإلغاء: ${e.message ?? e.code}';
    } catch (e) {
      return 'فشل الإلغاء: $e';
    }
  }
}
