import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'new_support_ticket_model.dart';

export 'new_support_ticket_model.dart';

/// "Create a 'New Support Ticket' page with a structured and intuitive UI.
///
/// The page should include the following fields:
///
/// Description (a text input for users to describe their issue)
/// Category Selection (a dropdown menu with options: Inquiry, Suggestion,
/// Complaint, Booking Issue, and Other)
/// Message (a larger text area for detailed explanation)
/// At the bottom, include a prominent 'Create New Ticket' button to submit
/// the request. Ensure the design is clean, user-friendly, and easy to
/// navigate."
class NewSupportTicketWidget extends StatefulWidget {
  const NewSupportTicketWidget({super.key});

  static String routeName = 'NewSupportTicket';
  static String routePath = '/newSupportTicket';

  @override
  State<NewSupportTicketWidget> createState() => _NewSupportTicketWidgetState();
}

class _NewSupportTicketWidgetState extends State<NewSupportTicketWidget> {
  late NewSupportTicketModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewSupportTicketModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  List<TextInputFormatter> get _sentenceCaseFormatters => [
        if (!isAndroid && !isiOS)
          TextInputFormatter.withFunction((oldValue, newValue) {
            return TextEditingValue(
              selection: newValue.selection,
              text: newValue.text.toCapitalization(
                TextCapitalization.sentences,
              ),
            );
          }),
      ];

  void _createTicket() {
    debugPrint('Button pressed ...');
  }

  @override
  Widget build(BuildContext context) {
    _model.dropDownValueController ??= FormFieldController<String>(null);

    final categories = [
      FFLocalizations.of(context).getText(
        'n0q7r4aa' /* Inquiry */,
      ),
      FFLocalizations.of(context).getText(
        'x63qzak0' /* Suggestion */,
      ),
      FFLocalizations.of(context).getText(
        '92vrxps3' /* Complaint */,
      ),
      FFLocalizations.of(context).getText(
        '61fh3lgd' /* Booking Issue */,
      ),
      FFLocalizations.of(context).getText(
        '2mqwfmfm' /* Other */,
      ),
    ];

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
                  '6hxnd9xt' /* New Support Ticket */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.huge,
                  ),
                  child: DsFadeSlide(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DsConstants.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DsCard(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          'xpwrz6p5' /* Contact us directly */,
                                        ),
                                        style: typography.titleSmall.copyWith(
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: DsSpacing.xxs),
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          'bz1w6ty1' /* Would you like to contact our ... */,
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
                                    '6hgljn1l' /* WhatsApp */,
                                  ),
                                  icon: DsIcons.chat,
                                  size: DsButtonSize.sm,
                                  onPressed: () async {
                                    await launchURL(
                                      'https://wa.me/966533356126',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          _SectionLabel(
                            label: FFLocalizations.of(context).getText(
                              'gli3wwly' /* Description */,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xs),
                          DsTextField(
                            controller: _model.textController1,
                            focusNode: _model.textFieldFocusNode1,
                            hint: FFLocalizations.of(context).getText(
                              'dsdmwhsc' /* Brief description of your issu... */,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: _sentenceCaseFormatters,
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          _SectionLabel(
                            label: FFLocalizations.of(context).getText(
                              'ifmrn8nq' /* Category */,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xs),
                          DsDropdown<String>(
                            value: _model.dropDownValue,
                            hint: FFLocalizations.of(context).getText(
                              '21v4uv3v' /* Select a category */,
                            ),
                            items: [
                              for (final category in categories)
                                DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                ),
                            ],
                            onChanged: (val) => safeSetState(() {
                              _model.dropDownValue = val;
                              _model.dropDownValueController?.value = val;
                            }),
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          _SectionLabel(
                            label: FFLocalizations.of(context).getText(
                              'ep2pnp4w' /* Message */,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xs),
                          DsTextField(
                            controller: _model.textController2,
                            focusNode: _model.textFieldFocusNode2,
                            hint: FFLocalizations.of(context).getText(
                              'fxbwomyc' /* Please provide detailed inform... */,
                            ),
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.multiline,
                            maxLines: 8,
                            minLines: 5,
                            inputFormatters: _sentenceCaseFormatters,
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          DsInformationCard(
                            title: FFLocalizations.of(context).getText(
                              '5y5898tw' /* Support ticket information */,
                            ),
                            message: FFLocalizations.of(context).getText(
                              'go40c6ek' /* Our support team typically res... */,
                            ),
                            icon: Icons.info_outline_rounded,
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          DsButton.primary(
                            label: FFLocalizations.of(context).getText(
                              '3mjks8fo' /* Create New Ticket */,
                            ),
                            icon: Icons.add_task_rounded,
                            expanded: true,
                            size: DsButtonSize.lg,
                            onPressed: _createTicket,
                          ),
                        ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return Text(
      label,
      style: context.dsTypography.titleMedium.copyWith(color: colors.primary),
    );
  }
}
