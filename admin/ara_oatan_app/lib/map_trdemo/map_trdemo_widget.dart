import '/backend/backend.dart';
import '/core/toury_trip_tracking_map.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/toury_order_meta.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'map_trdemo_model.dart';
export 'map_trdemo_model.dart';

class MapTrdemoWidget extends StatefulWidget {
  const MapTrdemoWidget({
    super.key,
    required this.idd,
  });

  final DocumentReference? idd;

  static String routeName = 'mapTrdemo';
  static String routePath = '/mapTrdemo';

  @override
  State<MapTrdemoWidget> createState() => _MapTrdemoWidgetState();
}

class _MapTrdemoWidgetState extends State<MapTrdemoWidget> {
  late MapTrdemoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapTrdemoModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: 'map_track_driver_title'.tr(),
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
            onPressed: () async {
              context.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: StreamBuilder<OrderRecord>(
          stream: OrderRecord.getDocument(widget.idd!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return DsLoading(
                size: DsConstants.avatarMd,
                message: 'map_waiting_driver_location'.tr(),
              );
            }

            final order = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: TouryTripTrackingMap(
                    order: order,
                    height: MediaQuery.sizeOf(context).height * 0.72,
                  ),
                ),
                Padding(
                  padding: DsSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (order.etaMinutes > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: DsSpacing.xs),
                          child: _EtaBanner(minutes: order.etaMinutes),
                        ),
                      _DriverStatusText(
                        driverName: order.naimMndobText,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EtaBanner extends StatelessWidget {
  const _EtaBanner({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: DsRadius.medium,
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: DsIcons.sm,
            color: colors.primary,
          ),
          const SizedBox(width: DsSpacing.xs),
          Flexible(
            child: Text(
              'map_eta_minutes'.tr(
                namedArgs: {'minutes': minutes.toString()},
              ),
              textAlign: TextAlign.center,
              style: typography.titleSmall.copyWith(
                color: colors.primaryStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStatusText extends StatelessWidget {
  const _DriverStatusText({required this.driverName});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final hasDriver = driverName.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasDriver ? DsIcons.car : Icons.location_searching_rounded,
          size: DsIcons.sm,
          color: hasDriver ? colors.success : colors.iconMuted,
        ),
        const SizedBox(width: DsSpacing.xs),
        Flexible(
          child: Text(
            hasDriver
                ? '${'map_driver'.tr()}: $driverName'
                : 'map_waiting_driver_location'.tr(),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(
              color: hasDriver ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
