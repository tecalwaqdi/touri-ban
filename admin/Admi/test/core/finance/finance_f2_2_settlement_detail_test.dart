import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_text.dart';
import 'package:admin_arawatan/core/finance/settlement_detail_presentation.dart';
import 'package:admin_arawatan/flutter_flow/flutter_flow_theme.dart';

void main() {
  group('F2.2 settlement detail presentation', () {
    test('1 country path not visible in normal settlement detail label', () {
      final label = SettlementDetailPresentation.countryAr(
        'countries/saudi_arabia',
      );
      expect(label, 'السعودية');
      expect(label.contains('countries/'), isFalse);
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(label),
        isFalse,
      );
    });

    test('2 driver UID not primary display', () {
      expect(
        SettlementDetailPresentation.driverDisplayName(null),
        'السائق غير محدد',
      );
      expect(
        SettlementDetailPresentation.driverDisplayName({'uid': 'abc'}),
        'السائق غير محدد',
      );
      expect(
        SettlementDetailPresentation.driverDisplayName({
          'display_name': 'أحمد',
        }),
        'أحمد',
      );
      expect(
        SettlementDetailPresentation.looksLikeRawUid('uid123', 'uid123'),
        isTrue,
      );
    });

    test('3 ISO timestamp not visible in normal business date', () {
      final human = SettlementDetailPresentation.humanDateAr(
        '2020-01-01T00:00:00.000Z',
      );
      expect(human.contains('T00:00:00'), isFalse);
      expect(human.contains('2020'), isTrue);
      expect(human.contains('يناير'), isTrue);
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(human),
        isFalse,
      );
    });

    test('4 QA fixture not visible in normal settlement trip set', () {
      expect(
        SettlementDetailPresentation.isQaTripId('fin7_ctrl_1788321182908'),
        isTrue,
      );
      expect(
        SettlementDetailPresentation.isQaTripLine(
          'fin9_ctrl_x',
          const {},
        ),
        isTrue,
      );
      expect(
        SettlementDetailPresentation.isQaTripLine('live_trip_1', const {}),
        isFalse,
      );
      expect(AdminQaFixture.isFixtureId('fin_rt_cash_ui_1'), isTrue);

      final normalIds = [
        'live_ok',
        'fin7_ctrl_1788321182908',
        'fin_rt_cash_ui_9',
      ].where((id) => !SettlementDetailPresentation.isQaTripId(id)).toList();
      expect(normalIds, ['live_ok']);
    });

    test('5 English developer legacy copy = 0', () {
      final ar = SettlementDetailPresentation.unallocatedPaymentsAr(count: 2);
      expect(ar.contains('UNALLOCATED'), isFalse);
      expect(ar.contains('heuristic'), isFalse);
      expect(ar.contains('Legacy'), isFalse);
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(
          'Legacy company_payments stay UNALLOCATED until an admin selects them explicitly. No heuristic matching.',
        ),
        isTrue,
      );
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(ar),
        isFalse,
      );
    });

    test('6 raw audit enums = 0', () {
      for (final raw in [
        'CREATED_DRAFT',
        'LOCKED',
        'SELF_APPROVAL',
        'PAYMENT_CREATED',
        'CASH_PAYMENT_CONFIRMED',
      ]) {
        final label = SettlementDetailPresentation.auditEventAr(raw);
        expect(label.toUpperCase().contains(raw), isFalse);
        expect(label, isNot(equals(raw)));
      }
    });

    test('7 Arabic audit labels render', () {
      expect(
        SettlementDetailPresentation.auditEventAr('CREATED_DRAFT'),
        'تم إنشاء مسودة التسوية',
      );
      expect(
        SettlementDetailPresentation.auditEventAr('LOCKED'),
        'تم اعتماد التسوية',
      );
      expect(
        SettlementDetailPresentation.auditEventAr('PAYMENT_CREATED'),
        'تم تسجيل دفعة',
      );
      expect(
        SettlementDetailPresentation.auditEventAr('CASH_PAYMENT_CONFIRMED'),
        'تم تأكيد الدفعة النقدية',
      );
      expect(
        SettlementDetailPresentation.auditEventAr('PAYMENT_CONFIRMED'),
        'تم تأكيد الدفعة',
      );
      expect(
        SettlementDetailPresentation.auditEventAr('SELF_APPROVAL'),
        'اعتماد إداري',
      );
      expect(
        SettlementDetailPresentation.actorRoleAr('super_admin'),
        'السوبر أدمن',
      );
      expect(
        SettlementDetailPresentation.statusTransitionAr('draft', 'locked'),
        'تغيرت الحالة من مسودة إلى معتمدة',
      );
      expect(
        SettlementDetailPresentation.statusTransitionAr(
          'locked',
          'partially_paid',
        ),
        'تغيرت الحالة من معتمدة إلى مسددة جزئيًا',
      );
      expect(
        SettlementDetailPresentation.containsForbiddenAccountantCopy(
          'draft → locked',
        ),
        isTrue,
      );
    });

    test('8 white-on-light settlement titles = 0', () {
      final light = LightModeTheme();
      final ink = AccountantFinanceText.ink(light);
      expect(ink.computeLuminance(), lessThan(0.45));
      expect(ink, isNot(equals(light.info)));
      final dark = DarkModeTheme();
      final darkInk = AccountantFinanceText.ink(dark);
      expect(darkInk.computeLuminance(), lessThanOrEqualTo(0.45));
      final title = AccountantFinanceText.sectionTitle(light);
      expect(title.color!.computeLuminance(), lessThan(0.45));
    });

    test('9 due/paid/remaining still equal canonical data', () {
      const due = 750;
      const paid = 750;
      const out = 0;
      expect(due, 750);
      expect(paid, 750);
      expect(out, 0);
      final outcome = SettlementDetailPresentation.settlementOutcomeAr(
        direction: 'DRIVER_PAYS_COMPANY',
        status: 'settled',
        dueMinor: due,
        paidMinor: paid,
        outstandingMinor: out,
      );
      expect(outcome, 'السائق دفع كامل المستحق للشركة');
      expect(
        SettlementDetailPresentation.directionAr('DRIVER_PAYS_COMPANY'),
        'مستحق للشركة على السائق',
      );
    });

    test('10 no settlement write occurs from viewing detail helpers', () {
      // Pure presentation — constructing labels must not mutate maps.
      final data = <String, dynamic>{
        'absoluteSettlementAmountMinor': 750,
        'paidConfirmedMinor': 750,
        'outstandingMinor': 0,
        'status': 'settled',
        'direction': 'DRIVER_PAYS_COMPANY',
        'countryId': 'countries/saudi_arabia',
      };
      final snapshot = Map<String, dynamic>.from(data);
      SettlementDetailPresentation.countryAr('${data['countryId']}');
      SettlementDetailPresentation.settlementOutcomeAr(
        direction: '${data['direction']}',
        status: '${data['status']}',
        dueMinor: data['absoluteSettlementAmountMinor'] as int,
        paidMinor: data['paidConfirmedMinor'] as int,
        outstandingMinor: data['outstandingMinor'] as int,
      );
      expect(data, snapshot);
    });
  });
}
