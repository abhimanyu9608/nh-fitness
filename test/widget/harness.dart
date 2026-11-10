import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 moved the `Override` type out of the main barrel file.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nh_fitness/app/theme.dart';
import 'package:nh_fitness/core/widgets/offline_bar.dart';
import 'package:nh_fitness/l10n/app_localizations.dart';

/// Wraps a widget in everything the app's widgets expect: the provider scope,
/// the real theme, and the generated localizations.
///
/// Animations are switched off through `disableAnimations`, which is also the
/// path PRD section 5.4 takes for "reduce motion" — so these tests exercise
/// that branch and never wait on a looping animation.
Widget harness({
  required Widget child,
  List<Override> overrides = const [],
  Size size = const Size(1280, 1600),
}) {
  return ProviderScope(
    overrides: [
      // Nothing in a test should decide the app is offline.
      isOfflineProvider.overrideWith((ref) => Stream.value(false)),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildNHTheme(),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: true),
        child: Scaffold(
          backgroundColor: NHColors.bg,
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
}

/// Call once per test file: keeps `google_fonts` from reaching for the network,
/// which a widget test cannot do anyway.
void useOfflineFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Finds a Text widget whose content contains [substring], however the string
/// was assembled.
Finder textContaining(String substring) => find.byWidgetPredicate(
  (widget) => widget is Text && (widget.data ?? '').contains(substring),
  description: 'Text containing "$substring"',
);
