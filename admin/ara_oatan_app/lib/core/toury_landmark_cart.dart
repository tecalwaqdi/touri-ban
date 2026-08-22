import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_mkan_i18n.dart';
import '/core/toury_navigation.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Result of a cart add/remove attempt for a landmark.
enum TouryLandmarkCartOutcome {
  added,
  removed,
  alreadyInCart,
  notInCart,
}

class TouryLandmarkCartResult {
  const TouryLandmarkCartResult({
    required this.outcome,
    required this.name,
  });

  final TouryLandmarkCartOutcome outcome;
  final String name;

  bool get changed =>
      outcome == TouryLandmarkCartOutcome.added ||
      outcome == TouryLandmarkCartOutcome.removed;
}

void touryClearThenShowSnackBar(
  BuildContext context, {
  required String message,
  DsSnackTone tone = DsSnackTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  DsSnackBar.show(
    context,
    message: message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void _showLandmarkOutcomeSnack(
  BuildContext context,
  TouryLandmarkCartResult result, {
  bool offerCheckout = true,
}) {
  if (!context.mounted) return;
  switch (result.outcome) {
    case TouryLandmarkCartOutcome.added:
      touryClearThenShowSnackBar(
        context,
        message: 'landmark_added_success'.tr(namedArgs: {'name': result.name}),
        tone: DsSnackTone.success,
        actionLabel: offerCheckout ? 'view_my_trip'.tr() : null,
        onAction: offerCheckout ? () => touryOpenCheckout(context) : null,
      );
    case TouryLandmarkCartOutcome.removed:
      touryClearThenShowSnackBar(
        context,
        message:
            'landmark_removed_success'.tr(namedArgs: {'name': result.name}),
        tone: DsSnackTone.neutral,
      );
    case TouryLandmarkCartOutcome.alreadyInCart:
      touryClearThenShowSnackBar(
        context,
        message: 'landmark_already_in_cart'.tr(),
        tone: DsSnackTone.error,
      );
    case TouryLandmarkCartOutcome.notInCart:
      touryClearThenShowSnackBar(
        context,
        message: 'landmark_not_in_cart'.tr(namedArgs: {'name': result.name}),
        tone: DsSnackTone.warning,
      );
  }
}

void _applyCartMetaAfterChange(FFAppState app) {
  app.addcart = app.cartmkss.length;
  app.Minimumhours = touryMinimumBookingHours(
    landmarkCount: app.cartmkss.length,
    driverGuide: app.DriverGuideState,
  );
  tourySyncCartMkanRefs(app);
  tourySyncBookingFlags();
  app.update(() {});
}

/// Adds a catalog landmark to the trip cart (deduped by [MkanRecord.reference]).
TouryLandmarkCartResult touryAddLandmarkToCart({
  required BuildContext context,
  required MkanRecord record,
  FFAppState? state,
  VoidCallback? onChanged,
  bool showSnack = true,
  bool offerCheckout = true,
}) {
  final app = state ?? FFAppState();
  final name = touryMkanName(context, record);

  if (touryLandmarkAlreadyInCart(record.reference, app)) {
    final result = TouryLandmarkCartResult(
      outcome: TouryLandmarkCartOutcome.alreadyInCart,
      name: name,
    );
    if (showSnack) {
      _showLandmarkOutcomeSnack(context, result, offerCheckout: offerCheckout);
    }
    return result;
  }

  app.addToCartmkss(
    AmaknCostmStruct(
      naim: name,
      textivill: touryLandmarkCartSubtitle(record, app),
      loceshn: record.location,
      revmkan: record.reference,
    ),
  );
  app.addToMkan(record.reference);
  app.dataSchedule = getCurrentTimestamp;
  app.fulltextSchedule = 'instant_booking'.tr();
  if (app.naimvillatext.trim().isNotEmpty) {
    app.textallAlmdn = '${app.textallAlmdn} ${app.naimvillatext}'.trim();
  }
  _applyCartMetaAfterChange(app);
  onChanged?.call();

  final result = TouryLandmarkCartResult(
    outcome: TouryLandmarkCartOutcome.added,
    name: name,
  );
  if (showSnack) {
    _showLandmarkOutcomeSnack(context, result, offerCheckout: offerCheckout);
  }
  return result;
}

/// Removes a cart item (and its [revmkan] ref) with immediate snack feedback.
TouryLandmarkCartResult touryRemoveLandmarkFromCart({
  required BuildContext context,
  required AmaknCostmStruct item,
  FFAppState? state,
  VoidCallback? onChanged,
  bool showSnack = true,
}) {
  final app = state ?? FFAppState();
  final name = item.naim.trim().isNotEmpty ? item.naim.trim() : '—';
  final ref = item.revmkan;
  final before = app.cartmkss.length;

  AmaknCostmStruct? match;
  if (app.cartmkss.contains(item)) {
    match = item;
  } else if (ref != null) {
    for (final e in app.cartmkss) {
      if (e.revmkan?.path == ref.path) {
        match = e;
        break;
      }
    }
  } else {
    for (final e in app.cartmkss) {
      if (e.naim == item.naim &&
          e.loceshn?.latitude == item.loceshn?.latitude &&
          e.loceshn?.longitude == item.loceshn?.longitude) {
        match = e;
        break;
      }
    }
  }
  if (match != null) {
    app.removeFromCartmkss(match);
  }

  if (ref != null) {
    app.removeFromMkan(ref);
  }

  if (app.cartmkss.length == before) {
    final result = TouryLandmarkCartResult(
      outcome: TouryLandmarkCartOutcome.notInCart,
      name: name,
    );
    if (showSnack) _showLandmarkOutcomeSnack(context, result);
    return result;
  }

  _applyCartMetaAfterChange(app);
  onChanged?.call();

  final result = TouryLandmarkCartResult(
    outcome: TouryLandmarkCartOutcome.removed,
    name: name,
  );
  if (showSnack) _showLandmarkOutcomeSnack(context, result);
  return result;
}

/// Removes by landmark document ref (used when UI only has the catalog record).
TouryLandmarkCartResult touryRemoveLandmarkRefFromCart({
  required BuildContext context,
  required DocumentReference ref,
  String? displayName,
  FFAppState? state,
  VoidCallback? onChanged,
  bool showSnack = true,
}) {
  final app = state ?? FFAppState();
  AmaknCostmStruct? match;
  for (final e in app.cartmkss) {
    if (e.revmkan?.path == ref.path) {
      match = e;
      break;
    }
  }
  if (match == null) {
    final result = TouryLandmarkCartResult(
      outcome: TouryLandmarkCartOutcome.notInCart,
      name: (displayName ?? '').trim().isNotEmpty ? displayName!.trim() : '—',
    );
    if (showSnack) _showLandmarkOutcomeSnack(context, result);
    return result;
  }
  return touryRemoveLandmarkFromCart(
    context: context,
    item: match,
    state: app,
    onChanged: onChanged,
    showSnack: showSnack,
  );
}
