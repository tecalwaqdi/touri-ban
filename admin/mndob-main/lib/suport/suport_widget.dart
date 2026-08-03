import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'suport_model.dart';
export 'suport_model.dart';

class SuportWidget extends StatefulWidget {
  const SuportWidget({super.key});

  static String routeName = 'suport';
  static String routePath = '/suport';

  @override
  State<SuportWidget> createState() => _SuportWidgetState();
}

class _SuportWidgetState extends State<SuportWidget> {
  late SuportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SuportModel());

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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: typography.bodyMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
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
                  'ic2tltrf' /* Transfer Confirmation */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      DsCard(
                        elevated: true,
                        child: StreamBuilder<List<BankRecord>>(
                          stream: queryBankRecord(
                            queryBuilder: (bankRecord) => bankRecord.where(
                              'ID',
                              isEqualTo: 1,
                            ),
                            singleRecord: true,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(DsSpacing.xl),
                                child: DsLoading(),
                              );
                            }
                            List<BankRecord> columnBankRecordList =
                                snapshot.data!;
                            if (snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final columnBankRecord =
                                columnBankRecordList.isNotEmpty
                                    ? columnBankRecordList.first
                                    : null;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'eq5o43g0' /* Bank Account Information */,
                                  ),
                                  style: typography.titleMedium.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Divider(color: colors.divider),
                                _infoRow(
                                  context,
                                  label: FFLocalizations.of(context).getText(
                                    'w8d3aapz' /* Bank Name: */,
                                  ),
                                  value: valueOrDefault<String>(
                                    columnBankRecord?.bankName,
                                    'بنك',
                                  ),
                                ),
                                DsSpacing.gapSm,
                                _infoRow(
                                  context,
                                  label: FFLocalizations.of(context).getText(
                                    'xy6ckv0p' /* Account Number: */,
                                  ),
                                  value: valueOrDefault<String>(
                                    columnBankRecord?.accountNumber,
                                    'غير معرف',
                                  ),
                                ),
                                DsSpacing.gapSm,
                                _infoRow(
                                  context,
                                  label: FFLocalizations.of(context).getText(
                                    '1i29t8jx' /* IBAN: */,
                                  ),
                                  value: valueOrDefault<String>(
                                    columnBankRecord?.iban,
                                    'غير معرف',
                                  ),
                                ),
                                DsSpacing.gapSm,
                                _infoRow(
                                  context,
                                  label: FFLocalizations.of(context).getText(
                                    'u33lhr0z' /* Account Holder: */,
                                  ),
                                  value: valueOrDefault<String>(
                                    columnBankRecord?.accountHolder,
                                    'شركة وكالة أرى وطن',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      DsSpacing.gapMd,
                      DsCard(
                        elevated: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'kqjw94gh' /* Transfer Confirmation Form */,
                              ),
                              style: typography.titleMedium.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Divider(color: colors.divider),
                            Form(
                              key: _model.formKey,
                              autovalidateMode: AutovalidateMode.disabled,
                              child: Column(
                                children: [
                                  DsTextField(
                                    controller: _model.textController1,
                                    focusNode: _model.textFieldFocusNode1,
                                    label: FFLocalizations.of(context).getText(
                                      '3cbykrnk' /* Sender's Name */,
                                    ),
                                  ),
                                  DsSpacing.gapMd,
                                  DsTextField(
                                    controller: _model.textController2,
                                    focusNode: _model.textFieldFocusNode2,
                                    label: FFLocalizations.of(context).getText(
                                      '52nc4zix' /* Sending Bank */,
                                    ),
                                  ),
                                  DsSpacing.gapMd,
                                  DsTextField(
                                    controller: _model.textController3,
                                    focusNode: _model.textFieldFocusNode3,
                                    label: FFLocalizations.of(context).getText(
                                      '5h0f3l6a' /* Transferred Amount */,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  DsSpacing.gapMd,
                                  DsTextField(
                                    controller: _model.textController4,
                                    focusNode: _model.textFieldFocusNode4,
                                    readOnly: true,
                                    onSubmitted: (_) async {
                                      final _datePickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: getCurrentTimestamp,
                                        firstDate: DateTime(1900),
                                        lastDate: (getCurrentTimestamp ??
                                            DateTime(2050)),
                                        builder: (context, child) {
                                          return wrapInMaterialDatePickerTheme(
                                            context,
                                            child!,
                                            headerBackgroundColor:
                                                colors.primary,
                                            headerForegroundColor:
                                                colors.onPrimary,
                                            headerTextStyle: typography
                                                .headlineLarge
                                                .copyWith(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w600,
                                              color: colors.onPrimary,
                                            ),
                                            pickerBackgroundColor:
                                                colors.surface,
                                            pickerForegroundColor:
                                                colors.textPrimary,
                                            selectedDateTimeBackgroundColor:
                                                colors.primary,
                                            selectedDateTimeForegroundColor:
                                                colors.onPrimary,
                                            actionButtonForegroundColor:
                                                colors.textPrimary,
                                            iconSize: 24,
                                          );
                                        },
                                      );

                                      if (_datePickedDate != null) {
                                        safeSetState(() {
                                          _model.datePicked = DateTime(
                                            _datePickedDate.year,
                                            _datePickedDate.month,
                                            _datePickedDate.day,
                                          );
                                        });
                                      } else if (_model.datePicked != null) {
                                        safeSetState(() {
                                          _model.datePicked =
                                              getCurrentTimestamp;
                                        });
                                      }
                                      _model.date = _model.datePicked;
                                      safeSetState(() {});
                                    },
                                    label: dateTimeFormat(
                                      'd/M/y',
                                      _model.datePicked,
                                      locale: FFLocalizations.of(context)
                                          .languageCode,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      color: colors.icon,
                                    ),
                                  ),
                                  DsSpacing.gapMd,
                                  DsTextField(
                                    controller: _model.textController5,
                                    focusNode: _model.textFieldFocusNode5,
                                    label: FFLocalizations.of(context).getText(
                                      'tan5nik6' /* Additional Notes (optional) */,
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                            DsSpacing.gapMd,
                            DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                'cojvvj9r' /* Submit Transfer Confirmation */,
                              ),
                              expanded: true,
                              onPressed: () async {
                                if ((_model.textController1.text != null &&
                                        _model.textController1.text != '') &&
                                    (_model.textController2.text != null &&
                                        _model.textController2.text != '') &&
                                    (_model.textController3.text != null &&
                                        _model.textController3.text != '') &&
                                    (_model.textController4.text != null &&
                                        _model.textController4.text != '') &&
                                    (_model.textController5.text != null &&
                                        _model.textController5.text != '')) {
                                  await SupportRecord.collection
                                      .doc()
                                      .set(createSupportRecordData(
                                        user: currentUserReference,
                                        sub:
                                            'سداد مستحقات من المندوب: ${currentUserDisplayName}',
                                        phonN: valueOrDefault(
                                            currentUserDocument?.phoneN, 0),
                                        msg:
                                            'تم سداد مستحقاتكم الخاصة بالرحلات بمبلغ : ${_model.textController3.text}بتاريخ : ${_model.datePicked?.toString()}بأسم: ${_model.textController1.text}  ريال وارجوا منكم تحديث بيانات الإستحقاق الخاصة بي   وشكرا ',
                                      ));
                                  await DsDialog.show(
                                    context: context,
                                    title: 'تم',
                                    message:
                                        'تم إرسال طلبك بنجاح وسيتم تحديث البيانات قريبا بعد التحقق منها',
                                    confirmLabel: 'Ok',
                                  );

                                  context.pushNamed(HomeWidget.routeName);
                                } else {
                                  await DsDialog.show(
                                    context: context,
                                    title: 'خطا',
                                    message: 'يرجى تعبئة جميع البيانات',
                                    confirmLabel: 'Ok',
                                  );
                                }
                              },
                            ),
                          ],
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
