import 'dart:async';
import 'package:ara_oatan_app/design_system/design_system.dart';
import 'package:ara_oatan_app/components/add_extra_hours2_widget.dart';
import 'package:ara_oatan_app/core/toury_extra_hours_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test double only; no Firebase client or network is initialized.
// ignore: subtype_of_sealed_class
class _OrderRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  String get path => 'order/o';
}

class _Service extends TouryExtraHoursService {
  int writes = 0;
  final pending = Completer<Map<String, dynamic>>();
  @override
  Future<TouryExtraHoursQuote> quote(
          DocumentReference order, int hours) async =>
      TouryExtraHoursQuote({
        'extraHours': hours,
        'currentHours': 2,
        'newHours': 2 + hours,
        'method': 'cash',
        'currency': 'KWD',
        'factor': 1000,
        'amountMinor': 1250 * hours,
        'newTotalMinor': 2500 + 1250 * hours,
        'quoteToken': 'quote-$hours',
      });
  @override
  Future<Map<String, dynamic>> addCash(
      DocumentReference order, TouryExtraHoursQuote quote, String requestKey) {
    writes++;
    return pending.future;
  }
}

void main() {
  final active = <String, dynamic>{
    'USER': 'user/u',
    'mndob_user': 'user/d',
    'status_code': 'trip_in_progress',
    'PaymentMethod': 'Cash',
    'payment_status': 'pending_cash',
  };
  test('canonical active trips are eligible without legacy Accepted', () {
    expect(touryCanExtendOrder(active, 'u'), isTrue);
    for (final status in [
      'completed',
      'cancelled',
      'pending_driver',
      'expired'
    ]) {
      expect(
          touryCanExtendOrder(
              {...active, 'status_code': status, 'halhOrderMndob': 'Accepted'},
              'u'),
          isFalse);
    }
    expect(touryCanExtendOrder(active, 'another-user'), isFalse);
    expect(touryCanExtendOrder({...active, 'mndob_user': null}, 'u'), isFalse);
    expect(touryCanExtendOrder({...active, 'financial_snapshot': {}}, 'u'),
        isFalse);
    expect(
        touryCanExtendOrder({
          ...active,
          'PaymentMethod': 'OnlinePayment',
          'payment_status': 'pending'
        }, 'u'),
        isFalse);
    expect(
        touryCanExtendOrder({
          ...active,
          'PaymentMethod': 'OnlinePayment',
          'payment_status': 'paid'
        }, 'u'),
        isTrue);
  });

  testWidgets(
      'shows authoritative price, requires confirmation and prevents double submit',
      (tester) async {
    final service = _Service();
    await tester.pumpWidget(MaterialApp(
        theme: DsTheme.light(),
        home: Scaffold(
            body: Builder(
          builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddExtraHours2Widget(
                      idorder: _OrderRef(),
                      srsaah: 999,
                      idMndob: null,
                      service: service)),
              child: const Text('open')),
        ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('1.250 KWD'), findsOneWidget);
    expect(find.text('3.750 KWD'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('2.500 KWD'), findsOneWidget);
    expect(find.text('5.000 KWD'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.writes, 0);
    expect(find.textContaining('extra_hours_current: 2'), findsOneWidget);
    await tester.tap(find.text('dialog_cancel'));
    await tester.pumpAndSettle();
    expect(service.writes, 0);
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('dialog_confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.writes, 1);
    await tester.tap(find.text('Add'), warnIfMissed: false);
    await tester.pump();
    expect(service.writes, 1);
    service.pending.complete({'applied': true});
    await tester.pumpAndSettle();
    expect(find.byType(AddExtraHours2Widget), findsNothing);
  });
}
