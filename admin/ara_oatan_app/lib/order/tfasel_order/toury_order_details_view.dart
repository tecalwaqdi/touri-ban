import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/add_extra_hours2_widget.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_currency.dart';
import '/core/toury_customer_cancel_policy.dart';
import '/core/toury_payment_flow.dart';
import '/core/toury_customer_order_actions.dart';
import '/core/toury_error_localizer.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Order/trip details body for the customer app.
class TouryOrderDetailsView extends StatefulWidget {
  const TouryOrderDetailsView({
    super.key,
    required this.order,
  });

  final OrderRecord order;

  @override
  State<TouryOrderDetailsView> createState() => _TouryOrderDetailsViewState();
}

class _TouryOrderDetailsViewState extends State<TouryOrderDetailsView> {
  bool _busy = false;
  String? _busyAction;

  OrderRecord get order => widget.order;

  String get _currency => TouryCurrency.displaySymbolForOrder(order);

  String get _statusLabel => BookingStatusLocalizer.label(
        context,
        statusCode: order.statusCode,
        halhText: order.halhText,
      );

  String get _statusCode => BookingStatusLocalizer.resolveCode(
        statusCode: order.statusCode,
        halhText: order.halhText,
      );

  bool get _isOwner => TouryCustomerCancelPolicy.isBookingOwner(
        userField: order.snapshotData['USER'] ?? order.user,
        authUid: currentUserUid,
        currentUserRef: currentUserReference,
      );

  bool get _isTerminal =>
      _alreadyCancelled ||
      _isCompleted ||
      _statusCode == TouryBookingStatusCodes.cancelled ||
      _statusCode == TouryBookingStatusCodes.cancelledByCustomer ||
      _statusCode == TouryBookingStatusCodes.cancelledByDriver ||
      _statusCode == TouryBookingStatusCodes.cancelledByAdmin;

  bool get _isAccepted =>
      !_isTerminal &&
      (order.halhOrderMndob == HalhOrder.Accepted ||
          _statusCode == TouryBookingStatusCodes.driverAssigned ||
          _statusCode == TouryBookingStatusCodes.driverArrived ||
          _statusCode == TouryBookingStatusCodes.tripInProgress);

  bool get _isCompleted => BookingStatusLocalizer.isTripCompleted(
        statusCode: order.statusCode,
        halhText: order.halhText,
        driverOrderStatus: order.halhOrderMndob?.name,
      );

  bool get _isTripStarted =>
      !_isTerminal &&
      (_statusCode == TouryBookingStatusCodes.tripInProgress ||
          order.halhText == 'تم البدء في الرحلة');

  bool get _canAddExtraHours =>
      _isOwner &&
      !_isTerminal &&
      order.halhOrderMndob == HalhOrder.Accepted &&
      !_isCompleted;

  bool get _canRate => _isOwner && _isCompleted && order.revewSendClent != true;

  bool get _showDriverCard =>
      _isOwner && !_isTerminal && _isAccepted && order.mndobUser != null;

  bool get _canTrack =>
      _showDriverCard &&
      (order.driverLivePosition != null || order.isDriverEnRoute);

  bool get _canChat => _showDriverCard && order.mndobUser != null;

  bool get _driverAccepted => TouryCustomerCancelPolicy.hasDriverAccepted(
        statusCode: order.rawStatusCode,
        halhText: order.halhText,
        halhOrderName: order.halhOrder?.name,
        driverOrderStatus: order.halhOrderMndob?.name,
        mndobUser: order.mndobUser ?? order.snapshotData['mndob_user'],
      );

  bool get _awaitingUnassigned =>
      TouryCustomerCancelPolicy.isAwaitingUnassignedDriver(
        statusCode: order.rawStatusCode,
        halhText: order.halhText,
        halhOrderName: order.halhOrder?.name,
        driverOrderStatus: order.halhOrderMndob?.name,
        mndobUser: order.mndobUser ?? order.snapshotData['mndob_user'],
      );

  bool get _alreadyCancelled => TouryCustomerCancelPolicy.isAlreadyCancelled(
        statusCode: order.rawStatusCode,
        halhText: order.halhText,
      );

  bool get _showCancelSection =>
      _isOwner && !_alreadyCancelled && (_awaitingUnassigned || _driverAccepted);

  bool get _canCancelNow => order.canCancelByCustomer;

  bool get _isAwaitingPayment => order.isAwaitingPayment;

  Future<void> _runGuarded(
    String actionKey,
    Future<void> Function() action,
  ) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _busyAction = actionKey;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      DsSnackBar.show(
        context,
        message: ErrorLocalizer.fromObject(e),
        tone: DsSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyAction = null;
        });
      }
    }
  }

  String _money(num? value) {
    final v = value;
    if (v == null || v.isNaN || v.isInfinite) return '—';
    final formatted = formatNumber(
      v.toDouble(),
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
    );
    final cur = _currency.trim();
    return cur.isEmpty ? formatted : '$formatted $cur';
  }

  String _phoneDigits() {
    final raw = order.phoneNuMndob;
    if (raw <= 0) return '';
    var s = raw.toString();
    if (!s.startsWith('0') && s.length <= 10) s = '0$s';
    return s;
  }

  Future<void> _retryPayment() async {
    if (!_isAwaitingPayment || _busy) return;
    await _runGuarded('retry_pay', () async {
      final result = await touryRetryUnpaidOrderPayment(order: order);
      if (!mounted) return;
      if (!result.success) {
        TouryDialogs.showSnackBar(
          context,
          result.errorMessage ?? 'checkout_payment_temporarily_unavailable'.tr(),
          type: TouryMessageType.error,
        );
        return;
      }
      if (result.isPaid) {
        TouryDialogs.showSnackBar(
          context,
          'status_paid'.tr(),
          type: TouryMessageType.success,
        );
        return;
      }
      await touryNavigateAfterCardPayment(
        context,
        result: result,
        paymentFlowType: TypeHgz.Rhlh,
      );
    });
  }

  Future<void> _cancelOrder() async {
    if (!_canCancelNow) {
      DsSnackBar.show(
        context,
        message: _driverAccepted
            ? 'order_cancel_after_driver_msg'.tr()
            : 'booking_cancel_not_allowed'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final colors = ctx.dsColors;
            final typography = ctx.dsTypography;
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
              title: Text(
                'order_cancel_confirm_title'.tr(),
                style: typography.titleLarge.copyWith(color: colors.textPrimary),
              ),
              content: Text(
                'order_cancel_confirm_body'.tr(),
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              actions: [
                DsButton.text(
                  label: 'order_cancel_confirm_back'.tr(),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                DsButton.danger(
                  label: 'order_cancel_confirm_yes'.tr(),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed || !mounted) return;

    await _runGuarded('cancel', () async {
      final err = await TouryCustomerOrderActions.cancelOrder(order);
      if (!mounted) return;
      if (err == null) {
        DsSnackBar.show(
          context,
          message: 'order_cancelled_success'.tr(),
          tone: DsSnackTone.success,
        );
        return;
      }
      DsSnackBar.show(
        context,
        message: TouryCustomerOrderActions.localizedError(err),
        tone: DsSnackTone.error,
      );
    });
  }

  Widget _cancelSection() {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final hint = _driverAccepted
        ? 'order_cancel_after_driver_msg'.tr()
        : 'order_cancel_ready_hint'.tr();

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hint,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            DsButton.danger(
              label: 'order_cancel'.tr(),
              icon: Icons.cancel_outlined,
              onPressed: _canCancelNow && !_busy ? _cancelOrder : null,
              loading: _busy && _busyAction == 'cancel',
              enabled: _canCancelNow && !_busy,
              expanded: true,
              size: DsButtonSize.lg,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    final phone = _phoneDigits();
    if (phone.isEmpty) {
      DsSnackBar.show(
        context,
        message: 'order_no_phone'.tr(),
        tone: DsSnackTone.error,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat() async {
    final mndob = order.mndobUser;
    if (mndob == null) {
      DsSnackBar.show(
        context,
        message: 'order_chat_no_driver'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }
    await _runGuarded('chat', () async {
      if (!mounted) return;
      await context.pushNamed(
        Chat2Widget.routeName,
        queryParameters: {
          'idorder': serializeParam(
            order.reference,
            ParamType.DocumentReference,
          ),
          'idmndob': serializeParam(
            mndob,
            ParamType.DocumentReference,
          ),
          'naimMndob': serializeParam(
            order.naimMndobText,
            ParamType.String,
          ),
          'phoneMndob': serializeParam(
            order.phoneNuMndob,
            ParamType.int,
          ),
          'imgMndob': serializeParam(
            order.imgMndob,
            ParamType.String,
          ),
        }.withoutNulls,
      );
    });
  }

  Future<void> _openTrack() async {
    await context.pushNamed(
      MapTrdemoWidget.routeName,
      queryParameters: {
        'idd': serializeParam(
          order.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _openExtraHours() async {
    final mndob = order.mndobUser;
    if (mndob == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.dsColors;
        return Padding(
          padding: MediaQuery.viewInsetsOf(ctx),
          child: Container(
            height: MediaQuery.sizeOf(ctx).height * 0.9,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DsRadius.xl),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AddExtraHours2Widget(
              idorder: order.reference,
              srsaah: order.srSAAH,
              idMndob: mndob,
              numperOrder: order.iDorder,
            ),
          ),
        );
      },
    );
  }

  Future<void> _rateTrip() async {
    final mndob = order.mndobUser;
    if (mndob == null) return;
    await _runGuarded('rate', () async {
      await context.pushNamed(
        Details24QuizPageWidget.routeName,
        queryParameters: {
          'usermndob': serializeParam(mndob, ParamType.DocumentReference),
          'idordeer': serializeParam(
            order.reference,
            ParamType.DocumentReference,
          ),
          'naimMndob': serializeParam(order.naimMndobText, ParamType.String),
        }.withoutNulls,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.xxxl,
      ),
      children: [
        if (order.isDriverEnRoute) _enRouteBanner(colors, typography),
        _statusHeader(colors, typography),
        _sectionCard(
          title: 'order_trip_section'.tr(),
          icon: Icons.route_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.totalTaim > 0)
                _infoLine(
                  Icons.schedule_outlined,
                  'order_hours_label'.tr(namedArgs: {
                    'hours': order.totalTaim.toString(),
                  }),
                ),
              if (order.addCartNumer > 0)
                _infoLine(
                  Icons.place_outlined,
                  'order_places_count'.tr(namedArgs: {
                    'count': order.addCartNumer.toString(),
                  }),
                ),
              if (_isTripStarted && order.endTime != null)
                _infoLine(
                  Icons.flag_outlined,
                  'order_end_time'.tr(
                    namedArgs: {
                      'time': dateTimeFormat(
                        'Hm',
                        order.endTime,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                    },
                  ),
                ),
              const SizedBox(height: DsSpacing.sm),
              _placeRow(
                label: 'order_pickup_point'.tr(),
                text: _pickupText(),
                loc: order.customerPickup,
                icon: Icons.trip_origin,
              ),
              ..._stopTiles(),
              _placeRow(
                label: 'order_destination'.tr(),
                text: _destinationText(),
                loc: order.tripDestination,
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
        ),
        if (_showDriverCard) ...[
          _sectionCard(
            title: 'order_driver_section'.tr(),
            icon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primarySoft,
                      backgroundImage: order.imgMndob.isNotEmpty
                          ? NetworkImage(order.imgMndob)
                          : null,
                      child: order.imgMndob.isEmpty
                          ? Icon(Icons.person, color: colors.primary)
                          : null,
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.naimMndobText.trim().isEmpty
                                ? '—'
                                : order.naimMndobText,
                            style: typography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xxs),
                          Text(
                            _vehicleLine(),
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'order_actions_section'.tr(),
            icon: Icons.touch_app_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    if (_canTrack)
                      Expanded(
                        child: _actionButton(
                          label: 'order_track_driver'.tr(),
                          icon: Icons.map_outlined,
                          onPressed: _busy ? null : _openTrack,
                          variant: DsButtonVariant.outlined,
                        ),
                      ),
                    if (_canTrack) const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: _actionButton(
                        label: 'order_call_driver'.tr(),
                        icon: Icons.phone_outlined,
                        onPressed: _busy ? null : _callDriver,
                        variant: DsButtonVariant.outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.sm),
                Row(
                  children: [
                    if (_canChat)
                      Expanded(
                        child: _actionButton(
                          label: 'order_chat_driver'.tr(),
                          icon: Icons.chat_bubble_outline,
                          onPressed: _busy ? null : _openChat,
                          variant: DsButtonVariant.primary,
                          loading: _busy && _busyAction == 'chat',
                        ),
                      ),
                    if (_canChat && _canAddExtraHours)
                      const SizedBox(width: DsSpacing.sm),
                    if (_canAddExtraHours)
                      Expanded(
                        child: _actionButton(
                          label: 'order_add_extra_hours'.tr(),
                          icon: Icons.add_alarm_outlined,
                          onPressed: _busy ? null : _openExtraHours,
                          variant: DsButtonVariant.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_isOwner)
          _sectionCard(
            title: 'order_price_section'.tr(),
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                _priceRow('order_payment_method'.tr(), _paymentMethodLabel()),
                _priceRow('order_payment_status'.tr(), _paymentStatusLabel()),
                if (order.ksm > 0)
                  _priceRow('order_discount_label'.tr(), _money(order.ksm)),
                if (order.totalVat > 0)
                  _priceRow('order_tax_label'.tr(), _money(order.totalVat)),
                const SizedBox(height: DsSpacing.xxs),
                Divider(color: colors.divider, height: 1),
                const SizedBox(height: DsSpacing.sm),
                _priceRow(
                  'order_total_label'.tr(),
                  _money(order.total),
                  emphasize: true,
                ),
              ],
            ),
          ),
        if (_canRate)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.sm),
            child: DsButton.primary(
              label: 'order_rate_trip'.tr(),
              icon: Icons.star_outline,
              onPressed: _rateTrip,
              loading: _busy && _busyAction == 'rate',
              enabled: !_busy,
              expanded: true,
              size: DsButtonSize.lg,
            ),
          ),
        if (_isOwner && _isAwaitingPayment)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.sm),
            child: Column(
              children: [
                DsButton.primary(
                  label: 'order_retry_payment'.tr(),
                  icon: Icons.payment_rounded,
                  onPressed: _busy ? null : _retryPayment,
                  loading: _busy && _busyAction == 'retry_pay',
                  enabled: !_busy,
                  expanded: true,
                  size: DsButtonSize.lg,
                ),
                const SizedBox(height: DsSpacing.sm),
                DsButton.danger(
                  label: 'order_cancel'.tr(),
                  icon: Icons.cancel_outlined,
                  onPressed: (_canCancelNow && !_busy) ? _cancelOrder : null,
                  enabled: _canCancelNow && !_busy,
                  expanded: true,
                  size: DsButtonSize.lg,
                ),
              ],
            ),
          ),
        if (_showCancelSection && !_isAwaitingPayment) _cancelSection(),
        Padding(
          padding: const EdgeInsets.only(bottom: DsSpacing.xs),
          child: DsButton.secondary(
            label: 'order_contact_support'.tr(),
            icon: Icons.support_agent_outlined,
            onPressed:
                _busy ? null : () => context.pushNamed(SupportWidget.routeName),
            enabled: !_busy,
            expanded: true,
            size: DsButtonSize.lg,
          ),
        ),
      ],
    );
  }

  Widget _statusHeader(DsColors colors, DsTypography typography) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: DsRadius.small,
              ),
              child: Text(
                _statusLabel,
                style: typography.labelLarge.copyWith(
                  color: colors.primaryStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(
              'order_details_number'.tr(
                namedArgs: {
                  'id': order.iDorder.toString().isEmpty
                      ? order.reference.id
                      : order.iDorder.toString(),
                },
              ),
              style: typography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (order.dataOrder != null) ...[
              const SizedBox(height: DsSpacing.xxs),
              Text(
                'order_time_label'.tr(
                  namedArgs: {
                    'time': dateTimeFormat(
                      'relative',
                      order.dataOrder,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                  },
                ),
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _enRouteBanner(DsColors colors, DsTypography typography) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: DsCard(
        elevated: true,
        color: colors.primarySoft,
        child: Row(
          children: [
            Icon(Icons.directions_car_filled, color: colors.primary),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.naimMndobText.trim().isEmpty
                        ? 'order_driver_en_route'.tr()
                        : 'order_driver_name'.tr(
                            namedArgs: {'name': order.naimMndobText},
                          ),
                    style: typography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order.etaLabel().isNotEmpty)
                    Text(
                      order.etaLabel(),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (order.driverLivePosition != null)
              DsIconButton(
                tooltip: 'order_track_driver'.tr(),
                onPressed: _openTrack,
                icon: Icons.map_outlined,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: DsRadius.small,
                  ),
                  child: Icon(icon, size: 18, color: colors.primary),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: typography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.iconMuted),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: typography.bodyMedium.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool emphasize = false}) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: typography.bodyMedium.copyWith(
                color: emphasize ? colors.primaryStrong : colors.textPrimary,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required DsButtonVariant variant,
    bool loading = false,
  }) {
    return DsButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: variant,
      loading: loading,
      enabled: onPressed != null && !loading,
      expanded: true,
      size: DsButtonSize.md,
    );
  }

  String _paymentMethodLabel() {
    switch (order.paymentMethod) {
      case PaymentMethod.Cash:
        return 'order_pay_method_cash'.tr();
      case PaymentMethod.OnlinePayment:
        return 'order_pay_method_online'.tr();
      case null:
        return '—';
    }
  }

  String _paymentStatusLabel() {
    final raw = (order.snapshotData['payment_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    switch (raw) {
      case 'paid':
      case 'captured':
        return 'order_pay_status_paid'.tr();
      case 'pending_cash':
      case 'cash_pending':
      case 'cash_due':
      case 'pending':
        return 'order_pay_status_pending_cash'.tr();
      case 'cash_collected':
        return 'order_pay_status_cash_collected'.tr();
      case 'failed':
        return 'order_pay_status_failed'.tr();
      case 'refunded':
        return 'order_pay_status_refunded'.tr();
      case 'processing':
      case 'authorized':
        return 'order_pay_status_processing'.tr();
      default:
        if (order.paymentMethod == PaymentMethod.Cash) {
          return 'order_pay_status_pending_cash'.tr();
        }
        if (order.halhOrder == Halh.Paid ||
            order.halh.toLowerCase().contains('paid') ||
            order.halh == 'مدفوع') {
          return 'order_pay_status_paid'.tr();
        }
        return 'order_pay_status_unpaid'.tr();
    }
  }

  String _pickupText() {
    if (order.loceshStreng.trim().isNotEmpty) return order.loceshStreng.trim();
    final p = order.customerPickup;
    if (p != null) {
      return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    }
    return 'order_unspecified_location'.tr();
  }

  String _destinationText() {
    if (order.listAmakn.isNotEmpty) {
      final last = order.listAmakn.last;
      final label = last.address.trim().isNotEmpty
          ? last.address.trim()
          : last.naim.trim();
      if (label.isNotEmpty) return label;
    }
    final d = order.tripDestination;
    if (d != null) {
      return '${d.latitude.toStringAsFixed(5)}, ${d.longitude.toStringAsFixed(5)}';
    }
    return 'order_unspecified_location'.tr();
  }

  List<Widget> _stopTiles() {
    if (order.listAmakn.length <= 1) return const [];
    final stops = order.listAmakn.take(order.listAmakn.length - 1).toList();
    return [
      for (var i = 0; i < stops.length; i++)
        _placeRow(
          label: '${'order_places_section'.tr()} ${i + 1}',
          text: () {
            final s = stops[i];
            final label =
                s.address.trim().isNotEmpty ? s.address.trim() : s.naim.trim();
            return label.isEmpty ? 'order_unspecified_location'.tr() : label;
          }(),
          loc: stops[i].loceshn,
          icon: Icons.pin_drop_outlined,
        ),
    ];
  }

  Widget _placeRow({
    required String label,
    required String text,
    LatLng? loc,
    IconData icon = Icons.place_outlined,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typography.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  text,
                  style: typography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (loc != null)
            IconButton(
              tooltip: 'order_open_route'.tr(),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await TouryNavigationService.openGoogleMapsNavigation(
                  destination: loc,
                );
              },
              icon: Icon(Icons.directions, color: colors.primary),
            ),
        ],
      ),
    );
  }

  String _vehicleLine() {
    final parts = <String>[
      if (order.carmndob.trim().isNotEmpty) order.carmndob.trim(),
      if (order.nameCar.trim().isNotEmpty) order.nameCar.trim(),
      if (order.modelCar.trim().isNotEmpty) order.modelCar.trim(),
    ];
    if (parts.isEmpty) return 'order_vehicle_unknown'.tr();
    return parts.join(' · ');
  }
}
