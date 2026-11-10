import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/app/router.dart';
import 'package:nh_fitness/core/format.dart';
import 'package:nh_fitness/data/models/app_user.dart';
import 'package:nh_fitness/features/admin/member_status.dart';

void main() {
  group('safeNextPath', () {
    test('keeps an in-app path, query string and all', () {
      // PRD PAY-5: checkout has to come back with the same plan selected.
      expect(safeNextPath('/checkout?plan=yearly&pt=1'),
          '/checkout?plan=yearly&pt=1');
      expect(safeNextPath('/account/classes'), '/account/classes');
    });

    test('refuses to send a member off to another site after login', () {
      expect(safeNextPath('https://evil.example.com'), isNull);
      expect(safeNextPath('//evil.example.com'), isNull);
      expect(safeNextPath('evil.example.com'), isNull);
    });

    test('treats a missing or empty value as "no destination"', () {
      expect(safeNextPath(null), isNull);
      expect(safeNextPath(''), isNull);
    });
  });

  group('Routes.memberPrefixes', () {
    test('covers the member-only areas from PRD section 6', () {
      expect(
        Routes.memberPrefixes.any('/account/payments'.startsWith),
        isTrue,
      );
      expect(Routes.memberPrefixes.any('/checkout'.startsWith), isTrue);
      expect(
        Routes.memberPrefixes.any('/checkout/submitted'.startsWith),
        isTrue,
      );
    });

    test('leaves the public pages alone', () {
      for (final path in ['/', '/explore', '/plans', '/privacy', '/login']) {
        expect(
          Routes.memberPrefixes.any(path.startsWith),
          isFalse,
          reason: '$path should stay public',
        );
      }
    });
  });

  group('memberStatusOf (PRD section 7.10 filters)', () {
    AppUser user(DateTime? activeUntil, {bool hasJoined = true}) => AppUser(
      uid: 'u',
      name: 'Ravi',
      email: 'ravi@example.com',
      hasJoined: hasJoined,
      activeUntil: activeUntil,
    );

    test('a member with no membership has never joined', () {
      expect(memberStatusOf(user(null, hasJoined: false)),
          MemberStatus.neverJoined);
    });

    test('a membership well in the future is active', () {
      expect(
        memberStatusOf(user(istToday().add(const Duration(days: 60)))),
        MemberStatus.active,
      );
    });

    test('7 days or fewer left counts as expiring soon', () {
      expect(
        memberStatusOf(user(istToday().add(const Duration(days: 6)))),
        MemberStatus.expiringSoon,
      );
      // The last day still counts as expiring soon, not expired.
      expect(memberStatusOf(user(istToday())), MemberStatus.expiringSoon);
    });

    test('8 days left is just active', () {
      expect(
        memberStatusOf(user(istToday().add(const Duration(days: 7)))),
        MemberStatus.active,
      );
    });

    test('a past end date is expired', () {
      expect(
        memberStatusOf(user(istToday().subtract(const Duration(days: 1)))),
        MemberStatus.expired,
      );
    });
  });
}
