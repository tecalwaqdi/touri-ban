import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Driver new-order FCM is owned by server offer waves
/// (`onOrderCreatedOfferWave` / `expandOrderOfferWaves`).
///
/// This entrypoint must NOT fan out to the full online pool. It only asks the
/// backend to (re)seed the nearest cohort for [orderId] when known.
Future<void> touryNotifyAgentsForNewOrder({
  required DocumentReference? villnow,
  required dynamic typecarRev,
  required dynamic nglValue,
  required int totalsaat,
  required double totalmndob3,
  required String currency,
  DocumentReference? countryRef,
  DocumentReference? cityRef,
  bool driverGuideOnly = false,
  String? orderCarLabel,
  String? orderId,
}) async {
  // Server onCreate already seeds wave 0. Optional refresh helps cash/client
  // paths that create the order before the trigger settles.
  final id = (orderId ?? '').trim();
  if (id.isEmpty) {
    debugPrint(
      'touryNotifyAgentsForNewOrder: deferred to server waves '
      '(no orderId; avoiding open-pool FCM fanout)',
    );
    return;
  }
  try {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('refreshOrderOfferWave');
    await callable.call(<String, dynamic>{'orderId': id});
  } catch (e, st) {
    debugPrint('touryNotifyAgentsForNewOrder refresh: $e\n$st');
  }
}
