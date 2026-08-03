import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'khj_model.dart';
export 'khj_model.dart';

/// Your booking has been set using the driver guide to choose tourist spots.
class KhjWidget extends StatefulWidget {
  const KhjWidget({super.key});

  static String routeName = 'khj';
  static String routePath = '/khj';

  @override
  State<KhjWidget> createState() => _KhjWidgetState();
}

class _KhjWidgetState extends State<KhjWidget> {
  late KhjModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KhjModel());

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
                  'ecoqcp1i' /* Page Title */,
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
                child: Padding(
                  padding: const EdgeInsets.all(DsSpacing.xl),
                  child: SingleChildScrollView(
                    primary: false,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DsFadeSlide(
                          child: Container(
                            width: 120.0,
                            height: 120.0,
                            decoration: BoxDecoration(
                              color: colors.success,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              color: colors.onSuccess,
                              size: 60.0,
                            ),
                          ),
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            'u3abc4f6' /* Trip Assistance Selected */,
                          ),
                          textAlign: TextAlign.center,
                          style: typography.headlineMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        DsCard(
                          color: colors.primarySoft,
                          bordered: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: colors.primary,
                                    size: DsConstants.iconMd,
                                  ),
                                  Expanded(
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'xqe32h46' /* Personalized Route */,
                                      ),
                                      style: typography.titleMedium.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ].divide(const SizedBox(width: DsSpacing.sm)),
                              ),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'nrv5yh9e' /* Top local attractions curated ... */,
                                ),
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              FlutterFlowChoiceChips(
                                options: [
                                  ChipData(FFLocalizations.of(context).getText(
                                    'l07tfzvq' /* Historical Sites */,
                                  )),
                                  ChipData(FFLocalizations.of(context).getText(
                                    'k135re5t' /* Local Markets */,
                                  )),
                                  ChipData(FFLocalizations.of(context).getText(
                                    '4f9z40pa' /* Scenic Views */,
                                  )),
                                  ChipData(FFLocalizations.of(context).getText(
                                    '9mc2o1fr' /* Cultural Centers */,
                                  ))
                                ],
                                onChanged: (val) => safeSetState(() =>
                                    _model.choiceChipsValue = val?.firstOrNull),
                                selectedChipStyle: ChipStyle(
                                  backgroundColor: colors.primary,
                                  textStyle: typography.labelMedium.copyWith(
                                    color: colors.onPrimary,
                                  ),
                                  iconColor: colors.onPrimary,
                                  iconSize: DsConstants.iconXs,
                                  elevation: 0.0,
                                  borderRadius: DsRadius.pill,
                                ),
                                unselectedChipStyle: ChipStyle(
                                  backgroundColor: colors.surface,
                                  textStyle: typography.labelMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  iconColor: colors.iconMuted,
                                  iconSize: DsConstants.iconXs,
                                  elevation: 0.0,
                                  borderRadius: DsRadius.pill,
                                ),
                                chipSpacing: DsSpacing.xs,
                                rowSpacing: DsSpacing.xs,
                                multiselect: false,
                                alignment: WrapAlignment.start,
                                controller: _model.choiceChipsValueController ??=
                                    FormFieldController<List<String>>(
                                  [],
                                ),
                                wrapped: true,
                              ),
                            ].divide(const SizedBox(height: DsSpacing.sm)),
                          ),
                        ),
                        DsButton.primary(
                          label: FFLocalizations.of(context).getText(
                            '8gufw3ls' /* Contact Your Guide */,
                          ),
                          icon: Icons.phone_rounded,
                          expanded: true,
                          size: DsButtonSize.lg,
                          onPressed: () {
                            print('Button pressed ...');
                          },
                        ),
                        DsButton.outlined(
                          label: FFLocalizations.of(context).getText(
                            'qps226t4' /* View Trip Details */,
                          ),
                          expanded: true,
                          onPressed: () {
                            print('Button pressed ...');
                          },
                        ),
                      ].divide(const SizedBox(height: DsSpacing.xxxl)),
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
