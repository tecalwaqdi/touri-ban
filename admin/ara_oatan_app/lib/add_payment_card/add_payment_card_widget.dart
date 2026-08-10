import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/toury_payment_labels.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compatibility route kept for old links. Card details are entered only on
/// the Network International hosted payment page.
class AddPaymentCardWidget extends StatelessWidget {
  const AddPaymentCardWidget({super.key});

  static String routeName = 'AddPaymentCard';
  static String routePath = '/addPaymentCard';

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            backgroundColor: colors.scaffold,
            appBar: DsAppBar(
              automaticallyImplyLeading: false,
              title: 'ux_card_payment_network'.tr(),
              leading: DsIconButton(
                icon: DsIcons.back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.safePop(),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(DsSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: DsConstants.maxFormWidth,
                    ),
                    child: DsFadeSlide(
                      child: DsCard(
                        elevated: true,
                        padding: const EdgeInsets.all(DsSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: DsConstants.avatarXl,
                                height: DsConstants.avatarXl,
                                decoration: BoxDecoration(
                                  color: colors.primarySoft,
                                  shape: BoxShape.circle,
                                  boxShadow: DsShadows.soft(
                                    dark: context.dsIsDark,
                                  ),
                                ),
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  size: DsIcons.xl,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: DsSpacing.lg),
                            Text(
                              'ux_card_payment_network'.tr(),
                              textAlign: TextAlign.center,
                              style: typography.titleLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.xs),
                            Text(
                              'please_do_not_close_the_page_until_the_payment_is_completed'
                                  .tr(),
                              textAlign: TextAlign.center,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.xl),
                            DsButton.primary(
                              label: 'dialog_continue'.tr(),
                              icon: Icons.check_rounded,
                              size: DsButtonSize.lg,
                              expanded: true,
                              onPressed: () {
                                FFAppState().clearSensitivePaymentSession();
                                FFAppState().ElectronicPayment = true;
                                FFAppState().payth = TouryPaymentKeys.online;
                                context.safePop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
