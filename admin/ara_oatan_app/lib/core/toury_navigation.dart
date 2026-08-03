import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_dialogs.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/order/checkout66/checkout66_widget.dart';
/// فتح صفحة الدفع بأمان — يعمل حتى من SnackBarAction.
void touryOpenCheckout(BuildContext context) {
  tourySyncBookingFlags();

  if (FFAppState().cartmkss.isEmpty && FFAppState().addcart < 1) {
    final messengerContext = appNavigatorKey.currentContext ?? context;
    if (messengerContext.mounted) {
      TouryDialogs.showSnackBar(
        messengerContext,
        'add_destination_first'.tr(),
        type: TouryMessageType.warning,
      );
    }
    return;
  }

  touryPrepareCheckoutState();

  void navigate() {
    final navContext = appNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      navContext.pushNamed(Checkout66Widget.routeName);
      return;
    }
    if (context.mounted) {
      context.pushNamed(Checkout66Widget.routeName);
    }
  }

  // تأجيل التنقل قليلاً حتى لا يتعارض مع إغلاق SnackBar.
  SchedulerBinding.instance.addPostFrameCallback((_) => navigate());
}

/// بعد اختيار السيارة — إشعار نجاح فقط (بدون تنقّل).
void touryOnCarSelected(BuildContext context) {
  final rootContext = appNavigatorKey.currentContext ?? context;
  if (!rootContext.mounted) return;

  TouryDialogs.showSnackBar(
    rootContext,
    'car_selected_success'.tr(),
    type: TouryMessageType.success,
    durationSeconds: 3,
  );

  touryPrepareCheckoutState();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final navContext = appNavigatorKey.currentContext ?? rootContext;
    if (!navContext.mounted) return;
    navContext.goNamed(Checkout66Widget.routeName);
  });
}

/// بعد إتمام الحجز — رسالة منبثقة ثم صفحة التأكيد.
Future<void> touryOnBookingSuccess(BuildContext context) async {
  final rootContext = appNavigatorKey.currentContext ?? context;
  if (!rootContext.mounted) return;

  if (currentUserReference == null) {
    TouryDialogs.showSnackBar(
      rootContext,
      'booking_login_required'.tr(),
      type: TouryMessageType.error,
    );
    return;
  }

  await TouryDialogs.showAlert(
    rootContext,
    title: 'booking_success_title'.tr(),
    message: 'booking_success_msg'.tr(),
    type: TouryMessageType.success,
  );

  if (!rootContext.mounted) return;
  rootContext.pushNamed(OksendWidget.routeName);
}
