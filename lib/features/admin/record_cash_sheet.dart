import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_user.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_providers.dart';
import 'review_sheets.dart';

/// PRD section 7.10: "Record cash payment button (for a registered member who
/// paid at the desk): pick the member, plan, add-on → creates an approved
/// request + membership in one batch with `method: 'cash'` and
/// `createdBy: admin`."
///
/// The member has to exist already — PRD section 17 settles that walk-ins
/// register on the app first (staff can help), and the admin then records the
/// cash.
Future<bool> showRecordCashSheet(
  BuildContext context, {
  AppUser? member,
}) async {
  final done = await showNHSheet<bool>(
    context: context,
    builder: (context) => _RecordCashSheet(preselected: member),
  );
  return done ?? false;
}

class _RecordCashSheet extends ConsumerStatefulWidget {
  const _RecordCashSheet({this.preselected});

  final AppUser? preselected;

  @override
  ConsumerState<_RecordCashSheet> createState() => _RecordCashSheetState();
}

class _RecordCashSheetState extends ConsumerState<_RecordCashSheet> {
  final _search = TextEditingController();

  AppUser? _member;
  String? _planId;
  bool _withPT = false;
  bool _searching = false;
  bool _saving = false;
  List<AppUser> _results = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _member = widget.preselected;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final term = _search.text.trim();
    if (term.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(userRepositoryProvider).search(term);
      if (mounted) setState(() => _results = results);
    } on RepositoryException {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save(Plan plan) async {
    final member = _member;
    final settings = ref.read(settingsProvider).value;
    final adminUid = ref.read(currentUidProvider);
    if (member == null || settings == null || adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).recordCashAtDesk(
            member: member,
            plan: plan,
            // PRD PLAN-3: the registration fee applies to a first membership
            // only, at the desk just as in the app.
            registrationFee: member.hasJoined ? 0 : settings.registrationFee,
            ptFee: _withPT ? settings.ptFee : 0,
            withPT: _withPT,
            adminUid: adminUid,
          );
      invalidateAdminData(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).adminWriteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final plans = ref.watch(activePlansProvider).value ?? const <Plan>[];
    final settings = ref.watch(settingsProvider).value;
    final member = _member;

    final plan = plans.where((p) => p.id == _planId).firstOrNull ??
        (plans.isEmpty ? null : plans.first);

    final registrationFee = member == null || member.hasJoined
        ? 0
        : (settings?.registrationFee ?? 0);
    final ptFee = _withPT ? (settings?.ptFee ?? 0) : 0;
    final total = (plan?.price ?? 0) + registrationFee + ptFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.adminRecordCashTitle.toUpperCase(), style: NHText.display(size: 28)),
        const SizedBox(height: 16),

        // ── Member ────────────────────────────────────────────────────────────
        Text(l.adminRecordCashMember, style: NHText.label()),
        const SizedBox(height: 8),
        if (member == null) ...[
          NHTextField(
            label: l.adminMembersSearchHint,
            controller: _search,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            suffix: IconButton(
              onPressed: _runSearch,
              icon: const Icon(Icons.arrow_forward, size: 18),
              tooltip: l.actionSearch,
            ),
          ),
          if (_searching)
            const NHLoading(minHeight: 80)
          else
            for (final result in _results)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: NHCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => setState(() => _member = result),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.name.isEmpty ? result.email : result.name,
                              style: NHText.body(
                                  size: 15, weight: FontWeight.w600),
                            ),
                            Text(
                              [result.email, result.phone ?? '']
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              style:
                                  NHText.body(size: 13, color: NHColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline, size: 19),
                    ],
                  ),
                ),
              ),
        ] else
          RaisedPanel(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name.isEmpty ? member.email : member.name,
                        style: NHText.body(size: 16, weight: FontWeight.w600),
                      ),
                      Text(
                        [member.email, member.phone ?? '']
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: NHText.body(size: 13, color: NHColors.muted),
                      ),
                    ],
                  ),
                ),
                if (widget.preselected == null)
                  IconButton(
                    onPressed: () => setState(() => _member = null),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l.actionCancel,
                  ),
              ],
            ),
          ),

        // ── Plan and add-on ───────────────────────────────────────────────────
        if (member != null) ...[
          const SizedBox(height: 18),
          Text(l.plansSummaryPlan, style: NHText.label()),
          const SizedBox(height: 8),
          if (plans.isEmpty)
            InlineNotice(
              message: l.adminNoPlans,
              color: NHColors.yellow,
              icon: Icons.info_outline,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in plans)
                  NHCard(
                    selected: option.id == (plan?.id ?? ''),
                    onTap: () => setState(() => _planId = option.id),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option.name, style: NHText.body(size: 14.5)),
                        Text(
                          formatRupees(option.price),
                          style: NHText.moneyBody(size: 15),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          NHSwitchRow(
            label: l.plansAddPtTitle,
            value: _withPT,
            onChanged: (value) => setState(() => _withPT = value),
            trailingLabel: Text(
              formatRupees(settings?.ptFee ?? 0),
              style: NHText.moneyBody(size: 15, color: NHColors.red),
            ),
          ),
          const Divider(height: 24),
          if (registrationFee > 0)
            DetailRow(
              label: l.plansSummaryRegistration,
              value: formatRupees(registrationFee),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.plansSummaryTotal.toUpperCase(),
                  style: NHText.display(size: 26),
                ),
              ),
              CountUpRupees(amount: total, style: NHText.money(size: 36)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineNotice(message: _error!),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l.adminRecordCash,
            showIcon: false,
            loading: _saving,
            onPressed: plan == null ? null : () => _save(plan),
          ),
        ],
        const SizedBox(height: 10),
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
