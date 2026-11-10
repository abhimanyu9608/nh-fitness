import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/plan.dart';
import 'package:nh_fitness/data/repositories/plan_repository.dart';
import 'package:nh_fitness/data/repositories/settings_repository.dart';
import 'package:nh_fitness/features/explore/path_cards.dart';

import 'harness.dart';

/// Regression test for a layout crash that took the whole public site down.
///
/// `PathCards` laid its desktop row out with `CrossAxisAlignment.stretch`, which
/// makes a Row adopt its parent's height. Inside a scroll view that height is
/// infinite, so layout threw — and because the failure happens during the
/// parent Column's layout, *every* section on Home went blank, not just this
/// one. The header still rendered, which made it look like a data problem
/// rather than a layout one.
void main() {
  setUpAll(useOfflineFonts);

  final overrides = [
    settingsProvider.overrideWith((ref) async => AppSettings.defaults),
    activePlansProvider.overrideWith((ref) async => Plan.defaults),
  ];

  /// One pump is enough: a layout assertion throws during the first frame,
  /// while the network images resolve later and would only add noise.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    await tester.pumpWidget(
      harness(child: const PathCards(), overrides: overrides, size: size),
    );
    await tester.pump();
  }

  testWidgets('lays out inside a scroll view at desktop width', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out at the 1024 px desktop breakpoint', (tester) async {
    await pumpAt(tester, const Size(1024, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out at tablet width', (tester) async {
    await pumpAt(tester, const Size(800, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out at mobile width', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the big card and the stack beside it are the same height',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(tester.takeException(), isNull);

    // Both sides stretch to the row, so measuring the row measures both. It
    // has to be at least as tall as the three stacked cards need, or the
    // stack overflows — which is what a fixed height got wrong before.
    final row = tester.getSize(find.byType(IntrinsicHeight));
    expect(row.height, greaterThanOrEqualTo(pathCardHeight * 3 + 14 * 2));
  });
}
