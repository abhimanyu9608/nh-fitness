import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/app_user.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';

/// What the member has picked on `/plans`, carried into `/checkout`.
class PlanSelection {
  const PlanSelection({this.planId, this.withPT = false});

  final String? planId;
  final bool withPT;

  PlanSelection copyWith({String? planId, bool? withPT}) => PlanSelection(
    planId: planId ?? this.planId,
    withPT: withPT ?? this.withPT,
  );
}

/// Held in a provider rather than in the screen so `/plans` and `/checkout`
/// agree, and so the choice survives the trip through `/login`
/// (PRD PAY-5). The same values are mirrored into the URL query, so a refresh
/// restores them too (PRD section 7.3).
class PlanSelectionNotifier extends Notifier<PlanSelection> {
  @override
  PlanSelection build() => const PlanSelection();

  void select(String planId) => state = state.copyWith(planId: planId);

  void setWithPT(bool withPT) => state = state.copyWith(withPT: withPT);

  /// Applies `?plan=` / `?pt=` from the URL, without clobbering a choice the
  /// member has already made in this session.
  void seedFromQuery({String? planId, bool? withPT}) {
    if (planId == null && withPT == null) return;
    state = PlanSelection(
      planId: planId ?? state.planId,
      withPT: withPT ?? state.withPT,
    );
  }
}

final planSelectionProvider =
    NotifierProvider<PlanSelectionNotifier, PlanSelection>(
  PlanSelectionNotifier.new,
);

/// Picks which plan a screen should show as selected.
///
/// PRD section 7.3: "Yearly selected by default, or the plan in `?plan=`".
/// The default is resolved as the best-value plan — which is Yearly in the
/// seed data (PRD section 8.2) — so it keeps working if the owner renames or
/// reprices the plans.
Plan? resolveSelectedPlan(List<Plan> plans, String? planId) {
  if (plans.isEmpty) return null;
  for (final plan in plans) {
    if (plan.id == planId) return plan;
  }
  for (final plan in plans) {
    if (plan.isBestValue) return plan;
  }
  // Fall back to the longest plan, which is the one the gym wants to sell.
  return plans.reduce((a, b) => a.months >= b.months ? a : b);
}

/// PRD PLAN-3: the registration fee is charged only on a member's *first*
/// membership. A visitor who is not logged in still sees it, with the note
/// "One-time, for new members".
bool chargesRegistrationFee(AppUser? user) => user == null || !user.hasJoined;

/// PRD PLAN-4: the free personal-training days are offered to new members only.
bool offersFreePtDays(AppUser? user) => user == null || !user.hasJoined;

/// The priced-up version of the member's current choice.
///
/// Null while plans or settings are still loading, or if the selected plan has
/// since been switched off.
class PricedSelection {
  const PricedSelection({
    required this.plan,
    required this.settings,
    required this.draft,
    required this.showsRegistrationFee,
    required this.offersFreePt,
  });

  final Plan plan;
  final AppSettings settings;
  final PaymentDraft draft;
  final bool showsRegistrationFee;
  final bool offersFreePt;

  int get total => draft.total;
}

/// Combines the selection, the plan list, the settings and the member's
/// `hasJoined` flag into the numbers both `/plans` and `/checkout` display.
///
/// PRD PLAN-1: Total = plan price + registration fee (if applicable) + PT fee
/// (if selected).
final pricedSelectionProvider = Provider<PricedSelection?>((ref) {
  final selection = ref.watch(planSelectionProvider);
  final plans = ref.watch(activePlansProviderForSelection);
  final settings = ref.watch(settingsProvider).value;
  if (plans == null || plans.isEmpty || settings == null) return null;

  final plan = resolveSelectedPlan(plans, selection.planId);
  if (plan == null) return null;

  final user = ref.watch(currentUserProvider).value;
  final chargesRegistration = chargesRegistrationFee(user);
  final registrationFee = chargesRegistration ? settings.registrationFee : 0;
  final ptFee = selection.withPT ? settings.ptFee : 0;

  return PricedSelection(
    plan: plan,
    settings: settings,
    showsRegistrationFee: chargesRegistration,
    offersFreePt: offersFreePtDays(user),
    draft: PaymentDraft(
      planId: plan.id,
      planName: plan.name,
      months: plan.months,
      planPrice: plan.price,
      registrationFee: registrationFee,
      ptFee: ptFee,
      withPT: selection.withPT,
    ),
  );
});

/// Indirection so [pricedSelectionProvider] can read the plan list without
/// caring whether it is still loading.
final activePlansProviderForSelection = Provider<List<Plan>?>(
  (ref) => ref.watch(activePlansProvider).value,
);
