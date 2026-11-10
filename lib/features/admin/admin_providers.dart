import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/membership.dart';
import '../../data/repositories/membership_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/user_repository.dart';

/// The four tiles on the admin dashboard (PRD section 7.10).
class AdminStats {
  const AdminStats({
    required this.activeMembers,
    required this.expiringSoon,
    required this.pendingApprovals,
    required this.incomeThisMonth,
  });

  final int activeMembers;
  final int expiringSoon;
  final int pendingApprovals;
  final int incomeThisMonth;
}

/// All four counts in one place, each an aggregate query so the whole row of
/// tiles costs four reads rather than one per member (PRD section 13).
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final users = ref.watch(userRepositoryProvider);
  final payments = ref.watch(paymentRepositoryProvider);

  final results = await Future.wait([
    users.countActiveMembers(),
    users.countExpiringSoon(),
    payments.countPending(),
    payments.incomeThisMonth(),
  ]);

  return AdminStats(
    activeMembers: results[0],
    expiringSoon: results[1],
    pendingApprovals: results[2],
    incomeThisMonth: results[3],
  );
});

/// The count on the "Pending payments" menu item (PRD section 7.10).
final pendingCountProvider = FutureProvider<int>(
  (ref) => ref.watch(paymentRepositoryProvider).countPending(),
);

/// A membership about to end, together with the member's contact details.
class ExpiringRow {
  const ExpiringRow({required this.membership, required this.member});

  final Membership membership;

  /// Null if the `users` document has gone missing — the row still shows the
  /// plan and the date rather than disappearing.
  final AppUser? member;
}

/// PRD section 7.10: "memberships expiring in the next 7 days (member name,
/// plan, end date, phone with copy button)".
///
/// PRD section 10 keeps this to an `endDate` range query, then one batched
/// lookup fills in the names and phone numbers.
final expiringSoonProvider = FutureProvider<List<ExpiringRow>>((ref) async {
  final memberships =
      await ref.watch(membershipRepositoryProvider).fetchExpiringSoon();
  if (memberships.isEmpty) return const [];

  final members = await ref
      .watch(userRepositoryProvider)
      .fetchByUids(memberships.map((m) => m.uid));

  return [
    for (final membership in memberships)
      ExpiringRow(membership: membership, member: members[membership.uid]),
  ];
});

/// Refreshes everything an approval, rejection or desk cash payment changes.
///
/// Called in one place so no screen can forget a provider and show stale
/// numbers after a write.
void invalidateAdminData(WidgetRef ref) {
  ref.invalidate(adminStatsProvider);
  ref.invalidate(pendingCountProvider);
  ref.invalidate(expiringSoonProvider);
}
