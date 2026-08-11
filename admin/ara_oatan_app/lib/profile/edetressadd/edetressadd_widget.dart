import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/listvill_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'edetressadd_model.dart';

export 'edetressadd_model.dart';

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
class EdetressaddWidget extends StatefulWidget {
  const EdetressaddWidget({
    super.key,
    required this.ed,
  });

  final AdressuserRecord? ed;

  static String routeName = 'edetressadd';
  static String routePath = '/edetressadd';

  @override
  State<EdetressaddWidget> createState() => _EdetressaddWidgetState();
}

class _EdetressaddWidgetState extends State<EdetressaddWidget> {
  late EdetressaddModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetressaddModel());

    _model.tiletTextController ??=
        TextEditingController(text: widget.ed?.tilet);
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

  Future<void> _saveAddress() async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }

    await widget.ed!.reference.update(createAdressuserRecordData(
      user: currentUserReference,
      tilet: _model.tiletTextController.text,
      naimVill: FFAppState().adressVillTEXT,
      map: _model.googleMapsCenter,
      vill: FFAppState().adressVillRev,
    ));

    if (!mounted) return;
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
              resizeToAvoidBottomInset: false,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: FFLocalizations.of(context).getText(
                  'idqqf2jh' /* update Your Address */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                            child: _buildDetailsCard(context),
                          ),
                          const SizedBox(height: DsSpacing.md),
                          DsFadeSlide(
                            delay: DsDurations.instant,
                            child: _buildMapCard(context),
                          ),
                          const SizedBox(height: DsSpacing.xl),
                          DsFadeSlide(
                            delay: DsDurations.fast,
                            child: DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                '5yvx7ss0' /* update Address */,
                              ),
                              icon: Icons.add_home_outlined,
                              size: DsButtonSize.lg,
                              expanded: true,
                              onPressed: _saveAddress,
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
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
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
              'gamz5zzj' /* Address Details */,
            ),
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            FFLocalizations.of(context).getText(
              '4otamswj' /* Note: This is the address wher... */,
            ),
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.md),
          Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.always,
            child: TextFormField(
              controller: _model.tiletTextController,
              focusNode: _model.tiletFocusNode,
              autofocus: false,
              obscureText: false,
              style: typography.bodyLarge.copyWith(color: colors.textPrimary),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                labelText: FFLocalizations.of(context).getText(
                  'p1fbvdyl' /* Address Name (e.g. Home, Work) */,
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

  Widget _buildMapCard(BuildContext context) {
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
              'v7k8e1dv' /* Select Location */,
            ),
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            FFLocalizations.of(context).getText(
              'a4omcttu' /* Please zoom in on the map to t... */,
            ),
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
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
                      initialLocation:
                          _model.googleMapsCenter ??= widget.ed!.map!,
                      markerColor: GoogleMarkerColor.violet,
                      mapType: MapType.normal,
                      style: GoogleMapStyle.standard,
                      initialZoom: 14.0,
                      allowInteraction: true,
                      allowZoom: true,
                      showZoomControls: true,
                      showLocation: true,
                      showCompass: true,
                      showMapToolbar: true,
                      showTraffic: false,
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
                        size: DsIcons.xl,
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
