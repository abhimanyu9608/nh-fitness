import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/path_url_strategy.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PRD section 3: path URLs on the web, no `#`.
  configurePathUrlStrategy();

  if (DefaultFirebaseOptions.isPlaceholder) {
    runApp(const FirebaseSetupApp(
      details: 'lib/firebase_options.dart still holds placeholder values.',
    ));
    return;
  }

  try {
    // The timeout matters: if this never completes, `runApp` is never reached
    // and the user is left staring at a blank page with nothing to go on.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  } catch (error) {
    // Catch-all rather than `on Exception`: a misconfigured Firebase web SDK
    // can surface a plain JS `Error`, which is not an `Exception`.
    runApp(FirebaseSetupApp(details: '$error'));
    return;
  }

  runApp(const ProviderScope(child: NHApp()));
}
