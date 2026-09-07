import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/backend/admin_finance_route_trace.dart';
import '/backend/admin_firestore_web_config.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY",
            authDomain: "tutorial-multi-language-70gx4j.firebaseapp.com",
            projectId: "tutorial-multi-language-70gx4j",
            storageBucket: "tutorial-multi-language-70gx4j.firebasestorage.app",
            messagingSenderId: "638010533068",
            appId: "1:638010533068:web:cd138c3c2424cbef844e69"));
    AdminFinanceRouteTrace.noteFirebaseInit();
    // PERF-P4C: apply web transport/cache policy before any Firestore use.
    AdminFirestoreWebConfig.applyOnce(isWeb: true);
    AdminFinanceRouteTrace.noteFirestoreSettings();
  } else {
    await Firebase.initializeApp();
    AdminFinanceRouteTrace.noteFirebaseInit();
    AdminFirestoreWebConfig.applyOnce(isWeb: false);
    AdminFinanceRouteTrace.noteFirestoreSettings();
  }
}
