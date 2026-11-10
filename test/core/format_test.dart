import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/core/format.dart';

void main() {
  group('Asia/Kolkata calendar days (PRD section 8)', () {
    test('istDay stores 00:00 IST, which is 18:30 UTC the day before', () {
      final day = istDay(2026, 11, 9);
      expect(day.isUtc, isTrue);
      expect(day.toIso8601String(), '2026-11-08T18:30:00.000Z');
    });

    test('istCivil reads an instant back as an IST wall clock', () {
      // 18:40 UTC on 8 Nov is already 00:10 on 9 Nov in India.
      final civil = istCivil(DateTime.utc(2026, 11, 8, 18, 40));
      expect(civil.year, 2026);
      expect(civil.month, 11);
      expect(civil.day, 9);
      expect(civil.hour, 0);
      expect(civil.minute, 10);
    });

    test('istDayOf snaps any instant to the start of its IST day', () {
      // 18:00 UTC is still 23:30 on the 8th in India, not the 9th.
      expect(istDayOf(DateTime.utc(2026, 11, 8, 18, 0)), istDay(2026, 11, 8));
      expect(istDayOf(DateTime.utc(2026, 11, 8, 19, 0)), istDay(2026, 11, 9));
    });

    test('isSameIstDay ignores the time of day', () {
      expect(
        isSameIstDay(
          DateTime.utc(2026, 11, 8, 19, 0),
          DateTime.utc(2026, 11, 9, 10, 0),
        ),
        isTrue,
      );
    });
  });

  group('addMonthsToDay', () {
    test('adds whole calendar months', () {
      expect(addMonthsToDay(istDay(2026, 1, 15), 1), istDay(2026, 2, 15));
      expect(addMonthsToDay(istDay(2026, 1, 15), 12), istDay(2027, 1, 15));
    });

    test('clamps to the end of a shorter month', () {
      // 31 Jan + 1 month has no 31 Feb, so it lands on the 28th.
      expect(addMonthsToDay(istDay(2026, 1, 31), 1), istDay(2026, 2, 28));
      // 2028 is a leap year.
      expect(addMonthsToDay(istDay(2028, 1, 31), 1), istDay(2028, 2, 29));
    });

    test('rolls over the year boundary', () {
      expect(addMonthsToDay(istDay(2026, 11, 9), 3), istDay(2027, 2, 9));
    });
  });

  group('membershipEndDate (PRD ADM-2)', () {
    test('is startDate + months − 1 day', () {
      // A 1-month plan starting 9 Nov runs to 8 Dec inclusive.
      expect(membershipEndDate(istDay(2026, 11, 9), 1), istDay(2026, 12, 8));
      // A yearly plan starting 9 Nov 2026 runs to 8 Nov 2027.
      expect(membershipEndDate(istDay(2026, 11, 9), 12), istDay(2027, 11, 8));
    });

    test('a 3-month plan from the 1st ends on the last day of the third month', () {
      expect(membershipEndDate(istDay(2026, 1, 1), 3), istDay(2026, 3, 31));
    });
  });

  group('daysLeftUntil (PRD ACC-1)', () {
    test('counts the end date itself, so today is the last day', () {
      expect(daysLeftUntil(istToday()), 1);
    });

    test('counts whole days ahead', () {
      expect(daysLeftUntil(istToday().add(const Duration(days: 6))), 7);
    });

    test('never goes negative for a plan that has ended', () {
      expect(daysLeftUntil(istToday().subtract(const Duration(days: 1))), 0);
      expect(daysLeftUntil(istToday().subtract(const Duration(days: 400))), 0);
    });
  });

  test('daysBetween counts whole days', () {
    expect(daysBetween(istDay(2026, 11, 9), istDay(2026, 11, 16)), 7);
    expect(daysBetween(istDay(2026, 11, 16), istDay(2026, 11, 9)), -7);
  });

  group('money (PRD section 13)', () {
    test('uses the Indian grouping and no paise', () {
      expect(formatRupees(1500), '₹1,500');
      expect(formatRupees(15000), '₹15,000');
      // Lakhs group in twos, not threes.
      expect(formatRupees(120000), '₹1,20,000');
      expect(formatRupees(0), '₹0');
    });
  });

  group('perMonthPrice (PRD section 7.3)', () {
    test('rounds to the rupee', () {
      expect(perMonthPrice(15000, 12), 1250);
      expect(perMonthPrice(4000, 3), 1333);
      expect(perMonthPrice(7800, 6), 1300);
    });

    test('treats a one-month plan as its own price', () {
      expect(perMonthPrice(1500, 1), 1500);
    });

    test('does not divide by zero on a malformed plan', () {
      expect(perMonthPrice(1500, 0), 1500);
    });
  });

  group('currentIstMonthRange', () {
    test('spans the first of this month to the first of the next', () {
      final range = currentIstMonthRange();
      final start = istCivil(range.start);
      expect(start.day, 1);
      expect(range.end.isAfter(range.start), isTrue);
      expect(istCivil(range.end).day, 1);
    });
  });

  group('firstName', () {
    test('takes the first word', () {
      expect(firstName('Ravi Kumar Sharma'), 'Ravi');
      expect(firstName('  Ravi  '), 'Ravi');
    });

    test('falls back politely on an empty name', () {
      expect(firstName(''), 'there');
      expect(firstName('   '), 'there');
    });
  });

  group('youtubeVideoId', () {
    test('reads every common YouTube link shape', () {
      const id = 'dQw4w9WgXcQ';
      expect(youtubeVideoId('https://youtu.be/$id'), id);
      expect(youtubeVideoId('https://www.youtube.com/watch?v=$id'), id);
      expect(youtubeVideoId('https://www.youtube.com/watch?v=$id&t=30s'), id);
      expect(youtubeVideoId('https://www.youtube.com/embed/$id'), id);
      expect(youtubeVideoId('https://www.youtube.com/shorts/$id'), id);
      expect(youtubeVideoId(id), id);
    });

    test('returns null for anything that is not a video link', () {
      expect(youtubeVideoId(''), isNull);
      expect(youtubeVideoId('https://example.com/video'), isNull);
      expect(youtubeVideoId('https://youtu.be/tooshort'), isNull);
    });
  });
}
