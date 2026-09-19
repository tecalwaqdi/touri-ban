import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/tour_guide_status.dart';
import '/core/toury_notification_localizer.dart';
import '/core/toury_vehicle_catalog.dart';

/// Notify online drivers that match the booking vehicle class.
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
}) async {
  try {
    final country = countryRef ?? FFAppState().dolh;
    final city = cityRef ?? FFAppState().mdenh;
    final typeCar = typecarRev is DocumentReference ? typecarRev : null;
    if (typeCar == null) return;

    // Only drivers currently online (`ngl == true`) should get a new-order push.
    // Do not use Settings.ngl — that is unrelated and was dropping all notifies.
    const onlineFlag = true;

    final requireApprovedGuide =
        driverGuideOnly || FFAppState().DriverGuideState == true;

    String? orderCode;
    String orderLabel = (orderCarLabel ?? FFAppState().tebycar).trim();
    try {
      final snap = await typeCar.get();
      final data = snap.data();
      if (data is Map) {
        orderCode = (data['codeCar'] ?? data['code_car'] ?? '').toString();
        if (orderLabel.isEmpty) {
          orderLabel = (data['naim'] ?? '').toString().trim();
        }
      }
    } catch (_) {}

    final orderCategory = touryVehicleCategoryFor(
      codeCar: orderCode,
      documentId: typeCar.id,
      displayName: orderLabel,
    );

    bool driverMatchesVehicle(UserRecord agent) {
      final data = agent.snapshotData;
      final driverCar = agent.mndobTypeCar ??
          (data['carRev_mndob'] is DocumentReference
              ? data['carRev_mndob'] as DocumentReference
              : null) ??
          (data['car_rev_mndob'] is DocumentReference
              ? data['car_rev_mndob'] as DocumentReference
              : null);
      if (driverCar == null) return false;
      if (driverCar.path == typeCar.path) return true;

      final driverLabel = (
        (data['text_type_car_mndob'] ?? data['mdenh_aml'] ?? '').toString()
      ).trim();
      final driverCategory = touryVehicleCategoryFor(
        documentId: driverCar.id,
        displayName: driverLabel,
      );
      if (orderCategory != null && driverCategory != null) {
        return orderCategory == driverCategory;
      }
      if (driverLabel.isNotEmpty &&
          orderLabel.isNotEmpty &&
          driverLabel.toLowerCase() == orderLabel.toLowerCase()) {
        return true;
      }
      return false;
    }

    Query baseDrivers(Query query) {
      var q = query
          .where('actev_mndob', isEqualTo: true)
          .where('ismndom', isEqualTo: true)
          .where('ismndob', isEqualTo: true)
          .where('ngl', isEqualTo: onlineFlag);
      if (requireApprovedGuide) {
        q = q
            .where(TourGuideStatus.fieldIsTourGuide, isEqualTo: true)
            .where(
              TourGuideStatus.fieldStatus,
              isEqualTo: TourGuideStatus.approved,
            );
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

    Future<List<UserRecord>> queryDrivers(
      Query Function(Query) builder,
    ) async {
      try {
        return await queryUserRecordOnce(queryBuilder: builder);
      } catch (e) {
        debugPrint('touryNotifyAgentsForNewOrder query fallback: $e');
        final all = await queryUserRecordOnce(
          queryBuilder: (q) => q
              .where('actev_mndob', isEqualTo: true)
              .where('ismndom', isEqualTo: true)
              .where('ismndob', isEqualTo: true)
              .where('ngl', isEqualTo: onlineFlag),
        );
        if (!requireApprovedGuide) return all;
        return all
            .where((u) => TourGuideStatus.isApproved(u.snapshotData))
            .toList();
      }
    }

    Future<List<UserRecord>> withVehicle(List<UserRecord> pool) async {
      // Prefer exact type_car ref first (cheap path).
      final exact = pool.where((u) {
        final data = u.snapshotData;
        final legacy = data['carRev_mndob'] is DocumentReference
            ? data['carRev_mndob'] as DocumentReference
            : (data['car_rev_mndob'] is DocumentReference
                ? data['car_rev_mndob'] as DocumentReference
                : null);
        return u.mndobTypeCar?.path == typeCar.path ||
            legacy?.path == typeCar.path;
      }).toList();
      if (exact.isNotEmpty) return exact;
      return pool.where(driverMatchesVehicle).toList();
    }

    // 1) Same village first.
    List<UserRecord> agents = [];
    if (villnow != null) {
      final villagePool = await queryDrivers(
        (q) => baseDrivers(q).where('mndob_vill', isEqualTo: villnow),
      );
      agents = await withVehicle(villagePool);
    }

    // 2) Same city (village.cities ↔ booking city).
    if (agents.isEmpty && city != null) {
      final allOnline = await queryDrivers(baseDrivers);
      final cityPool = await filterByVillageCountryOrCity(
        pool: allOnline,
        matchCity: true,
        matchCountry: false,
      );
      agents = await withVehicle(cityPool);
    }

    // 3) Broaden to same country when city/village pool is empty.
    if (agents.isEmpty) {
      final allOnline = await queryDrivers(baseDrivers);
      List<UserRecord> countryPool;
      if (country == null) {
        countryPool = allOnline;
      } else {
        countryPool = await filterByVillageCountryOrCity(
          pool: allOnline,
          matchCity: false,
          matchCountry: true,
        );
      }
      agents = await withVehicle(countryPool);
    }

    if (requireApprovedGuide) {
      agents = agents
          .where((u) => TourGuideStatus.isApproved(u.snapshotData))
          .toList();
    }

    // De-dupe by uid.
    final seen = <String>{};
    agents = agents.where((a) => seen.add(a.reference.id)).toList();

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
