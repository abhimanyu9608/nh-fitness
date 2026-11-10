import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/widgets/nh_pill.dart';
import '../../data/models/app_user.dart';
import '../../l10n/app_localizations.dart';

/// The buckets the admin members list filters by (PRD section 7.10), derived
/// from `users.activeUntil` and `users.hasJoined` so no extra read is needed.
enum MemberStatus { active, expiringSoon, expired, neverJoined }

MemberStatus memberStatusOf(AppUser member) {
  final activeUntil = member.activeUntil;
  if (activeUntil == null) return MemberStatus.neverJoined;

  final daysLeft = daysLeftUntil(activeUntil);
  if (daysLeft <= 0) return MemberStatus.expired;
  return daysLeft <= 7 ? MemberStatus.expiringSoon : MemberStatus.active;
}

/// The pill shown on a member row.
StatusPill memberStatusPill(BuildContext context, AppUser member) {
  final l = L.of(context);
  return switch (memberStatusOf(member)) {
    MemberStatus.active =>
      StatusPill(label: l.accountStatusActive, kind: PillKind.success),
    MemberStatus.expiringSoon =>
      StatusPill(label: l.adminFilterExpiring, kind: PillKind.pending),
    MemberStatus.expired =>
      StatusPill(label: l.accountStatusExpired, kind: PillKind.danger),
    MemberStatus.neverJoined =>
      StatusPill(label: l.adminFilterNeverJoined, kind: PillKind.neutral),
  };
}
