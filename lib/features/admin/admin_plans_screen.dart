import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/validators.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/plan_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_shell.dart';
import 'review_sheets.dart';

/// `/admin/plans` — PRD section 7.10.
///
/// "Plans are never deleted, only made inactive (old payment records point to
/// them)."
class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final plans = ref.watch(allPlansProvider);

    return AdminShell(
      title: l.adminPlansTitle,
      titleTrailing: SmallButton(
        label: l.adminPlanAdd,
        icon: Icons.add,
        onPressed: () => _openEditor(context, ref, null),
      ),
      children: [
        FadeUp(
          index: 1,
          child: InlineNotice(
            message: l.adminPlanNeverDeleted,
            icon: Icons.info_outline,
            color: NHColors.muted,
          ),
        ),
        const SizedBox(height: 16),
        AsyncSection<List<Plan>>(
          value: plans,
          onRetry: () => ref.invalidate(allPlansProvider),
          data: (list) {
            if (list.isEmpty) {
              return NHEmptyState(
                message: l.adminNoPlans,
                icon: Icons.sell_outlined,
                action: PrimaryButton(
                  label: l.adminSeedPlans,
                  expand: false,
                  showIcon: false,
                  onPressed: () => _seedDefaults(context, ref),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeUp(
                      index: i < 6 ? i + 2 : 0,
                      child: _PlanRow(
                        plan: list[i],
                        onEdit: () => _openEditor(context, ref, list[i]),
                        onToggleActive: (active) => _save(
                          context,
                          ref,
                          list[i].copyWith(active: active),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, Plan? plan) async {
    final saved = await showNHSheet<bool>(
      context: context,
      builder: (context) => _PlanEditor(plan: plan),
    );
    if (saved == true) {
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlansProvider);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref, Plan plan) async {
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;
    try {
      await ref.read(planRepositoryProvider).save(plan, adminUid: adminUid);
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlansProvider);
    } on RepositoryException {
      if (context.mounted) {
        showNHSnack(context, L.of(context).adminWriteFailed, isError: true);
      }
    }
  }

  /// PRD section 7.10: "If no plans exist, show Create default plans which
  /// writes the defaults in section 8.2."
  Future<void> _seedDefaults(BuildContext context, WidgetRef ref) async {
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;
    try {
      await ref.read(planRepositoryProvider).seedDefaults(adminUid: adminUid);
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlansProvider);
      if (context.mounted) {
        showNHSnack(context, L.of(context).adminSeedPlansDone);
      }
    } on RepositoryException {
      if (context.mounted) {
        showNHSnack(context, L.of(context).adminWriteFailed, isError: true);
      }
    }
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.onEdit,
    required this.onToggleActive,
  });

  final Plan plan;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        plan.name,
                        style: NHText.body(size: 16, weight: FontWeight.w700),
                      ),
                    ),
                    if (plan.isBestValue) ...[
                      const SizedBox(width: 8),
                      YellowTag(label: l.plansBestValue),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${plan.id} · ${plan.months == 1 ? l.plansMonthsOne : l.plansMonthsOther('${plan.months}')}'
                  ' · #${plan.sortOrder}',
                  style: NHText.body(size: 13, color: NHColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(formatRupees(plan.price), style: NHText.money(size: 28)),
          const SizedBox(width: 14),
          // PRD section 7.10: never delete a plan — switch it off.
          Semantics(
            label: l.adminPlanActive,
            toggled: plan.active,
            child: ExcludeSemantics(
              child: Switch(value: plan.active, onChanged: onToggleActive),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: l.actionEdit,
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

class _PlanEditor extends ConsumerStatefulWidget {
  const _PlanEditor({this.plan});

  /// Null when adding a new plan.
  final Plan? plan;

  @override
  ConsumerState<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<_PlanEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _months;
  late final TextEditingController _price;
  late final TextEditingController _sortOrder;

  late bool _isBestValue;
  late bool _active;
  bool _saving = false;
  String? _error;
  String? _idError;

  bool get _isNew => widget.plan == null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _id = TextEditingController(text: plan?.id ?? '');
    _name = TextEditingController(text: plan?.name ?? '');
    _months = TextEditingController(text: '${plan?.months ?? 1}');
    _price = TextEditingController(text: '${plan?.price ?? 0}');
    _sortOrder = TextEditingController(text: '${plan?.sortOrder ?? 1}');
    _isBestValue = plan?.isBestValue ?? false;
    _active = plan?.active ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _months.dispose();
    _price.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;

    final id = _id.text.trim();
    setState(() {
      _saving = true;
      _error = null;
      _idError = null;
    });

    final repo = ref.read(planRepositoryProvider);

    try {
      // A new plan must not land on an existing id — that would silently
      // reprice a plan old payment records point at.
      if (_isNew && await repo.exists(id)) {
        setState(() {
          _saving = false;
          _idError = L.of(context).adminPlanIdTaken;
        });
        return;
      }

      await repo.save(
        Plan(
          id: id,
          name: _name.text.trim(),
          months: int.parse(_months.text.trim()),
          price: int.parse(_price.text.trim()),
          sortOrder: int.parse(_sortOrder.text.trim()),
          isBestValue: _isBestValue,
          active: _active,
        ),
        adminUid: adminUid,
      );
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

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (_isNew ? l.adminPlanNewTitle : l.adminPlanEditTitle).toUpperCase(),
            style: NHText.display(size: 28),
          ),
          const SizedBox(height: 18),
          NHTextField(
            label: l.adminPlanIdLabel,
            controller: _id,
            helper: l.adminPlanIdHelp,
            errorText: _idError,
            // The id is the Firestore document id, so it can never change.
            enabled: _isNew,
            validator: (value) =>
                Validate.planId(value ?? '') ? null : l.adminPlanIdHelp,
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminPlanName,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? l.adminErrorRequired : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NHTextField(
                  label: l.adminPlanMonths,
                  controller: _months,
                  digitsOnly: true,
                  keyboardType: TextInputType.number,
                  validator: _positiveInt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NHTextField(
                  label: l.adminPlanPrice,
                  controller: _price,
                  digitsOnly: true,
                  keyboardType: TextInputType.number,
                  validator: _nonNegativeInt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminPlanSortOrder,
            controller: _sortOrder,
            digitsOnly: true,
            keyboardType: TextInputType.number,
            validator: _nonNegativeInt,
          ),
          const SizedBox(height: 10),
          NHSwitchRow(
            label: l.adminPlanBestValue,
            value: _isBestValue,
            onChanged: (value) => setState(() => _isBestValue = value),
          ),
          NHSwitchRow(
            label: l.adminPlanActive,
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineNotice(message: _error!),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l.actionSave,
            showIcon: false,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: l.actionCancel,
            expand: true,
            height: 48,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    return parsed != null && parsed > 0 ? null : L.of(context).adminErrorNumber;
  }

  String? _nonNegativeInt(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    return parsed != null && parsed >= 0 ? null : L.of(context).adminErrorNumber;
  }
}
