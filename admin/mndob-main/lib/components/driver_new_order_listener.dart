import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/driver_ride_request_sheet.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_eligibility_service.dart';
import '/core/driver_i18n.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_trip_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// يستمع لطلبات جديدة ويعرض إشعاراً فورياً للمندوب (فقط وهو Online وجاهز).
class DriverNewOrderListener extends StatefulWidget {
  const DriverNewOrderListener({super.key, required this.child});

  final Widget child;

  @override
  State<DriverNewOrderListener> createState() => _DriverNewOrderListenerState();
}

class _DriverNewOrderListenerState extends State<DriverNewOrderListener> {
  final Set<String> _seenOrderIds = {};
  final Set<String> _dismissedOrderIds = {};
  StreamSubscription<List<OrderRecord>>? _sub;
  AudioPlayer? _player;
  bool _sheetOpen = false;
  bool _streamPrimed = false;
  bool _attachInFlight = false;
  bool? _lastReady;

  @override
  void dispose() {
    _sub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _syncListener() {
    final ready = DriverOnlineState.canReceiveOrders &&
        DriverEligibilityService.evaluateReadyForOrders().isEligible &&
        !valueOrDefault(currentUserDocument?.mndonNewacc, false);

    if (_lastReady == ready && (_sub != null || !ready)) {
      if (!ready) {
        _sub?.cancel();
        _sub = null;
        _streamPrimed = false;
      }
      return;
    }
    _lastReady = ready;

    if (!ready) {
      _sub?.cancel();
      _sub = null;
      _streamPrimed = false;
      return;
    }

    if (_sub != null || _attachInFlight) return;
    _attach();
  }

  void _attach() {
    if (!loggedIn || currentUserReference == null) return;
    final car = currentUserDocument?.mndobTypeCar;
    if (car == null) return;

    _attachInFlight = true;
    _sub?.cancel();
    () async {
      try {
        await DriverOrderMatch.ensureDriverCountry();
        if (!mounted) return;
        if (!DriverOnlineState.canReceiveOrders) return;

        _sub = queryOrderRecord(
          queryBuilder: DriverOrderMatch.queryBuilder(typeCarRef: car),
        ).listen((orders) async {
          if (!DriverOnlineState.canReceiveOrders) return;
          if (valueOrDefault(currentUserDocument?.mndonNewacc, false)) return;

          LatLng? driverPos;
          try {
            driverPos = await getCurrentUserLocation(
              defaultLocation: const LatLng(0, 0),
            );
            if (driverPos.latitude == 0 && driverPos.longitude == 0) {
              driverPos = null;
            }
          } catch (_) {
            driverPos = null;
          }
          final cityRef = await DriverOrderMatch.ensureDriverCity();
          final ranked = DriverOrderMatch.rankForDriver(
            orders,
            driverCityOrVillage: currentUserDocument?.mndobVill,
            driverCityRef: cityRef,
            driverPosition: driverPos,
          );
          if (!_streamPrimed) {
            for (final order in ranked) {
              _seenOrderIds.add(order.reference.id);
            }
            _streamPrimed = true;
            return;
          }
          for (final order in ranked) {
            final id = order.reference.id;
            if (_seenOrderIds.contains(id)) continue;
            _seenOrderIds.add(id);
            if (_dismissedOrderIds.contains(id)) continue;
            if (_sheetOpen) continue;
            if (!mounted) return;
            _present(order);
            break;
          }
        });
      } finally {
        _attachInFlight = false;
      }
    }();
  }

  Future<void> _present(OrderRecord order) async {
    _sheetOpen = true;
    _player ??= AudioPlayer();
    try {
      await _player!.setAsset('assets/audios/835880__matustrm__completed.wav');
      unawaited(_player!.play());
    } catch (_) {}

    if (!mounted) return;
    await DriverRideRequestSheet.show(
      context,
      order: order,
      onReject: (o) {
        _dismissedOrderIds.add(o.reference.id);
      },
      onAccept: (o) async {
        final loc = await getCurrentUserLocation(
          defaultLocation: const LatLng(0, 0),
        );
        final result = await DriverTripService.acceptOrder(
          order: o,
          driverLocation: loc,
          onStateChanged: () => safeSetState(() {}),
        );
        if (!result.ok) {
          if (result.message != null && mounted) {
            await DriverDialogs.showAlert(
              context,
              title: driverTr(context, 'Unable to accept'),
              message: driverTr(context, result.message!),
              type: DriverMessageType.error,
            );
          }
          return;
        }
        if (!mounted) return;
        context.pushNamed(
          TfaselOrserWidget.routeName,
          queryParameters: {
            'id': serializeParam(o.reference, ParamType.DocumentReference),
          }.withoutNulls,
        );
      },
    );
    _sheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncListener();
        });
        return widget.child;
      },
    );
  }
}
