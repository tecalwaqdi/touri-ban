import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'c_l_e_n_t_model.dart';
export 'c_l_e_n_t_model.dart';

/// معلومات العميل : الاسم Maryam Kutob البريد الالكتروني :
/// kutob.m1413@gmail.com الجوال: 561790844 تاريخ ووقت التسجيل : 5/01/2025
/// HGSHUM: 5:36مساء  حالة المستخدم : فعال
class CLENTWidget extends StatefulWidget {
  const CLENTWidget({super.key});

  static String routeName = 'cLENT';
  static String routePath = '/cLENT';

  @override
  State<CLENTWidget> createState() => _CLENTWidgetState();
}

class _CLENTWidgetState extends State<CLENTWidget> {
  late CLENTModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CLENTModel());

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
                  'z500a02z' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0, 0, DsSpacing.xs, 0),
                    child: DsIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
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
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        DsFadeSlide(
                          child: DsCard(
                            elevated: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '0kq06ppj' /* بيانات الحساب */,
                                        ),
                                        style:
                                            typography.headlineSmall.copyWith(
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: DsSpacing.chipPadding,
                                      decoration: BoxDecoration(
                                        color: colors.successContainer,
                                        borderRadius: DsRadius.pill,
                                      ),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '0ikz0cm7' /* فعال */,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: typography.labelMedium.copyWith(
                                          color: colors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const DsDivider(),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    'sx1se0xw' /* الاسم */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'm2uk6z9x' /* Maryam Kutob */,
                                  ),
                                ),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    '2uzivn3x' /* البريد الإلكتروني */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'x9k9c3m1' /* kutob.m1413@gmail.com */,
                                  ),
                                ),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    '4mdbdo6q' /* رقم الجوال */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    '3nwyn55d' /* 561790844 */,
                                  ),
                                ),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    'pqjmtcra' /* تاريخ التسجيل */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'bc3a0uzo' /* 5/01/2025 */,
                                  ),
                                ),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    '6jzprtir' /* وقت التسجيل */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'ujm72x79' /* 5:36 مساء */,
                                  ),
                                ),
                                _InfoRow(
                                  label: FFLocalizations.of(context).getText(
                                    '0l4fzfr2' /* رمز المستخدم */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'esu5z3xb' /* HGSHUM */,
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.sm)),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'zqpla5m1' /* الإجراءات */,
                                  ),
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                                const DsDivider(),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: DsButton.primary(
                                        label:
                                            FFLocalizations.of(context).getText(
                                          'wmfgpmkz' /* تعديل البيانات */,
                                        ),
                                        expanded: true,
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: DsButton.secondary(
                                        label:
                                            FFLocalizations.of(context).getText(
                                          '7p8b3652' /* تغيير كلمة المرور */,
                                        ),
                                        expanded: true,
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                      ),
                                    ),
                                  ].divide(const SizedBox(width: DsSpacing.sm)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: DsButton.danger(
                                        label:
                                            FFLocalizations.of(context).getText(
                                          '9qis5zxw' /* إيقاف الحساب */,
                                        ),
                                        expanded: true,
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: DsButton.outlined(
                                        label:
                                            FFLocalizations.of(context).getText(
                                          '72j566sl' /* حذف الحساب */,
                                        ),
                                        expanded: true,
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                      ),
                                    ),
                                  ].divide(const SizedBox(width: DsSpacing.sm)),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.sm)),
                            ),
                          ),
                        ),
                      ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: typography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
