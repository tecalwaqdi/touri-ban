import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'updet_bank_model.dart';
export 'updet_bank_model.dart';

class UpdetBankWidget extends StatefulWidget {
  const UpdetBankWidget({super.key});

  static String routeName = 'UpdetBank';
  static String routePath = '/updetBank';

  @override
  State<UpdetBankWidget> createState() => _UpdetBankWidgetState();
}

class _UpdetBankWidgetState extends State<UpdetBankWidget> {
  late UpdetBankModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UpdetBankModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??=
        TextEditingController(text: currentUserDisplayName);
    _model.textFieldFocusNode4 ??= FocusNode();

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
            appBar: DriverMainAppBar(
              title: driverTr(context, 'bank.title'),
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: DsSpacing.pagePadding,
                child: DriverFormWidth(
                  child: DsCard(
                    elevated: true,
                    padding: DsSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.primarySoft,
                                borderRadius: DsRadius.medium,
                              ),
                              child: Icon(
                                Icons.account_balance_rounded,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: DsSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverTr(context, 'bank.account_info'),
                                    style: typography.titleLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    driverTr(context, 'bank.update_prompt'),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DsSpacing.xl),
                        DsTextField(
                          controller: _model.textController1,
                          focusNode: _model.textFieldFocusNode1,
                          label: driverTr(context, 'bank.bank_name'),
                          hint: driverTr(context, 'bank.bank_name_hint'),
                          prefixIcon: const Icon(Icons.account_balance_outlined),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        DsTextField(
                          controller: _model.textController2,
                          focusNode: _model.textFieldFocusNode2,
                          label: driverTr(context, 'bank.account_number'),
                          hint: driverTr(context, 'bank.account_number_hint'),
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.numbers_outlined),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        DsTextField(
                          controller: _model.textController3,
                          focusNode: _model.textFieldFocusNode3,
                          label: driverTr(context, 'bank.iban'),
                          hint: 'SA0000000000000000000000',
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        AuthUserStreamWidget(
                          builder: (context) => DsTextField(
                            controller: _model.textController4,
                            focusNode: _model.textFieldFocusNode4,
                            label: driverTr(context, 'bank.account_holder'),
                            hint: driverTr(context, 'bank.account_holder_hint'),
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xl),
                        DsButton.primary(
                          label: driverTr(context, 'bank.update'),
                          expanded: true,
                          icon: Icons.save_outlined,
                          onPressed: () async {
                            if ((_model.textController2.text != null &&
                                    _model.textController2.text != '') &&
                                (_model.textController3.text != null &&
                                    _model.textController3.text != '')) {
                              await currentUserReference!
                                  .update(createUserRecordData(
                                bankNaim: _model.textController1.text,
                                bankIdAcc: valueOrDefault(
                                    currentUserDocument?.bankIdAcc, ''),
                                ipanBank: _model.textController3.text,
                                banknaimAcc: _model.textController4.text,
                              ));
                              DsSnackBar.show(
                                context,
                                message: driverTr(context, 'Data updated successfully'),
                                tone: DsSnackTone.success,
                              );

                              context.pushNamed(HomeWidget.routeName);
                            } else {
                              DsSnackBar.show(
                                context,
                                message: driverTr(context, 'Please enter account number and IBAN'),
                                tone: DsSnackTone.error,
                              );
                            }
                          },
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
