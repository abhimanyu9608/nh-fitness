import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_user.dart';
import '../../data/models/staff_member.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_shell.dart';
import 'review_sheets.dart';

/// `/admin/staff` — who can use the admin panel.
///
/// Owners manage staff here. Owners themselves live in `owners/{uid}`, which
/// is created by hand in the Firebase Console and is not writable from the app
/// — that is what stops a compromised staff login from locking the owner out.
class AdminStaffScreen extends ConsumerWidget {
  const AdminStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final isOwner = ref.watch(isOwnerProvider).value ?? false;
    final staff = ref.watch(staffProvider);

    return AdminShell(
      title: l.adminStaffTitle,
      subtitle: l.adminStaffSubtitle,
      titleTrailing: isOwner
          ? SmallButton(
              label: l.adminStaffAdd,
              icon: Icons.person_add_alt,
              onPressed: () => _openAddSheet(context, ref),
            )
          : null,
      children: [
        if (!isOwner)
          FadeUp(
            index: 1,
            child: InlineNotice(
              message:
                  '${l.adminStaffOwnerOnlyTitle}. ${l.adminStaffOwnerOnlyBody}',
              icon: Icons.lock_outline,
              color: NHColors.yellow,
            ),
          )
        else
          FadeUp(
            index: 1,
            child: InlineNotice(
              message: l.adminStaffOwnerNote,
              icon: Icons.shield_outlined,
              color: NHColors.muted,
            ),
          ),
        const SizedBox(height: 16),
        AsyncSection<List<StaffMember>>(
          value: staff,
          onRetry: () => ref.invalidate(staffProvider),
          data: (people) {
            final owners = people.where((p) => p.isOwner).toList();
            final admins = people.where((p) => !p.isOwner).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (owners.isNotEmpty) ...[
                  FadeUp(
                    index: 2,
                    child: _SectionLabel(label: l.adminStaffOwnersSection),
                  ),
                  for (final owner in owners)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StaffRow(member: owner, canRemove: false),
                    ),
                  const SizedBox(height: 18),
                ],
                FadeUp(
                  index: 3,
                  child: _SectionLabel(label: l.adminStaffStaffSection),
                ),
                if (admins.isEmpty)
                  NHEmptyState(
                    message: l.adminStaffNone,
                    icon: Icons.people_outline,
                    minHeight: 120,
                  )
                else
                  for (final member in admins)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StaffRow(
                        member: member,
                        canRemove: isOwner,
                        onRemove: () => _confirmRemove(context, ref, member),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final added = await showNHSheet<bool>(
      context: context,
      builder: (context) => const _AddStaffSheet(),
    );
    if (added == true) ref.invalidate(staffProvider);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    StaffMember member,
  ) async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.adminStaffRemoveTitle.toUpperCase()),
        content: Text(l.adminStaffRemoveBody(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l.adminStaffRemove,
              style: NHText.body(color: NHColors.danger, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).removeStaff(member.uid);
      ref.invalidate(staffProvider);
      if (context.mounted) {
        showNHSnack(context, l.adminStaffRemoved(member.name));
      }
    } on RepositoryException {
      if (context.mounted) {
        showNHSnack(context, l.adminWriteFailed, isError: true);
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label.toUpperCase(), style: NHText.label()),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.member,
    required this.canRemove,
    this.onRemove,
  });

  final StaffMember member;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(14),
      borderColor: member.isOwner ? NHColors.yellow : null,
      child: Row(
        children: [
          Icon(
            member.isOwner ? Icons.shield_outlined : Icons.person_outline,
            size: 20,
            color: member.isOwner ? NHColors.yellow : NHColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.isEmpty ? member.uid : member.name,
                  style: NHText.body(size: 15.5, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.addedAt != null)
                  Text(
                    l.adminStaffAddedOn(formatDate(member.addedAt!)),
                    style: NHText.body(size: 13, color: NHColors.muted),
                  ),
              ],
            ),
          ),
          if (member.isOwner)
            YellowTag(label: l.adminStaffOwnerBadge)
          else if (canRemove)
            SmallButton(
              label: l.adminStaffRemove,
              color: NHColors.surface2,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Finds a member by name or email and grants them admin access.
///
/// Searching `users` rather than asking for a raw uid: an owner knows their
/// staff member's email, not a 28-character Firebase id.
class _AddStaffSheet extends ConsumerStatefulWidget {
  const _AddStaffSheet();

  @override
  ConsumerState<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<_AddStaffSheet> {
  final _search = TextEditingController();

  List<AppUser> _results = const [];
  Set<String> _existing = const {};
  bool _searching = false;
  bool _searched = false;
  String? _savingUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _existing = {
      for (final member in ref.read(staffProvider).value ?? const <StaffMember>[])
        member.uid,
    };
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final term = _search.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await ref.read(userRepositoryProvider).search(term);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        _searched = true;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searched = true;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).stateGenericError;
      });
    }
  }

  Future<void> _add(AppUser user) async {
    final ownerUid = ref.read(currentUidProvider);
    if (ownerUid == null) return;

    setState(() {
      _savingUid = user.uid;
      _error = null;
    });

    try {
      await ref.read(adminRepositoryProvider).addStaff(
            uid: user.uid,
            name: user.name.isEmpty ? user.email : user.name,
            ownerUid: ownerUid,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _savingUid = null;
        _error = error.isPermissionDenied
            // Only an owner may write `admins`, enforced by the rules.
            ? L.of(context).adminStaffOwnerOnlyBody
            : L.of(context).adminWriteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.adminStaffAddTitle.toUpperCase(), style: NHText.display(size: 28)),
        const SizedBox(height: 8),
        Text(
          l.adminStaffAddHelp,
          style: NHText.body(size: 14.5, color: NHColors.muted),
        ),
        const SizedBox(height: 18),
        NHTextField(
          label: l.adminStaffSearchHint,
          controller: _search,
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          autofocus: true,
          onSubmitted: (_) => _runSearch(),
          suffix: IconButton(
            onPressed: _runSearch,
            icon: const Icon(Icons.arrow_forward, size: 18),
            tooltip: l.actionSearch,
          ),
        ),
        if (_searching)
          const NHLoading(minHeight: 90)
        else if (_results.isEmpty && _searched)
          NHEmptyState(
            message: l.adminStaffNoMatches,
            icon: Icons.person_search_outlined,
            minHeight: 110,
          )
        else
          for (final user in _results)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: NHCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isEmpty ? user.email : user.name,
                            style:
                                NHText.body(size: 15, weight: FontWeight.w600),
                          ),
                          Text(
                            user.email,
                            style:
                                NHText.body(size: 13, color: NHColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_existing.contains(user.uid))
                      Text(
                        l.adminStaffAlreadyHasAccess,
                        style: NHText.label(size: 11, color: NHColors.success),
                      )
                    else
                      SmallButton(
                        label: l.adminStaffAdd,
                        onPressed: _savingUid == null ? () => _add(user) : null,
                      ),
                  ],
                ),
              ),
            ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          InlineNotice(message: _error!),
        ],
        const SizedBox(height: 18),
        GhostButton(
          label: l.actionCancel,
          expand: true,
          height: 48,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
