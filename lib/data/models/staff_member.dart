import 'package:cloud_firestore/cloud_firestore.dart';

import 'converters.dart';

/// How someone got access to the admin panel.
enum StaffRole {
  /// `owners/{uid}` — the gym's proprietor. Created by hand in the Firebase
  /// Console and not changeable from the app, so staff can never lock the
  /// owner out.
  owner,

  /// `admins/{uid}` — staff, managed by an owner from the admin panel.
  staff,
}

/// A person with admin access, from either `owners/{uid}` or `admins/{uid}`.
///
/// Both collections hold the same shape, so one model covers them and the
/// [role] records which list they came from.
class StaffMember {
  const StaffMember({
    required this.uid,
    required this.name,
    required this.role,
    this.addedAt,
    this.addedBy,
  });

  final String uid;
  final String name;
  final StaffRole role;
  final DateTime? addedAt;

  /// The owner who granted access. Null for owners, and for the first admin
  /// created by hand in the Console.
  final String? addedBy;

  bool get isOwner => role == StaffRole.owner;

  factory StaffMember.fromMap(
    String uid,
    Map<String, dynamic> data, {
    required StaffRole role,
  }) {
    return StaffMember(
      uid: uid,
      name: asString(data['name']),
      role: role,
      addedAt: asDate(data['addedAt']),
      addedBy: asStringOrNull(data['addedBy']),
    );
  }

  factory StaffMember.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required StaffRole role,
  }) =>
      StaffMember.fromMap(doc.id, doc.data() ?? const {}, role: role);
}
