import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';
import 'firebase_providers.dart';

/// `plans` (PRD section 8.1).
class PlanRepository {
  PlanRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.plans);

  /// PRD PLAN-2: inactive plans are hidden, and the order is `sortOrder`.
  Future<List<Plan>> fetchActive() {
    return guardFirestore(() async {
      final snap = await _col
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snap.docs.map(Plan.fromDoc).toList();
    });
  }

  /// Admin view — includes the switched-off plans so they can be turned back on.
  Future<List<Plan>> fetchAll() {
    return guardFirestore(() async {
      final snap = await _col.orderBy('sortOrder').get();
      return snap.docs.map(Plan.fromDoc).toList();
    });
  }

  Future<Plan?> fetch(String planId) {
    return guardFirestore(() async {
      final doc = await _col.doc(planId).get();
      return doc.exists ? Plan.fromDoc(doc) : null;
    });
  }

  Future<bool> exists(String planId) {
    return guardFirestore(() async => (await _col.doc(planId).get()).exists);
  }

  /// PRD ADM-4: every admin write stores `updatedAt` and `updatedBy`.
  Future<void> save(Plan plan, {required String adminUid}) {
    return guardFirestore(() => _col.doc(plan.id).set({
          ...plan.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        }, SetOptions(merge: true)));
  }

  /// PRD section 8.2 / 7.10: the "Create default plans" button.
  ///
  /// Uses `create`-style writes so pressing it twice cannot overwrite prices
  /// the owner has already edited.
  Future<void> seedDefaults({required String adminUid}) {
    return guardFirestore(() async {
      final existing = await _col.get();
      final taken = existing.docs.map((d) => d.id).toSet();
      final batch = _db.batch();
      for (final plan in Plan.defaults) {
        if (taken.contains(plan.id)) continue;
        batch.set(_col.doc(plan.id), {
          ...plan.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        });
      }
      await batch.commit();
    });
  }
}

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(firestoreProvider)),
);

/// PRD section 13: `plans` is cached in memory for the session rather than
/// streamed, so browsing the site costs one read set.
///
/// `ref.invalidate(activePlansProvider)` is the Retry button (PRD HOME-2) and
/// is also called after an admin edits a plan.
final activePlansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(planRepositoryProvider).fetchActive(),
);

final allPlansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(planRepositoryProvider).fetchAll(),
);

/// The lowest per-month price across active plans, for
/// "From ₹x a month" on `/explore` (PRD section 7.2).
final lowestMonthlyPriceProvider = Provider<int?>((ref) {
  final plans = ref.watch(activePlansProvider).value;
  if (plans == null || plans.isEmpty) return null;
  return plans.map((p) => p.pricePerMonth).reduce((a, b) => a < b ? a : b);
});
