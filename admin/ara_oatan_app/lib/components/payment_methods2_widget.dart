import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_labels.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'payment_methods2_model.dart';

export 'payment_methods2_model.dart';

class PaymentMethods2Widget extends StatefulWidget {
  const PaymentMethods2Widget({super.key});

  @override
  State<PaymentMethods2Widget> createState() => _PaymentMethods2WidgetState();
}

class _PaymentMethods2WidgetState extends State<PaymentMethods2Widget> {
  late PaymentMethods2Model _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentMethods2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _selectOnline() {
    if (!TouryPaymentFlags.onlineOptionVisible()) return;
    FFAppState().clearSensitivePaymentSession();
    FFAppState().ElectronicPayment = true;
    FFAppState().payth = TouryPaymentKeys.online;
    Navigator.pop(context);
  }

  void _selectCash() {
    FFAppState().clearSensitivePaymentSession();
    FFAppState().ElectronicPayment = false;
    FFAppState().payth = TouryPaymentKeys.cash;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final showOnline = TouryPaymentFlags.onlineOptionVisible();

    return SafeArea(
      top: false,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.sm,
            DsSpacing.md,
            DsSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: DsRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ux_choose_payment_method'.tr(),
                      style: typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  DsIconButton(
                    icon: DsIcons.close,
                    onPressed: () => Navigator.pop(context),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              if (showOnline) ...[
                DsPaymentCard(
                  title: 'ux_card_payment_network'.tr(),
                  subtitle: '',
                  leading: Icon(
                    Icons.verified_user_rounded,
                    color: colors.primary,
                    size: DsIcons.lg,
                  ),
                  onTap: _selectOnline,
                ),
                const SizedBox(height: DsSpacing.sm),
              ],
              StreamBuilder<List<SettingsRecord>>(
                stream: TouryFirestoreCache.settingsStream(singleRecord: true),
                builder: (context, snapshot) {
                  final remoteOkCash = snapshot.hasData &&
                      snapshot.data!.isNotEmpty &&
                      snapshot.data!.first.oKcash;
                  final cashEnabled = TouryPaymentFlags.cashOptionVisible(
                    remoteOkCash: remoteOkCash,
                  );
                  if (!cashEnabled) return const SizedBox.shrink();
                  return DsPaymentCard(
                    title: 'ux_cash_on_delivery'.tr(),
                    subtitle: '',
                    leading: Icon(
                      Icons.payments_rounded,
                      color: colors.primary,
                      size: DsIcons.lg,
                    ),
                    onTap: _selectCash,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
