import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/backend/backend.dart';
import '/components/listvill_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'edet_adress2_model.dart';

export 'edet_adress2_model.dart';

/// Create a Flutter page where a client can add their home address.
///
/// The page should include the following elements:
///
/// Title: Display "Add Your Address" at the top.
/// Input Fields:
/// A text field for the address name (e.g., "Home," "Apartment," etc.).
/// A read-only text field showing the name of the city.
/// Map Integration:
/// A widget to display a map where the user can manually select their
/// location.
/// Include a draggable marker to indicate the selected location.
/// Save Button:
/// A button labeled "Save Address" to save the entered details.
/// Layout:
///
/// Arrange the elements vertically using a column.
/// Add appropriate padding and spacing between widgets for a clean and
/// user-friendly design.
class EdetAdress2Widget extends StatefulWidget {
  const EdetAdress2Widget({
    super.key,
    required this.idad,
  });

  final DocumentReference? idad;

  static String routeName = 'EdetAdress2';
  static String routePath = '/edetAdress2';

  @override
  State<EdetAdress2Widget> createState() => _EdetAdress2WidgetState();
}

class _EdetAdress2WidgetState extends State<EdetAdress2Widget> {
  late EdetAdress2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetAdress2Model());

    _model.tiletFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickCity() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: context.dsColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: DsRadius.xlRadius),
      ),
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
                height: MediaQuery.sizeOf(context).height * 0.77,
                child: const ListvillWidget(),
              ),
            ),
          ),
        );
      },
    ).then((value) => safeSetState(() {}));
  }

  Future<void> _update(AdressuserRecord record) async {
    if ((_model.tiletTextController.text != '') &&
        (FFAppState().adressVillRev != null)) {
      await record.reference.update(createAdressuserRecordData(
        tilet: _model.tiletTextController.text,
        vill: FFAppState().adressVillRev,
        naimVill: FFAppState().adressVillTEXT,
      ));
      if (!mounted) return;
      context.safePop();
    } else {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          final colors = DsColors.of(alertDialogContext);
          final typography = DsTypography.of(alertDialogContext);
          return WebViewAware(
            child: AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
              title: Text(
                'ui_text_b6f51cadc4'.tr(),
                style: typography.titleLarge.copyWith(color: colors.textPrimary),
              ),
              content: Text(
                'ui_text_1d36255e4a'.tr(),
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                DsSpacing.md,
                0,
                DsSpacing.md,
                DsSpacing.md,
              ),
              actions: [
                DsButton.primary(
                  label: 'ui_text_b0a98216a3'.tr(),
                  onPressed: () => Navigator.pop(alertDialogContext),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return StreamBuilder<AdressuserRecord>(
            stream: AdressuserRecord.getDocument(widget.idad!),
            builder: (context, snapshot) {
              // Customize what your widget looks like when it's loading.
              if (!snapshot.hasData) {
                return Scaffold(
                  backgroundColor: colors.scaffold,
                  body: const DsLoading(),
                );
              }

              final edetAdress2AdressuserRecord = snapshot.data!;

              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Scaffold(
                  key: scaffoldKey,
                  resizeToAvoidBottomInset: false,
                  backgroundColor: colors.scaffold,
                  appBar: DsAppBar(
                    automaticallyImplyLeading: false,
                    title: FFLocalizations.of(context).getText(
                      'wsqmrigb' /* Edit the address. */,
                    ),
                    leading: DsIconButton(
                      icon: DsIcons.back,
                      onPressed: () async {
                        context.safePop();
                      },
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
                        DsSpacing.xxxl,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: DsConstants.maxContentWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DsFadeSlide(
                                child: _buildDetailsCard(
                                  context,
                                  edetAdress2AdressuserRecord,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              DsFadeSlide(
                                delay: DsDurations.instant,
                                child: _buildMapCard(
                                  context,
                                  edetAdress2AdressuserRecord,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xl),
                              DsFadeSlide(
                                delay: DsDurations.fast,
                                child: DsButton.primary(
                                  label: FFLocalizations.of(context).getText(
                                    'tblq28h6' /* Update */,
                                  ),
                                  icon: Icons.undo_rounded,
                                  size: DsButtonSize.lg,
                                  expanded: true,
                                  onPressed: () =>
                                      _update(edetAdress2AdressuserRecord),
                                ),
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
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, AdressuserRecord record) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              'wh8uh7m1' /* Address Details */,
            ),
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            FFLocalizations.of(context).getText(
              'eucjzx07' /* Note: This is the address wher... */,
            ),
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.md),
          Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.always,
            child: TextFormField(
              controller: _model.tiletTextController ??= TextEditingController(
                text: record.tilet,
              ),
              focusNode: _model.tiletFocusNode,
              autofocus: false,
              obscureText: false,
              style: typography.bodyLarge.copyWith(color: colors.textPrimary),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                labelText: FFLocalizations.of(context).getText(
                  't3b8ud3p' /* Address Name (e.g. Home, Work) */,
                ),
                prefixIcon: Icon(
                  Icons.bookmark_border_rounded,
                  size: DsIcons.sm,
                  color: colors.iconMuted,
                ),
              ),
              validator:
                  _model.tiletTextControllerValidator.asValidator(context),
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          _CityPickerTile(onTap: _pickCity),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, AdressuserRecord record) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              'b0voiq5o' /* Select Location */,
            ),
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.sm),
          ClipRRect(
            borderRadius: DsRadius.medium,
            child: SizedBox(
              height: TouryLayout.mapPanelHeight(context),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterFlowGoogleMap(
                      controller: _model.googleMapsController,
                      onCameraIdle: (latLng) => safeSetState(
                          () => _model.googleMapsCenter = latLng),
                      initialLocation: _model.googleMapsCenter ??= record.map!,
                      markerColor: GoogleMarkerColor.violet,
                      mapType: MapType.normal,
                      style: GoogleMapStyle.standard,
                      initialZoom: 25.0,
                      allowInteraction: true,
                      allowZoom: true,
                      showZoomControls: true,
                      showLocation: true,
                      showCompass: true,
                      showMapToolbar: true,
                      showTraffic: true,
                      centerMapOnMarkerTap: true,
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: Icon(
                        Icons.location_pin,
                        color: colors.error,
                        size: DsIcons.lg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable row that opens the city selector sheet.
class _CityPickerTile extends StatelessWidget {
  const _CityPickerTile({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final selected = FFAppState().adressVillTEXT;
    final hasCity = selected.isNotEmpty;

    return DsCard(
      onTap: () => onTap(),
      color: hasCity ? colors.selected : colors.errorContainer,
      bordered: false,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_city_rounded,
            size: DsIcons.sm,
            color: hasCity ? colors.primary : colors.error,
          ),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(
              valueOrDefault<String>(selected, 'حدد المدينة'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.titleSmall.copyWith(
                color: hasCity ? colors.textPrimary : colors.error,
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down_rounded,
            size: DsIcons.md,
            color: hasCity ? colors.iconMuted : colors.error,
          ),
        ],
      ),
    );
  }
}
