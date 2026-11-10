import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nh_fitness/app/theme.dart';
import 'package:nh_fitness/core/widgets/offline_bar.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/plan.dart';
import 'package:nh_fitness/data/repositories/admin_repository.dart';
import 'package:nh_fitness/data/repositories/announcement_repository.dart';
import 'package:nh_fitness/data/repositories/auth_repository.dart';
import 'package:nh_fitness/data/repositories/plan_repository.dart';
import 'package:nh_fitness/data/repositories/settings_repository.dart';
import 'package:nh_fitness/features/explore/explore_screen.dart';
import 'package:nh_fitness/features/home/home_screen.dart';
import 'package:nh_fitness/features/plans/plans_screen.dart';
import 'package:nh_fitness/l10n/app_localizations.dart';

import 'harness.dart';

/// Whole-page layout smoke tests.
///
/// These exist because two layout bugs shipped that no leaf-widget test could
/// see: a Row using `CrossAxisAlignment.stretch` inside a scroll view (which
/// threw on infinite height and blanked every section of the page), and a hero
/// with a hard-coded height that overflowed on a short window. Both only
/// appear when a real page is laid out at a real window size.
///
/// Horizontal overflow is deliberately ignored. `google_fonts` cannot fetch
/// Barlow Condensed inside a test, so every label falls back to a much wider
/// default face and the text-heavy header reports an overflow the real app —
/// rendering in a condensed font — does not have. Vertical overflow and
/// unbounded-constraint errors do not depend on glyph widths, and they are
/// exactly what these tests are for.
bool _isFontWidthArtifact(String message) =>
    message.contains('overflowed') && message.contains('on the right');

void main() {
  setUpAll(useOfflineFonts);

  final overrides = <Override>[
    settingsProvider.overrideWith((ref) async => AppSettings.defaults),
    activePlansProvider.overrideWith((ref) async => Plan.defaults),
    liveAnnouncementsProvider.overrideWith((ref) async => const []),
    isAdminProvider.overrideWith((ref) async => false),
    isOfflineProvider.overrideWith((ref) => Stream.value(false)),
    authStateProvider.overrideWith((ref) => Stream.value(null)),
    currentUidProvider.overrideWith((ref) => null),
  ];

  /// Lays the page out at [size] and returns the layout errors worth failing
  /// over.
  ///
  /// Errors are captured through `FlutterError.onError` rather than
  /// `tester.takeException()`, because the test binding collapses several
  /// exceptions into one opaque "Multiple exceptions were detected" summary
  /// that cannot be filtered.
  Future<List<String>> layoutErrorsFor(
    WidgetTester tester,
    String path,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final captured = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) =>
        captured.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previousOnError);

    // The public pages live inside the site shell, which reads the router, so
    // a real GoRouter is needed rather than a bare `home:`.
    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
        GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
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
          routerConfig: router,
          // Switches off the looping animations, which never settle.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );

    // Layout assertions throw on the first frames; the network images resolve
    // later and would only add noise.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    FlutterError.onError = previousOnError;
    return captured.where((e) => !_isFontWidthArtifact(e)).toList();
  }

  /// A deliberately short desktop window — the one the hero overflowed on.
  const sizes = <String, Size>{
    'large desktop': Size(1920, 1080),
    'laptop': Size(1536, 695),
    'small desktop': Size(1024, 700),
    'tablet': Size(820, 900),
    'phone': Size(390, 844),
    'short phone': Size(360, 640),
  };

  for (final path in ['/', '/explore', '/plans']) {
    group('$path lays out cleanly', () {
      sizes.forEach((label, size) {
        testWidgets('at $label (${size.width.toInt()}x${size.height.toInt()})',
            (tester) async {
          expect(
            await layoutErrorsFor(tester, path, size),
            isEmpty,
            reason: '$path failed to lay out at $label',
          );
        });
      });
    });
  }

  testWidgets('home shows the hero headline and the plan prices',
      (tester) async {
    expect(
      await layoutErrorsFor(tester, '/', const Size(1536, 900)),
      isEmpty,
    );

    expect(textContaining('STRONGER THAN'), findsOneWidget);
    expect(textContaining('YESTERDAY'), findsOneWidget);
    // PRD HOME-1: the prices come from the plan list, not from the widget.
    expect(textContaining('₹15,000'), findsWidgets);
  });
}
