import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive.dart';
import '../core/widgets/nh_logo.dart';
import '../data/repositories/auth_repository.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// The app. Waits for Firebase Auth's first answer before handing over to the
/// router, so a logged-in member never sees the login screen flash past.
class NHApp extends ConsumerWidget {
  const NHApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    if (!auth.hasValue && !auth.hasError) {
      return const _SplashApp();
    }

    return MaterialApp.router(
      title: 'NH Fitness',
      debugShowCheckedModeBanner: false,
      theme: buildNHTheme(),
      // PRD section 5: dark theme only, on every device.
      darkTheme: buildNHTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      // PRD section 13: English only in Phase 1. Adding `lib/l10n/app_hi.arb`
      // is all it takes to offer Hindi later.
      locale: const Locale('en'),
      builder: (context, child) => _TextScaleGuard(child: child),
    );
  }
}

/// Keeps a very large system font from breaking the display type, while still
/// honouring the member's preference up to a point (PRD section 13
/// accessibility).
class _TextScaleGuard extends StatelessWidget {
  const _TextScaleGuard({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.4),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildNHTheme(),
      home: const Scaffold(
        backgroundColor: NHColors.bg,
        body: Center(child: NHLogo(size: 36)),
      ),
    );
  }
}

/// Shown when `Firebase.initializeApp` fails — almost always because
/// `flutterfire configure` has not been run yet (PRD section 4 step 8).
///
/// A readable screen beats a red crash: the owner can see exactly what to do.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildNHTheme(),
      home: Scaffold(
        backgroundColor: NHColors.bg,
        body: Center(
          child: SingleChildScrollView(
            child: ContentWidth(
              maxWidth: 620,
              padVertical: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NHLogo(size: 32),
                  const SizedBox(height: 28),
                  Text(
                    'FIREBASE IS NOT CONNECTED YET',
                    style: NHText.display(size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Run this in the project folder, then start the app again:',
                    style: NHText.body(color: NHColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NHColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NHColors.line, width: 2),
                    ),
                    child: Text(
                      'dart pub global activate flutterfire_cli\n'
                      'flutterfire configure --project=nh-fitness-8a972',
                      style: NHText.body(size: 14.5).copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Courier New'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    details,
                    style: NHText.body(size: 13, color: NHColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
