import '/backend/api_requests/api_calls.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'reg_compne_model.dart';
export 'reg_compne_model.dart';

/// identityNumber: رقم هوية الشركة أو الفرد.
///
/// commercialRecordNumber: رقم السجل التجاري.
/// commercialRecordIssueDateHijri: تاريخ إصدار السجل (هجري).
/// phoneNumber: رقم الهاتف (بصيغة +966).
/// extensionNumber: رقم التحويلة (اختياري).
/// emailAddress: البريد الإلكتروني للشركة.
/// managerName: اسم مدير الشركة.
/// managerPhoneNumber: رقم هاتف المدير.
/// managerMobileNumber: رقم جوال المدير.
/// activity: نوع النشاط (نقل متخصص، تأجير حافلات، نقل تعليمي)
class RegCompneWidget extends StatefulWidget {
  const RegCompneWidget({super.key});

  static String routeName = 'reg_compne';
  static String routePath = '/regCompne';

  @override
  State<RegCompneWidget> createState() => _RegCompneWidgetState();
}

class _RegCompneWidgetState extends State<RegCompneWidget> {
  late RegCompneModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegCompneModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.textController5 ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();

    _model.textController6 ??= TextEditingController();
    _model.textFieldFocusNode6 ??= FocusNode();

    _model.textController7 ??= TextEditingController();
    _model.textFieldFocusNode7 ??= FocusNode();

    _model.textController8 ??= TextEditingController();
    _model.textFieldFocusNode8 ??= FocusNode();

    _model.textController9 ??= TextEditingController();
    _model.textFieldFocusNode9 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _onActivitySelected(String? val) async {
    safeSetState(() => _model.choiceChipsValue = val);
    _model.apiResultjrx = await WaslhaflhCall.call(
      identityNumber: _model.textController2.text,
      commercialRecordNumber: _model.textController1.text,
      commercialRecordIssueDateHijri: _model.textController4.text,
      phoneNumber: _model.textController3.text,
      emailAddress: _model.textController6.text,
      managerName: _model.textController7.text,
      managerPhoneNumber: _model.textController8.text,
      extensionNumber: _model.textController5.text,
    );

    if ((_model.apiResultjrx?.succeeded ?? true)) {
      await DsDialog.show(
        context: context,
        title: driverTr(context, 'Registration successful'),
        message: driverTr(context, 'Registration successful'),
        confirmLabel: 'Ok',
      );
    } else {
      await DsDialog.show(
        context: context,
        title: driverTr(context, 'There is an error'),
        message: driverTr(context, 'Error'),
        confirmLabel: 'Ok',
      );
    }

    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return DsScreenScaffold(
            scaffoldKey: scaffoldKey,
            appBar: DsAppBar(
              automaticallyImplyLeading: true,
              title: FFLocalizations.of(context).getText(
                'jbty0rd1' /* تسجيل الشركات في أرى وطن */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: DsSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        'jbty0rd1' /* تسجيل الشركات في أرى وطن */,
                      ),
                      style: typography.headlineSmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    Form(
                      key: _model.formKey2,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: DsCard(
                        elevated: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '7y3s4gp6' /* معلومات الشركة */,
                              ),
                              style: typography.titleLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.md),
                            DsTextField(
                              controller: _model.textController1,
                              focusNode: _model.textFieldFocusNode1,
                              hint: FFLocalizations.of(context).getText(
                                'eni9yuvm' /* رقم السجل التجاري */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField(
                              controller: _model.textController2,
                              focusNode: _model.textFieldFocusNode2,
                              hint: FFLocalizations.of(context).getText(
                                'pg9q8k9q' /* رقم هوية الشركة أو الفرد */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField.phone(
                              controller: _model.textController3,
                              focusNode: _model.textFieldFocusNode3,
                              hint: FFLocalizations.of(context).getText(
                                'kykweopk' /*  +966 رقم الهاتف */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField(
                              controller: _model.textController4,
                              focusNode: _model.textFieldFocusNode4,
                              hint: FFLocalizations.of(context).getText(
                                '6br81xy1' /* تاريخ إصدار السجل (هجري) */,
                              ),
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField(
                              controller: _model.textController5,
                              focusNode: _model.textFieldFocusNode5,
                              hint: FFLocalizations.of(context).getText(
                                'l3dtyarc' /* رقم التحويلة (اختياري) */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField.email(
                              controller: _model.textController6,
                              focusNode: _model.textFieldFocusNode6,
                              hint: FFLocalizations.of(context).getText(
                                '7a9dg36g' /* البريد الإلكتروني للشركة */,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    Form(
                      key: _model.formKey1,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: DsCard(
                        elevated: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'hi539rl7' /* معلومات المدير */,
                              ),
                              style: typography.titleLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.md),
                            DsTextField(
                              controller: _model.textController7,
                              focusNode: _model.textFieldFocusNode7,
                              hint: FFLocalizations.of(context).getText(
                                '1313wasv' /* اسم مدير الشركة */,
                              ),
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField.phone(
                              controller: _model.textController8,
                              focusNode: _model.textFieldFocusNode8,
                              hint: FFLocalizations.of(context).getText(
                                'khty22qt' /*  +966 رقم هاتف المدير */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField.phone(
                              controller: _model.textController9,
                              focusNode: _model.textFieldFocusNode9,
                              hint: FFLocalizations.of(context).getText(
                                '8edb6gp4' /*  +966 رقم جوال المدير */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.lg),
                            Text(
                              FFLocalizations.of(context).getText(
                                'l57eommt' /* نوع النشاط */,
                              ),
                              style: typography.titleMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            FlutterFlowChoiceChips(
                              options: [
                                ChipData(FFLocalizations.of(context).getText(
                                  'teen9wgy' /* نقل متخصص */,
                                )),
                                ChipData(FFLocalizations.of(context).getText(
                                  'shcgfgch' /* تأجير حافلات */,
                                )),
                                ChipData(FFLocalizations.of(context).getText(
                                  'rvh9b56m' /* نقل تعليمي */,
                                )),
                              ],
                              onChanged: (val) async {
                                await _onActivitySelected(val?.firstOrNull);
                              },
                              selectedChipStyle: ChipStyle(
                                backgroundColor: colors.primary,
                                textStyle: typography.bodyMedium.copyWith(
                                  color: colors.onPrimary,
                                ),
                                iconColor: colors.onPrimary,
                                iconSize: 18.0,
                                elevation: 0.0,
                                borderColor: colors.primary,
                                borderWidth: 2.0,
                                borderRadius: DsRadius.medium,
                              ),
                              unselectedChipStyle: ChipStyle(
                                backgroundColor: colors.surface,
                                textStyle: typography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                                iconColor: colors.textPrimary,
                                iconSize: 18.0,
                                elevation: 0.0,
                                borderColor: colors.border,
                                borderWidth: 1.0,
                                borderRadius: DsRadius.medium,
                              ),
                              chipSpacing: DsSpacing.sm,
                              rowSpacing: DsSpacing.sm,
                              multiselect: false,
                              alignment: WrapAlignment.start,
                              controller: _model.choiceChipsValueController ??=
                                  FormFieldController<List<String>>([]),
                              wrapped: true,
                            ),
                            const SizedBox(height: DsSpacing.xl),
                            DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                'hl3hjoo1' /* تقديم الطلب */,
                              ),
                              expanded: true,
                              onPressed: () {
                                print('Button pressed ...');
                              },
                            ),
                          ],
                        ),
                      ),
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
