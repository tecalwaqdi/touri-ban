import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'paymet_hostre_model.dart';

export 'paymet_hostre_model.dart';

class PaymetHostreWidget extends StatefulWidget {
  const PaymetHostreWidget({super.key});

  static String routeName = 'paymetHostre';
  static String routePath = '/paymetHostre';

  @override
  State<PaymetHostreWidget> createState() => _PaymetHostreWidgetState();
}

class _PaymetHostreWidgetState extends State<PaymetHostreWidget> {
  late PaymetHostreModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymetHostreModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _copyReference(BuildContext context, String reference) async {
    await Clipboard.setData(ClipboardData(text: reference));
    if (!context.mounted) return;
    DsSnackBar.show(
      context,
      message: 'ui_text_5a9a57155e'.tr(),
      tone: DsSnackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: FFLocalizations.of(context).getText(
                  'l6tvs8nj' /* Payment History */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: SafeArea(
                top: true,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.sm,
                        ),
                        child: const DsFadeSlide(child: _SupportCard()),
                      ),
                    ),
                    _PaymentHistorySliver(onCopy: _copyReference),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: DsSpacing.huge),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              DsIcons.support,
              size: DsIcons.sm,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FFLocalizations.of(context).getText(
                    '1zy89rub' /* Contact us directly */,
                  ),
                  style: typography.titleSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: DsSpacing.xxs),
                Text(
                  FFLocalizations.of(context).getText(
                    'hgf4wq1o' /* Would you like to contact our ... */,
                  ),
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.xs),
          DsButton.success(
            label: FFLocalizations.of(context).getText(
              'mkpy4art' /* WhatsApp */,
            ),
            icon: DsIcons.chat,
            size: DsButtonSize.sm,
            onPressed: () async {
              await launchURL('https://wa.me/966533356126');
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentHistorySliver extends StatelessWidget {
  const _PaymentHistorySliver({required this.onCopy});

  final Future<void> Function(BuildContext context, String reference) onCopy;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymenthistoryRecord>>(
      stream: queryPaymenthistoryRecord(
        queryBuilder: (paymenthistoryRecord) => paymenthistoryRecord
            .where(
              'RevUser',
              isEqualTo: currentUserReference,
            )
            .orderBy('DateAdd', descending: true),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(DsSpacing.xl),
              child: DsLoading(),
            ),
          );
        }

        final payments = snapshot.data!;
        if (payments.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xl),
              child: DsEmptyState(
                title: FFLocalizations.of(context).getText(
                  'l6tvs8nj' /* Payment History */,
                ),
                icon: DsIcons.payment,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          sliver: SliverList.separated(
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.sm),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return DsFadeSlide(
                delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                child: _PaymentCard(payment: payment, onCopy: onCopy),
              );
            },
          ),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onCopy,
  });

  final PaymenthistoryRecord payment;
  final Future<void> Function(BuildContext context, String reference) onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        'mfpactp9' /* TXN ID: */,
                      ),
                      style: typography.labelMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Text(
                      payment.id.toString(),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xs),
                    Text(
                      FFLocalizations.of(context).getText(
                        '22fhwxu4' /* Online Payment ID: */,
                      ),
                      style: typography.labelMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            payment.myserReference,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: DsSpacing.xxs),
                        DsIconButton(
                          icon: Icons.copy_all_rounded,
                          size: DsIcons.xs,
                          tooltip: FFLocalizations.of(context).getText(
                            '22fhwxu4' /* Online Payment ID: */,
                          ),
                          onPressed: () =>
                              onCopy(context, payment.myserReference),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DsSpacing.xs),
              Container(
                padding: DsSpacing.chipPadding,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.pill,
                ),
                child: Text(
                  payment.total.toString(),
                  style: typography.titleMedium.copyWith(
                    color: colors.primaryStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            payment.osf,
            style: typography.titleSmall.copyWith(color: colors.primary),
          ),
          const SizedBox(height: DsSpacing.sm),
          const DsDivider(),
          const SizedBox(height: DsSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: DsIcons.xs,
                color: colors.iconMuted,
              ),
              const SizedBox(width: DsSpacing.xxs),
              Text(
                dateTimeFormat(
                  "yMd",
                  payment.dateAdd!,
                  locale: FFLocalizations.of(context).languageCode,
                ),
                style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
