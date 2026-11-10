import 'package:cloud_firestore/cloud_firestore.dart';

import 'converters.dart';

/// A member profile (`users/{uid}`, PRD section 8.1).
///
/// A member may only ever change `name`, `phone` and `updatedAt`. The fields
/// that decide what they have paid for — `hasJoined`, `activeUntil`,
/// `currentMembershipId`, `ptFreeDaysUsed` — are admin-only, enforced by the
/// rules in PRD section 9.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
    this.hasJoined = false,
    this.activeUntil,
    this.currentMembershipId,
    this.ptFreeDaysUsed = 0,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;

  /// 10 digits, optional but recommended (PRD section 7.5).
  final String? phone;
  final DateTime? createdAt;

  /// False until the first payment is approved. Drives the registration fee
  /// (PRD PLAN-3) and the free PT offer (PRD PLAN-4).
  final bool hasJoined;

  /// End of the latest membership. The rules read this to unlock the online
  /// classes (PRD section 9).
  final DateTime? activeUntil;
  final String? currentMembershipId;
  final int ptFreeDaysUsed;
  final DateTime? updatedAt;

  /// Mirrors `isActiveMember()` in the Firestore rules, so the UI locks the
  /// same doors the server does.
  bool get isActive =>
      activeUntil != null && activeUntil!.isAfter(DateTime.now());

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: asString(data['name']),
      email: asString(data['email']),
      phone: asStringOrNull(data['phone']),
      createdAt: asDate(data['createdAt']),
      hasJoined: asBool(data['hasJoined']),
      activeUntil: asDate(data['activeUntil']),
      currentMembershipId: asStringOrNull(data['currentMembershipId']),
      ptFreeDaysUsed: asInt(data['ptFreeDaysUsed']),
      updatedAt: asDate(data['updatedAt']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});
}
