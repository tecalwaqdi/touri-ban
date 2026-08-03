import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'r_e_gdrev_model.dart';
export 'r_e_gdrev_model.dart';

/// رسالة تحفيزية - يمكنك التسجيل كسائق في أرى وطن والحصول على عمولات بحد أدنى
/// 300 ريال للرحلة الواحدة
class REGdrevWidget extends StatefulWidget {
  const REGdrevWidget({super.key});

  static String routeName = 'REGdrev';
  static String routePath = '/rEGdrev';

  @override
  State<REGdrevWidget> createState() => _REGdrevWidgetState();
}

class _REGdrevWidgetState extends State<REGdrevWidget> {
  late REGdrevModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => REGdrevModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: colors.scaffold,
            appBar: DsAppBar(
              title: FFLocalizations.of(context).getText(
                'l2ec3lla' /* تسجيل سائق */,
              ),
              automaticallyImplyLeading: false,
              actions: const [],
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DsFadeSlide(
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  'hosgoswn' /* انضم إلى فريق أرى وطن */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.headlineSmall.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                              Text(
                                FFLocalizations.of(context).getText(
                                  '3yaghabt' /* احصل على عمولات مجزية تبدأ من ... */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.titleMedium.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const DsDivider(),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BenefitRow(
                                    icon: Icons.attach_money_rounded,
                                    label: FFLocalizations.of(context).getText(
                                      '9iun4k79' /* دخل إضافي يصل إلى 10,000 ريال ... */,
                                    ),
                                  ),
                                  _BenefitRow(
                                    icon: Icons.schedule_rounded,
                                    label: FFLocalizations.of(context).getText(
                                      'ss0u7khu' /* ساعات عمل مرنة تناسب جدولك */,
                                    ),
                                  ),
                                  _BenefitRow(
                                    icon: DsIcons.support,
                                    label: FFLocalizations.of(context).getText(
                                      'hjygkifa' /* دعم فني على مدار الساعة */,
                                    ),
                                  ),
                                  _BenefitRow(
                                    icon: Icons.payments_rounded,
                                    label: FFLocalizations.of(context).getText(
                                      '6dullggg' /* تحويل مباشر للأرباح أسبوعياً */,
                                    ),
                                  ),
                                ].divide(const SizedBox(height: DsSpacing.sm)),
                              ),
                            ].divide(const SizedBox(height: DsSpacing.md)),
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 60),
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  '3hzs74oz' /*  التسجيل */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.titleLarge.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                              DsButton.primary(
                                label: FFLocalizations.of(context).getText(
                                  'x4sbnhc9' /* اضغط هنا للتسجيل كسائق */,
                                ),
                                expanded: true,
                                size: DsButtonSize.lg,
                                onPressed: () async {
                                  await launchURL(
                                      'https://forms.gle/WiiYrRwDaM2dz2xb6');
                                },
                              ),
                              const DsDivider(),
                            ].divide(const SizedBox(height: DsSpacing.sm)),
                          ),
                        ),
                      ),
                    ],
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(
          icon,
          color: colors.primary,
          size: DsConstants.iconMd,
        ),
        Expanded(
          child: Text(
            label,
            style: typography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ].divide(const SizedBox(width: DsSpacing.xs)),
    );
  }
}
