import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/schema/user_record.dart';

/// PERF-P3F — keeps [authenticatedUserStream] subscribed for the panel session.
///
/// Without this, disposing [AuthUserStreamWidget] on every route (sidebar remount)
/// can drop the last listener and cancel [UserRecord.getDocument] snapshots,
/// causing a fresh profile listen on the next page.
abstract final class AdminAuthSessionOwner {
  AdminAuthSessionOwner._();

  static StreamSubscription<UserRecord?>? _sub;

  static bool get isActive => _sub != null;

  static void ensureStarted() {
    if (_sub != null) return;
    AdminPerfTrace.authSessionOwnerStart();
    _sub = authenticatedUserStream.listen((_) {});
  }

  static void stop() {
    if (_sub == null) return;
    _sub!.cancel();
    _sub = null;
    AdminPerfTrace.authSessionOwnerStop();
  }
}
