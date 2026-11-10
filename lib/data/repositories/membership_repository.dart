import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../models/membership.dart';
import 'auth_repository.dart';
import 'firebase_providers.dart';

/// `memberships` (PRD section 8.1). Only admins write here — members read
/// their own rows.
class MembershipRepository {
  MembershipRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.memberships);

  /// Newest-ending first, which is also "most relevant first" for the member's
  /// dashboard. Uses the `uid ASC, endDate DESC` index from PRD section 10.
  Future<List<Membership>> fetchForUser(String uid, {int limit = 20}) {
    return guardFirestore(() async {
      final snap = await _col
          .where('uid', isEqualTo: uid)
          .orderBy('endDate', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(Membership.fromDoc).toList();
    });
  }

  /// A one-document stream of the membership that matters right now, so the
  /// dashboard flips to "Active" the moment the admin approves.
  Stream<Membership?> watchLatestForUser(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('endDate', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Membership.fromDoc(s.docs.first));
  }

  /// Plan names for a page of the admin members list.
  ///
  /// `users` stores `currentMembershipId` but not the plan name, so one batched
  /// lookup fills in the whole page instead of one read per row.
  Future<Map<String, Membership>> fetchByIds(Iterable<String> ids) {
    return guardFirestore(() async {
      final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
      if (unique.isEmpty) return <String, Membership>{};

      final result = <String, Membership>{};
      // `whereIn` takes at most 30 values per query.
      for (var i = 0; i < unique.length; i += 30) {
        final chunk = unique.sublist(i, (i + 30).clamp(0, unique.length));
        final snap = await _col.where(FieldPath.documentId, whereIn: chunk).get();
        for (final doc in snap.docs) {
          result[doc.id] = Membership.fromDoc(doc);
        }
      }
      return result;
    });
  }

  /// PRD section 7.10: memberships ending in the next 7 days, for the admin
  /// dashboard's call list.
  ///
  /// PRD section 10: an `endDate` range only, so the automatic single-field
  /// index covers it.
  Future<List<Membership>> fetchExpiringSoon({int days = 7, int limit = 50}) {
    return guardFirestore(() async {
      final today = istToday();
      final until = today.add(Duration(days: days));
      final snap = await _col
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(until))
          .orderBy('endDate')
          .limit(limit)
          .get();
      return snap.docs.map(Membership.fromDoc).toList();
    });
  }

  /// PRD section 7.10: "Edit a membership's end date (with a confirm step) for
  /// corrections."
  ///
  /// `users/{uid}.activeUntil` is corrected in the same write, otherwise the
  /// online classes would stay unlocked past the new end date — the rules read
  /// `activeUntil`, not this document.
  Future<void> updateEndDate({
    required Membership membership,
    required DateTime endDay,
    required String adminUid,
  }) {
    return guardFirestore(() async {
      final batch = _db.batch();
      batch.update(_col.doc(membership.id), {
        'endDate': Timestamp.fromDate(endDay),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      });

      final userRef = _db.collection(Col.users).doc(membership.uid);
      final userSnap = await userRef.get();
      // Only follow the correction when this membership is the one driving
      // `activeUntil`; an older row must not move a live membership.
      if (userSnap.data()?['currentMembershipId'] == membership.id) {
        batch.update(userRef, {
          'activeUntil': Timestamp.fromDate(endDay),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        });
      }

      await batch.commit();
    });
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MembershipRepository(ref.watch(firestoreProvider)),
);

/// The signed-in member's latest membership, or null if they never joined.
final myMembershipProvider = StreamProvider<Membership?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(membershipRepositoryProvider).watchLatestForUser(uid);
});
