import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_user.dart';
import '../../data/models/membership.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/membership_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../account/payment_row.dart';
import 'admin_payment_row.dart';
import 'admin_providers.dart';
import 'admin_shell.dart';
import 'member_status.dart';
import 'record_cash_sheet.dart';

/// `/admin/members/:uid` — PRD section 7.10: "Profile, all memberships, all
/// payment requests", plus the free-PT counter and the end-date correction.
class AdminMemberDetailScreen extends ConsumerStatefulWidget {
  const AdminMemberDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState
    extends ConsumerState<AdminMemberDetailScreen> {
  AppUser? _member;
  List<Membership> _memberships = const [];
  List<PaymentRequest> _requests = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Three reads, fired together so the screen opens in one round trip.
      final member = await ref.read(userRepositoryProvider).fetch(widget.uid);
      final memberships = await ref
          .read(membershipRepositoryProvider)
          .fetchForUser(widget.uid);
      final requests = await ref
          .read(paymentRepositoryProvider)
          .fetchAllForUser(widget.uid);

      if (!mounted) return;
      setState(() {
        _member = member;
        _memberships = memberships;
        _requests = requests;
        _loading = false;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).stateGenericError;
      });
    }
  }

  /// PRD section 7.10: "Free PT days: '+1 day used' / '−1' buttons updating
  /// `ptFreeDaysUsed` (0 to `ptFreeDays`)."
  Future<void> _changePtDays(int delta) async {
    final member = _member;
    final settings = ref.read(settingsProvider).value;
    final adminUid = ref.read(currentUidProvider);
    if (member == null || settings == null || adminUid == null) return;

    final next = (member.ptFreeDaysUsed + delta).clamp(0, settings.ptFreeDays);
    if (next == member.ptFreeDaysUsed) return;

    try {
      await ref.read(userRepositoryProvider).setPtFreeDaysUsed(
            uid: member.uid,
            value: next,
            adminUid: adminUid,
          );
      await _load();
    } on RepositoryException {
      if (mounted) {
        showNHSnack(context, L.of(context).adminWriteFailed, isError: true);
      }
    }
  }

  /// PRD section 7.10: "Edit a membership's end date (with a confirm step) for
  /// corrections."
  Future<void> _editEndDate(Membership membership) async {
    final l = L.of(context);
    final civil = istCivil(membership.endDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(civil.year, civil.month, civil.day),
      firstDate: DateTime(civil.year - 2),
      lastDate: DateTime(civil.year + 3),
      helpText: l.adminEditEndDate,
    );
    if (picked == null || !mounted) return;

    final endDay = istDay(picked.year, picked.month, picked.day);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.adminEditEndDate.toUpperCase()),
        content: Text('${l.adminEditEndDateBody}\n\n${formatDate(endDay)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l.actionConfirm,
              style: NHText.body(color: NHColors.red, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;

    try {
      await ref.read(membershipRepositoryProvider).updateEndDate(
            membership: membership,
            endDay: endDay,
            adminUid: adminUid,
          );
      invalidateAdminData(ref);
      await _load();
      if (mounted) showNHSnack(context, l.adminEndDateUpdated);
    } on RepositoryException {
      if (mounted) showNHSnack(context, l.adminWriteFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final member = _member;

    return AdminShell(
      title: member?.name.isNotEmpty == true
          ? member!.name
          : l.adminMemberDetailTitle,
      titleTrailing: BackSquareButton(
        tooltip: l.actionBack,
        onPressed: () => context.go(Routes.adminMembers),
      ),
      children: [
        if (_error != null)
          NHErrorState(message: _error!, onRetry: _load)
        else if (_loading)
          const NHLoading()
        else if (member == null)
          NHEmptyState(
            message: l.adminMembersEmpty,
            icon: Icons.person_off_outlined,
          )
        else ...[
          FadeUp(index: 1, child: _ProfilePanel(member: member)),
          const SizedBox(height: 18),
          FadeUp(
            index: 2,
            child: _FreePtPanel(
              member: member,
              onChange: _changePtDays,
            ),
          ),
          const SizedBox(height: 18),
          FadeUp(
            index: 3,
            child: _Section(
              title: l.adminMemberMemberships,
              trailing: SmallButton(
                label: l.adminRecordCash,
                icon: Icons.payments_outlined,
                onPressed: () async {
                  final done = await showRecordCashSheet(context, member: member);
                  if (done) {
                    if (context.mounted) {
                      showNHSnack(context, l.adminRecordCashDone);
                    }
                    await _load();
                  }
                },
              ),
              child: _memberships.isEmpty
                  ? NHEmptyState(
                      message: l.adminNoMembership,
                      icon: Icons.card_membership_outlined,
                      minHeight: 100,
                    )
                  : Column(
                      children: [
                        for (final membership in _memberships)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MembershipRow(
                              membership: membership,
                              onEditEndDate: () => _editEndDate(membership),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          FadeUp(
            index: 4,
            child: _Section(
              title: l.adminMemberRequests,
              child: _requests.isEmpty
                  ? NHEmptyState(
                      message: l.paymentsEmpty,
                      icon: Icons.receipt_long_outlined,
                      minHeight: 100,
                    )
                  : Column(
                      children: [
                        for (final request in _requests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: request.isPending
                                ? AdminPaymentRow(
                                    request: request,
                                    duplicateUtr: false,
                                    onReviewed: () {
                                      invalidateAdminData(ref);
                                      _load();
                                    },
                                  )
                                : PaymentRequestTile(request: request),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.member});

  final AppUser member;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.adminMemberProfile.toUpperCase(),
                  style: NHText.display(size: 24),
                ),
              ),
              memberStatusPill(context, member),
            ],
          ),
          const SizedBox(height: 12),
          DetailRow(label: l.authFieldName, value: member.name),
          DetailRow(label: l.authFieldEmail, value: member.email),
          if ((member.phone ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.authFieldPhone,
                      style: NHText.body(size: 15, color: NHColors.muted),
                    ),
                  ),
                  PhoneLine(phone: member.phone!),
                ],
              ),
            ),
          if (member.activeUntil != null)
            DetailRow(
              label: l.accountValidTill,
              value: formatDate(member.activeUntil!),
            ),
          if (member.createdAt != null)
            DetailRow(
              label: l.accountSubmittedOnLabel,
              value: formatDate(member.createdAt!),
            ),
        ],
      ),
    );
  }
}

class _FreePtPanel extends ConsumerWidget {
  const _FreePtPanel({required this.member, required this.onChange});

  final AppUser member;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final total = ref.watch(settingsProvider).value?.ptFreeDays ?? 0;
    final used = member.ptFreeDaysUsed.clamp(0, total);

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.adminFreePtTitle.toUpperCase(),
            style: NHText.display(size: 24, color: NHColors.yellow),
          ),
          const SizedBox(height: 10),
          Text(
            l.adminFreePtUsed('$used', '$total'),
            style: NHText.body(size: 15),
          ),
          const SizedBox(height: 10),
          NHProgressBar(
            value: total == 0 ? 0 : used / total,
            color: NHColors.yellow,
            semanticsLabel: l.adminFreePtTitle,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SmallButton(
                label: l.adminFreePtAdd,
                icon: Icons.add,
                onPressed: used >= total ? null : () => onChange(1),
              ),
              const SizedBox(width: 10),
              SmallButton(
                label: l.adminFreePtRemove,
                color: NHColors.surface2,
                onPressed: used <= 0 ? null : () => onChange(-1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({required this.membership, required this.onEditEndDate});

  final Membership membership;
  final VoidCallback onEditEndDate;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        membership.planName,
                        style: NHText.body(size: 15.5, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: switch (membership.state) {
                        MembershipState.active => l.accountStatusActive,
                        MembershipState.upcoming => l.accountStatusUpcoming,
                        MembershipState.expired => l.accountStatusExpired,
                      },
                      kind: switch (membership.state) {
                        MembershipState.active => PillKind.success,
                        MembershipState.upcoming => PillKind.pending,
                        MembershipState.expired => PillKind.danger,
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(membership.startDate)} — '
                  '${formatDate(membership.endDate)}'
                  '${membership.withPT ? ' · ${l.paymentsWithPt}' : ''}',
                  style: NHText.body(size: 13.5, color: NHColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditEndDate,
            icon: const Icon(Icons.edit_calendar_outlined, size: 19),
            tooltip: l.adminEditEndDate,
            constraints: const BoxConstraints(
              minWidth: NHSizes.minTouchTarget,
              minHeight: NHSizes.minTouchTarget,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(), style: NHText.display(size: 26)),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
