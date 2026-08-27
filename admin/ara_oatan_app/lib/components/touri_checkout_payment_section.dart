import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/payments/touri_payment_lock.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_labels.dart';
import '/design_system/design_system.dart';

/// Inline cash / card selector on the booking checkout screen.
class TouriCheckoutPaymentMethodPicker extends StatelessWidget {
  const TouriCheckoutPaymentMethodPicker({
    super.key,
    required this.onChanged,
    this.remoteOkCash = true,
  });

  final VoidCallback onChanged;
  final bool remoteOkCash;

  @override
  Widget build(BuildContext context) {
    final cashVisible = TouryPaymentFlags.cashOptionVisible(
      remoteOkCash: remoteOkCash,
    );
    final cardVisible = TouryPaymentFlags.onlineOptionVisible();
    final payth = FFAppState().payth;
    final cashSelected = touryIsCashPaymentValue(payth);
    final cardSelected = touryIsOnlinePaymentValue(payth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'checkout_pay_method_title'.tr(),
          style: context.dsTypography.titleMedium.copyWith(
            color: context.dsColors.textPrimary,
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        if (cashVisible)
          DsPaymentCard(
            title: 'checkout_pay_cash_title'.tr(),
            subtitle: 'checkout_pay_cash_subtitle'.tr(),
            selected: cashSelected,
            leading: Icon(
              Icons.payments_rounded,
              color: context.dsColors.primary,
            ),
            onTap: () {
              FFAppState().ElectronicPayment = false;
              FFAppState().payth = TouryPaymentKeys.cash;
              onChanged();
            },
          ),
        if (cashVisible && cardVisible) const SizedBox(height: DsSpacing.sm),
        if (cardVisible)
          DsPaymentCard(
            title: 'checkout_pay_card_title'.tr(),
            subtitle: 'checkout_pay_card_subtitle'.tr(),
            selected: cardSelected,
            leading: Icon(
              Icons.credit_card_rounded,
              color: context.dsColors.primary,
            ),
            onTap: () {
              FFAppState().ElectronicPayment = true;
              FFAppState().payth = TouryPaymentKeys.online;
              onChanged();
            },
          ),
      ],
    );
  }
}

String touriCheckoutCtaLabel({
  required TouriCheckoutCtaKind kind,
  required String amountLabel,
}) {
  switch (kind) {
    case TouriCheckoutCtaKind.chooseMethod:
      return 'ux_choose_payment_method'.tr();
    case TouriCheckoutCtaKind.confirmCash:
      return 'checkout_confirm_booking'.tr();
    case TouriCheckoutCtaKind.payCard:
      return 'checkout_pay_amount'.tr(namedArgs: {'amount': amountLabel});
    case TouriCheckoutCtaKind.resumeCard:
      return 'checkout_resume_payment'.tr();
    case TouriCheckoutCtaKind.retryCard:
      return 'order_retry_payment'.tr();
    case TouriCheckoutCtaKind.paid:
      return 'checkout_payment_paid'.tr();
  }
}
