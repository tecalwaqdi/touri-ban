/// Pure payment-lock decision. No Firestore / UI.
///
/// Same unpaid booking must RESUME. "Another booking" only when a genuinely
/// different operational (or different unpaid) booking is active.
library;

enum TouriPaymentLockKind {
  none,
  resumeSame,
  resumeUnpaidCheckout,
  conflictOtherPayment,
  conflictActiveBooking,
  paidBlock,
}

class TouriPaymentLockDecision {
  const TouriPaymentLockDecision({
    required this.kind,
    this.activeOrderId = '',
    this.activeStatusCode = '',
    this.activePaymentStatus = '',
  });

  final TouriPaymentLockKind kind;
  final String activeOrderId;
  final String activeStatusCode;
  final String activePaymentStatus;

  bool get blocked =>
      kind == TouriPaymentLockKind.conflictOtherPayment ||
      kind == TouriPaymentLockKind.conflictActiveBooking ||
      kind == TouriPaymentLockKind.paidBlock;

  bool get shouldResume =>
      kind == TouriPaymentLockKind.resumeSame ||
      kind == TouriPaymentLockKind.resumeUnpaidCheckout;

  String get resumeOrderId => shouldResume ? activeOrderId : '';

  bool get isFalseOtherBooking =>
      kind == TouriPaymentLockKind.resumeSame ||
      kind == TouriPaymentLockKind.resumeUnpaidCheckout;
}

const Set<String> kTouriPaymentPendingStatusCodes = {
  'payment_pending',
  'pending_payment',
  'awaiting_payment',
};

const Set<String> kTouriUnpaidPaymentStatuses = {
  'unpaid',
  'pending',
  'failed',
  'cancelled',
  'canceled',
  'expired',
  '',
};

const Set<String> kTouriPaidPaymentStatuses = {
  'paid',
  'captured',
  'authorized',
};

const Set<String> kTouriOperationalActiveStatusCodes = {
  'pending_driver',
  'pending',
  'awaiting_driver',
  'driver_assigned',
  'driver_arriving',
  'driver_arrived',
  'trip_in_progress',
  'trip_started',
  'active',
};

const Set<String> kTouriTerminalBookingStatusCodes = {
  'completed',
  'trip_completed',
  'cancelled',
  'canceled',
  'cancelled_by_customer',
  'cancelled_by_driver',
  'cancelled_by_admin',
  'expired',
};

bool touriIsPaymentPendingCode(String? code) {
  return kTouriPaymentPendingStatusCodes.contains(
    (code ?? '').trim().toLowerCase(),
  );
}

bool touriIsOperationalActiveCode(String? code) {
  return kTouriOperationalActiveStatusCodes.contains(
    (code ?? '').trim().toLowerCase(),
  );
}

bool touriIsPaidPaymentStatus(String? status) {
  return kTouriPaidPaymentStatuses.contains((status ?? '').trim().toLowerCase());
}

bool touriIsUnpaidDraft({
  required String statusCode,
  String paymentStatus = '',
}) {
  if (touriIsPaidPaymentStatus(paymentStatus)) return false;
  if (!touriIsPaymentPendingCode(statusCode)) return false;
  final pay = paymentStatus.trim().toLowerCase();
  return kTouriUnpaidPaymentStatuses.contains(pay);
}

/// True when [activeOrderId] is the current checkout / payment flow.
bool touriIsSamePaymentBooking({
  required String activeOrderId,
  String? currentOrderId,
  String pendingPaymentOrderId = '',
  String paymentOrderId = '',
  String paymentSessionId = '',
}) {
  final id = activeOrderId.trim();
  if (id.isEmpty) return false;
  final allow = <String>{
    if ((currentOrderId ?? '').trim().isNotEmpty) currentOrderId!.trim(),
    if (pendingPaymentOrderId.trim().isNotEmpty) pendingPaymentOrderId.trim(),
    if (paymentOrderId.trim().isNotEmpty) paymentOrderId.trim(),
    if (paymentSessionId.trim().isNotEmpty) paymentSessionId.trim(),
  };
  return allow.contains(id);
}

/// Core lock rule:
/// - no active → none
/// - paid active → paidBlock (no retry / no cash switch)
/// - same booking unpaid → resumeSame
/// - unpaid payment_pending + checkout has no id → resumeUnpaidCheckout
///   (NOT "another booking")
/// - different unpaid payment → conflictOtherPayment
/// - operational trip → conflictActiveBooking (unless same id)
TouriPaymentLockDecision touriDecidePaymentLock({
  String? currentOrderId,
  String pendingPaymentOrderId = '',
  String paymentOrderId = '',
  String paymentSessionId = '',
  String? activeOrderId,
  String activeStatusCode = '',
  String activePaymentStatus = '',
}) {
  final activeId = (activeOrderId ?? '').trim();
  if (activeId.isEmpty) {
    return const TouriPaymentLockDecision(kind: TouriPaymentLockKind.none);
  }

  final code = activeStatusCode.trim().toLowerCase();
  final pay = activePaymentStatus.trim().toLowerCase();

  if (kTouriTerminalBookingStatusCodes.contains(code)) {
    return const TouriPaymentLockDecision(kind: TouriPaymentLockKind.none);
  }

  if (touriIsPaidPaymentStatus(pay) && !touriIsPaymentPendingCode(code)) {
    final samePaid = touriIsSamePaymentBooking(
      activeOrderId: activeId,
      currentOrderId: currentOrderId,
      pendingPaymentOrderId: pendingPaymentOrderId,
      paymentOrderId: paymentOrderId,
      paymentSessionId: paymentSessionId,
    );
    if (samePaid || (currentOrderId ?? '').trim().isEmpty) {
      return TouriPaymentLockDecision(
        kind: TouriPaymentLockKind.paidBlock,
        activeOrderId: activeId,
        activeStatusCode: code,
        activePaymentStatus: pay,
      );
    }
  }

  final same = touriIsSamePaymentBooking(
    activeOrderId: activeId,
    currentOrderId: currentOrderId,
    pendingPaymentOrderId: pendingPaymentOrderId,
    paymentOrderId: paymentOrderId,
    paymentSessionId: paymentSessionId,
  );

  final unpaidDraft = touriIsUnpaidDraft(
    statusCode: code,
    paymentStatus: pay,
  );

  if (same) {
    if (touriIsPaidPaymentStatus(pay) && !unpaidDraft) {
      return TouriPaymentLockDecision(
        kind: TouriPaymentLockKind.paidBlock,
        activeOrderId: activeId,
        activeStatusCode: code,
        activePaymentStatus: pay,
      );
    }
    return TouriPaymentLockDecision(
      kind: TouriPaymentLockKind.resumeSame,
      activeOrderId: activeId,
      activeStatusCode: code,
      activePaymentStatus: pay,
    );
  }

  if (unpaidDraft) {
    final knownCurrent = (currentOrderId ?? '').trim();
    if (knownCurrent.isEmpty) {
      // Checkout Pay with leftover unpaid draft of THIS user — resume, do not
      // treat as a foreign booking.
      return TouriPaymentLockDecision(
        kind: TouriPaymentLockKind.resumeUnpaidCheckout,
        activeOrderId: activeId,
        activeStatusCode: code,
        activePaymentStatus: pay,
      );
    }
    return TouriPaymentLockDecision(
      kind: TouriPaymentLockKind.conflictOtherPayment,
      activeOrderId: activeId,
      activeStatusCode: code,
      activePaymentStatus: pay,
    );
  }

  if (touriIsOperationalActiveCode(code) || code.isNotEmpty) {
    return TouriPaymentLockDecision(
      kind: TouriPaymentLockKind.conflictActiveBooking,
      activeOrderId: activeId,
      activeStatusCode: code,
      activePaymentStatus: pay,
    );
  }

  return const TouriPaymentLockDecision(kind: TouriPaymentLockKind.none);
}

/// CTA matrix for checkout / unpaid booking screens.
enum TouriCheckoutCtaKind {
  chooseMethod,
  confirmCash,
  payCard,
  resumeCard,
  retryCard,
  paid,
}

TouriCheckoutCtaKind touriCheckoutCtaKind({
  required bool cashSelected,
  required bool cardSelected,
  required bool paid,
  required bool hasPendingSameBookingAttempt,
  required bool lastAttemptFailed,
}) {
  if (paid) return TouriCheckoutCtaKind.paid;
  if (cashSelected) return TouriCheckoutCtaKind.confirmCash;
  if (!cardSelected) return TouriCheckoutCtaKind.chooseMethod;
  if (hasPendingSameBookingAttempt) return TouriCheckoutCtaKind.resumeCard;
  if (lastAttemptFailed) return TouriCheckoutCtaKind.retryCard;
  return TouriCheckoutCtaKind.payCard;
}

String touriStableOrderIdempotencyKey(String orderId) {
  final id = orderId.trim();
  if (id.isEmpty) return '';
  return 'pay_order_$id';
}
