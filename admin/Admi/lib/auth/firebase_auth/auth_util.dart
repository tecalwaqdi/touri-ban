import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stream_transform/stream_transform.dart';

import '/backend/admin_panel_session.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/auth/auth_claims.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/nav/nav.dart';
import 'firebase_auth_manager.dart';

export 'firebase_auth_manager.dart';

final _authManager = FirebaseAuthManager();
FirebaseAuthManager get authManager => _authManager;

String get currentUserEmail =>
    currentUserDocument?.email ?? currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto =>
    currentUserDocument?.photoUrl ?? currentUser?.photoUrl ?? '';

String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .map((user) async {
      _currentJwtToken = await user?.getIdToken();
      if (user != null) {
        await AdminRoleService.refreshClaims(forceRefresh: true);
      } else {
        AuthClaims.clearCache();
        AdminRoleService.bindClaims(AuthClaims.fromToken(null));
        AdminRoleService.bindProfile(null);
      }
      return _currentJwtToken;
    })
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UserRecord.collection.doc(currentUser!.uid) : null;

UserRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UserRecord.getDocument(UserRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  final hadProfile = currentUserDocument != null;
  final prevRole = AdminRoleService.roleFrom(currentUserDocument);
  currentUserDocument = user;
  AdminRoleService.bindProfile(user);
  if (user != null && loggedIn) {
    final newRole = AdminRoleService.roleFrom(user);
    if (!hadProfile || prevRole != newRole) {
      AppStateNotifier.instance.notifyProfileReady();
    }
    if (!hadProfile && AdminRoleService.hasPanelAccess) {
      unawaited(AdminPanelSession.ensureScopeReady());
    } else if (prevRole != newRole && AdminRoleService.hasPanelAccess) {
      unawaited(AdminPanelSession.ensureScopeReady(force: true));
    }
  }
  return currentUserDocument;
}).asBroadcastStream();

/// Loads the Firestore profile for the signed-in user (direct read, not stream).
Future<UserRecord?> ensureCurrentUserDocument({
  Duration timeout = const Duration(seconds: 20),
  bool forceRefresh = false,
}) async {
  var ref = currentUserReference;
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (ref == null && firebaseUser != null) {
    ref = UserRecord.collection.doc(firebaseUser.uid);
  }
  if (ref == null) return null;

  if (!forceRefresh &&
      currentUserDocument != null &&
      currentUserDocument!.reference.path == ref.path &&
      AdminRoleService.hasPanelAccess) {
    return currentUserDocument;
  }

  try {
    final snap = await ref
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(timeout);
    if (!snap.exists) return null;
    var doc = UserRecord.fromSnapshot(snap);
    currentUserDocument = doc;
    AdminRoleService.bindProfile(doc);
    await _syncClaimsFromServer();

    // After login, refresh from server when cache may lack admin role fields.
    if (forceRefresh && !AdminRoleService.hasPanelAccess) {
      try {
        final serverSnap = await ref
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 12));
        if (serverSnap.exists) {
          doc = UserRecord.fromSnapshot(serverSnap);
          currentUserDocument = doc;
          AdminRoleService.bindProfile(doc);
        }
      } catch (_) {}
    }

    return currentUserDocument;
  } catch (_) {
    try {
      final doc = await UserRecord.getDocumentOnce(ref).timeout(
        const Duration(seconds: 8),
      );
      currentUserDocument = doc;
      AdminRoleService.bindProfile(doc);
      return doc;
    } catch (_) {
      return currentUserDocument;
    }
  }
}

Future<void> refreshAuthClaims() async {
  try {
    await CloudFunctionsClient.refreshMyClaims();
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    await AdminRoleService.refreshClaims(forceRefresh: true);
  } catch (_) {}
}

Future<void> _syncClaimsFromServer() => refreshAuthClaims();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.builder})
      : super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}
