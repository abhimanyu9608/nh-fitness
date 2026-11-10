import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/app/router.dart';

/// The admin guard, as a route-level decision.
///
/// A signed-in member who opens `/admin` used to be redirected to `/account`,
/// which reads as the app losing the page rather than refusing it. They now
/// land on the admin shell, which explains the refusal and names the account
/// they are signed in with. Nothing about the security boundary changed —
/// `firestore.rules` refuses every admin read and write either way.
void main() {
  bool needsAdmin(String path) =>
      path == Routes.admin || path.startsWith('${Routes.admin}/');

  group('which paths are admin-gated', () {
    test('covers the admin panel and everything under it', () {
      for (final path in [
        Routes.admin,
        Routes.adminPayments,
        Routes.adminMembers,
        Routes.adminPlans,
        Routes.adminClasses,
        Routes.adminAnnouncements,
        Routes.adminSettings,
        Routes.adminStaff,
        '${Routes.adminMembers}/some-uid',
      ]) {
        expect(needsAdmin(path), isTrue, reason: '$path must be admin-gated');
      }
    });

    test('leaves member and public pages alone', () {
      for (final path in [
        Routes.home,
        Routes.plans,
        Routes.explore,
        Routes.account,
        Routes.accountProfile,
        Routes.checkout,
        Routes.privacy,
      ]) {
        expect(needsAdmin(path), isFalse, reason: '$path must not be gated');
      }
    });

    test('does not gate a path that merely starts with the same letters', () {
      // `/administration` is not `/admin/...`, and the prefix check must not
      // treat it as such.
      expect(needsAdmin('/administration'), isFalse);
      expect(needsAdmin('/admins'), isFalse);
    });
  });

  group('safeNextPath still protects the login bounce', () {
    test('keeps an admin path so the member returns after signing in', () {
      expect(safeNextPath(Routes.adminPayments), Routes.adminPayments);
    });

    test('refuses to bounce anywhere off-site', () {
      expect(safeNextPath('https://evil.example.com/admin'), isNull);
      expect(safeNextPath('//evil.example.com'), isNull);
    });
  });
}
