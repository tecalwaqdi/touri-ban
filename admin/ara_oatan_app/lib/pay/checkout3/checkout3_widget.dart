import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/toury_payment_labels.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'checkout3_model.dart';

export 'checkout3_model.dart';

class Checkout3Widget extends StatefulWidget {
  const Checkout3Widget({super.key});

  static String routeName = 'Checkout3';
  static String routePath = '/checkout3';

  @override
  State<Checkout3Widget> createState() => _Checkout3WidgetState();
}

class _Checkout3WidgetState extends State<Checkout3Widget> {
  late Checkout3Model _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Checkout3Model());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _selectHostedPayment() {
    FFAppState().clearSensitivePaymentSession();
    FFAppState().ElectronicPayment = true;
    FFAppState().payth = TouryPaymentKeys.online;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenScaffold(
      appBar: DsAppBar(title: 'ux_choose_payment_method'.tr()),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final colors = context.dsColors;
            final typography = context.dsTypography;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DsSpacing.lg,
                DsSpacing.lg,
                DsSpacing.lg,
                DsSpacing.xxxl,
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                DsFadeSlide(
                  child: Column(
                    children: [
                      Container(
                        width: DsConstants.avatarXl,
                        height: DsConstants.avatarXl,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          shape: BoxShape.circle,
                          boxShadow: DsShadows.soft(dark: context.dsIsDark),
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: DsIcons.xl,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
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
                    ],
                  ),
                ),
                const SizedBox(height: DsSpacing.xl),
                DsFadeSlide(
                  delay: DsDurations.fast,
                  child: DsInformationCard(
                    tone: DsInfoTone.info,
                    icon: Icons.lock_outline_rounded,
                    title: 'ux_card_payment_network'.tr(),
                    message: 'ux_choose_payment_method'.tr(),
                  ),
                ),
                const SizedBox(height: DsSpacing.xxl),
                DsFadeSlide(
                  delay: DsDurations.normal,
                  child: DsButton.primary(
                    expanded: true,
                    size: DsButtonSize.lg,
                    icon: Icons.lock_outline_rounded,
                    label: 'ux_choose_payment_method'.tr(),
                    onPressed: _selectHostedPayment,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
