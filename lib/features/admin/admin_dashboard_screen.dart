import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_payment_row.dart';
import 'admin_providers.dart';
import 'admin_shell.dart';

/// `/admin` — PRD section 7.10.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);

    return AdminShell(
      title: l.adminNavDashboard,
      children: [
        const FadeUp(index: 1, child: _StatTiles()),
        const SizedBox(height: 26),
        const FadeUp(index: 2, child: _PendingPreview()),
        const SizedBox(height: 26),
        const FadeUp(index: 3, child: _ExpiringList()),
      ],
    );
  }
}

/// PRD section 7.10: "Tiles: Active members, Expiring in next 7 days, Pending
/// approvals, Income this month".
class _StatTiles extends ConsumerWidget {
  const _StatTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final stats = ref.watch(adminStatsProvider);

    return AsyncSection<AdminStats>(
      value: stats,
      minHeight: 140,
      onRetry: () => ref.invalidate(adminStatsProvider),
      data: (value) => NHGrid(
        columns: context.bp.isMobile ? 2 : 4,
        spacing: 14,
        children: [
          _Tile(
            label: l.adminTileActiveMembers,
            value: '${value.activeMembers}',
            icon: Icons.people_outline,
          ),
          _Tile(
            label: l.adminTileExpiring,
            value: '${value.expiringSoon}',
            icon: Icons.timer_outlined,
            color: value.expiringSoon > 0 ? NHColors.yellow : null,
          ),
          _Tile(
            label: l.adminTilePending,
            value: '${value.pendingApprovals}',
            icon: Icons.pending_actions_outlined,
            color: value.pendingApprovals > 0 ? NHColors.red : null,
            onTap: () => context.go(Routes.adminPayments),
          ),
          _Tile(
            label: l.adminTileIncome,
            value: formatRupees(value.incomeThisMonth),
            icon: Icons.trending_up_outlined,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? NHColors.text;

    return NHCard(
      onTap: onTap,
      lift: onTap != null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: NHColors.muted),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: NHText.money(size: 42, color: accent)),
          ),
          const SizedBox(height: 6),
          Text(label, style: NHText.label(size: 11)),
        ],
      ),
    );
  }
}

/// PRD section 7.10: "List: pending requests (top 5) with Approve/Reject."
class _PendingPreview extends ConsumerWidget {
  const _PendingPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pending = ref.watch(pendingPaymentsProvider);

    return _Panel(
      title: l.adminPendingListTitle,
      onViewAll: () => context.go(Routes.adminPayments),
      child: AsyncSection<List<PaymentRequest>>(
        value: pending,
        minHeight: 120,
        onRetry: () => ref.invalidate(pendingPaymentsProvider),
        data: (list) => list.isEmpty
            ? NHEmptyState(
                message: l.adminNoPending,
                icon: Icons.check_circle_outline,
                minHeight: 120,
              )
            : Column(
                children: [
                  for (final request in list.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdminPaymentRow(
                        request: request,
                        // The dashboard preview keeps to five rows, so the
                        // duplicate-UTR lookup is left to the payments screen
                        // where the whole queue is visible.
                        duplicateUtr: false,
                        onReviewed: () => invalidateAdminData(ref),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// PRD section 7.10: "List: memberships expiring in the next 7 days (member
/// name, plan, end date, phone with copy button)."
class _ExpiringList extends ConsumerWidget {
  const _ExpiringList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final expiring = ref.watch(expiringSoonProvider);

    return _Panel(
      title: l.adminExpiringListTitle,
      onViewAll: () => context.go('${Routes.adminMembers}?filter=expiring'),
      child: AsyncSection<List<ExpiringRow>>(
        value: expiring,
        minHeight: 120,
        onRetry: () => ref.invalidate(expiringSoonProvider),
        data: (rows) => rows.isEmpty
            ? NHEmptyState(
                message: l.adminNoExpiring,
                icon: Icons.event_available_outlined,
                minHeight: 120,
              )
            : Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NHCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => context
                            .go('${Routes.adminMembers}/${row.membership.uid}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.member?.name.isNotEmpty == true
                                        ? row.member!.name
                                        : row.membership.planName,
                                    style: NHText.body(
                                        size: 15.5, weight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${row.membership.planName} · '
                                    '${l.accountValidTill} '
                                    '${formatDate(row.membership.endDate)}',
                                    style: NHText.body(
                                        size: 13.5, color: NHColors.muted),
                                  ),
                                  if ((row.member?.phone ?? '').isNotEmpty)
                                    PhoneLine(phone: row.member!.phone!),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l.accountDaysLeft('${row.membership.daysLeft}'),
                              style: NHText.moneyBody(
                                size: 13.5,
                                color: NHColors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    required this.onViewAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(), style: NHText.display(size: 30)),
            ),
            if (onViewAll != null)
              NHTextLink(
                label: L.of(context).actionViewAll,
                onPressed: onViewAll,
              ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
