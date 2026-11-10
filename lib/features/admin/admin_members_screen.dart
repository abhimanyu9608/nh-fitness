import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/chip_row.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_user.dart';
import '../../data/models/membership.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/membership_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_payment_row.dart';
import 'admin_shell.dart';
import 'member_status.dart';
import 'record_cash_sheet.dart';

/// `/admin/members` — PRD section 7.10.
class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key, this.initialFilter});

  /// `?filter=expiring`, so the dashboard's "View all" lands on the right tab.
  final String? initialFilter;

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  final _search = TextEditingController();

  MemberFilter _filter = MemberFilter.all;
  final _members = <AppUser>[];
  Map<String, Membership> _memberships = const {};

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true;
  bool _hasMore = false;
  bool _isSearchResult = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filter = switch (widget.initialFilter) {
      'active' => MemberFilter.active,
      'expiring' => MemberFilter.expiringSoon,
      'expired' => MemberFilter.expired,
      'never' => MemberFilter.neverJoined,
      _ => MemberFilter.all,
    };
    _load(first: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Waits for the typing to settle, so a five-letter name costs one search
  /// rather than five (PRD section 13 read budget).
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(first: true);
    });
  }

  Future<void> _load({bool first = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final term = _search.text.trim();

    try {
      final users = ref.read(userRepositoryProvider);
      List<AppUser> page;
      if (term.isNotEmpty) {
        // Search ignores the filter chips — looking someone up by name should
        // find them whatever state their membership is in.
        page = await users.search(term);
        if (!mounted) return;
        setState(() {
          _members
            ..clear()
            ..addAll(page);
          _cursor = null;
          _hasMore = false;
          _isSearchResult = true;
        });
      } else {
        final result = await users.fetchPage(
          filter: _filter,
          startAfter: first ? null : _cursor,
        );
        if (!mounted) return;
        setState(() {
          if (first) _members.clear();
          _members.addAll(result.members);
          _cursor = result.cursor;
          _hasMore = result.hasMore;
          _isSearchResult = false;
        });
      }

      await _loadMembershipNames();
      if (mounted) setState(() => _loading = false);
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

  /// One batched query gives every visible row its plan name.
  Future<void> _loadMembershipNames() async {
    final ids = {
      for (final member in _members)
        if (member.currentMembershipId != null) member.currentMembershipId!,
    };
    if (ids.isEmpty) return;
    try {
      final found =
          await ref.read(membershipRepositoryProvider).fetchByIds(ids);
      if (mounted) setState(() => _memberships = {..._memberships, ...found});
    } on RepositoryException {
      // The plan name is a nicety; the row still shows name, phone and status.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return AdminShell(
      title: l.adminMembersTitle,
      titleTrailing: SmallButton(
        label: l.adminRecordCash,
        icon: Icons.payments_outlined,
        onPressed: () async {
          final done = await showRecordCashSheet(context);
          if (done) {
            if (context.mounted) showNHSnack(context, l.adminRecordCashDone);
            await _load(first: true);
          }
        },
      ),
      children: [
        FadeUp(
          index: 1,
          child: NHTextField(
            label: l.adminMembersSearchHint,
            controller: _search,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _load(first: true),
            suffix: _search.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _search.clear();
                      _load(first: true);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l.actionCancel,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        if (!_isSearchResult)
          FadeUp(
            index: 2,
            child: ChipRow(
              labels: [
                l.adminFilterAll,
                l.adminFilterActive,
                l.adminFilterExpiring,
                l.adminFilterExpired,
                l.adminFilterNeverJoined,
              ],
              selectedIndex: MemberFilter.values.indexOf(_filter),
              onSelected: (index) {
                setState(() => _filter = MemberFilter.values[index]);
                _load(first: true);
              },
            ),
          ),
        const SizedBox(height: 18),
        if (_error != null)
          NHErrorState(message: _error!, onRetry: () => _load(first: true))
        else if (_loading && _members.isEmpty)
          const NHLoading()
        else if (_members.isEmpty)
          NHEmptyState(
            message: l.adminMembersEmpty,
            icon: Icons.people_outline,
          )
        else ...[
          for (final member in _members)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberRow(
                member: member,
                membership: _memberships[member.currentMembershipId ?? ''],
              ),
            ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GhostButton(
                label: l.paymentsLoadMore,
                expand: true,
                loading: _loading,
                onPressed: _loading ? null : _load,
              ),
            ),
        ],
      ],
    );
  }
}

/// PRD section 7.10: "Row: name, phone, plan, valid till, status pill."
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.membership});

  final AppUser member;
  final Membership? membership;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final activeUntil = member.activeUntil;

    return NHCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('${Routes.adminMembers}/${member.uid}'),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.isEmpty ? member.email : member.name,
                  style: NHText.body(size: 15.5, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if ((member.phone ?? '').isNotEmpty)
                  PhoneLine(phone: member.phone!)
                else
                  Text(
                    member.email,
                    style: NHText.body(size: 13, color: NHColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership?.planName ?? l.adminNoMembership,
                  style: NHText.body(size: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                if (activeUntil != null)
                  Text(
                    '${l.accountValidTill} ${formatDate(activeUntil)}',
                    style: NHText.body(size: 13, color: NHColors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          memberStatusPill(context, member),
        ],
      ),
    );
  }
}
