import 'package:cloud_functions/cloud_functions.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/widgets.dart';

/// Maps Firebase / finance callable errors to readable admin copy.
String adminFriendlyError(BuildContext context, Object error) {
  String code = '';
  String message = '$error';
  if (error is FirebaseFunctionsException) {
    code = error.details is Map
        ? '${(error.details as Map)['errorCode'] ?? error.message ?? error.code}'
        : (error.message ?? error.code);
    message = error.message ?? error.code;
  }
  final raw = (code.isNotEmpty ? code : message).toUpperCase();
  if (raw.contains('FEATURE_FLAG_DISABLED')) {
    return uiTr(
      context,
      'This financial write is disabled by production feature flags.',
    );
  }
  if (raw.contains('SELF_APPROVAL_FORBIDDEN')) {
    return uiTr(
      context,
      'Maker cannot approve their own item. Use an independent checker.',
    );
  }
  if (raw.contains('PERIOD_CLOSED')) {
    return uiTr(context, 'This accounting period is closed.');
  }
  if (raw.contains('PERIOD_CLOSE_BLOCKED')) {
    return uiTr(context, 'Period close blocked — resolve checklist items first.');
  }
  if (raw.contains('PAYMENT_EXCEEDS_OUTSTANDING')) {
    return uiTr(context, 'Payment exceeds outstanding balance.');
  }
  if (raw.contains('PREVIEW_STALE') || raw.contains('SETTLEMENT_PREVIEW_STALE')) {
    return uiTr(context, 'Settlement preview is stale. Refresh and try again.');
  }
  if (raw.contains('PERMISSION_DENIED') || raw.contains('PERMISSION-DENIED')) {
    return uiTr(context, 'You do not have permission for this action.');
  }
  if (raw.contains('INDEX_REQUIRED') ||
      raw.contains('CREATE_COMPOSITE') ||
      raw.contains('REQUIRES AN INDEX') ||
      raw.contains('CONSOLE.FIREBASE.GOOGLE.COM') ||
      (raw.contains('FAILED_PRECONDITION') && raw.contains('INDEX')) ||
      (raw.contains('FAILED-PRECONDITION') && raw.contains('INDEX'))) {
    return uiTr(context, 'A Firestore index is required for this query.');
  }
  if (raw.contains('UNSUPPORTED_CURRENCY')) {
    return uiTr(context, 'Unsupported currency for financial math.');
  }
  if (raw.contains('INCOMPLETE')) {
    return uiTr(context, 'Financial data is incomplete for this record.');
  }
  if (raw.contains('ALREADY_CLAIMED') || raw.contains('SETTLEMENT_ALREADY_CLAIMED')) {
    return uiTr(context, 'Orders in this settlement are already claimed.');
  }
  if (raw.contains('OVERPAYMENT') || raw.contains('PAYMENT_EXCEEDS')) {
    return uiTr(context, 'Payment exceeds outstanding balance.');
  }
  if (raw.contains('DEADLINE-EXCEEDED') ||
      raw.contains('TIMEOUT') ||
      raw.contains('UNAVAILABLE')) {
    return uiTr(context, 'Service timed out or is temporarily unavailable. Retry.');
  }
  if (raw.contains('NETWORK') ||
      raw.contains('SOCKET') ||
      (raw.contains('FAILED-PRECONDITION') && raw.contains('NETWORK'))) {
    return uiTr(context, 'Network failure. Check connection and retry.');
  }
  // Never return Firebase console URLs or stack-like noise to operators.
  final cleaned = message
      .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '')
      .trim();
  if (cleaned.toLowerCase().contains('requires an index') ||
      cleaned.toLowerCase().contains('failed-precondition')) {
    return uiTr(context, 'A Firestore index is required for this query.');
  }
  if (cleaned.length < 180 &&
      !cleaned.contains('FirebaseException') &&
      !cleaned.contains('Instance of')) {
    return cleaned.isEmpty
        ? uiTr(context, 'Something went wrong. Please try again.')
        : cleaned;
  }
  return uiTr(context, 'Something went wrong. Please try again.');
}
