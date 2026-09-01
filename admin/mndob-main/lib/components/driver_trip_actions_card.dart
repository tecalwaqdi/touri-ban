import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/order_record.dart';
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
  Timer? _completeGateTick;

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

  bool get _tripInProgress {
    if (!_assigned) return false;
    final c = _code.toLowerCase();
    return c == TourySystemStatusCodes.tripInProgress ||
        c == TourySystemStatusCodes.tripStarted ||
        order.halhText == DriverTripHalh.inProgress;
  }

  bool get _canComplete =>
      _assigned &&
      DriverTripService.canCompleteTrip(
        order: order,
        driverLocation: currentUserDocument?.loceshnMndobNow,
      );

  /// Booked hours not finished yet.
  bool get _waitingForTripTime {
    if (!_tripInProgress) return false;
    final left = DriverTripService.remainingBeforeComplete(order);
    return left != null && left > Duration.zero;
  }

  /// Time done, but still not near dropoff / no GPS.
  bool get _waitingForDropoff =>
      _tripInProgress && !_waitingForTripTime && !_canComplete;

  bool get _hasAny =>
      _canAccept ||
      _canCancel ||
      _canArrive ||
      _canStart ||
      _canComplete ||
      _waitingForTripTime ||
      _waitingForDropoff;

  @override
  void initState() {
    super.initState();
    _completeGateTick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_tripInProgress) setState(() {});
    });
  }

  @override
  void dispose() {
    _completeGateTick?.cancel();
    super.dispose();
  }

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
      final loc = await _driverLocationFast();
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
                        ? driverTrMessage(context, phrase)
                        : driverTr(
                            context,
                            'Your wallet balance must be at least {amount} to accept cash orders.',
                          ).replaceAll('{amount}', '200'),
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

  Future<LatLng?> _driverLocationFast() async {
    try {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
        cached: true,
      ).timeout(const Duration(seconds: 6));
      return DriverTripService.usableDriverLocation(loc);
    } catch (_) {
      return DriverTripService.usableDriverLocation(
        currentUserDocument?.loceshnMndobNow,
      );
    }
  }

  Future<void> _arrive() async {
    await _run(() async {
      final loc = await _driverLocationFast();
      if (loc == null) {
        throw StateError('LOCATION_REQUIRED');
      }
      await DriverTripService.markDriverArrived(
        orderRef: order.reference,
        driverLocation: loc,
        customerRef: order.user,
        order: order,
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
      final loc = await _driverLocationFast();
      await DriverTripService.startTrip(
        order: order,
        driverLocation: loc,
      ).timeout(const Duration(seconds: 12));
    });
  }

  Future<void> _complete() async {
    final ok = await _confirm(
      title: 'Confirm',
      body: 'Are you sure this trip is completed?',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final loc = await _driverLocationFast();
      final block = DriverTripService.completeBlockReason(
        order: order,
        driverLocation: loc,
      );
      if (block != null) {
        throw StateError(block);
      }
      await DriverTripService.completeTrip(
        order: order,
        driverLocation: loc,
      ).timeout(const Duration(seconds: 20));
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
      final loc = await _driverLocationFast();
      final result = await DriverTripService.cancelTrip(
        order: order,
        driverLocation: loc,
      ).timeout(const Duration(seconds: 20));
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
          SnackBar(content: Text(driverTrMessage(context, key))),
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
            if (_waitingForTripTime) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.success(
                  label: driverTr(context, 'Complete trip'),
                  icon: Icons.flag_outlined,
                  expanded: true,
                  enabled: false,
                  onPressed: null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  () {
                    final left =
                        DriverTripService.remainingBeforeComplete(order);
                    final pretty = left == null
                        ? '—'
                        : DriverTripService.formatRemainingTripTime(left);
                    return driverTrNamed(
                      context,
                      'Trip ends in {time}. Completing early is not allowed.',
                      {'time': pretty},
                    );
                  }(),
                  textAlign: TextAlign.center,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
            if (_waitingForDropoff) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsButton.success(
                  label: driverTr(context, 'Complete trip'),
                  icon: Icons.flag_outlined,
                  expanded: true,
                  enabled: false,
                  onPressed: null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  DriverTripService.messageForCode(
                    DriverTripService.completeBlockReason(order: order) ??
                        'TOO_FAR_FROM_DROPOFF',
                  ),
                  textAlign: TextAlign.center,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
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
