import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_phone_util.dart';
import '/core/toury_profile_state.dart';
import 'package:stream_transform/stream_transform.dart';
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

String get currentPhoneNumber {
  final doc = currentUserDocument;
  final fromDoc = doc?.phoneNumber.trim() ?? '';
  if (TouryPhoneUtil.digitsOnly(fromDoc).length >= 7) return fromDoc;
  final n = doc?.phoneN ?? 0;
  if (n > 0) return n.toString();
  return currentUser?.phoneNumber ?? '';
}

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .asyncMap((user) async {
      if (user == null) {
        _currentJwtToken = null;
        return null;
      }
      try {
        return _currentJwtToken = await user.getIdToken();
      } catch (_) {
        return _currentJwtToken;
      }
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
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: TouryProfileState.refreshTick,
        builder: (context, _) => StreamBuilder<UserRecord?>(
          stream: authenticatedUserStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              currentUserDocument = snapshot.data;
            }
            return builder(context);
          },
        ),
      );
}
