import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/states.dart';
import '../../data/models/membership.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/membership_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';

/// PRD section 7.6 item 2 — the membership card, in all five of its states:
/// active, waiting for approval, rejected, never joined, expired.
class MembershipStatusCard extends ConsumerWidget {
  const MembershipStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(myMembershipProvider);
    final requestsAsync = ref.watch(myRecentPaymentsProvider);

    // Both reads have to land before the card can tell "no plan yet" from
    // "still loading", which would otherwise flash the wrong message.
    if (!membershipAsync.hasValue || !requestsAsync.hasValue) {
      if (membershipAsync.hasError || requestsAsync.hasError) {
        return NHErrorState(
          message: messageForError(
            context,
            membershipAsync.error ?? requestsAsync.error,
          ),
          onRetry: () {
            ref.invalidate(myMembershipProvider);
            ref.invalidate(myRecentPaymentsProvider);
          },
        );
      }
      return const NHLoading(minHeight: 180);
    }

    final membership = membershipAsync.value;
    final requests = requestsAsync.value ?? const <PaymentRequest>[];
    final pending = ref.watch(myPendingPaymentProvider);
    final latest = requests.isEmpty ? null : requests.first;

    // A live or upcoming membership is the headline, even while a renewal is
    // waiting for approval — that renewal shows as a note underneath.
    if (membership != null && membership.state != MembershipState.expired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActiveCard(membership: membership),
          if (pending != null) ...[
            const SizedBox(height: 14),
            _PendingCard(request: pending),
          ],
        ],
      );
    }

    if (pending != null) return _PendingCard(request: pending);

    if (latest != null && latest.status == PaymentStatus.rejected) {
      return _RejectedCard(request: latest);
    }

    if (membership != null) return _ExpiredCard(membership: membership);

    return const _NoPlanCard();
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final upcoming = membership.state == MembershipState.upcoming;
    final daysLeft = membership.daysLeft;

    return NHCard(
      padding: const EdgeInsets.all(22),
      borderColor: NHColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  membership.planName.toUpperCase(),
                  style: NHText.display(size: 34),
                ),
              ),
              StatusPill(
                label: upcoming ? l.accountStatusUpcoming : l.accountStatusActive,
                kind: upcoming ? PillKind.pending : PillKind.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcoming)
            Text(
              l.accountUpcomingStarts(formatDate(membership.startDate)),
              style: NHText.body(size: 15, color: NHColors.muted),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // PRD ACC-1: whole days to the end date, counting it, never
                // negative.
                Text(
                  daysLeft == 1 ? '1' : '$daysLeft',
                  style: NHText.money(size: 56, color: NHColors.red),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    daysLeft == 1 ? l.accountOneDayLeft : l.accountDaysLeftLabel,
                    style: NHText.display(size: 24, color: NHColors.muted),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          NHProgressBar(
            value: membership.progress,
            semanticsLabel: l.accountProgressUsed(
              '${membership.daysUsed}',
              '${membership.totalDays}',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.accountProgressUsed(
              '${membership.daysUsed}',
              '${membership.totalDays}',
            ),
            style: NHText.body(size: 13, color: NHColors.muted),
          ),
          const SizedBox(height: 14),
          DetailRow(
            label: l.accountStartDate,
            value: formatDate(membership.startDate),
          ),
          DetailRow(
            label: l.accountValidTill,
            value: formatDate(membership.endDate),
          ),
          if (membership.withPT)
            DetailRow(label: l.plansSummaryPt, value: l.accountStatusActive),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: l.accountRenewPlan,
              expand: false,
              height: 48,
              onPressed: () => context.go(Routes.plans),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.request});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final approvalTime = ref.watch(settingsProvider).value?.approvalTimeText;

    return NHCard(
      padding: const EdgeInsets.all(22),
      borderColor: NHColors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.accountWaitingTitle.toUpperCase(),
                  style: NHText.display(size: 28, color: NHColors.yellow),
                ),
              ),
              StatusPill(label: l.accountStatusPending, kind: PillKind.pending),
            ],
          ),
          if (approvalTime != null) ...[
            const SizedBox(height: 8),
            Text(
              l.accountWaitingBody(approvalTime),
              style: NHText.body(size: 15, color: NHColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          DetailRow(label: l.plansSummaryPlan, value: request.planName),
          DetailRow(
            label: l.plansSummaryTotal,
            value: formatRupees(request.total),
            strong: true,
          ),
          DetailRow(
            label: l.paymentsMethodLabel,
            value: request.method == PaymentMethod.cash
                ? l.paymentsMethodCash
                : l.paymentsMethodUpi,
          ),
          if (request.createdAt != null)
            DetailRow(
              label: l.accountSubmittedOnLabel,
              value: formatDateTime(request.createdAt!),
            ),
        ],
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({required this.request});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(22),
      borderColor: NHColors.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.accountRejectedTitle.toUpperCase(),
                  style: NHText.display(size: 28, color: NHColors.danger),
                ),
              ),
              StatusPill(label: l.accountStatusRejected, kind: PillKind.danger),
            ],
          ),
          if (request.rejectReason != null) ...[
            const SizedBox(height: 10),
            Text(
              l.accountRejectedReason(request.rejectReason!),
              style: NHText.body(size: 15, color: NHColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          DetailRow(label: request.planName, value: formatRupees(request.total)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: l.actionTryAgain,
              expand: false,
              height: 48,
              // PRD section 11: "Try again (pre-filled checkout)".
              onPressed: () => context.go(
                '${Routes.checkout}?plan=${request.planId}'
                '${request.withPT ? '&pt=1' : ''}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.accountExpiredTitle(formatDate(membership.endDate))
                      .toUpperCase(),
                  style: NHText.display(size: 28),
                ),
              ),
              StatusPill(label: l.accountStatusExpired, kind: PillKind.danger),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: l.accountRenewPlan,
              expand: false,
              height: 48,
              onPressed: () => context.go(Routes.plans),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.accountNoPlanTitle.toUpperCase(),
            style: NHText.display(size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            l.accountNoPlanBody,
            style: NHText.body(size: 15, color: NHColors.muted),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: l.accountChoosePlan,
              expand: false,
              onPressed: () => context.go(Routes.plans),
            ),
          ),
        ],
      ),
    );
  }
}

/// PRD section 7.6 item 3: "Expiry banner when 7 days or fewer are left: 'Your
/// plan ends in {n} days. Renew now.'"
class ExpiryBanner extends ConsumerWidget {
  const ExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final membership = ref.watch(myMembershipProvider).value;
    if (membership == null || membership.state != MembershipState.active) {
      return const SizedBox.shrink();
    }

    final daysLeft = membership.daysLeft;
    if (daysLeft > 7) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NHColors.selectedBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: NHColors.red, width: 1.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: NHColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              daysLeft <= 1
                  ? l.accountExpiryBannerToday
                  : l.accountExpiryBanner('$daysLeft'),
              style: NHText.body(size: 15, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          SmallButton(
            label: l.accountRenewPlan,
            onPressed: () => context.go(Routes.plans),
          ),
        ],
      ),
    );
  }
}

/// PRD section 7.6 item 4: "Free personal training card for new members:
/// '{ptFreeDays - ptFreeDaysUsed} of {ptFreeDays} free days left'".
///
/// Appears once a membership is live; the admin moves the counter from the
/// member detail screen (PRD section 7.10).
class FreePtCard extends ConsumerWidget {
  const FreePtCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final membership = ref.watch(myMembershipProvider).value;

    if (user == null || settings == null || membership == null) {
      return const SizedBox.shrink();
    }
    if (settings.ptFreeDays <= 0) return const SizedBox.shrink();

    final used = user.ptFreeDaysUsed.clamp(0, settings.ptFreeDays);
    final left = settings.ptFreeDays - used;

    return NHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.redeem_outlined, size: 20, color: NHColors.yellow),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.accountFreePtTitle.toUpperCase(),
                  style: NHText.display(size: 22, color: NHColors.yellow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            left > 0
                ? l.accountFreePtDaysLeft('$left', '${settings.ptFreeDays}')
                : l.accountFreePtUsedUp('${settings.ptFreeDays}'),
            style: NHText.body(size: 15),
          ),
          const SizedBox(height: 10),
          NHProgressBar(
            value: settings.ptFreeDays == 0 ? 0 : used / settings.ptFreeDays,
            color: NHColors.yellow,
            semanticsLabel: l.accountFreePtTitle,
          ),
        ],
      ),
    );
  }
}
