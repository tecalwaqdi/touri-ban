import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/order_record.dart';
import '/core/driver_i18n.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/toury_system_status_codes.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Primary trip lifecycle actions with busy lock and status-gated visibility.
class DriverTripActionsCard extends StatefulWidget {
  const DriverTripActionsCard({
    super.key,
    required this.order,
    this.onChanged,
  });

  final OrderRecord order;
  final VoidCallback? onChanged;

  @override
  State<DriverTripActionsCard> createState() => _DriverTripActionsCardState();
}

class _DriverTripActionsCardState extends State<DriverTripActionsCard> {
  bool _busy = false;

  OrderRecord get order => widget.order;

  String get _code => DriverTripActionGates.codeOf(
        order.snapshotData,
        order.halhText,
      );

  bool get _assigned =>
      DriverTripActionGates.isAssignedToCurrentDriver(order.mndobUser);

  bool get _canAccept {
    final c = _code.toLowerCase();
    return c == TourySystemStatusCodes.pendingDriver ||
        c == TourySystemStatusCodes.legacyAwaitingDriver ||
        c == 'pending' ||
        order.halhText == DriverTripHalh.waitingAccept ||
        order.halhText == DriverTripHalh.pendingHalhOrder;
  }

  bool get _canCancel =>
      _assigned && DriverTripActionGates.canCancel(_code, order.halhText);

  bool get _canArrive {
    if (!_assigned) return false;
    final c = _code.toLowerCase();
    return c == TourySystemStatusCodes.driverAssigned ||
        c == TourySystemStatusCodes.driverArriving ||
        order.halhText == DriverTripHalh.accepted;
  }

  bool get _canStart =>
      _assigned && DriverTripActionGates.canStart(_code, order.halhText);

  bool get _canComplete =>
      _assigned &&
      DriverTripService.canCompleteTrip(
        order: order,
        driverLocation: currentUserDocument?.loceshnMndobNow,
      );

  bool get _hasAny =>
      _canAccept || _canCancel || _canArrive || _canStart || _canComplete;

  Future<bool> _confirm({
    required String title,
    required String body,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(driverTr(context, title)),
            content: Text(driverTr(context, body)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(driverTr(context, 'No')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(driverTr(context, 'Confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      String safe =
          driverTr(context, 'Something went wrong. Please try again.');
      if (e is StateError) {
        final mapped = DriverTripService.messageForCode(e.message);
        if (mapped.trim().isNotEmpty) safe = driverTr(context, mapped);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safe)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    final ok = await _confirm(
      title: 'Confirm acceptance',
      body: 'Are you sure you want to accept this order?',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
        cached: true,
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () => const LatLng(0, 0),
      );
      final result = await DriverTripService.acceptOrder(
        order: order,
        driverLocation: loc,
        onStateChanged: () => widget.onChanged?.call(),
      );
      if (!mounted) return;
      if (!result.ok) {
        final code = (result.code ?? '').trim();
        final phrase = (result.message ?? '').trim();
        if (code == 'DRIVER_WALLET_INSUFFICIENT') {
          final goTopUp = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(driverTr(context, 'Wallet')),
                  content: Text(
                    phrase.isNotEmpty
                        ? phrase
                        : 'يجب أن يكون رصيد محفظتك 200 ريال على الأقل لقبول الطلبات النقدية.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(driverTr(context, 'Cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(driverTr(context, 'Top up wallet')),
                    ),
                  ],
                ),
              ) ??
              false;
          if (goTopUp && mounted) {
            context.pushNamed(DriverWalletWidget.routeName);
          }
          return;
        }
        final key = phrase.isNotEmpty &&
                !phrase.toUpperCase().contains('INTERNAL') &&
                phrase != 'INTERNAL'
            ? phrase.split(' (').first.trim()
            : DriverTripService.messageForCode(
                code.isEmpty ? 'BOOKING_ASSIGNMENT_FAILED' : code,
              );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(key)),
        );
      }
    });
  }

  Future<void> _arrive() async {
    await _run(() async {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
      );
      await DriverTripService.markDriverArrived(
        orderRef: order.reference,
        driverLocation: loc,
      );
    });
  }

  Future<void> _start() async {
    final ok = await _confirm(
      title: 'Confirm start',
      body: 'Are you sure you want to start this trip?',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
      );
      await DriverTripService.startTrip(
        order: order,
        driverLocation: loc,
      );
    });
  }

  Future<void> _complete() async {
    final ok = await _confirm(
      title: 'Confirm',
      body: 'Are you sure this trip is completed?',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
      );
      await DriverTripService.completeTrip(
        order: order,
        driverLocation: loc,
      );
      if (!mounted) return;
      context.goNamed(HomeWidget.routeName);
    });
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
      title: 'Confirm cancel',
      body: 'Are you sure you want to cancel this request?',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
      );
      final result = await DriverTripService.cancelTrip(
        order: order,
        driverLocation: loc,
      );
      if (!mounted) return;
      if (!result.ok) {
        final phrase = (result.message ?? '').trim();
        final code = (result.code ?? '').trim();
        final key = phrase.isNotEmpty
            ? phrase.split(' (').first.trim()
            : (code.isEmpty
                ? 'Something went wrong. Please try again.'
                : DriverTripService.messageForCode(code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(driverTr(context, key))),
        );
        return;
      }
      context.goNamed(HomeWidget.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.sm,
      ),
      child: DsCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driverTr(context, 'Actions'),
                    style: typography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_canAccept)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.primary(
                  label: driverTr(context, 'Accept'),
                  icon: Icons.check_circle_outline,
                  expanded: true,
                  loading: _busy,
                  enabled: !_busy,
                  onPressed: _accept,
                ),
              ),
            if (_canArrive)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.primary(
                  label: driverTr(context, 'Confirm arrival to customer'),
                  icon: Icons.place_outlined,
                  expanded: true,
                  loading: _busy,
                  enabled: !_busy,
                  onPressed: _arrive,
                ),
              ),
            if (_canStart)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.success(
                  label: driverTr(context, 'Start trip'),
                  icon: Icons.play_arrow_rounded,
                  expanded: true,
                  loading: _busy,
                  enabled: !_busy,
                  onPressed: _start,
                ),
              ),
            if (_canComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.success(
                  label: driverTr(context, 'Complete trip'),
                  icon: Icons.flag_outlined,
                  expanded: true,
                  loading: _busy,
                  enabled: !_busy,
                  onPressed: _complete,
                ),
              ),
            if (_canCancel)
              DsButton.danger(
                label: driverTr(context, 'Cancel Order'),
                icon: Icons.cancel_outlined,
                expanded: true,
                loading: _busy,
                enabled: !_busy,
                onPressed: _cancel,
              ),
          ],
        ),
      ),
    );
  }
}
