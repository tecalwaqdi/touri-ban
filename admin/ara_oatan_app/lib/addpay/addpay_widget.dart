import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/toury_payment_labels.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'addpay_model.dart';

export 'addpay_model.dart';

class AddpayWidget extends StatefulWidget {
  const AddpayWidget({super.key});

  static String routeName = 'addpay';
  static String routePath = '/addpay';

  @override
  State<AddpayWidget> createState() => _AddpayWidgetState();
}

class _AddpayWidgetState extends State<AddpayWidget> {
  late AddpayModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddpayModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _continueWithNGenius() {
    FFAppState().clearSensitivePaymentSession();
    FFAppState().ElectronicPayment = true;
    FFAppState().payth = TouryPaymentKeys.online;
    Navigator.pop(context);
  }

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
              title: 'ux_choose_payment_method'.tr(),
              leading: DsIconButton(
                icon: DsIcons.back,
                onPressed: () => Navigator.pop(context),
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
                                Icons.lock_person_rounded,
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
                          const SizedBox(height: DsSpacing.xxl),
                          DsButton.primary(
                            label: 'ux_choose_payment_method'.tr(),
                            icon: Icons.open_in_browser_rounded,
                            size: DsButtonSize.lg,
                            expanded: true,
                            onPressed: _continueWithNGenius,
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
