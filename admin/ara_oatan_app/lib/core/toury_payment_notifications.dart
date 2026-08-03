import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/toury_booking_agents.dart';
import '/core/toury_notification_localizer.dart';

Future<void> touryNotifyAfterSuccessfulOrderPayment({
  required DocumentReference? villnow,
  required dynamic typecarRev,
  required dynamic nglValue,
  required int totalsaat,
  required double totalmndob3,
  required String currency,
  required String orderIdLabel,
}) async {
  try {
    if (currentUserReference != null) {
      final locale = TouryNotificationLocalizer.currentLocale();
      triggerPushNotification(
        notificationTitle: await TouryNotificationLocalizer.text(
          locale,
          'notification_payment_success_title',
        ),
        notificationText: await TouryNotificationLocalizer.text(
          locale,
          'notification_payment_success_body',
          args: {'bookingId': orderIdLabel},
        ),
        userRefs: [currentUserReference!],
        initialPageName: 'Bookings',
        parameterData: const {},
      );
    }

    await touryNotifyAgentsForNewOrder(
      villnow: villnow,
      typecarRev: typecarRev,
      nglValue: nglValue,
      totalsaat: totalsaat,
      totalmndob3: totalmndob3,
      currency: currency,
      countryRef: FFAppState().dolh,
      cityRef: FFAppState().mdenh,
    );

    final admins = await queryUserRecordOnce(
      queryBuilder: (record) => record.where('isAdmin', isEqualTo: true),
    );
    final adminsByLocale = <String, List<UserRecord>>{};
    for (final admin in admins) {
      adminsByLocale
          .putIfAbsent(
            TouryNotificationLocalizer.localeForUser(admin),
            () => [],
          )
          .add(admin);
    }

    for (final entry in adminsByLocale.entries) {
      triggerPushNotification(
        notificationTitle: await TouryNotificationLocalizer.text(
          entry.key,
          'notification_paid_order_admin_title',
        ),
        notificationText: await TouryNotificationLocalizer.text(
          entry.key,
          'notification_paid_order_admin_body',
          args: {
            'bookingId': orderIdLabel,
            'hours': totalsaat.toString(),
            'amount': totalmndob3.toStringAsFixed(2),
            'currency': currency,
          },
        ),
        userRefs: entry.value.map((user) => user.reference).toList(),
        initialPageName: 'Dashbord',
        parameterData: const {},
      );
    }
  } catch (error, stackTrace) {
    debugPrint(
      'touryNotifyAfterSuccessfulOrderPayment: $error\n$stackTrace',
    );
  }
}

void touryNotifyWalletTopUpSuccess({required double amountSar}) {
  if (currentUserReference == null) return;
  unawaited(() async {
    final locale = TouryNotificationLocalizer.currentLocale();
    triggerPushNotification(
      notificationTitle: await TouryNotificationLocalizer.text(
        locale,
        'notification_wallet_topup_title',
      ),
      notificationText: await TouryNotificationLocalizer.text(
        locale,
        'notification_wallet_topup_body',
        args: {'amount': amountSar.toStringAsFixed(2)},
      ),
      userRefs: [currentUserReference!],
      initialPageName: 'List22TaskOverviewResponsive',
      parameterData: const {},
    );
  }());
}
