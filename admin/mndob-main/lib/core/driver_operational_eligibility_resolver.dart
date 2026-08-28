import '/backend/backend.dart';
import '/core/driver_document_expiry_resolver.dart';
import '/core/driver_document_requirements.dart';
import '/core/driver_requirement_effective_state_resolver.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Resolves country driver document requirements from Firestore config.
abstract final class DriverDocumentRequirementResolver {
  DriverDocumentRequirementResolver._();

  static bool hasConfiguredRequirements(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return false;
    return raw.values.any((v) {
      if (v is! Map) return false;
      return v['enabled'] == true;
    });
  }

  static List<DriverDocumentRequirement> resolveFromCountryData(
    Map<String, dynamic>? driverRequirements,
  ) {
    if (!hasConfiguredRequirements(driverRequirements)) {
      return const [];
    }
    return DriverDocumentRequirementsRepository.mergeCountryConfig(
      DriverDocumentRequirementsRepository.baseline,
      driverRequirements,
    );
  }

  /// Load from country doc; falls back to baseline when config absent (legacy compat).
  static Future<List<DriverDocumentRequirement>> resolveForCountryRef(
    DocumentReference? countryRef,
  ) async {
    if (countryRef == null) {
      return DriverDocumentRequirementsRepository.baseline;
    }
    try {
      final snap = await countryRef.get();
      if (!snap.exists) {
        return DriverDocumentRequirementsRepository.baseline;
      }
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final raw = data['driver_requirements'];
      final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final resolved = resolveFromCountryData(map);
      if (resolved.isEmpty) {
        return DriverDocumentRequirementsRepository.baseline;
      }
      return resolved;
    } catch (_) {
      return DriverDocumentRequirementsRepository.baseline;
    }
  }
}

/// Operational eligibility including document expiry + retroactive rollout.
class DriverOperationalEligibility {
  const DriverOperationalEligibility({
    required this.allowed,
    required this.reasonCode,
    this.blockingDocumentType = '',
  });

  final bool allowed;
  final String reasonCode;
  final String blockingDocumentType;

  static const ok = DriverOperationalEligibility(
    allowed: true,
    reasonCode: 'ok',
  );
}

/// UI-facing document alert (expiring / expired / grace).
class DriverDocumentUxAlert {
  const DriverDocumentUxAlert({
    required this.severity,
    required this.documentType,
    required this.titleKey,
    this.expiryDate,
    this.reviewStatus = '',
    this.daysRemaining,
  });

  final DriverDocumentUxSeverity severity;
  final String documentType;
  final String titleKey;
  final DateTime? expiryDate;
  final String reviewStatus;
  final int? daysRemaining;
}

enum DriverDocumentUxSeverity {
  graceWarning,
  expiringSoon,
  expiredBlocking,
  replacementPending,
}

abstract final class DriverOperationalEligibilityResolver {
  DriverOperationalEligibilityResolver._();

  static DateTime? _driverApprovedAt(Map<String, dynamic> userData) {
    return DriverRequirementEffectiveStateResolver.parseDate(
          userData['reviewed_at'],
        ) ??
        DriverRequirementEffectiveStateResolver.parseDate(
          userData['approved_at'],
        ) ??
        DriverRequirementEffectiveStateResolver.parseDate(
          userData['actev_mndob_at'],
        );
  }

  static DriverRequirementEffectiveState _effectiveFor(
    DriverDocumentRequirement req,
    Map<String, dynamic> userData,
    DateTime? now, {
    bool actevMndob = false,
  }) {
    final approvedAt = actevMndob
        ? (_driverApprovedAt(userData) ?? DateTime.utc(1970, 1, 1))
        : null;
    return DriverRequirementEffectiveStateResolver.resolve(
      requirementEnabled: true,
      requirementRequired: req.required,
      effectiveFrom:
          DriverRequirementEffectiveStateResolver.parseDate(req.effectiveFrom),
      gracePeriodDays: req.gracePeriodDays,
      driverApprovedAt: approvedAt,
      now: now,
    );
  }

  static DriverOperationalEligibility evaluate({
    required bool emailVerified,
    required bool actevMndob,
    required bool suspended,
    required bool onActiveTrip,
    required List<DriverDocumentRequirement> requirements,
    required Map<String, dynamic> userData,
    DateTime? now,
  }) {
    if (!emailVerified) {
      return const DriverOperationalEligibility(
        allowed: false,
        reasonCode: 'email_not_verified',
      );
    }
    if (suspended) {
      return const DriverOperationalEligibility(
        allowed: false,
        reasonCode: 'account_suspended',
      );
    }
    if (!actevMndob) {
      return const DriverOperationalEligibility(
        allowed: false,
        reasonCode: 'application_not_approved',
      );
    }

    for (final req in requirements) {
      if (!req.required) continue;

      final effective = _effectiveFor(
        req,
        userData,
        now,
        actevMndob: actevMndob,
      );
      final mayBlock =
          DriverRequirementEffectiveStateResolver.mayBlockOperations(effective);

      final slot = userData[req.firestoreField];
      Map<String, dynamic>? map;
      if (slot is Map) map = Map<String, dynamic>.from(slot);

      final reviewStatus = (map?['reviewStatus'] ?? map?['status'] ?? '')
          .toString()
          .toLowerCase();
      final hasAsset = map != null &&
          ((map['storagePath'] as String?)?.trim().isNotEmpty == true ||
              (map['url'] as String?)?.trim().isNotEmpty == true);

      // Missing required document under enforceable requirement.
      if (!hasAsset && mayBlock) {
        if (onActiveTrip) continue;
        return DriverOperationalEligibility(
          allowed: false,
          reasonCode: 'document_missing',
          blockingDocumentType: req.type,
        );
      }

      if (reviewStatus == 'needs_replacement' ||
          reviewStatus == 'needs_reupload' ||
          reviewStatus == 'rejected') {
        if (!mayBlock) continue;
        if (onActiveTrip) continue;
        return DriverOperationalEligibility(
          allowed: false,
          reasonCode: 'document_needs_replacement',
          blockingDocumentType: req.type,
        );
      }

      if (reviewStatus == 'pending_review' &&
          req.expiryRequired &&
          _slotExpiredOrMissing(map, req, now)) {
        // Expired replacement pending — always block new ops (not retroactive).
        if (onActiveTrip) continue;
        return DriverOperationalEligibility(
          allowed: false,
          reasonCode: 'document_expired',
          blockingDocumentType: req.type,
        );
      }

      // Early renewal: pending_review while still valid → keep operating.
      if (reviewStatus == 'pending_review' &&
          !_slotExpiredOrMissing(map, req, now)) {
        continue;
      }

      if (!req.expiryRequired || !req.operationalBlockingOnExpiry) continue;

      final expiry = DriverDocumentExpiryResolver.parseExpiry(
        map?['expiryDate'] ?? map?['expiry_date'],
      );
      final state = DriverDocumentExpiryResolver.resolve(
        expiryDate: expiry,
        expiryRequired: true,
        warningDays: req.expiryWarningDays,
        now: now,
      );
      if (DriverDocumentExpiryResolver.blocksNewOperations(state)) {
        // Document lifecycle expiry always blocks when configured —
        // independent of requirement rollout grace.
        if (onActiveTrip) continue;
        return DriverOperationalEligibility(
          allowed: false,
          reasonCode: 'document_expired',
          blockingDocumentType: req.type,
        );
      }
    }
    return DriverOperationalEligibility.ok;
  }

  /// Collect UX alerts (non-SOT); eligibility remains separate.
  static List<DriverDocumentUxAlert> collectUxAlerts({
    required List<DriverDocumentRequirement> requirements,
    required Map<String, dynamic> userData,
    bool actevMndob = false,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now().toUtc();
    final out = <DriverDocumentUxAlert>[];
    for (final req in requirements) {
      if (!req.required) continue;
      final effective = _effectiveFor(
        req,
        userData,
        today,
        actevMndob: actevMndob,
      );
      if (DriverRequirementEffectiveStateResolver.showGraceWarning(effective)) {
        out.add(DriverDocumentUxAlert(
          severity: DriverDocumentUxSeverity.graceWarning,
          documentType: req.type,
          titleKey: req.localizedTitleKey,
        ));
      }

      final slot = userData[req.firestoreField];
      Map<String, dynamic>? map;
      if (slot is Map) map = Map<String, dynamic>.from(slot);
      final reviewStatus = (map?['reviewStatus'] ?? map?['status'] ?? '')
          .toString()
          .toLowerCase();
      final expiry = DriverDocumentExpiryResolver.parseExpiry(
        map?['expiryDate'] ?? map?['expiry_date'],
      );

      if (req.expiryRequired) {
        final state = DriverDocumentExpiryResolver.resolve(
          expiryDate: expiry,
          expiryRequired: true,
          warningDays: req.expiryWarningDays,
          now: today,
        );
        if (state == DriverDocumentExpiryState.expiringSoon) {
          final days = expiry == null
              ? null
              : DateTime.utc(expiry.year, expiry.month, expiry.day)
                  .difference(DateTime.utc(today.year, today.month, today.day))
                  .inDays;
          out.add(DriverDocumentUxAlert(
            severity: DriverDocumentUxSeverity.expiringSoon,
            documentType: req.type,
            titleKey: req.localizedTitleKey,
            expiryDate: expiry,
            reviewStatus: reviewStatus,
            daysRemaining: days,
          ));
        }
        if (state == DriverDocumentExpiryState.expired ||
            state == DriverDocumentExpiryState.missingExpiry) {
          out.add(DriverDocumentUxAlert(
            severity: DriverDocumentUxSeverity.expiredBlocking,
            documentType: req.type,
            titleKey: req.localizedTitleKey,
            expiryDate: expiry,
            reviewStatus: reviewStatus,
          ));
        }
      }

      if (reviewStatus == 'pending_review' &&
          _slotExpiredOrMissing(map, req, today)) {
        out.add(DriverDocumentUxAlert(
          severity: DriverDocumentUxSeverity.replacementPending,
          documentType: req.type,
          titleKey: req.localizedTitleKey,
          expiryDate: expiry,
          reviewStatus: reviewStatus,
        ));
      }
    }
    return out;
  }

  static bool _slotExpiredOrMissing(
    Map<String, dynamic>? map,
    DriverDocumentRequirement req,
    DateTime? now,
  ) {
    final expiry = DriverDocumentExpiryResolver.parseExpiry(
      map?['expiryDate'] ?? map?['expiry_date'],
    );
    final state = DriverDocumentExpiryResolver.resolve(
      expiryDate: expiry,
      expiryRequired: req.expiryRequired,
      warningDays: req.expiryWarningDays,
      now: now,
    );
    return DriverDocumentExpiryResolver.blocksNewOperations(state);
  }

  static DriverOperationalEligibility evaluateFromUserRecord({
    required bool emailVerified,
    required UserRecord doc,
    required List<DriverDocumentRequirement> requirements,
    required bool onActiveTrip,
    DateTime? now,
  }) {
    final suspended =
        doc.registrationStatus.trim().toLowerCase() == 'suspended' ||
            doc.registrationStatus.trim().toLowerCase() == 'blocked';
    return evaluate(
      emailVerified: emailVerified,
      actevMndob: valueOrDefault<bool>(doc.actevMndob, false),
      suspended: suspended,
      onActiveTrip: onActiveTrip,
      requirements: requirements,
      userData: Map<String, dynamic>.from(doc.snapshotData),
      now: now,
    );
  }
}
