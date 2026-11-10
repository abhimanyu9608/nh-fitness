import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/format.dart';
import 'converters.dart';

/// What the member's card on `/account` is showing (PRD ACC-2).
enum MembershipState { active, upcoming, expired }

/// An activated membership (`memberships/{id}`, PRD section 8.1).
///
/// Created only by an admin, inside the approval batch (PRD ADM-1).
class Membership {
  const Membership({
    required this.id,
    required this.uid,
    required this.planId,
    required this.planName,
    required this.months,
    required this.withPT,
    required this.startDate,
    required this.endDate,
    required this.paymentRequestId,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
  });

  final String id;
  final String uid;
  final String planId;
  final String planName;
  final int months;
  final bool withPT;

  /// 00:00 Asia/Kolkata of the first day (PRD section 8).
  final DateTime startDate;

  /// 00:00 Asia/Kolkata of the last day, inclusive.
  final DateTime endDate;
  final String paymentRequestId;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;

  /// PRD ACC-2: derived on the client, in the gym's timezone.
  MembershipState get state {
    final today = istToday();
    if (istDayOf(startDate).isAfter(today)) return MembershipState.upcoming;
    if (istDayOf(endDate).isBefore(today)) return MembershipState.expired;
    return MembershipState.active;
  }

  bool get isActive => state == MembershipState.active;

  /// PRD ACC-1: whole days to `endDate` inclusive, never negative.
  int get daysLeft => daysLeftUntil(endDate);

  /// Total days the membership covers, used by the progress bar on `/account`.
  int get totalDays => daysBetween(startDate, endDate) + 1;

  /// Days already used, clamped into `0..totalDays` so the bar never overflows.
  int get daysUsed {
    final used = daysBetween(startDate, istToday());
    if (used < 0) return 0;
    return used > totalDays ? totalDays : used;
  }

  double get progress => totalDays <= 0 ? 0 : daysUsed / totalDays;

  factory Membership.fromMap(String id, Map<String, dynamic> data) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return Membership(
      id: id,
      uid: asString(data['uid']),
      planId: asString(data['planId']),
      planName: asString(data['planName']),
      months: asInt(data['months'], 1),
      withPT: asBool(data['withPT']),
      startDate: asDateOr(data['startDate'], epoch),
      endDate: asDateOr(data['endDate'], epoch),
      paymentRequestId: asString(data['paymentRequestId']),
      createdAt: asDate(data['createdAt']),
      createdBy: asStringOrNull(data['createdBy']),
      updatedAt: asDate(data['updatedAt']),
    );
  }

  factory Membership.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Membership.fromMap(doc.id, doc.data() ?? const {});
}
