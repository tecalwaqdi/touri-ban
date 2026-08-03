import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_payment_status_mapper.dart';
import 'package:mndob/core/driver_registration_validators.dart';
import 'package:mndob/core/driver_support_ticket_service.dart';
import 'package:mndob/core/driver_wallet_service.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('DriverPlateNormalizer length', () {
    test('accepts VIN-length plate up to 20', () {
      final v = DriverPlateNormalizer.validate('MROEX19G6C3444849');
      expect(v.isValid, isTrue);
      expect(DriverPlateNormalizer.normalize('MROEX19G6C3444849').length, 17);
    });

    test('rejects empty and too short', () {
      expect(DriverPlateNormalizer.validate('').isValid, isFalse);
      expect(DriverPlateNormalizer.validate('AB').isValid, isFalse);
    });

    test('rejects over maxLength', () {
      expect(
        DriverPlateNormalizer.validate('ABCDEFGHIJKLMNOPQRSTU').isValid,
        isFalse,
      );
    });
  });

  group('DriverPaymentStatusMapper', () {
    test('display keys for lifecycle statuses', () {
      expect(
        DriverPaymentStatusMapper.displayKey(
          TourySystemStatusCodes.pendingCash,
        ),
        'Payment pending',
      );
      expect(
        DriverPaymentStatusMapper.displayKey(
          TourySystemStatusCodes.cashCollected,
        ),
        'Cash collected',
      );
      expect(
        DriverPaymentStatusMapper.displayKey(TourySystemStatusCodes.paid),
        'Paid',
      );
      expect(
        DriverPaymentStatusMapper.displayKey(TourySystemStatusCodes.failed),
        'Payment failed',
      );
      expect(
        DriverPaymentStatusMapper.displayKey(TourySystemStatusCodes.refunded),
        'Refunded',
      );
      expect(DriverPaymentStatusMapper.displayKey('disputed'), 'Disputed');
      expect(DriverPaymentStatusMapper.displayKey('authorized'), 'Authorized');
    });

    test('supported currencies set', () {
      expect(
        DriverPaymentStatusMapper.supportedCurrencies,
        containsAll(['SAR', 'KGS', 'RUB', 'UZS']),
      );
    });

    test('driver may write payment only for cash', () {
      expect(
        DriverPaymentStatusMapper.driverMayWritePaymentStatus(null),
        isFalse,
      );
    });
  });

  group('DriverSupportTicketService.validate', () {
    test('requires subject and message', () {
      expect(
        DriverSupportTicketService.validate(
          const DriverSupportTicketDraft(
            category: DriverSupportCategory.trip,
            subject: '',
            message: 'hi',
          ),
        ),
        isNotNull,
      );
      expect(
        DriverSupportTicketService.validate(
          const DriverSupportTicketDraft(
            category: DriverSupportCategory.payment,
            subject: 'Pay',
            message: 'Problem with cash confirm after trip end',
          ),
        ),
        isNull,
      );
    });
  });

  group('DriverWallet currency isolation helpers', () {
    test('compatible same currency', () {
      expect(DriverWalletService.currenciesCompatible('SAR', 'SAR'), isTrue);
      expect(DriverWalletService.currenciesCompatible('SAR', 'KGS'), isFalse);
      expect(DriverWalletService.currenciesCompatible('', 'SAR'), isTrue);
    });
  });
}