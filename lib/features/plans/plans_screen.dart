import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import 'order_summary.dart';
import 'pending_notice.dart';
import 'plan_selection.dart';

/// `/plans` — PRD section 7.3.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key, this.planIdFromQuery, this.withPtFromQuery});

  /// `?plan=` — PRD section 7.3.
  final String? planIdFromQuery;

  /// `?pt=1`, so a refresh keeps the add-on too.
  final bool? withPtFromQuery;

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  @override
  void initState() {
    super.initState();
    // Seeding has to happen outside build, which cannot change provider state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(planSelectionProvider.notifier).seedFromQuery(
            planId: widget.planIdFromQuery,
            withPT: widget.withPtFromQuery,
          );
    });
  }

  /// Mirrors the choice into the URL so a refresh restores it
  /// (PRD section 7.3). `replace` keeps the browser Back button sane.
  void _syncUrl() {
    final selection = ref.read(planSelectionProvider);
    final plan = selection.planId;
    if (plan == null) return;
    context.replace('/plans?plan=$plan${selection.withPT ? '&pt=1' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final plans = ref.watch(activePlansProvider);

    return NHScaffold(
      children: [
        ContentWidth(
          padVertical: const EdgeInsets.only(top: 34, bottom: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(
                index: 0,
                child: SectionTitle(
                  title: l.plansTitle,
                  subtitle: l.plansSubtitle,
                ),
              ),
              const SizedBox(height: 22),
              const FadeUp(index: 1, child: PendingRequestNotice()),
              const SizedBox(height: 12),
              AsyncSection<List<Plan>>(
                value: plans,
                errorMessage: l.homePricesError,
                onRetry: () {
                  ref.invalidate(activePlansProvider);
                  ref.invalidate(settingsProvider);
                },
                data: (list) => list.isEmpty
                    ? NHEmptyState(
                        message: l.homeNoPlans,
                        icon: Icons.card_membership_outlined,
                      )
                    : _PlansBody(plans: list, onSelectionChanged: _syncUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlansBody extends ConsumerWidget {
  const _PlansBody({required this.plans, required this.onSelectionChanged});

  final List<Plan> plans;
  final VoidCallback onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priced = ref.watch(pricedSelectionProvider);
    if (priced == null) return const NHLoading();

    final selection = ref.watch(planSelectionProvider);
    final notifier = ref.read(planSelectionProvider.notifier);

    final picker = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PRD section 7.3: a 2×2 grid of plan cards.
        NHGrid(
          columns: 2,
          children: [
            for (final plan in plans)
              PlanPickerCard(
                plan: plan,
                selected: plan.id == priced.plan.id,
                onTap: () {
                  notifier.select(plan.id);
                  onSelectionChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        _AddOnToggle(
          withPT: selection.withPT,
          ptFee: priced.settings.ptFee,
          ptFreeDays: priced.settings.ptFreeDays,
          showFreeDays: priced.offersFreePt,
          onChanged: (value) {
            notifier.setWithPT(value);
            onSelectionChanged();
          },
        ),
      ],
    );

    final summary = _OrderSummary(priced: priced);

    if (context.bp.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: FadeUp(index: 2, child: picker)),
          const SizedBox(width: 26),
          Expanded(flex: 4, child: FadeUp(index: 3, child: summary)),
        ],
      );
    }

    return Column(
      children: [
        FadeUp(index: 2, child: picker),
        const SizedBox(height: 22),
        FadeUp(index: 3, child: summary),
      ],
    );
  }
}

/// PRD section 5.3: "`surface`, 2 px `line` border, radius 16–18. Selected: red
/// border, `selectedBg` fill, tick circle filled red. Yearly card has a yellow
/// 'Best value' tag on its top edge."
class PlanPickerCard extends StatelessWidget {
  const PlanPickerCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.name}, ${formatRupees(plan.price)}'
          '${plan.isBestValue ? ', ${l.plansBestValue}' : ''}',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NHCard(
              selected: selected,
              onTap: onTap,
              lift: true,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name.toUpperCase(),
                          style: NHText.display(size: 25),
                        ),
                      ),
                      _TickCircle(selected: selected),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(formatRupees(plan.price), style: NHText.money(size: 44)),
                  const SizedBox(height: 4),
                  Text(
                    plan.isPayAsYouGo
                        ? l.plansPayAsYouGo
                        : l.plansPerMonth(formatRupees(plan.pricePerMonth)),
                    style: NHText.body(size: 14, color: NHColors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.months == 1
                        ? l.plansMonthsOne
                        : l.plansMonthsOther('${plan.months}'),
                    style: NHText.label(size: 11),
                  ),
                ],
              ),
            ),
            // The tag sits on the card's top edge.
            if (plan.isBestValue)
              Positioned(
                top: -10,
                left: 16,
                child: YellowTag(label: l.plansBestValue, icon: Icons.star_outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _TickCircle extends StatelessWidget {
  const _TickCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: NHMotion.hover,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? NHColors.red : Colors.transparent,
        border: Border.all(
          color: selected ? NHColors.red : NHColors.line,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// PRD section 7.3: "Add personal training — ₹{ptFee} — First {ptFreeDays}
/// days free".
class _AddOnToggle extends StatelessWidget {
  const _AddOnToggle({
    required this.withPT,
    required this.ptFee,
    required this.ptFreeDays,
    required this.showFreeDays,
    required this.onChanged,
  });

  final bool withPT;
  final int ptFee;
  final int ptFreeDays;

  /// PRD PLAN-4: the free days line is for new members only.
  final bool showFreeDays;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      selected: withPT,
      child: NHSwitchRow(
        label: l.plansAddPtTitle,
        value: withPT,
        onChanged: onChanged,
        subtitle: showFreeDays ? l.plansAddPtFreeDays('$ptFreeDays') : null,
        trailingLabel: Text(
          formatRupees(ptFee),
          style: NHText.moneyBody(size: 16, color: NHColors.red),
        ),
      ),
    );
  }
}

/// PRD section 7.3: "plan price, registration charge (only if the user has
/// never joined), personal training (if selected), Total."
class _OrderSummary extends ConsumerWidget {
  const _OrderSummary({required this.priced});

  final PricedSelection priced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final draft = priced.draft;
    // PRD PAY-1: with a request already waiting, the Continue button is off.
    final hasPending = ref.watch(myPendingPaymentProvider) != null;

    return OrderSummaryCard(
      priced: priced,
      showOffer: priced.offersFreePt,
      action: PrimaryButton(
        label: l.plansContinueToPayment,
        onPressed: hasPending
            ? null
            : () => context.go(
                  '${Routes.checkout}?plan=${draft.planId}'
                  '${draft.withPT ? '&pt=1' : ''}',
                ),
      ),
    );
  }
}
