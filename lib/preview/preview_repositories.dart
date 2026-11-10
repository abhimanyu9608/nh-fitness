import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/format.dart';
import '../data/models/app_user.dart';
import '../data/models/membership.dart';
import '../data/models/payment_request.dart';
import '../data/models/plan.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/membership_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/user_repository.dart';
import 'preview_data.dart';

/// In-memory stand-ins for the three repositories the screens call directly
/// from `initState` (payment history, the admin members list, member detail).
///
/// Overriding only the provider-level reads is not enough for those screens, so
/// these fakes keep the design preview working end to end. Writes are no-ops:
/// the preview is for looking at the layout, not for changing data.
///
/// Each one `implements` the real repository, so if a method is added to the
/// real class the compiler flags it here too.

/// Keeps the preview from ever touching `FirebaseAuth.instance`, which throws
/// unless Firebase has been initialised. A couple of widgets read the auth
/// repository during build (the profile screen, the verify-email banner), so
/// without this the preview cannot start at all.
class PreviewAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Stream<User?> userChanges() => Stream.value(null);

  /// The preview has no Firebase to sign in to. Throwing the app's own
  /// exception means the login form shows a normal error instead of crashing.
  Future<Never> _unavailable() async =>
      throw const AuthException(AuthFailure.unknown, 'preview-mode');

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<UserCredential> signInWithGoogle() => _unavailable();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _unavailable();

  @override
  bool get hasPasswordProvider => true;

  @override
  Future<void> signOut() async {}
}

class PreviewUserRepository implements UserRepository {
  @override
  Future<void> createIfMissing({
    required String uid,
    required String name,
    required String email,
    String? phone,
  }) async {}

  @override
  Stream<AppUser?> watch(String uid) => Stream.value(_byUid(uid));

  @override
  Future<AppUser?> fetch(String uid) async => _byUid(uid);

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? phone,
  }) async {}

  @override
  Future<void> setPtFreeDaysUsed({
    required String uid,
    required int value,
    required String adminUid,
  }) async {}

  @override
  Future<MemberPage> fetchPage({
    MemberFilter filter = MemberFilter.all,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    final today = istToday();
    final all = PreviewData.members;
    final filtered = switch (filter) {
      MemberFilter.all => all,
      MemberFilter.active => all.where(
          (m) => m.activeUntil != null && !m.activeUntil!.isBefore(today)),
      MemberFilter.expiringSoon => all.where((m) =>
          m.activeUntil != null &&
          !m.activeUntil!.isBefore(today) &&
          daysLeftUntil(m.activeUntil!) <= 7),
      MemberFilter.expired => all.where(
          (m) => m.activeUntil != null && m.activeUntil!.isBefore(today)),
      MemberFilter.neverJoined => all.where((m) => !m.hasJoined),
    };

    final page = filtered.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return MemberPage(members: page, cursor: null, hasMore: false);
  }

  @override
  Future<List<AppUser>> search(String term, {int limit = 20}) async {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return PreviewData.members
        .where((m) =>
            m.name.toLowerCase().startsWith(needle) ||
            m.email.toLowerCase().startsWith(needle) ||
            (m.phone ?? '').startsWith(term.trim()))
        .take(limit)
        .toList();
  }

  @override
  Future<int> countActiveMembers() async => PreviewData.members
      .where((m) =>
          m.activeUntil != null && !m.activeUntil!.isBefore(istToday()))
      .length;

  @override
  Future<int> countExpiringSoon() async => PreviewData.members
      .where((m) =>
          m.activeUntil != null &&
          !m.activeUntil!.isBefore(istToday()) &&
          daysLeftUntil(m.activeUntil!) <= 7)
      .length;

  @override
  Future<Map<String, AppUser>> fetchByUids(Iterable<String> uids) async {
    final wanted = uids.toSet();
    return {
      for (final member in PreviewData.members)
        if (wanted.contains(member.uid)) member.uid: member,
    };
  }

  AppUser? _byUid(String uid) {
    for (final member in PreviewData.members) {
      if (member.uid == uid) return member;
    }
    return null;
  }
}

class PreviewPaymentRepository implements PaymentRepository {
  @override
  Future<String> submit({
    required PaymentDraft draft,
    required AppUser member,
    required PaymentMethod method,
    String? upiRef,
  }) async =>
      'preview-request';

  @override
  Future<PaymentRequest?> fetchPending(String uid) async {
    for (final request in PreviewData.allPayments) {
      if (request.uid == uid && request.isPending) return request;
    }
    return null;
  }

  @override
  Stream<List<PaymentRequest>> watchMine(String uid, {int limit = 5}) =>
      Stream.value(
        PreviewData.allPayments.where((r) => r.uid == uid).take(limit).toList(),
      );

  @override
  Future<PaymentPage> fetchMinePage({
    required String uid,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    return PaymentPage(
      requests: PreviewData.allPayments.where((r) => r.uid == uid).toList(),
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<List<PaymentRequest>> fetchAllForUser(String uid, {int limit = 50}) async =>
      PreviewData.allPayments.where((r) => r.uid == uid).toList();

  @override
  Stream<List<PaymentRequest>> watchPending({int limit = 20}) =>
      Stream.value(PreviewData.pendingPayments.take(limit).toList());

  @override
  Future<PaymentPage> fetchByStatusPage({
    required PaymentStatus status,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    return PaymentPage(
      requests:
          PreviewData.allPayments.where((r) => r.status == status).toList(),
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<int> countPending() async => PreviewData.pendingPayments.length;

  @override
  Future<int> incomeThisMonth() async => 42300;

  @override
  Future<Set<String>> findDuplicateUtrs(Iterable<String> refs) async {
    final counts = <String, int>{};
    for (final request in PreviewData.allPayments) {
      final ref = request.upiRef;
      if (ref != null) counts[ref] = (counts[ref] ?? 0) + 1;
    }
    return refs.where((ref) => (counts[ref] ?? 0) > 1).toSet();
  }

  @override
  Future<Membership> approve({
    required PaymentRequest request,
    required String adminUid,
    required DateTime startDay,
  }) async {
    // The preview has no backing store, so nothing is written — but returning a
    // membership keeps the confirm sheet's success path honest.
    return Membership(
      id: 'preview-membership',
      uid: request.uid,
      planId: request.planId,
      planName: request.planName,
      months: request.months,
      withPT: request.withPT,
      startDate: startDay,
      endDate: membershipEndDate(startDay, request.months),
      paymentRequestId: request.id,
      createdBy: adminUid,
    );
  }

  @override
  Future<void> reject({
    required String requestId,
    required String adminUid,
    required String reason,
  }) async {}

  @override
  Future<Membership> recordCashAtDesk({
    required AppUser member,
    required Plan plan,
    required int registrationFee,
    required int ptFee,
    required bool withPT,
    required String adminUid,
  }) async {
    final startDay = approvalStartDay(member.activeUntil);
    return Membership(
      id: 'preview-membership',
      uid: member.uid,
      planId: plan.id,
      planName: plan.name,
      months: plan.months,
      withPT: withPT,
      startDate: startDay,
      endDate: membershipEndDate(startDay, plan.months),
      paymentRequestId: 'preview-request',
      createdBy: adminUid,
    );
  }
}

class PreviewMembershipRepository implements MembershipRepository {
  @override
  Future<List<Membership>> fetchForUser(String uid, {int limit = 20}) async =>
      PreviewData.memberships.where((m) => m.uid == uid).toList();

  @override
  Stream<Membership?> watchLatestForUser(String uid) {
    final mine = PreviewData.memberships.where((m) => m.uid == uid).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    return Stream.value(mine.isEmpty ? null : mine.first);
  }

  @override
  Future<Map<String, Membership>> fetchByIds(Iterable<String> ids) async {
    final wanted = ids.toSet();
    return {
      for (final membership in PreviewData.memberships)
        if (wanted.contains(membership.id)) membership.id: membership,
    };
  }

  @override
  Future<List<Membership>> fetchExpiringSoon({
    int days = 7,
    int limit = 50,
  }) async {
    final today = istToday();
    final until = today.add(Duration(days: days));
    return PreviewData.memberships
        .where((m) => !m.endDate.isBefore(today) && !m.endDate.isAfter(until))
        .take(limit)
        .toList();
  }

  @override
  Future<void> updateEndDate({
    required Membership membership,
    required DateTime endDay,
    required String adminUid,
  }) async {}
}
