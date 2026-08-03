import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';

/// Domains that expose admin statistics UIs.
enum StatsDomain {
  dashboard,
  reports,
  profits,
  agent,
}

/// Broadcasts stat invalidation so every stats screen reloads together.
class AdminStatsCoordinator {
  AdminStatsCoordinator._();

  static final AdminStatsCoordinator instance = AdminStatsCoordinator._();

  final Map<StatsDomain, StreamController<int>> _controllers = {
    for (final d in StatsDomain.values)
      d: StreamController<int>.broadcast(),
  };

  final Map<StatsDomain, int> _generation = {
    for (final d in StatsDomain.values) d: 0,
  };

  StreamSubscription<QuerySnapshot>? _orderWatch;
  Timer? _orderWatchDebounce;

  int generation(StatsDomain domain) => _generation[domain] ?? 0;

  Stream<int> stream(StatsDomain domain) => _controllers[domain]!.stream;

  /// Bump generation and notify listeners for the given domains.
  void invalidate({Iterable<StatsDomain>? domains}) {
    final targets = domains ?? StatsDomain.values;
    for (final domain in targets) {
      final next = (_generation[domain] ?? 0) + 1;
      _generation[domain] = next;
      final controller = _controllers[domain];
      if (controller != null && !controller.isClosed) {
        controller.add(next);
      }
    }
  }

  /// Listen to recent order changes and debounce stat refresh.
  void startLiveSync() {
    stopLiveSync();

    Query query = OrderRecord.collection
        .orderBy('data_order', descending: true)
        .limit(8);

    final countryRef = AdminCountryScope.activeCountryRef;
    if (countryRef != null) {
      query = query.where('Rev_dolh', isEqualTo: countryRef);
    }

    _orderWatch = query.snapshots().listen((_) {
      _orderWatchDebounce?.cancel();
      _orderWatchDebounce = Timer(const Duration(milliseconds: 1500), () {
        invalidate();
      });
    });
  }

  void stopLiveSync() {
    _orderWatchDebounce?.cancel();
    _orderWatchDebounce = null;
    _orderWatch?.cancel();
    _orderWatch = null;
  }

  void dispose() {
    stopLiveSync();
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }
}
