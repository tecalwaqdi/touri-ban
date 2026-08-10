import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/map_suggesta_new_place_widget.dart';
import '/core/toury_content_locale.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'new_place_model.dart';

export 'new_place_model.dart';

const double _kUploadBoxHeight = 136;
const double _kMapBoxHeight = 200;

/// إقتراح مكان
class NewPlaceWidget extends StatefulWidget {
  const NewPlaceWidget({super.key});

  static String routeName = 'NewPlace';
  static String routePath = '/newPlace';

  @override
  State<NewPlaceWidget> createState() => _NewPlaceWidgetState();
}

class _NewPlaceWidgetState extends State<NewPlaceWidget> {
  late NewPlaceModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewPlaceModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia != null &&
        selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
      safeSetState(() => _model.isDataUploading_uploadData1 = true);
      var selectedUploadedFiles = <FFUploadedFile>[];

      var downloadUrls = <String>[];
      try {
        selectedUploadedFiles = selectedMedia
            .map((m) => FFUploadedFile(
                  name: m.storagePath.split('/').last,
                  bytes: m.bytes,
                  height: m.dimensions?.height,
                  width: m.dimensions?.width,
                  blurHash: m.blurHash,
                  originalFilename: m.originalFilename,
                ))
            .toList();

        downloadUrls = (await Future.wait(
          selectedMedia.map(
            (m) async => await uploadData(m.storagePath, m.bytes),
          ),
        ))
            .where((u) => u != null)
            .map((u) => u!)
            .toList();
      } finally {
        _model.isDataUploading_uploadData1 = false;
      }
      if (selectedUploadedFiles.length == selectedMedia.length &&
          downloadUrls.length == selectedMedia.length) {
        safeSetState(() {
          _model.uploadedLocalFile_uploadData1 = selectedUploadedFiles.first;
          _model.uploadedFileUrl_uploadData1 = downloadUrls.first;
        });
      } else {
        safeSetState(() {});
        return;
      }
    }
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final surface = context.dsColors.surface;
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: surface,
      enableDrag: false,
      context: context,
      builder: (context) {
        return WebViewAware(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.88,
                child: const MapSuggestaNewPlaceWidget(),
              ),
            ),
          ),
        );
      },
    ).then((value) => safeSetState(() {}));
  }

  Future<void> _submit(BuildContext context) async {
    await MkanRecord.collection.doc().set(createMkanRecordData(
          naim: _model.textController1.text,
          osf: _model.textController3.text,
          namesI18n: {
            touryContentLocaleFromContext(context):
                _model.textController1.text.trim(),
          },
          osfI18n: {
            touryContentLocaleFromContext(context):
                _model.textController3.text.trim(),
          },
          img1: _model.uploadedFileUrl_uploadData1,
          acctev: false,
          location: FFAppState().mapSuggestaNewPlace,
          suggestedPlaceCity: _model.textController2.text,
          isSuggested: true,
          contentLocale: touryContentLocaleFromContext(context),
        ));
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return WebViewAware(
          child: AlertDialog(
            title: Text('ui_text_f0ad7ac205'.tr()),
            content: Text(FFLocalizations.of(context).getVariableText(
              enText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              arText:
                  'شكراً لك. تم إرسال اقتراحك وسيُراجع قبل النشر.',
              zh_HansText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              trText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              urText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              ruText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              azText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
              kaText:
                  'Thank you! Your request has been submitted and will be reviewed by the administration for approval.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(alertDialogContext),
                child: Text('ui_text_b0a98216a3'.tr()),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted) return;
    context.safePop();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
                  'twtdn6ra' /* Suggest a New Place! */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _IntroCard(),
                        const SizedBox(height: DsSpacing.xl),
                        Text(
                          FFLocalizations.of(context).getText(
                            'v7iyihyc' /* Share your favorite place with... */,
                          ),
                          style: context.dsTypography.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        _FieldLabel(
                          emoji: FFLocalizations.of(context).getText(
                            'aae3rrqh' /* 📌 */,
                          ),
                          label: FFLocalizations.of(context).getText(
                            'yb9lgu6p' /* Place Name */,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xs),
                        DsTextField(
                          controller: _model.textController1,
                          focusNode: _model.textFieldFocusNode1,
                          hint: FFLocalizations.of(context).getText(
                            'a8ldor9h' /* Enter the name of the place */,
                          ),
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.place_outlined),
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        _FieldLabel(
                          emoji: FFLocalizations.of(context).getText(
                            '9rjvkvej' /* 📌 */,
                          ),
                          label: FFLocalizations.of(context).getText(
                            'do7491gj' /* Country, City, and Address */,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xs),
                        DsTextField(
                          controller: _model.textController2,
                          focusNode: _model.textFieldFocusNode2,
                          hint: FFLocalizations.of(context).getText(
                            'vd59u3ot' /* Enter the full address (City a... */,
                          ),
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.map_outlined),
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        _FieldLabel(
                          emoji: FFLocalizations.of(context).getText(
                            '2vuaqog8' /* 📝 */,
                          ),
                          label: FFLocalizations.of(context).getText(
                            '0qo18l4i' /* Description */,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xxs),
                        Text(
                          FFLocalizations.of(context).getText(
                            'nur7ag3e' /* Tell us what makes it special */,
                          ),
                          style: context.dsTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xs),
                        DsTextField(
                          controller: _model.textController3,
                          focusNode: _model.textFieldFocusNode3,
                          hint: FFLocalizations.of(context).getText(
                            'zqvk52y6' /* Describe what makes this place... */,
                          ),
                          maxLines: 4,
                          minLines: 4,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        _FieldLabel(
                          emoji: FFLocalizations.of(context).getText(
                            'sxj5nve6' /* 📷 */,
                          ),
                          label: FFLocalizations.of(context).getText(
                            '09tikovz' /* Upload  Photos */,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xs),
                        _PickerBox(
                          height: _kUploadBoxHeight,
                          icon: Icons.cloud_upload_rounded,
                          onTap: _pickPhotos,
                          title: FFLocalizations.of(context).getText(
                            'l1vt0zae' /* Tap to upload photos */,
                          ),
                          caption: FFLocalizations.of(context).getText(
                            'u1e985hj' /* Maximum 3 photos */,
                          ),
                          confirmation: _model.isDataUploading_uploadData1
                              ? FFLocalizations.of(context).getText(
                                  'rxcd59vu' /* Image uploaded successfully. ✅ */,
                                )
                              : null,
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        _FieldLabel(
                          emoji: FFLocalizations.of(context).getText(
                            'j2goojen' /* 🗺️ */,
                          ),
                          label: FFLocalizations.of(context).getText(
                            'qu91s3ft' /* Mark the Location on the Map */,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xs),
                        _PickerBox(
                          height: _kMapBoxHeight,
                          icon: DsIcons.location,
                          onTap: () => _openMapPicker(context),
                          title: FFLocalizations.of(context).getText(
                            'u5e5rmy1' /* Tap to select location on map */,
                          ),
                          confirmation: FFAppState().mapSuggestaNewPlace != null
                              ? FFLocalizations.of(context).getText(
                                  'b46apyil' /* Location has been set✅ */,
                                )
                              : null,
                        ),
                        const SizedBox(height: DsSpacing.xl),
                        DsButton.primary(
                          label: FFLocalizations.of(context).getText(
                            '2jr3h8am' /*  Submit */,
                          ),
                          icon: Icons.add_box_rounded,
                          expanded: true,
                          size: DsButtonSize.lg,
                          onPressed: () => _submit(context),
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

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: DsConstants.avatarLg,
            height: DsConstants.avatarLg,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add_location_alt_rounded,
              size: DsIcons.lg,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            FFLocalizations.of(context).getText(
              'jhd5sd4d' /* Suggest a New Place! */,
            ),
            textAlign: TextAlign.center,
            style: typography.headlineSmall.copyWith(color: colors.primary),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            FFLocalizations.of(context).getText(
              'qv127f88' /* Help Us Enrich the Experience */,
            ),
            textAlign: TextAlign.center,
            style: typography.titleSmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            FFLocalizations.of(context).getText(
              '5lh88yrd' /* Do you know a hidden gem or a ... */,
            ),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.sm,
              vertical: DsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: DsRadius.medium,
            ),
            child: Text(
              FFLocalizations.of(context).getText(
                'uxvsxqlp' /* Your suggestions help others d... */,
              ),
              textAlign: TextAlign.center,
              style: typography.bodySmall.copyWith(color: colors.primaryStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      children: [
        Text(emoji, style: typography.titleMedium),
        const SizedBox(width: DsSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: typography.titleSmall.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({
    required this.height,
    required this.icon,
    required this.title,
    required this.onTap,
    this.caption,
    this.confirmation,
  });

  final double height;
  final IconData icon;
  final String title;
  final String? caption;
  final String? confirmation;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: DsRadius.medium,
            border: Border.all(color: colors.primaryMuted, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: DsIcons.xl, color: colors.primary),
              const SizedBox(height: DsSpacing.xs),
              Text(
                title,
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (confirmation != null) ...[
                const SizedBox(height: DsSpacing.xs),
                Text(
                  confirmation!,
                  textAlign: TextAlign.center,
                  style: typography.labelMedium.copyWith(color: colors.success),
                ),
              ],
              if (caption != null) ...[
                const SizedBox(height: DsSpacing.xs),
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: typography.bodySmall.copyWith(color: colors.hint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
