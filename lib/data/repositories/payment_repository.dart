import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../models/app_user.dart';
import '../models/membership.dart';
import '../models/payment_request.dart';
import '../models/plan.dart';
import 'auth_repository.dart';
import 'firebase_providers.dart';

/// PRD ADM-2 — the start date the approval sheet offers by default.
///
/// If the member already has a membership that ends today or later, the new one
/// starts the day after it ends, so renewals stack instead of overlapping.
/// Otherwise it starts on the approval date.
///
/// `activeUntil` is the end of the member's latest membership
/// (PRD section 8.1), so no extra query is needed.
DateTime approvalStartDay(DateTime? activeUntil, {DateTime? approvedOn}) {
  final today = approvedOn == null ? istToday() : istDayOf(approvedOn);
  if (activeUntil == null) return today;
  final currentEnd = istDayOf(activeUntil);
  if (currentEnd.isBefore(today)) return today;
  return currentEnd.add(const Duration(days: 1));
}

/// One page of payment requests plus the cursor for the next page.
class PaymentPage {
  const PaymentPage({
    required this.requests,
    required this.cursor,
    required this.hasMore,
  });

  final List<PaymentRequest> requests;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;

  static const empty = PaymentPage(requests: [], cursor: null, hasMore: false);
}

/// Raised when an admin tries to review a request that someone else already
/// reviewed (PRD ADM-3).
class AlreadyReviewedException implements Exception {
  const AlreadyReviewedException();
}

/// `paymentRequests`, plus the approval write that also touches `memberships`
/// and `users` (PRD ADM-1).
class PaymentRepository {
  PaymentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.paymentRequests);

  // ── Member side ────────────────────────────────────────────────────────────

  /// Creates the `pending` request the admin will review.
  ///
  /// Every price is copied in as it stands right now (PRD PAY-2); the rules in
  /// PRD section 9 re-check each one against Firestore and reject the write if
  /// the member tampered with the total.
  Future<String> submit({
    required PaymentDraft draft,
    required AppUser member,
    required PaymentMethod method,
    String? upiRef,
  }) {
    return guardFirestore(() async {
      final ref = _col.doc();
      await ref.set({
        'uid': member.uid,
        'userName': member.name,
        'userPhone': member.phone ?? '',
        'planId': draft.planId,
        'planName': draft.planName,
        'months': draft.months,
        'planPrice': draft.planPrice,
        'registrationFee': draft.registrationFee,
        'ptFee': draft.ptFee,
        'withPT': draft.withPT,
        'total': draft.total,
        'method': method.wire,
        'upiRef': method == PaymentMethod.cash ? null : upiRef,
        'status': PaymentStatus.pending.wire,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': member.uid,
      });
      return ref.id;
    });
  }

  /// PRD PAY-1: a member can have only one pending request at a time.
  Future<PaymentRequest?> fetchPending(String uid) {
    return guardFirestore(() async {
      final snap = await _col
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: PaymentStatus.pending.wire)
          .limit(1)
          .get();
      return snap.docs.isEmpty ? null : PaymentRequest.fromDoc(snap.docs.first);
    });
  }

  /// A member's own requests, newest first. Streaming these is one of the two
  /// real-time listeners PRD section 13 allows.
  Stream<List<PaymentRequest>> watchMine(String uid, {int limit = 5}) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentRequest.fromDoc).toList());
  }

  /// `/account/payments`, 20 per page (PRD section 7.8).
  Future<PaymentPage> fetchMinePage({
    required String uid,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = pageSize,
  }) {
    Query<Map<String, dynamic>> query =
        _col.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return _page(query, limit);
  }

  /// Every request for one member, for the admin's member detail screen.
  Future<List<PaymentRequest>> fetchAllForUser(String uid, {int limit = 50}) {
    return guardFirestore(() async {
      final snap = await _col
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(PaymentRequest.fromDoc).toList();
    });
  }

  // ── Admin side ─────────────────────────────────────────────────────────────

  /// The admin's pending list — the other real-time listener PRD section 13
  /// allows, because the whole point is to notice a payment the moment it
  /// arrives.
  Stream<List<PaymentRequest>> watchPending({int limit = pageSize}) {
    return _col
        .where('status', isEqualTo: PaymentStatus.pending.wire)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentRequest.fromDoc).toList());
  }

  Future<PaymentPage> fetchByStatusPage({
    required PaymentStatus status,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = pageSize,
  }) {
    Query<Map<String, dynamic>> query = _col
        .where('status', isEqualTo: status.wire)
        .orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return _page(query, limit);
  }

  Future<int> countPending() {
    return guardFirestore(() async {
      final snap = await _col
          .where('status', isEqualTo: PaymentStatus.pending.wire)
          .count()
          .get();
      return snap.count ?? 0;
    });
  }

  /// Admin tile "Income this month": the sum of `total` across approved
  /// requests reviewed in the current Asia/Kolkata month (PRD section 7.10).
  ///
  /// An aggregate query, so a busy month still costs one read.
  Future<int> incomeThisMonth() {
    return guardFirestore(() async {
      final month = currentIstMonthRange();
      final snap = await _col
          .where('status', isEqualTo: PaymentStatus.approved.wire)
          .where('reviewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(month.start))
          .where('reviewedAt', isLessThan: Timestamp.fromDate(month.end))
          .aggregate(sum('total'))
          .get();
      return (snap.getSum('total') ?? 0).round();
    });
  }

  /// PRD section 7.10: "if another request has the same `upiRef`, show a red
  /// 'UTR already used' warning on the row".
  ///
  /// Returns the ids of the *other* requests sharing this UTR.
  Future<Set<String>> findDuplicateUtrs(Iterable<String> refs) {
    return guardFirestore(() async {
      final unique = refs.where((r) => r.trim().isNotEmpty).toSet().toList();
      if (unique.isEmpty) return <String>{};

      final duplicates = <String>{};
      // `whereIn` takes at most 30 values per query.
      for (var i = 0; i < unique.length; i += 30) {
        final chunk = unique.sublist(i, (i + 30).clamp(0, unique.length));
        final snap = await _col.where('upiRef', whereIn: chunk).get();
        final seen = <String, int>{};
        for (final doc in snap.docs) {
          final ref = asStringField(doc.data()['upiRef']);
          if (ref != null) seen[ref] = (seen[ref] ?? 0) + 1;
        }
        seen.forEach((ref, timesUsed) {
          if (timesUsed > 1) duplicates.add(ref);
        });
      }
      return duplicates;
    });
  }

  /// PRD ADM-1 — approval, as one atomic write:
  ///
  /// 1. the request becomes `approved` and remembers who reviewed it,
  /// 2. a `memberships` document is created,
  /// 3. `users/{uid}` gets `activeUntil`, `hasJoined` and
  ///    `currentMembershipId`.
  ///
  /// Implemented as a transaction rather than a plain batch so the `pending`
  /// check in PRD ADM-3 cannot be raced by two staff members approving the
  /// same payment at the same moment. A transaction commits all three writes
  /// together exactly like a batch.
  Future<Membership> approve({
    required PaymentRequest request,
    required String adminUid,
    required DateTime startDay,
  }) {
    return guardFirestore(() async {
      final requestRef = _col.doc(request.id);
      final userRef = _db.collection(Col.users).doc(request.uid);
      final membershipRef = _db.collection(Col.memberships).doc();
      final endDay = membershipEndDate(startDay, request.months);

      await _db.runTransaction((tx) async {
        final requestSnap = await tx.get(requestRef);
        final status = PaymentStatus.fromWire(requestSnap.data()?['status']);
        if (!requestSnap.exists || status != PaymentStatus.pending) {
          throw const AlreadyReviewedException();
        }

        final userSnap = await tx.get(userRef);
        final existingActiveUntil = asDateField(userSnap.data()?['activeUntil']);

        // `activeUntil` must never move backwards — an admin correcting an old
        // record should not shorten a live membership.
        final activeUntil =
            existingActiveUntil != null && existingActiveUntil.isAfter(endDay)
                ? existingActiveUntil
                : endDay;

        tx.update(requestRef, {
          'status': PaymentStatus.approved.wire,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminUid,
          'membershipId': membershipRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        });

        tx.set(membershipRef, {
          'uid': request.uid,
          'planId': request.planId,
          'planName': request.planName,
          'months': request.months,
          'withPT': request.withPT,
          'startDate': Timestamp.fromDate(startDay),
          'endDate': Timestamp.fromDate(endDay),
          'paymentRequestId': request.id,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(
          userRef,
          {
            'activeUntil': Timestamp.fromDate(activeUntil),
            'hasJoined': true,
            'currentMembershipId': membershipRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': adminUid,
          },
          SetOptions(merge: true),
        );
      });

      return Membership(
        id: membershipRef.id,
        uid: request.uid,
        planId: request.planId,
        planName: request.planName,
        months: request.months,
        withPT: request.withPT,
        startDate: startDay,
        endDate: endDay,
        paymentRequestId: request.id,
        createdBy: adminUid,
      );
    });
  }

  /// PRD section 7.10: reject with a reason the member will read, and only
  /// while the request is still pending (PRD ADM-3).
  Future<void> reject({
    required String requestId,
    required String adminUid,
    required String reason,
  }) {
    return guardFirestore(() async {
      final ref = _col.doc(requestId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final status = PaymentStatus.fromWire(snap.data()?['status']);
        if (!snap.exists || status != PaymentStatus.pending) {
          throw const AlreadyReviewedException();
        }
        tx.update(ref, {
          'status': PaymentStatus.rejected.wire,
          'rejectReason': reason.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        });
      });
    });
  }

  /// PRD section 7.10: "Record cash payment" for a registered member who paid
  /// at the desk — an already-approved request and its membership, in one
  /// batch.
  Future<Membership> recordCashAtDesk({
    required AppUser member,
    required Plan plan,
    required int registrationFee,
    required int ptFee,
    required bool withPT,
    required String adminUid,
  }) {
    return guardFirestore(() async {
      final requestRef = _col.doc();
      final membershipRef = _db.collection(Col.memberships).doc();
      final userRef = _db.collection(Col.users).doc(member.uid);

      final startDay = approvalStartDay(member.activeUntil);
      final endDay = membershipEndDate(startDay, plan.months);
      final total = plan.price + registrationFee + ptFee;
      final activeUntil =
          member.activeUntil != null && member.activeUntil!.isAfter(endDay)
              ? member.activeUntil!
              : endDay;

      final batch = _db.batch();

      batch.set(requestRef, {
        'uid': member.uid,
        'userName': member.name,
        'userPhone': member.phone ?? '',
        'planId': plan.id,
        'planName': plan.name,
        'months': plan.months,
        'planPrice': plan.price,
        'registrationFee': registrationFee,
        'ptFee': ptFee,
        'withPT': withPT,
        'total': total,
        'method': PaymentMethod.cash.wire,
        'upiRef': null,
        'status': PaymentStatus.approved.wire,
        'membershipId': membershipRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        // PRD section 8.1: `createdBy` is the admin for a desk cash payment.
        'createdBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      });

      batch.set(membershipRef, {
        'uid': member.uid,
        'planId': plan.id,
        'planName': plan.name,
        'months': plan.months,
        'withPT': withPT,
        'startDate': Timestamp.fromDate(startDay),
        'endDate': Timestamp.fromDate(endDay),
        'paymentRequestId': requestRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        userRef,
        {
          'activeUntil': Timestamp.fromDate(activeUntil),
          'hasJoined': true,
          'currentMembershipId': membershipRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      return Membership(
        id: membershipRef.id,
        uid: member.uid,
        planId: plan.id,
        planName: plan.name,
        months: plan.months,
        withPT: withPT,
        startDate: startDay,
        endDate: endDay,
        paymentRequestId: requestRef.id,
        createdBy: adminUid,
      );
    });
  }

  Future<PaymentPage> _page(Query<Map<String, dynamic>> query, int limit) {
    return guardFirestore(() async {
      // One extra document tells us whether a next page exists.
      final snap = await query.limit(limit + 1).get();
      final docs = snap.docs;
      final hasMore = docs.length > limit;
      final page = hasMore ? docs.sublist(0, limit) : docs;
      return PaymentPage(
        requests: page.map(PaymentRequest.fromDoc).toList(),
        cursor: page.isEmpty ? null : page.last,
        hasMore: hasMore,
      );
    });
  }
}

/// Small readers used inside transactions, where there is no model to build.
String? asStringField(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

DateTime? asDateField(Object? value) => switch (value) {
  Timestamp v => v.toDate(),
  DateTime v => v,
  _ => null,
};

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(firestoreProvider)),
);

/// The member's latest few requests, used by the dashboard card and the
/// "Recent payments" preview (PRD section 7.6).
final myRecentPaymentsProvider = StreamProvider<List<PaymentRequest>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(paymentRepositoryProvider).watchMine(uid);
});

/// PRD PAY-1: the one pending request a member may have, if any.
final myPendingPaymentProvider = Provider<PaymentRequest?>((ref) {
  final requests = ref.watch(myRecentPaymentsProvider).value;
  if (requests == null) return null;
  for (final request in requests) {
    if (request.isPending) return request;
  }
  return null;
});

/// The admin's live pending queue.
final pendingPaymentsProvider = StreamProvider<List<PaymentRequest>>(
  (ref) => ref.watch(paymentRepositoryProvider).watchPending(),
);
