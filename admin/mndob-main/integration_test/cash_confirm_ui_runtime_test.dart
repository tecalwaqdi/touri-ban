import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mndob/auth/firebase_auth/auth_util.dart';
import 'package:mndob/auth/firebase_auth/firebase_user_provider.dart';
import 'package:mndob/backend/firebase/firebase_config.dart';
import 'package:mndob/backend/schema/order_record.dart';
import 'package:mndob/components/driver_cash_collection_panel.dart';
import 'package:mndob/core/driver_locale_loader.dart';
import 'package:mndob/core/driver_resolve_locale.dart';
import 'package:mndob/design_system/design_system.dart';

/// FINANCE P1 — actual UI tap of cash confirm on controlled fixture.
/// Uses WidgetTester tap through DriverCashCollectionPanel → confirmCashCollectionV2.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const orderId = 'fin_rt_cash_ui_1788391945231';
  const email = 'fin.runtime.driver@touri-taxi.com';
  const password = 'Demo@2026';

  testWidgets('Driver cash confirm button tap realizes pending cash',
      (tester) async {
    await EasyLocalization.ensureInitialized();
    await const DriverCachedAssetLoader()
        .load('assets/langs', driverFallbackLocale);
    await initFirebase();

    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    currentUser = MndobFirebaseUser.fromFirebaseUser(cred.user);
    expect(currentUserReference?.id, cred.user!.uid);

    final orderRef = OrderRecord.collection.doc(orderId);
    var order = await OrderRecord.getDocumentOnce(orderRef);
    expect(order.snapshotData['status_code'], 'completed');
    expect(
      (order.snapshotData['payment_status'] ?? '').toString().toLowerCase(),
      'pending_cash',
    );
    expect(
      (order.snapshotData['cash_collection_status'] ?? '')
          .toString()
          .toLowerCase(),
      anyOf('pending', ''),
    );
    expect(order.snapshotData['cashCollectedByDriver'], isNot(true));

    final beforeMoney = Map<String, dynamic>.from(order.snapshotData)
      ..removeWhere(
        (k, _) => !RegExp(
          r'fee|gross|net|due|amount|minor|vat|platform|total_mndob|currency',
          caseSensitive: false,
        ).hasMatch(k),
      );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: driverSupportedLocales,
        path: 'assets/langs',
        assetLoader: const DriverCachedAssetLoader(),
        fallbackLocale: driverFallbackLocale,
        startLocale: const Locale('ar'),
        child: MaterialApp(
          theme: DsTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverCashCollectionPanel(order: order),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Harness may fall back to English keys when AR assets are not fully wired.
    final buttonAr = find.text('تأكيد استلام النقد');
    final buttonEn = find.text('Confirm cash received');
    final button = buttonAr.evaluate().isNotEmpty ? buttonAr : buttonEn;
    expect(button, findsOneWidget, reason: 'Confirm cash button must be visible');

    // Actual UI tap.
    await tester.tap(button);
    await tester.pump(); // busy frame
    // Second rapid tap must not crash / double-fire (busy guard).
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));

    // Wait for callable + UI settle.
    await tester.pumpAndSettle(const Duration(seconds: 20));

    order = await OrderRecord.getDocumentOnce(orderRef);
    expect(order.snapshotData['status_code'], 'completed');
    expect(
      (order.snapshotData['payment_status'] ?? '').toString().toLowerCase(),
      'cash_collected',
    );
    expect(
      (order.snapshotData['cash_collection_status'] ?? '')
          .toString()
          .toLowerCase(),
      'collected',
    );
    expect(order.snapshotData['cashCollectedByDriver'], isTrue);
    expect(
      order.snapshotData['cashCollectedAt'] != null ||
          order.snapshotData['financial_realized_at'] != null,
      isTrue,
    );

    for (final e in beforeMoney.entries) {
      final after = order.snapshotData[e.key];
      if (e.value is DocumentReference || after is DocumentReference) continue;
      expect(after, e.value, reason: 'money field ${e.key} must stay unchanged');
    }

    // Panel should hide after collected (no longer pending).
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: driverSupportedLocales,
        path: 'assets/langs',
        assetLoader: const DriverCachedAssetLoader(),
        fallbackLocale: driverFallbackLocale,
        startLocale: const Locale('ar'),
        child: MaterialApp(
          theme: DsTheme.light(),
          home: Scaffold(
            body: DriverCashCollectionPanel(order: order),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تأكيد استلام النقد'), findsNothing);
    expect(find.text('Confirm cash received'), findsNothing);
  });
}
