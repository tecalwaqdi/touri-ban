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

/// Temporary cash-wave path: activates driver accounts immediately after
/// registration. Replace with admin review when the approval flow is ready.
abstract final class DriverAutoActivationService {
  DriverAutoActivationService._();

  static Future<DriverAutoActivationResult> tryAutoActivate() async {
    if (!loggedIn || currentUserReference == null) {
      return const DriverAutoActivationResult.fail('AUTH_REQUIRED');
    }

    final doc = currentUserDocument;
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
