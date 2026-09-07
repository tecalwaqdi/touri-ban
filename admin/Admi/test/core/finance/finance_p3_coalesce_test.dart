import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Unit-level coalescing semantics used by AdminFinanceRepository.
Future<T> coalesceMap<T>({
  required Map<String, Future<T>> inFlight,
  required String key,
  required Future<T> Function() loader,
}) {
  final existing = inFlight[key];
  if (existing != null) return existing;
  final fut = () async {
    try {
      return await loader();
    } finally {
      inFlight.remove(key);
    }
  }();
  inFlight[key] = fut;
  return fut;
}

void main() {
  test('PERF-P3 coalescing: 3 waiters → 1 loader', () async {
    var loads = 0;
    final inFlight = <String, Future<int>>{};
    Future<int> one() => coalesceMap(
          inFlight: inFlight,
          key: 'k',
          loader: () async {
            loads++;
            await Future<void>.delayed(const Duration(milliseconds: 40));
            return 7;
          },
        );

    final results = await Future.wait([one(), one(), one()]);
    expect(results, [7, 7, 7]);
    expect(loads, 1);
  });

  test('PERF-P3 coalescing: different keys → separate loaders', () async {
    var loads = 0;
    final inFlight = <String, Future<int>>{};
    Future<int> load(String key) => coalesceMap(
          inFlight: inFlight,
          key: key,
          loader: () async {
            loads++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return key.length;
          },
        );

    final results = await Future.wait([load('a'), load('bb')]);
    expect(results, [1, 2]);
    expect(loads, 2);
  });

  test('PERF-P3 coalescing: failure is not sticky', () async {
    var loads = 0;
    final inFlight = <String, Future<int>>{};
    Future<int> load({required bool fail}) => coalesceMap(
          inFlight: inFlight,
          key: 'k',
          loader: () async {
            loads++;
            if (fail) throw StateError('boom');
            return 1;
          },
        );

    await expectLater(load(fail: true), throwsStateError);
    expect(inFlight.containsKey('k'), isFalse);
    expect(await load(fail: false), 1);
    expect(loads, 2);
  });
}
