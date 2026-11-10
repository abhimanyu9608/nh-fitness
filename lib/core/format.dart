import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Money and date helpers.
///
/// PRD section 13: every date calculation uses Asia/Kolkata, and money is shown
/// with the Indian grouping (`₹15,500`, `₹1,20,000`).
///
/// India has never used daylight saving time, so Asia/Kolkata is a fixed
/// UTC+05:30 offset. That lets the whole app do IST date maths without pulling
/// in a timezone database.
const istOffset = Duration(hours: 5, minutes: 30);

/// A calendar day as stored in Firestore: the instant of 00:00 Asia/Kolkata on
/// that day (PRD section 8).
DateTime istDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).subtract(istOffset);

/// Reads `instant` as an Asia/Kolkata wall clock.
///
/// The returned `DateTime` is only for reading its `year`/`month`/`day`/`hour`
/// fields — it is not the same point in time, so never store it.
DateTime istCivil(DateTime instant) => instant.toUtc().add(istOffset);

/// The calendar day (00:00 Asia/Kolkata) that `instant` falls on.
DateTime istDayOf(DateTime instant) {
  final civil = istCivil(instant);
  return istDay(civil.year, civil.month, civil.day);
}

/// Today in the gym's timezone, as 00:00 Asia/Kolkata.
DateTime istToday() => istDayOf(DateTime.now());

int _daysInMonth(int year, int month) {
  // Day 0 of the next month is the last day of this one.
  return DateTime.utc(year, month + 1, 0).day;
}

/// `day` moved forward by whole calendar months, clamped to the end of the
/// month (31 Jan + 1 month = 28 Feb).
DateTime addMonthsToDay(DateTime day, int months) {
  final civil = istCivil(day);
  final zeroBased = civil.month - 1 + months;
  final year = civil.year + (zeroBased >= 0 ? zeroBased ~/ 12 : (zeroBased - 11) ~/ 12);
  final month = zeroBased % 12 + 1;
  return istDay(year, month, math.min(civil.day, _daysInMonth(year, month)));
}

/// PRD ADM-2: `endDate = startDate + months − 1 day`.
DateTime membershipEndDate(DateTime startDay, int months) =>
    addMonthsToDay(startDay, months).subtract(const Duration(days: 1));

/// PRD ACC-1: whole days from today to `endDay` in Asia/Kolkata, counting the
/// end date itself. Never negative, so an ended plan reads as 0.
int daysLeftUntil(DateTime endDay) {
  final days = istDayOf(endDay).difference(istToday()).inDays + 1;
  return days < 0 ? 0 : days;
}

/// Whole days between two calendar days.
int daysBetween(DateTime fromDay, DateTime toDay) =>
    istDayOf(toDay).difference(istDayOf(fromDay)).inDays;

bool isSameIstDay(DateTime a, DateTime b) =>
    istDayOf(a).isAtSameMomentAs(istDayOf(b));

/// Money is stored as whole rupees (PRD section 8), so there are no paise to
/// show. `₹15,500`, `₹1,20,000`.
final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatRupees(num amount) => _rupees.format(amount);

/// Plain grouped digits with no symbol, for text fields and CSV-ish places.
final _plainNumber = NumberFormat.decimalPattern('en_IN');

String formatNumber(num value) => _plainNumber.format(value);

final _dayMonthYear = DateFormat('d MMM yyyy', 'en_IN');
final _dayMonth = DateFormat('d MMM', 'en_IN');
final _dayMonthYearTime = DateFormat('d MMM yyyy, h:mm a', 'en_IN');

/// `9 Nov 2026`, always read in Asia/Kolkata.
String formatDate(DateTime instant) => _dayMonthYear.format(istCivil(instant));

/// `9 Nov`, for compact rows.
String formatDayMonth(DateTime instant) => _dayMonth.format(istCivil(instant));

/// `9 Nov 2026, 7:05 pm`, for submission and review times.
String formatDateTime(DateTime instant) =>
    _dayMonthYearTime.format(istCivil(instant)).replaceAll('AM', 'am').replaceAll('PM', 'pm');

/// The month a payment belongs to, for the admin income tile: `Nov 2026`.
String formatMonth(DateTime instant) =>
    DateFormat('MMM yyyy', 'en_IN').format(istCivil(instant));

/// First and last instant of the current Asia/Kolkata month, used by the
/// "Income this month" tile (PRD section 7.10).
({DateTime start, DateTime end}) currentIstMonthRange() {
  final civil = istCivil(DateTime.now());
  final start = istDay(civil.year, civil.month, 1);
  final end = addMonthsToDay(start, 1);
  return (start: start, end: end);
}

/// Greeting uses the first word of the member's name (PRD section 7.6).
String firstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'there';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Per-month price shown on plan cards, rounded to the rupee (PRD section 7.3).
int perMonthPrice(int price, int months) =>
    months <= 0 ? price : (price / months).round();

/// Pulls the 11-character video id out of any common YouTube URL shape:
/// `youtu.be/ID`, `watch?v=ID`, `/embed/ID`, `/shorts/ID`, or a bare id.
String? youtubeVideoId(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;

  final match = RegExp(
    r'(?:youtu\.be/|v=|/embed/|/shorts/|/live/|/v/)([A-Za-z0-9_-]{11})',
  ).firstMatch(trimmed);
  return match?.group(1);
}
