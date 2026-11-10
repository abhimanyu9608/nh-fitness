import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/class_item.dart';
import 'firebase_providers.dart';
import 'user_repository.dart';

/// `classes` (PRD section 8.1).
class ClassRepository {
  ClassRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.classes);

  /// PRD section 9: "Queries from members must include
  /// `where('published', '==', true)`" — without it the rules reject the whole
  /// query, not just the unpublished rows. Uses the
  /// `published ASC, sortOrder ASC` index from PRD section 10.
  Future<List<ClassItem>> fetchPublished({int limit = 60}) {
    return guardFirestore(() async {
      final snap = await _col
          .where('published', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(limit)
          .get();
      return snap.docs.map(ClassItem.fromDoc).toList();
    });
  }

  /// Admin view — drafts included.
  Future<List<ClassItem>> fetchAll({int limit = 100}) {
    return guardFirestore(() async {
      final snap = await _col.orderBy('sortOrder').limit(limit).get();
      return snap.docs.map(ClassItem.fromDoc).toList();
    });
  }

  Future<ClassItem?> fetch(String id) {
    return guardFirestore(() async {
      final doc = await _col.doc(id).get();
      return doc.exists ? ClassItem.fromDoc(doc) : null;
    });
  }

  /// PRD ADM-4: stamp `updatedAt`/`updatedBy` on every admin write.
  Future<String> save(ClassItem item, {required String adminUid}) {
    return guardFirestore(() async {
      final isNew = item.id.isEmpty;
      final ref = isNew ? _col.doc() : _col.doc(item.id);
      await ref.set({
        ...item.toMap(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      }, SetOptions(merge: true));
      return ref.id;
    });
  }

  Future<void> setPublished({
    required String id,
    required bool published,
    required String adminUid,
  }) {
    return guardFirestore(() => _col.doc(id).update({
          'published': published,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        }));
  }
}

final classRepositoryProvider = Provider<ClassRepository>(
  (ref) => ClassRepository(ref.watch(firestoreProvider)),
);

/// Published classes for the member grid.
///
/// Fetched once per session rather than streamed (PRD section 13). Returns an
/// empty list for a member whose membership is not active — the rules would
/// refuse the read anyway, and the screen shows the locked state instead
/// (PRD CLS-1).
final publishedClassesProvider = FutureProvider<List<ClassItem>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isActive) return const [];
  return ref.watch(classRepositoryProvider).fetchPublished();
});

/// Every category that has at least one published class, for the filter chips
/// (PRD section 7.7).
final classCategoriesProvider = Provider<List<String>>((ref) {
  final classes = ref.watch(publishedClassesProvider).value ?? const [];
  final categories = <String>{
    for (final item in classes)
      if (item.category.trim().isNotEmpty) item.category.trim(),
  }.toList()
    ..sort();
  return categories;
});

final allClassesProvider = FutureProvider<List<ClassItem>>(
  (ref) => ref.watch(classRepositoryProvider).fetchAll(),
);
