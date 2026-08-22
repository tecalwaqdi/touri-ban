import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/driver_ride_request_sheet.dart';
import '/core/driver_eligibility_service.dart';
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
  final Set<String> _presentedOrderIds = {};
  final ListQueue<OrderRecord> _pendingQueue = ListQueue();
  StreamSubscription<List<OrderRecord>>? _sub;
  AudioPlayer? _player;
  bool _sheetOpen = false;
  bool _streamPrimed = false;
  bool _attachInFlight = false;
  bool? _lastReady;
  LatLng? _lastDriverPos;

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
        _pendingQueue.clear();
      }
      return;
    }
    _lastReady = ready;

    if (!ready) {
      _sub?.cancel();
      _sub = null;
      _streamPrimed = false;
      _pendingQueue.clear();
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
              cached: true,
            );
            if (driverPos.latitude == 0 && driverPos.longitude == 0) {
              driverPos = null;
            }
          } catch (_) {
            driverPos = null;
          }
          _lastDriverPos = driverPos;
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
            if (_dismissedOrderIds.contains(id)) {
              _seenOrderIds.add(id);
              continue;
            }
            if (_presentedOrderIds.contains(id) || _seenOrderIds.contains(id)) {
              continue;
            }
            if (_sheetOpen) {
              _enqueue(order);
              continue;
            }
            _seenOrderIds.add(id);
            if (!mounted) return;
            await _present(order);
            break;
          }
        });
      } finally {
        _attachInFlight = false;
      }
    }();
  }

  void _enqueue(OrderRecord order) {
    final id = order.reference.id;
    if (_dismissedOrderIds.contains(id) || _presentedOrderIds.contains(id)) {
      return;
    }
    final alreadyQueued =
        _pendingQueue.any((o) => o.reference.id == id);
    if (alreadyQueued) return;
    _pendingQueue.add(order);
  }

  Future<void> _drainQueue() async {
    while (!_sheetOpen && _pendingQueue.isNotEmpty && mounted) {
      final next = _pendingQueue.removeFirst();
      final id = next.reference.id;
      if (_dismissedOrderIds.contains(id) || _presentedOrderIds.contains(id)) {
        continue;
      }
      if (_seenOrderIds.contains(id) && !_presentedOrderIds.contains(id)) {
        // Seen but never presented (edge) — still show once.
      } else if (_seenOrderIds.contains(id)) {
        continue;
      }
      _seenOrderIds.add(id);
      await _present(next);
      return;
    }
  }

  Future<void> _present(OrderRecord order) async {
    final id = order.reference.id;
    if (_sheetOpen || _presentedOrderIds.contains(id)) return;
    _sheetOpen = true;
    _presentedOrderIds.add(id);
    _player ??= AudioPlayer();
    try {
      await _player!.setAsset('assets/audios/835880__matustrm__completed.wav');
      unawaited(_player!.play());
    } catch (_) {}

    if (!mounted) {
      _sheetOpen = false;
      return;
    }

    final accepted = await DriverRideRequestSheet.show(
      context,
      order: order,
      driverPosition: _lastDriverPos,
      onReject: (o) {
        _dismissedOrderIds.add(o.reference.id);
      },
      onAccept: (o) async {
        // Accept immediately with last known GPS — never block on a fresh fix.
        final loc = DriverTripService.usableDriverLocation(_lastDriverPos);
        final result = await DriverTripService.acceptOrder(
          order: o,
          driverLocation: loc,
          onStateChanged: () => safeSetState(() {}),
        );
        // Refresh GPS in background for tracking only (does not delay accept).
        if (result.ok) {
          unawaited(() async {
            try {
              final fresh = await getCurrentUserLocation(
                defaultLocation: const LatLng(0, 0),
                cached: true,
              ).timeout(const Duration(seconds: 4));
              final safe = DriverTripService.usableDriverLocation(fresh);
              if (safe != null) _lastDriverPos = safe;
            } catch (_) {}
          }());
        }
        return result;
      },
    );

    _sheetOpen = false;

    if (accepted == true && mounted) {
      _dismissedOrderIds.add(id);
      _pendingQueue.removeWhere((o) => o.reference.id == id);
      // Drop from available pool locally; accepted list filters by assignment.
      FFAppState().revOrder = order.reference;
      FFAppState().update(() {});

      final idParam = serializeParam(
        order.reference,
        ParamType.DocumentReference,
      );
      if (idParam != null && idParam.isNotEmpty) {
        context.pushNamed(
          TfaselOrserWidget.routeName,
          queryParameters: {'id': idParam}.withoutNulls,
        );
      } else {
        // Fallback: open Accepted tab if serialization fails.
        context.pushNamed(AcceptedWidget.routeName);
      }
      return;
    }

    if (mounted) {
      unawaited(_drainQueue());
    }
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
