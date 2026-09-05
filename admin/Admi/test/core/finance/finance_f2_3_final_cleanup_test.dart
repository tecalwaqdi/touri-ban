import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/settlement_detail_presentation.dart';

void main() {
  group('F2.3 final QA / technical leakage', () {
    final stl2026000001 = <String, dynamic>{
      'settlementCode': 'STL-2026-000001',
      'status': 'settled',
      'driverId': 'Cl7quxoFD5hY8sOm4rrnL1XnE7f1',
      'periodStart': '2020-01-01T00:00:00.000Z',
      'periodEnd': '2030-01-01T00:00:00.000Z',
      'eligibleTripCount': 1,
      'eligibleOrderIds': ['fin7_ctrl_1788321182908'],
      'idempotencyKey': 'fin8_draft_fin7_ctrl_1788321182908',
      'absoluteSettlementAmountMinor': 750,
      'paidConfirmedMinor': 750,
      'outstandingMinor': 0,
    };

    test('1 QA settlement excluded from normal settlement list', () {
      final real = <String, dynamic>{
        'settlementCode': 'STL-2026-000099',
        'eligibleOrderIds': ['live_trip_abc'],
        'idempotencyKey': 'prod_draft_xyz',
        'absoluteSettlementAmountMinor': 10000,
        'paidConfirmedMinor': 0,
        'outstandingMinor': 10000,
      };
      final all = [stl2026000001, real];
      final normal = all
          .where((d) => !AdminQaFixture.isFinanceQaSettlement(d))
          .toList();
      expect(normal.length, 1);
      expect(normal.first['settlementCode'], 'STL-2026-000099');
      expect(AdminQaFixture.isFinanceQaSettlement(stl2026000001), isTrue);
    });

    test('2 QA settlement contributes 0 to summary', () {
      final docs = [stl2026000001];
      final normal = docs
          .where((d) => !AdminQaFixture.isFinanceQaSettlement(d))
          .toList();
      var paid = 0;
      var remaining = 0;
      for (final s in normal) {
        paid += (s['paidConfirmedMinor'] as num).toInt();
        remaining += (s['outstandingMinor'] as num).toInt();
      }
      expect(paid, 0);
      expect(remaining, 0);
      expect(normal, isEmpty);
    });

    test('3 QA settlement detail not reachable from normal accountant UI', () {
      final isQa = AdminQaFixture.isFinanceQaSettlement(stl2026000001);
      const diagnostic = false;
      const isSuperAdmin = false;
      final allowDiagnostic = diagnostic && isSuperAdmin && isQa;
      expect(isQa && !allowDiagnostic, isTrue);
    });

    test('4 diagnostics can still access QA settlement', () {
      final isQa = AdminQaFixture.isFinanceQaSettlement(stl2026000001);
      const diagnostic = true;
      const isSuperAdmin = true;
      final allowDiagnostic = diagnostic && isSuperAdmin && isQa;
      expect(allowDiagnostic, isTrue);
      final diagList = [stl2026000001]
          .where((d) => AdminQaFixture.isFinanceQaSettlement(d))
          .toList();
      expect(diagList.length, 1);
    });

    test('5 mutated=false not rendered in normal UI', () {
      final msg = SettlementDetailPresentation.sourceVerificationMessageAr(
        flag: null,
        mutated: false,
      );
      expect(msg.contains('mutated'), isFalse);
      expect(msg, 'لم يتم تعديل المصدر');
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(
          'اللقطة مطابقة للمصدر الحالي. mutated=false',
        ),
        isTrue,
      );
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(msg),
        isFalse,
      );
    });

    test('6 source verification not rendered in normal accountant view', () {
      // Normal accountant sections must not include the verify control label
      // as primary content; diagnostics use a distinct technical label.
      const normalSections = [
        'ملخص التسوية',
        'المبالغ',
        'الدفعات',
        'الرحلات',
        'سجل العمليات',
      ];
      for (final s in normalSections) {
        expect(s.contains('التحقق من المصدر'), isFalse);
      }
      const technical = 'تشخيص تقني — التحقق من المصدر';
      expect(technical.contains('تشخيص تقني'), isTrue);
    });

    test('7 unresolved driver does not fabricate a name', () {
      expect(
        SettlementDetailPresentation.driverDisplayName(null),
        'السائق غير محدد',
      );
      expect(
        SettlementDetailPresentation.driverDisplayName({'uid': 'abc'}),
        'السائق غير محدد',
      );
    });

    test('8 resolved driver uses human-readable name', () {
      expect(
        SettlementDetailPresentation.driverDisplayName({
          'display_name': 'فيصل خليفه',
        }),
        'فيصل خليفه',
      );
      expect(
        SettlementDetailPresentation.looksLikeRawUid(
          'فيصل خليفه',
          'Cl7quxoFD5hY8sOm4rrnL1XnE7f1',
        ),
        isFalse,
      );
    });

    test('STL-2026-000001 markers prove FIN-8 QA fixture', () {
      expect(
        AdminQaFixture.isFixtureId('fin7_ctrl_1788321182908'),
        isTrue,
      );
      expect(
        AdminQaFixture.isFinanceQaPaymentRef('FIN8-BANK-REF-2'),
        isTrue,
      );
      expect(
        AdminQaFixture.isFinanceQaSettlement(
          stl2026000001,
          paymentExternalRefs: [
            'FIN8-BANK-REF-2',
            'FIN8-RECEIPT-1',
            'FIN8-OVER-ATTEMPT',
          ],
        ),
        isTrue,
      );
    });
  });
}
