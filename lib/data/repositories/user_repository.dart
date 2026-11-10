import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';
import 'firebase_providers.dart';

/// Which bucket the admin members list is showing (PRD section 7.10).
enum MemberFilter { all, active, expiringSoon, expired, neverJoined }

/// One page of members plus the cursor for the next page.
class MemberPage {
  const MemberPage({required this.members, required this.cursor, required this.hasMore});

  final List<AppUser> members;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;

  static const empty = MemberPage(members: [], cursor: null, hasMore: false);
}

/// `users` (PRD section 8.1).
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.users);

  /// PRD section 7.5: on first login by any method, create `users/{uid}` if it
  /// does not exist.
  ///
  /// The field list matches the `create` rule in PRD section 9 exactly — adding
  /// a key here without adding it there makes every sign-up fail.
  Future<void> createIfMissing({
    required String uid,
    required String name,
    required String email,
    String? phone,
  }) {
    return guardFirestore(() async {
      final ref = _col.doc(uid);
      if ((await ref.get()).exists) return;
      await ref.set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'hasJoined': false,
        'ptFreeDaysUsed': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// A single-document listener, so a membership going live during approval
  /// shows up on the member's dashboard without a refresh.
  Stream<AppUser?> watch(String uid) {
    return _col.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }

  Future<AppUser?> fetch(String uid) {
    return guardFirestore(() async {
      final doc = await _col.doc(uid).get();
      return doc.exists ? AppUser.fromDoc(doc) : null;
    });
  }

  /// PRD section 7.8: a member may only change their name and phone. The rules
  /// reject anything else.
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? phone,
  }) {
    return guardFirestore(() => _col.doc(uid).update({
          'name': name.trim(),
          'phone': phone?.trim() ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }));
  }

  /// PRD section 7.10: the "+1 day used" / "−1" buttons on member detail.
  /// Clamped to `0..ptFreeDays` by the caller.
  Future<void> setPtFreeDaysUsed({
    required String uid,
    required int value,
    required String adminUid,
  }) {
    return guardFirestore(() => _col.doc(uid).update({
          'ptFreeDaysUsed': value,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        }));
  }

  /// One page of the admin members list.
  ///
  /// Each filter uses only automatic single-field indexes, so no composite
  /// index beyond PRD section 10 is needed.
  Future<MemberPage> fetchPage({
    MemberFilter filter = MemberFilter.all,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = pageSize,
  }) {
    return guardFirestore(() async {
      final today = istToday();
      final weekAhead = today.add(const Duration(days: 7));

      Query<Map<String, dynamic>> query = switch (filter) {
        MemberFilter.all => _col.orderBy('name'),
        MemberFilter.active => _col
            .where('activeUntil', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
            .orderBy('activeUntil'),
        MemberFilter.expiringSoon => _col
            .where('activeUntil', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
            .where('activeUntil', isLessThanOrEqualTo: Timestamp.fromDate(weekAhead))
            .orderBy('activeUntil'),
        MemberFilter.expired => _col
            .where('activeUntil', isLessThan: Timestamp.fromDate(today))
            .orderBy('activeUntil', descending: true),
        // Equality plus an order by document id runs on the automatic index.
        MemberFilter.neverJoined =>
          _col.where('hasJoined', isEqualTo: false).orderBy(FieldPath.documentId),
      };

      if (startAfter != null) query = query.startAfterDocument(startAfter);

      // Ask for one extra document to learn whether another page exists.
      final snap = await query.limit(limit + 1).get();
      final docs = snap.docs;
      final hasMore = docs.length > limit;
      final page = hasMore ? docs.sublist(0, limit) : docs;

      return MemberPage(
        members: page.map(AppUser.fromDoc).toList(),
        cursor: page.isEmpty ? null : page.last,
        hasMore: hasMore,
      );
    });
  }

  /// PRD section 7.10: "Search by name, email or phone".
  ///
  /// Firestore has no substring search, so this is a prefix search: three
  /// cheap range queries (name, email, phone) merged by uid. Typing "ravi"
  /// finds "Ravi Kumar" but not "Kumar Ravi" — which is what a staff member
  /// looking someone up actually types.
  Future<List<AppUser>> search(String term, {int limit = pageSize}) {
    return guardFirestore(() async {
      final raw = term.trim();
      if (raw.isEmpty) return const <AppUser>[];

      // U+F8FF sorts after every ordinary character, so the range
      // term .. term+U+F8FF matches everything starting with term.
      const high = '\uf8ff';
      final lower = raw.toLowerCase();

      final queries = <Query<Map<String, dynamic>>>[
        // Names are stored as typed, so try the term as-is and capitalised.
        _col.orderBy('name').startAt([raw]).endAt(['$raw$high']).limit(limit),
        _col.orderBy('email').startAt([lower]).endAt(['$lower$high']).limit(limit),
        _col.orderBy('phone').startAt([raw]).endAt(['$raw$high']).limit(limit),
      ];

      final results = await Future.wait(queries.map((q) => q.get()));
      final byUid = <String, AppUser>{};
      for (final snap in results) {
        for (final doc in snap.docs) {
          byUid[doc.id] = AppUser.fromDoc(doc);
        }
      }

      // A prefix range on `name` is case sensitive, so filter the merged set
      // case-insensitively to drop anything that only matched loosely.
      final matches = byUid.values.where((u) {
        return u.name.toLowerCase().startsWith(lower) ||
            u.email.toLowerCase().startsWith(lower) ||
            (u.phone ?? '').startsWith(raw);
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return matches.take(limit).toList();
    });
  }

  /// Admin dashboard tile "Active members" (PRD section 7.10).
  ///
  /// Counted on `users.activeUntil` with an aggregate query — one read instead
  /// of one per member, which matters on the Spark plan.
  Future<int> countActiveMembers() {
    return guardFirestore(() async {
      final snap = await _col
          .where('activeUntil',
              isGreaterThanOrEqualTo: Timestamp.fromDate(istToday()))
          .count()
          .get();
      return snap.count ?? 0;
    });
  }

  /// Admin dashboard tile "Expiring in next 7 days".
  Future<int> countExpiringSoon() {
    return guardFirestore(() async {
      final today = istToday();
      final snap = await _col
          .where('activeUntil', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('activeUntil',
              isLessThanOrEqualTo: Timestamp.fromDate(today.add(const Duration(days: 7))))
          .count()
          .get();
      return snap.count ?? 0;
    });
  }

  /// Names and phone numbers for the expiring-soon list, which reads
  /// `memberships` and then needs the member's contact details.
  Future<Map<String, AppUser>> fetchByUids(Iterable<String> uids) {
    return guardFirestore(() async {
      final unique = uids.toSet().toList();
      if (unique.isEmpty) return <String, AppUser>{};

      // `whereIn` takes at most 30 values per query.
      final result = <String, AppUser>{};
      for (var i = 0; i < unique.length; i += 30) {
        final chunk = unique.sublist(i, (i + 30).clamp(0, unique.length));
        final snap =
            await _col.where(FieldPath.documentId, whereIn: chunk).get();
        for (final doc in snap.docs) {
          result[doc.id] = AppUser.fromDoc(doc);
        }
      }
      return result;
    });
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

/// The signed-in member's own profile document. Null when logged out, or when
/// the document has not been created yet.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watch(uid);
});
