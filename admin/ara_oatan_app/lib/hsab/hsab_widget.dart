import 'package:easy_localization/easy_localization.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'hsab_model.dart';
export 'hsab_model.dart';

class HsabWidget extends StatefulWidget {
  const HsabWidget({super.key});

  static String routeName = 'hsab';
  static String routePath = '/hsab';

  @override
  State<HsabWidget> createState() => _HsabWidgetState();
}

class _HsabWidgetState extends State<HsabWidget> {
  late HsabModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HsabModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Distance lookup — identical call chain to the previous implementation.
  Future<void> _calculateDistance() async {
    _model.msg = await actions.get(
      _model.placePickerValue1.latLng,
      _model.placePickerValue2.latLng,
    );
    if (!mounted) return;

    final colors = context.dsColors;
    final typography = context.dsTypography;

    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return WebViewAware(
          child: AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: DsRadius.extraLarge),
            title: Text(
              _model.msg!.toString(),
              style: typography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            content: Text(
              _model.msg.toString(),
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            actions: [
              DsButton.text(
                label: 'ui_text_b0a98216a3'.tr(),
                onPressed: () => Navigator.pop(alertDialogContext),
              ),
            ],
          ),
        );
      },
    );

    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final originLabel = FFLocalizations.of(context).getText(
      'ws9o10k6' /* Select Location */,
    );
    final destinationLabel = FFLocalizations.of(context).getText(
      '739h13nw' /* Select Location */,
    );

    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: FFLocalizations.of(context).getText(
          '3qzx47fr' /* Page Title */,
        ),
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () async {
            context.pop();
          },
        ),
        actions: [
          DsIconButton(
            icon: DsIcons.close,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: DsSpacing.xxs),
        ],
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: DsSpacing.pagePadding,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsFadeSlide(
                child: _LocationPickerCard(
                  icon: Icons.trip_origin_rounded,
                  placeholder: originLabel,
                  selectedAddress: _model.placePickerValue1.address,
                  picker: _buildPlacePicker(
                    context,
                    defaultText: originLabel,
                    onSelect: (place) async {
                      safeSetState(() => _model.placePickerValue1 = place);
                    },
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              DsFadeSlide(
                delay: DsDurations.fast,
                child: _LocationPickerCard(
                  icon: DsIcons.location,
                  placeholder: destinationLabel,
                  selectedAddress: _model.placePickerValue2.address,
                  picker: _buildPlacePicker(
                    context,
                    defaultText: destinationLabel,
                    onSelect: (place) async {
                      safeSetState(() => _model.placePickerValue2 = place);
                    },
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.xxl),
              DsFadeSlide(
                delay: DsDurations.normal,
                child: DsButton.primary(
                  expanded: true,
                  size: DsButtonSize.lg,
                  icon: Icons.route_rounded,
                  label: FFLocalizations.of(context).getText(
                    'mtik4r67' /* Button */,
                  ),
                  onPressed: _calculateDistance,
                ),
              ),
              const SizedBox(height: DsSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacePicker(
    BuildContext context, {
    required String defaultText,
    required Future<void> Function(FFPlace place) onSelect,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return FlutterFlowPlacePicker(
      iOSGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      androidGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      webGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      onSelect: onSelect,
      defaultText: defaultText,
      icon: Icon(
        DsIcons.location,
        color: colors.onPrimary,
        size: DsIcons.xs,
      ),
      buttonOptions: FFButtonOptions(
        width: double.infinity,
        height: DsConstants.buttonHeightMd,
        color: colors.primary,
        textStyle: typography.labelLarge.copyWith(color: colors.onPrimary),
        elevation: 0.0,
        borderSide: const BorderSide(
          color: Colors.transparent,
          width: 1.0,
        ),
        borderRadius: DsRadius.medium,
      ),
    );
  }
}

class _LocationPickerCard extends StatelessWidget {
  const _LocationPickerCard({
    required this.icon,
    required this.placeholder,
    required this.selectedAddress,
    required this.picker,
  });

  final IconData icon;
  final String placeholder;
  final String selectedAddress;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final hasAddress = selectedAddress.trim().isNotEmpty;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: DsConstants.avatarSm,
                height: DsConstants.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.small,
                ),
                child: Icon(icon, size: DsIcons.sm, color: colors.primary),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  hasAddress ? selectedAddress : placeholder,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleSmall.copyWith(
                    color: hasAddress ? colors.textPrimary : colors.hint,
                  ),
                ),
              ),
              if (hasAddress)
                Icon(
                  Icons.check_circle_rounded,
                  size: DsIcons.sm,
                  color: colors.success,
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          picker,
        ],
      ),
    );
  }
}
