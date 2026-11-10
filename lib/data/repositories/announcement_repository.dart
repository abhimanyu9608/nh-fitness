import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import 'firebase_providers.dart';

/// `announcements` (PRD section 8.1). Readable by everyone, including visitors
/// (PRD section 7.9).
class AnnouncementRepository {
  AnnouncementRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.announcements);

  /// Active announcements, newest first.
  ///
  /// Sorting happens on the client: an equality filter plus `orderBy
  /// createdAt` would need a composite index that PRD section 10 does not
  /// list, and there are only ever a handful of these.
  Future<List<Announcement>> fetchLive({int limit = 10}) {
    return guardFirestore(() async {
      final snap = await _col.where('active', isEqualTo: true).limit(limit).get();
      final live = snap.docs.map(Announcement.fromDoc).where((a) => a.isLive).toList()
        ..sort((a, b) {
          final at = a.createdAt, bt = b.createdAt;
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });
      return live;
    });
  }

  Future<List<Announcement>> fetchAll({int limit = 50}) {
    return guardFirestore(() async {
      final snap = await _col.limit(limit).get();
      final all = snap.docs.map(Announcement.fromDoc).toList()
        ..sort((a, b) {
          final at = a.createdAt, bt = b.createdAt;
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });
      return all;
    });
  }

  /// PRD ADM-4: stamp `updatedAt`/`updatedBy` on every admin write.
  Future<String> save(Announcement announcement, {required String adminUid}) {
    return guardFirestore(() async {
      final isNew = announcement.id.isEmpty;
      final ref = isNew ? _col.doc() : _col.doc(announcement.id);
      await ref.set({
        ...announcement.toMap(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      }, SetOptions(merge: true));
      return ref.id;
    });
  }

  Future<void> setActive({
    required String id,
    required bool active,
    required String adminUid,
  }) {
    return guardFirestore(() => _col.doc(id).update({
          'active': active,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        }));
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(ref.watch(firestoreProvider)),
);

/// Fetched once per session: the strip at the top of Home and the dashboard.
final liveAnnouncementsProvider = FutureProvider<List<Announcement>>(
  (ref) => ref.watch(announcementRepositoryProvider).fetchLive(),
);

final allAnnouncementsProvider = FutureProvider<List<Announcement>>(
  (ref) => ref.watch(announcementRepositoryProvider).fetchAll(),
);
