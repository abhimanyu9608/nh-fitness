import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../l10n/app_localizations.dart';
import 'plan_selection.dart';

/// PRD section 7.3: "Order summary: plan price, registration charge (only if
/// the user has never joined, see PLAN-3), personal training (if selected),
/// Total."
///
/// Shared by `/plans` and `/checkout` so the member sees the same breakdown
/// before and after logging in.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.priced,
    this.action,
    this.showOffer = false,
  });

  final PricedSelection priced;

  /// "Continue to payment" on `/plans`, "I have paid …" on `/checkout`.
  final Widget? action;

  /// PRD PLAN-4: the free-PT offer badge, for new members only.
  final bool showOffer;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final draft = priced.draft;
    final months = priced.plan.months == 1
        ? l.plansMonthsOne
        : l.plansMonthsOther('${priced.plan.months}');

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.plansOrderSummary.toUpperCase(), style: NHText.display(size: 26)),
          const SizedBox(height: 14),
          DetailRow(
            label: '${priced.plan.name} · $months',
            value: formatRupees(draft.planPrice),
          ),
          if (priced.showsRegistrationFee) ...[
            DetailRow(
              label: l.plansSummaryRegistration,
              value: formatRupees(draft.registrationFee),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l.plansRegistrationNote,
                style: NHText.body(size: 12.5, color: NHColors.muted),
              ),
            ),
          ],
          if (draft.withPT)
            DetailRow(
              label: l.plansSummaryPt,
              value: formatRupees(draft.ptFee),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l.plansSummaryTotal.toUpperCase(),
                  style: NHText.display(size: 28),
                ),
              ),
              // PRD section 5.4: the total counts up or down in 450 ms when the
              // plan or the add-on changes.
              CountUpRupees(amount: draft.total, style: NHText.money(size: 42)),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
          if (showOffer) ...[
            const SizedBox(height: 16),
            OfferBadge(
              title: l.plansPtFreeNote,
              subtitle: l.homeOfferBadgeSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}
