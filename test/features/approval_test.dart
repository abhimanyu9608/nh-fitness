import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/core/format.dart';
import 'package:nh_fitness/data/repositories/payment_repository.dart';

void main() {
  group('approvalStartDay (PRD ADM-2)', () {
    test('starts today for a member who has never joined', () {
      expect(approvalStartDay(null), istToday());
    });

    test('starts today when the last membership has already ended', () {
      final lapsed = istToday().subtract(const Duration(days: 30));
      expect(approvalStartDay(lapsed), istToday());
    });

    test('starts the day after a membership that ends in the future', () {
      // The worked example in PRD section 11: a plan ending 10 Jan, renewed on
      // 5 Jan, starts 11 Jan.
      final endsOn = istDay(2027, 1, 10);
      expect(
        approvalStartDay(endsOn, approvedOn: istDay(2027, 1, 5)),
        istDay(2027, 1, 11),
      );
    });

    test('starts tomorrow when the current membership ends today', () {
      // "ends today or later" counts today, so the new plan starts tomorrow
      // rather than overlapping the last day.
      expect(
        approvalStartDay(istToday()),
        istToday().add(const Duration(days: 1)),
      );
    });

    test('stacks a renewal on top of an upcoming membership', () {
      final endsOn = istToday().add(const Duration(days: 300));
      expect(
        approvalStartDay(endsOn),
        istToday().add(const Duration(days: 301)),
      );
    });
  });

  group('the renewal flow end to end (PRD section 11)', () {
    test('a yearly renewal picks up the day after the current plan ends', () {
      // Current plan ends 10 Jan 2027; the member renews on 5 Jan.
      final currentEnd = istDay(2027, 1, 10);
      final start = approvalStartDay(currentEnd, approvedOn: istDay(2027, 1, 5));
      final end = membershipEndDate(start, 12);

      expect(start, istDay(2027, 1, 11));
      expect(end, istDay(2028, 1, 10));
      // No gap and no overlap between the two memberships.
      expect(daysBetween(currentEnd, start), 1);
    });

    test('a first yearly membership approved today runs 365 days', () {
      final start = approvalStartDay(null, approvedOn: istDay(2026, 11, 9));
      final end = membershipEndDate(start, 12);
      expect(end, istDay(2027, 11, 8));
      expect(daysBetween(start, end) + 1, 365);
    });
  });
}
