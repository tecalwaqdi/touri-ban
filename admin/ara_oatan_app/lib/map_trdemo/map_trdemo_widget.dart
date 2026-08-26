import '/backend/backend.dart';
import '/core/toury_trip_progress.dart';
import '/core/toury_trip_tracking_map.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/toury_order_meta.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  /// Bumped to force a fresh Firestore subscription after a stream error.
  int _streamEpoch = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapTrdemoModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _reconnect() => safeSetState(() => _streamEpoch++);

  Future<void> _callDriver(OrderRecord order) async {
    final raw = order.phoneNuMndob;
    if (raw <= 0) {
      DsSnackBar.show(
        context,
        message: 'order_no_phone'.tr(),
        tone: DsSnackTone.error,
      );
      return;
    }
    var digits = raw.toString();
    if (!digits.startsWith('0') && digits.length <= 10) digits = '0$digits';
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat(OrderRecord order) async {
    final mndob = order.mndobUser;
    if (mndob == null) {
      DsSnackBar.show(
        context,
        message: 'order_chat_no_driver'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }
    await context.pushNamed(
      Chat2Widget.routeName,
      queryParameters: {
        'idorder': serializeParam(order.reference, ParamType.DocumentReference),
        'idmndob': serializeParam(mndob, ParamType.DocumentReference),
        'naimMndob': serializeParam(order.naimMndobText, ParamType.String),
        'phoneMndob': serializeParam(order.phoneNuMndob, ParamType.int),
        'imgMndob': serializeParam(order.imgMndob, ParamType.String),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderRef = widget.idd;

    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: 'map_track_driver_title'.tr(),
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () async => context.pop(),
        ),
      ),
      body: SafeArea(
        top: true,
        child: orderRef == null
            ? DsErrorState(
                title: 'track_error_title'.tr(),
                message: 'track_error_body'.tr(),
                retryLabel: 'ux_retry'.tr(),
                onRetry: () => context.pop(),
              )
            : StreamBuilder<OrderRecord>(
                key: ValueKey('track_$_streamEpoch'),
                stream: OrderRecord.getDocument(orderRef),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return DsErrorState(
                      title: 'track_error_title'.tr(),
                      message: 'track_error_body'.tr(),
                      retryLabel: 'ux_retry'.tr(),
                      onRetry: _reconnect,
                    );
                  }
                  if (!snapshot.hasData) {
                    return const _TrackingSkeleton();
                  }

                  final order = snapshot.data!;
                  final stage = touryResolveTripStage(
                    statusCode: order.rawStatusCode.isNotEmpty
                        ? order.rawStatusCode
                        : order.statusCode,
                    halhText: order.halhText,
                    driverOrderStatus: order.halhOrderMndob?.name,
                  );
                  final hasDriverLocation = order.driverLivePosition != null;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final mapHeight = (constraints.maxHeight * 0.58)
                          .clamp(220.0, constraints.maxHeight);
                      return Column(
                        children: [
                          SizedBox(
                            height: mapHeight,
                            child: TouryTripTrackingMap(
                              order: order,
                              height: mapHeight,
                            ),
                          ),
                          Expanded(
                            child: _TrackingPanel(
                              order: order,
                              stage: stage,
                              hasDriverLocation: hasDriverLocation,
                              onCall: () => _callDriver(order),
                              onChat: () => _openChat(order),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({
    required this.order,
    required this.stage,
    required this.hasDriverLocation,
    required this.onCall,
    required this.onChat,
  });

  final OrderRecord order;
  final TouryTripStage stage;
  final bool hasDriverLocation;
  final VoidCallback onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final hasDriver = order.naimMndobText.trim().isNotEmpty;
    final etaMinutes = order.etaMinutes;
    final distanceKm = order.distanceRemainingMeters / 1000.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.md,
          DsSpacing.md,
          DsSpacing.md,
          DsSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: DsRadius.pill,
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    touryTripStageTitleKey(stage).tr(),
                    style: typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (etaMinutes > 0)
                  Container(
                    padding: DsSpacing.chipPadding,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: DsRadius.pill,
                    ),
                    child: Text(
                      'map_eta_minutes'.tr(
                        namedArgs: {'minutes': etaMinutes.toString()},
                      ),
                      style: typography.labelMedium.copyWith(
                        color: colors.primaryStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (!hasDriverLocation && touryTripStageIsLive(stage)) ...[
              const SizedBox(height: DsSpacing.xs),
              Text(
                'map_waiting_driver_location'.tr(),
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: DsSpacing.md),
            _StageTimeline(stage: stage),
            if (distanceKm > 0) ...[
              const SizedBox(height: DsSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: DsIcons.xs,
                    color: colors.iconMuted,
                  ),
                  const SizedBox(width: DsSpacing.xs),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} ${'map_km'.tr()}',
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (hasDriver) ...[
              const SizedBox(height: DsSpacing.md),
              _DriverCard(
                order: order,
                onCall: onCall,
                onChat: onChat,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.stage});

  final TouryTripStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final currentIndex = touryTripStageIndex(stage);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < touryTripTimeline.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= currentIndex
                                ? colors.primary
                                : colors.border),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: i == currentIndex ? 16 : 12,
                      height: i == currentIndex ? 16 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            i <= currentIndex ? colors.primary : colors.border,
                        border: i == currentIndex
                            ? Border.all(
                                color: colors.primary.withValues(alpha: 0.25),
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == touryTripTimeline.length - 1
                            ? Colors.transparent
                            : (i < currentIndex
                                ? colors.primary
                                : colors.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.xs),
                Text(
                  touryTripStageTitleKey(touryTripTimeline[i]).tr(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelSmall.copyWith(
                    color: i <= currentIndex
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontWeight:
                        i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.order,
    required this.onCall,
    required this.onChat,
  });

  final OrderRecord order;
  final VoidCallback onCall;
  final VoidCallback onChat;

  String _vehicleLine() {
    final parts = <String>[
      if (order.carmndob.trim().isNotEmpty) order.carmndob.trim(),
      if (order.nameCar.trim().isNotEmpty) order.nameCar.trim(),
      if (order.modelCar.trim().isNotEmpty) order.modelCar.trim(),
    ];
    if (parts.isEmpty) return 'order_vehicle_unknown'.tr();
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      bordered: true,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colors.primarySoft,
                backgroundImage: order.imgMndob.isNotEmpty
                    ? NetworkImage(order.imgMndob)
                    : null,
                child: order.imgMndob.isEmpty
                    ? Icon(Icons.person_rounded, color: colors.primary)
                    : null,
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.naimMndobText.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Text(
                      _vehicleLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DsButton.outlined(
                  label: 'order_call_driver'.tr(),
                  icon: Icons.phone_rounded,
                  size: DsButtonSize.sm,
                  onPressed: onCall,
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: DsButton.primary(
                  label: 'order_chat_driver'.tr(),
                  icon: Icons.chat_bubble_outline_rounded,
                  size: DsButtonSize.sm,
                  onPressed: onChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingSkeleton extends StatelessWidget {
  const _TrackingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return Column(
      children: [
        Expanded(
          child: Container(
            color: colors.primarySoft.withValues(alpha: 0.4),
            alignment: Alignment.center,
            child: DsLoading(message: 'map_loading'.tr()),
          ),
        ),
        Padding(
          padding: DsSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              DsShimmer(height: 20, width: 180),
              SizedBox(height: DsSpacing.sm),
              DsShimmer(height: 12),
              SizedBox(height: DsSpacing.md),
              DsShimmer(height: 64),
            ],
          ),
        ),
      ],
    );
  }
}
