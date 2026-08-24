import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';

class DriverAutoActivationResult {
  const DriverAutoActivationResult._({
    required this.ok,
    this.alreadyActive = false,
    this.code,
  });

  const DriverAutoActivationResult.ok({this.alreadyActive = false})
      : ok = true,
        code = null;

  const DriverAutoActivationResult.fail(this.code) : ok = false, alreadyActive = false;

  final bool ok;
  final bool alreadyActive;
  final String? code;
}

/// Legacy cash-wave auto-activation.
///
/// Registration V2 (`registration_flow_version == 2`) must never call
/// `autoActivateDriver` — activation is admin review only.
abstract final class DriverAutoActivationService {
  DriverAutoActivationService._();

  static bool _isRegistrationV2(UserRecord? doc) {
    if (doc == null) return false;
    final v = doc.snapshotData['registration_flow_version'];
    if (v is num) return v.toInt() == 2;
    if (v is String) return int.tryParse(v) == 2;
    return false;
  }

  static Future<DriverAutoActivationResult> tryAutoActivate() async {
    if (!loggedIn || currentUserReference == null) {
      return const DriverAutoActivationResult.fail('AUTH_REQUIRED');
    }

    final doc = currentUserDocument;
    if (_isRegistrationV2(doc)) {
      debugPrint(
        'DriverAutoActivationService: skipped (registration_flow_version=2)',
      );
      return const DriverAutoActivationResult.fail(
        'AUTO_ACTIVATE_DISABLED_FOR_REGISTRATION_V2',
      );
    }

    if (doc != null &&
        doc.actevMndob == true &&
        doc.registrationStatus.trim().toLowerCase() == 'approved') {
      return const DriverAutoActivationResult.ok(alreadyActive: true);
    }

    final body = await makeCloudCall('autoActivateDriver', {});
    if (body['ok'] == true) {
      try {
        currentUserDocument =
            await UserRecord.getDocumentOnce(currentUserReference!);
      } catch (e) {
        debugPrint('DriverAutoActivationService reload: $e');
      }
      return DriverAutoActivationResult.ok(
        alreadyActive: body['action'] == 'already_active',
      );
    }

    final code = body['code']?.toString() ?? body['error']?.toString();
    debugPrint('DriverAutoActivationService failed: $code');
    return DriverAutoActivationResult.fail(code ?? 'auto_activate_failed');
  }
}
