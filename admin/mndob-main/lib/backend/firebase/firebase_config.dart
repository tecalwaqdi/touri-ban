import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY",
            authDomain: "tutorial-multi-language-70gx4j.firebaseapp.com",
            projectId: "tutorial-multi-language-70gx4j",
            storageBucket: "tutorial-multi-language-70gx4j.firebasestorage.app",
            messagingSenderId: "638010533068",
            appId: "1:638010533068:web:cd138c3c2424cbef844e69"));
  } else {
    await Firebase.initializeApp();
  }
}
