import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/toury_notification_localizer.dart';

Future<void> touryNotifyAgentsForNewOrder({
  required DocumentReference? villnow,
  required dynamic typecarRev,
  required dynamic nglValue,
  required int totalsaat,
  required double totalmndob3,
  required String currency,
  DocumentReference? countryRef,
  DocumentReference? cityRef,
}) async {
  try {
    final country = countryRef ?? FFAppState().dolh;
    final city = cityRef ?? FFAppState().mdenh;
    final typeCar = typecarRev is DocumentReference ? typecarRev : null;
    if (typeCar == null) return;

    Query baseDrivers(Query query) {
      var q = query
          .where('actev_mndob', isEqualTo: true)
          .where('ismndom', isEqualTo: true)
          .where('ismndob', isEqualTo: true)
          .where('mndob_type_car', isEqualTo: typeCar);
      if (nglValue != null) {
        q = q.where('ngl', isEqualTo: nglValue);
      }
      return q;
    }

    Future<List<UserRecord>> filterByVillageCountryOrCity({
      required List<UserRecord> pool,
      required bool matchCity,
      required bool matchCountry,
    }) async {
      if (!matchCity && !matchCountry) return pool;
      final cityPath = city?.path;
      final countryPath = country?.path;
      final matched = <UserRecord>[];
      for (final agent in pool) {
        final vill = agent.mndobVill;
        if (vill == null) continue;
        try {
          final snap = await vill.get();
          final data = snap.data() as Map<String, dynamic>?;
          if (matchCity && cityPath != null) {
            final cities = data?['cities'];
            final citiesPath = cities is DocumentReference
                ? cities.path
                : (cities?.toString() ?? '');
            if (citiesPath == cityPath) {
              matched.add(agent);
              continue;
            }
          }
          if (matchCountry && countryPath != null) {
            final dolh = data?['dolh'];
            final dolhPath = dolh is DocumentReference
                ? dolh.path
                : (dolh?.toString() ?? '');
            if (dolhPath == countryPath) {
              matched.add(agent);
            }
          }
        } catch (_) {}
      }
      return matched;
    }

    // 1) Same village first.
    List<UserRecord> agents = [];
    if (villnow != null) {
      agents = await queryUserRecordOnce(
        queryBuilder: (q) =>
            baseDrivers(q).where('mndob_vill', isEqualTo: villnow),
      );
    }

    // 2) Same city (village.cities ↔ booking city).
    if (agents.isEmpty && city != null) {
      final allForType = await queryUserRecordOnce(queryBuilder: baseDrivers);
      agents = await filterByVillageCountryOrCity(
        pool: allForType,
        matchCity: true,
        matchCountry: false,
      );
    }

    // 3) Broaden to same country when city/village pool is empty.
    if (agents.isEmpty) {
      final allForType = await queryUserRecordOnce(queryBuilder: baseDrivers);
      if (country == null) {
        agents = allForType;
      } else {
        agents = await filterByVillageCountryOrCity(
          pool: allForType,
          matchCity: false,
          matchCountry: true,
        );
      }
    }

    for (final agent in agents) {
      final locale = TouryNotificationLocalizer.localeForUser(agent);
      final title = await TouryNotificationLocalizer.text(
        locale,
        'notification_new_order_driver_title',
      );
      final body = await TouryNotificationLocalizer.text(
        locale,
        'notification_new_order_driver_body',
        args: {
          'hours': totalsaat.toString(),
          'amount': totalmndob3.toStringAsFixed(2),
          'currency': currency,
        },
      );

      if (agent.phoneNumber.trim().isNotEmpty) {
        unawaited(WatcCall.call(to: agent.phoneNumber, msg: body));
      }
      triggerPushNotification(
        notificationTitle: title,
        notificationText: body,
        userRefs: [agent.reference],
        initialPageName: 'Now',
        parameterData: const {},
      );
    }
  } catch (error, stackTrace) {
    debugPrint('touryNotifyAgentsForNewOrder: $error\n$stackTrace');
  }
}
