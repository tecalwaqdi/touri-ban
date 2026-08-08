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
import '/core/toury_customer_order_actions.dart';
import '/core/toury_error_localizer.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Modern order/trip details body for the customer app (active route only).
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

  bool get _isAccepted =>
      order.halhOrderMndob == HalhOrder.Accepted ||
      _statusCode == TouryBookingStatusCodes.driverAssigned ||
      _statusCode == TouryBookingStatusCodes.driverArrived ||
      _statusCode == TouryBookingStatusCodes.tripInProgress;

  bool get _isCompleted => BookingStatusLocalizer.isTripCompleted(
        statusCode: order.statusCode,
        halhText: order.halhText,
        driverOrderStatus: order.halhOrderMndob?.name,
      );

  bool get _isTripStarted =>
      _statusCode == TouryBookingStatusCodes.tripInProgress ||
      order.halhText == 'تم البدء في الرحلة';

  bool get _canAddExtraHours =>
      _isOwner && order.halhOrderMndob == HalhOrder.Accepted && !_isCompleted;

  bool get _canRate => _isOwner && _isCompleted && order.revewSendClent != true;

  bool get _showDriverCard =>
      _isOwner && _isAccepted && order.mndobUser != null;

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorLocalizer.fromObject(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _money(num? value) {
    final v = value;
    if (v == null || v.isNaN || v.isInfinite) {
      return '—';
    }
    final formatted = formatNumber(
      v.toDouble(),
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
    );
    final cur = _currency.trim();
    if (cur.isEmpty) return formatted;
    return '$formatted $cur';
  }

  String _safeHours() {
    final h = order.totalTaim;
    if (h <= 0) return '';
    return 'order_hours_label'.tr(namedArgs: {'hours': h.toString()});
  }

  String _phoneDigits() {
    final raw = order.phoneNuMndob;
    if (raw <= 0) return '';
    var s = raw.toString();
    if (!s.startsWith('0') && s.length <= 10) s = '0$s';
    return s;
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('order_cancel_confirm_title'.tr()),
            content: Text('order_cancel_confirm_body'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('order_cancel_confirm_back'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('order_cancel_confirm_yes'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    await _runGuarded(() async {
      final err = await TouryCustomerOrderActions.cancelOrder(order);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (err == null) {
        messenger?.showSnackBar(
          SnackBar(content: Text('order_cancelled_success'.tr())),
        );
        return;
      }
      if (err == 'booking_cancelled_refund_pending') {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              TouryCustomerOrderActions.localizedError(err),
            ),
          ),
        );
        return;
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            TouryCustomerOrderActions.localizedError(err),
          ),
        ),
      );
    });
  }

  Future<void> _callDriver() async {
    final phone = _phoneDigits();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('order_no_phone'.tr())),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openExtraHours() async {
    final mndob = order.mndobUser;
    if (mndob == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: MediaQuery.viewInsetsOf(ctx),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.9,
          child: AddExtraHours2Widget(
            idorder: order.reference,
            srsaah: order.srSAAH,
            idMndob: mndob,
            numperOrder: order.iDorder,
          ),
        ),
      ),
    );
  }

  Future<void> _rateTrip() async {
    final mndob = order.mndobUser;
    if (mndob == null) return;
    await _runGuarded(() async {
      await context.pushNamed(
        Details24QuizPageWidget.routeName,
        queryParameters: {
          'usermndob': serializeParam(
            mndob,
            ParamType.DocumentReference,
          ),
          'idordeer': serializeParam(
            order.reference,
            ParamType.DocumentReference,
          ),
          'naimMndob': serializeParam(
            order.naimMndobText,
            ParamType.String,
          ),
        }.withoutNulls,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (order.isDriverEnRoute) _enRouteBanner(colors, typography),
            _sectionCard(
              title: 'order_status_section'.tr(),
              icon: Icons.flag_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel,
                    style: typography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'order_details_number'.tr(
                      namedArgs: {
                        'id': order.iDorder.toString().isEmpty
                            ? order.reference.id
                            : order.iDorder.toString(),
                      },
                    ),
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (order.dataOrder != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'order_time_label'.tr(
                        namedArgs: {
                          'time': dateTimeFormat(
                            'relative',
                            order.dataOrder,
                            locale:
                                Localizations.localeOf(context).languageCode,
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
            _sectionCard(
              title: 'order_trip_section'.tr(),
              icon: Icons.route_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_safeHours().isNotEmpty)
                    _kv('order_hours_label'.tr(namedArgs: {
                      'hours': order.totalTaim.toString(),
                    })),
                  if (order.addCartNumer > 0)
                    _kv('order_places_count'.tr(namedArgs: {
                      'count': order.addCartNumer.toString(),
                    })),
                  if (_isTripStarted && order.endTime != null)
                    _kv(
                      'order_end_time'.tr(
                        namedArgs: {
                          'time': dateTimeFormat(
                            'Hm',
                            order.endTime,
                            locale:
                                Localizations.localeOf(context).languageCode,
                          ),
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  _placeRow(
                    label: 'order_pickup_point'.tr(),
                    text: _pickupText(),
                    loc: order.customerPickup,
                  ),
                  ..._stopTiles(),
                  _placeRow(
                    label: 'order_destination'.tr(),
                    text: _destinationText(),
                    loc: order.tripDestination,
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
                          radius: 26,
                          backgroundImage: order.imgMndob.isNotEmpty
                              ? NetworkImage(order.imgMndob)
                              : null,
                          child: order.imgMndob.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order.naimMndobText.trim().isEmpty
                                ? '—'
                                : order.naimMndobText,
                            style: typography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _vehicleLine(),
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _sectionCard(
                title: 'order_actions_section'.tr(),
                icon: Icons.touch_app_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.driverLivePosition != null ||
                        order.isDriverEnRoute)
                      _actionChip(
                        icon: Icons.map_outlined,
                        label: 'order_track_driver'.tr(),
                        onTap: () => context.pushNamed(
                          MapTrdemoWidget.routeName,
                          queryParameters: {
                            'idd': serializeParam(
                              order.reference,
                              ParamType.DocumentReference,
                            ),
                          }.withoutNulls,
                        ),
                      ),
                    _actionChip(
                      icon: Icons.phone_outlined,
                      label: 'order_call_driver'.tr(),
                      onTap: _callDriver,
                    ),
                    if (order.mndobUser != null)
                      _actionChip(
                        icon: Icons.chat_bubble_outline,
                        label: 'order_chat_driver'.tr(),
                        onTap: () => context.pushNamed(
                          Chat2Widget.routeName,
                          queryParameters: {
                            'idorder': serializeParam(
                              order.reference,
                              ParamType.DocumentReference,
                            ),
                            'idmndob': serializeParam(
                              order.mndobUser,
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
                        ),
                      ),
                    if (_canAddExtraHours)
                      _actionChip(
                        icon: Icons.add_alarm_outlined,
                        label: 'order_add_extra_hours'.tr(),
                        onTap: _openExtraHours,
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
                    _priceRow(
                      'order_payment_method'.tr(),
                      _paymentMethodLabel(),
                    ),
                    _priceRow(
                      'order_payment_status'.tr(),
                      _paymentStatusLabel(),
                    ),
                    if (order.ksm > 0)
                      _priceRow(
                        'order_discount_label'.tr(),
                        _money(order.ksm),
                      ),
                    if (order.totalVat > 0)
                      _priceRow(
                        'order_tax_label'.tr(),
                        _money(order.totalVat),
                      ),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: DsButton.primary(
                  label: 'order_rate_trip'.tr(),
                  icon: Icons.star_outline,
                  onPressed: _rateTrip,
                  loading: _busy,
                  enabled: !_busy,
                  expanded: true,
                ),
              ),
            if (_isOwner && order.canCancelByCustomer)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DsButton.danger(
                  label: 'order_cancel'.tr(),
                  icon: Icons.cancel_outlined,
                  onPressed: _cancelOrder,
                  loading: _busy,
                  enabled: !_busy,
                  expanded: true,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DsButton.secondary(
                label: 'order_contact_support'.tr(),
                icon: Icons.support_agent_outlined,
                onPressed: () => context.pushNamed(SupportWidget.routeName),
                expanded: true,
              ),
            ),
          ],
        ),
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: colors.scrim.withValues(alpha: 0.25),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'order_action_in_progress'.tr(),
                      style: typography.bodyMedium.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _enRouteBanner(DsColors colors, DsTypography typography) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        elevated: true,
        child: Row(
          children: [
            Icon(Icons.directions_car_filled, color: colors.primary),
            const SizedBox(width: 10),
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
              IconButton(
                tooltip: 'order_track_driver'.tr(),
                onPressed: () => context.pushNamed(
                  MapTrdemoWidget.routeName,
                  queryParameters: {
                    'idd': serializeParam(
                      order.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                ),
                icon: const Icon(Icons.map_outlined),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
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
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kv(String text) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: typography.bodyMedium.copyWith(color: colors.textPrimary),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool emphasize = false}) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                color: colors.textPrimary,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: _busy ? null : onTap,
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
        ),
    ];
  }

  Widget _placeRow({
    required String label,
    required String text,
    LatLng? loc,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
