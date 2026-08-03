import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_app_options.dart';
import '/core/toury_cache_config.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: FirebaseAppOptions.web);
  } else {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: TouryCacheConfig.firestoreCacheBytes,
    );
  }
  FirebaseAppOptions.warnIfTutorialProjectInRelease();
}
