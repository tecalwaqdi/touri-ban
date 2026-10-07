import 'package:ara_oatan_app/core/toury_payment_verify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('touryShouldPollPaymentStatus', () {
    test('polls for native SDK after success (webhook lag)', () {
      expect(
        touryShouldPollPaymentStatus(
          isPending: true,
          awaitingExternalHpp: false,
          openPaymentInExternalBrowser: false,
          preferMobileSdk: true,
        ),
        isTrue,
      );
    });

    test('polls when external HPP browser path is active', () {
      expect(
        touryShouldPollPaymentStatus(
          isPending: true,
          awaitingExternalHpp: true,
          openPaymentInExternalBrowser: false,
          preferMobileSdk: false,
        ),
        isTrue,
      );
      expect(
        touryShouldPollPaymentStatus(
          isPending: true,
          awaitingExternalHpp: false,
          openPaymentInExternalBrowser: true,
          preferMobileSdk: false,
        ),
        isTrue,
      );
    });

    test('does not poll when status is not pending', () {
      expect(
        touryShouldPollPaymentStatus(
          isPending: false,
          awaitingExternalHpp: true,
          openPaymentInExternalBrowser: true,
          preferMobileSdk: true,
        ),
        isFalse,
      );
    });
  });

  group('TouryPaymentVerification.recoverable', () {
    test('error and pending are recoverable; failed is not', () {
      expect(
        const TouryPaymentVerification(
          result: TouryPaymentVerifyResult.pending,
        ).isRecoverablePending,
        isTrue,
      );
      expect(
        const TouryPaymentVerification(
          result: TouryPaymentVerifyResult.error,
        ).isRecoverablePending,
        isTrue,
      );
      expect(
        const TouryPaymentVerification(
          result: TouryPaymentVerifyResult.failed,
        ).isRecoverablePending,
        isFalse,
      );
      expect(
        const TouryPaymentVerification(
          result: TouryPaymentVerifyResult.paid,
        ).isRecoverablePending,
        isFalse,
      );
    });
  });
}
