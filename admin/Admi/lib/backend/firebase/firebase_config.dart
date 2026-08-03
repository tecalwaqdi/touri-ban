import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    // Offline cache for web — instant repeat loads (ideal for KSA users).
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (_) {}
  } else {
    await Firebase.initializeApp();
    // Unlimited local cache: show cached data immediately, sync in background.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
