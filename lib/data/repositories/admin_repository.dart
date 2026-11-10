import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_member.dart';
import 'auth_repository.dart';
import 'firebase_providers.dart';

/// `owners/{uid}` and `admins/{uid}`.
///
/// Two tiers, because one tier cannot be managed safely from inside the app:
/// if every admin could edit the admin list, one compromised staff login could
/// lock the owner out. So `owners` is created by hand in the Firebase Console
/// and is never writable from the app (PRD section 2), while owners manage
/// `admins` from the admin panel.
class AdminRepository {
  AdminRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection(Col.admins);

  CollectionReference<Map<String, dynamic>> get _owners =>
      _db.collection(Col.owners);

  /// True when the user may see `/admin/*`.
  ///
  /// Mirrors `isAdmin()` in the rules, owners included — an owner keeps the
  /// admin panel even with no `admins` entry of their own.
  Future<bool> isAdmin(String uid) {
    return guardFirestore(() async {
      final admin = await _admins.doc(uid).get();
      if (admin.exists) return true;
      return (await _owners.doc(uid).get()).exists;
    });
  }

  /// True when the user may add and remove staff.
  Future<bool> isOwner(String uid) {
    return guardFirestore(() async => (await _owners.doc(uid).get()).exists);
  }

  /// Everyone with admin access, owners first.
  Future<List<StaffMember>> fetchStaff() {
    return guardFirestore(() async {
      final results = await Future.wait([_owners.get(), _admins.get()]);

      final owners = results[0].docs
          .map((d) => StaffMember.fromDoc(d, role: StaffRole.owner))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final ownerUids = owners.map((o) => o.uid).toSet();

      // Someone listed in both collections is shown once, as an owner — that
      // is the stronger role and the one that cannot be revoked here.
      final staff = results[1].docs
          .where((d) => !ownerUids.contains(d.id))
          .map((d) => StaffMember.fromDoc(d, role: StaffRole.staff))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return [...owners, ...staff];
    });
  }

  /// Grants admin access. Only an owner may do this; the rules enforce it.
  ///
  /// The person must have signed in at least once, so that a `users/{uid}`
  /// document exists to look their uid up from.
  Future<void> addStaff({
    required String uid,
    required String name,
    required String ownerUid,
  }) {
    return guardFirestore(() => _admins.doc(uid).set({
          'name': name.trim(),
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': ownerUid,
        }));
  }

  /// Revokes admin access.
  ///
  /// Their open session keeps showing the admin menu until they reload — the
  /// check is cached per session — but every write is re-checked by the rules
  /// server-side, so nothing they do from that stale screen will be accepted.
  Future<void> removeStaff(String uid) {
    return guardFirestore(() => _admins.doc(uid).delete());
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(firestoreProvider)),
);

/// Whether the signed-in user may see `/admin/*`.
///
/// One read per session. The router watches this, and so does the header, to
/// decide whether to show the Admin link.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  try {
    return await ref.watch(adminRepositoryProvider).isAdmin(uid);
  } on RepositoryException {
    // The rules let a signed-in user read only their own entry, so a denial
    // here means "not an admin", never "something broke".
    return false;
  }
});

/// Whether the signed-in user may manage staff.
final isOwnerProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  try {
    return await ref.watch(adminRepositoryProvider).isOwner(uid);
  } on RepositoryException {
    return false;
  }
});

/// Everyone with admin access, for the Staff access screen.
final staffProvider = FutureProvider<List<StaffMember>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchStaff(),
);
