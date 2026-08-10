import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_autocomplete_options_list.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'demoall_model.dart';
export 'demoall_model.dart';

class DemoallWidget extends StatefulWidget {
  const DemoallWidget({super.key});

  static String routeName = 'demoall';
  static String routePath = '/demoall';

  @override
  State<DemoallWidget> createState() => _DemoallWidgetState();
}

class _DemoallWidgetState extends State<DemoallWidget> {
  late DemoallModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DemoallModel());

    _model.textController ??= TextEditingController();

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
                  '9ac24svm' /* Page Title */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: Padding(
                  padding: DsSpacing.pagePadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: 200.0,
                        child: Autocomplete<String>(
                          initialValue: const TextEditingValue(),
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }
                            return [
                              FFLocalizations.of(context).getText(
                                'y3ohw9ob' /* Option 1 */,
                              )
                            ].where((option) {
                              final lowercaseOption = option.toLowerCase();
                              return lowercaseOption
                                  .contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return AutocompleteOptionsList(
                              textFieldKey: _model.textFieldKey,
                              textController: _model.textController!,
                              options: options.toList(),
                              onSelected: onSelected,
                              textStyle: typography.bodyMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                              textHighlightStyle: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              elevation: 4.0,
                              optionBackgroundColor: colors.surface,
                              optionHighlightColor: colors.selected,
                              maxHeight: 200.0,
                            );
                          },
                          onSelected: (String selection) {
                            safeSetState(
                                () => _model.textFieldSelectedOption = selection);
                            FocusScope.of(context).unfocus();
                          },
                          fieldViewBuilder: (
                            context,
                            textEditingController,
                            focusNode,
                            onEditingComplete,
                          ) {
                            _model.textFieldFocusNode = focusNode;

                            _model.textController = textEditingController;
                            return TextFormField(
                              key: _model.textFieldKey,
                              controller: textEditingController,
                              focusNode: focusNode,
                              onEditingComplete: onEditingComplete,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                labelStyle: typography.labelMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                                hintText: FFLocalizations.of(context).getText(
                                  'l05w1po4' /* TextField */,
                                ),
                                hintStyle: typography.labelMedium.copyWith(
                                  color: colors.hint,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.border,
                                    width: 1.0,
                                  ),
                                  borderRadius: DsRadius.medium,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.focus,
                                    width: 1.6,
                                  ),
                                  borderRadius: DsRadius.medium,
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.error,
                                    width: 1.0,
                                  ),
                                  borderRadius: DsRadius.medium,
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.error,
                                    width: 1.6,
                                  ),
                                  borderRadius: DsRadius.medium,
                                ),
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding: DsSpacing.inputContentPadding,
                              ),
                              style: typography.bodyMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                              cursorColor: colors.primary,
                              validator: _model.textControllerValidator
                                  .asValidator(context),
                            );
                          },
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
