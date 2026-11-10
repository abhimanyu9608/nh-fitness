// PLACEHOLDER — replace this whole file by running, in the project root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=nh-fitness-8a972
//
// That writes the real `lib/firebase_options.dart` for web, Android and iOS
// (PRD section 4, step 8).
//
// These values are not secrets — the Firebase web config ships inside every
// web app. Security comes from the Firestore rules (PRD section 9). Never put a
// service-account key in this repo.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// The one value every platform shares. Keep it even after regenerating.
const nhFirebaseProjectId = 'nh-fitness-8a972';

const _placeholder = 'REPLACE_ME';

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  /// True until `flutterfire configure` has written the real values.
  ///
  /// `main.dart` checks this so the app can show setup instructions instead of
  /// crashing on a half-configured machine.
  static bool get isPlaceholder => currentPlatform.apiKey == _placeholder;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ => throw UnsupportedError(
          'NH Fitness targets web, Android and iOS only (PRD section 3). '
          '$defaultTargetPlatform is not configured.',
        ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoaxaWI4GsqCOOe1u7ZwKyyO14FI-o_Wc',
    appId: '1:379882726974:web:bad620b564dbd4ae0a936f',
    messagingSenderId: '379882726974',
    projectId: 'nh-fitness-8a972',
    authDomain: 'nh-fitness-8a972.firebaseapp.com',
    storageBucket: 'nh-fitness-8a972.firebasestorage.app',
    measurementId: 'G-21RMHKJ47S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDg1oTuVQ7OVk3M5Z1vdhf70NdVnldIGKc',
    appId: '1:379882726974:android:722e955035b886f80a936f',
    messagingSenderId: '379882726974',
    projectId: 'nh-fitness-8a972',
    storageBucket: 'nh-fitness-8a972.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYfxOXz5G14fK_vauMPEkHvAHzFPMeVzc',
    appId: '1:379882726974:ios:7880eab4274ba8f90a936f',
    messagingSenderId: '379882726974',
    projectId: 'nh-fitness-8a972',
    storageBucket: 'nh-fitness-8a972.firebasestorage.app',
    iosClientId: '379882726974-7ejdnb5r5slcvbjpsk8egehqos0be5ld.apps.googleusercontent.com',
    iosBundleId: 'com.nhfitness.app',
  );
}
