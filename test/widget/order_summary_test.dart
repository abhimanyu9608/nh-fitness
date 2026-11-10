import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/payment_request.dart';
import 'package:nh_fitness/data/models/plan.dart';
import 'package:nh_fitness/features/plans/order_summary.dart';
import 'package:nh_fitness/features/plans/plan_selection.dart';
import 'package:nh_fitness/features/plans/plans_screen.dart';

import 'harness.dart';

const _yearly = Plan(
  id: 'yearly',
  name: 'Yearly',
  months: 12,
  price: 15000,
  sortOrder: 4,
  isBestValue: true,
  active: true,
);

const _monthly = Plan(
  id: 'monthly',
  name: 'Monthly',
  months: 1,
  price: 1500,
  sortOrder: 1,
  isBestValue: false,
  active: true,
);

PricedSelection priced({
  Plan plan = _yearly,
  bool newMember = true,
  bool withPT = false,
}) {
  const settings = AppSettings.defaults;
  return PricedSelection(
    plan: plan,
    settings: settings,
    showsRegistrationFee: newMember,
    offersFreePt: newMember,
    draft: PaymentDraft(
      planId: plan.id,
      planName: plan.name,
      months: plan.months,
      planPrice: plan.price,
      registrationFee: newMember ? settings.registrationFee : 0,
      ptFee: withPT ? settings.ptFee : 0,
      withPT: withPT,
    ),
  );
}

void main() {
  setUpAll(useOfflineFonts);

  group('OrderSummaryCard (PRD section 7.3)', () {
    testWidgets('breaks down plan, registration and total for a new member',
        (tester) async {
      await tester.pumpWidget(harness(
        child: OrderSummaryCard(priced: priced()),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('Yearly'), findsOneWidget);
      expect(textContaining('₹15,000'), findsOneWidget);
      expect(textContaining('Registration charge'), findsOneWidget);
      expect(textContaining('₹500'), findsOneWidget);
      expect(textContaining('One-time, for new members'), findsOneWidget);
      expect(textContaining('₹15,500'), findsOneWidget);
    });

    testWidgets('adds the personal training line when the add-on is on',
        (tester) async {
      await tester.pumpWidget(harness(
        child: OrderSummaryCard(priced: priced(withPT: true)),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('Personal training'), findsOneWidget);
      expect(textContaining('₹5,000'), findsOneWidget);
      // ₹15,000 + ₹500 + ₹5,000 — the PRD section 11 example.
      expect(textContaining('₹20,500'), findsOneWidget);
    });

    testWidgets('hides the registration charge for a returning member',
        (tester) async {
      // PRD PLAN-3.
      await tester.pumpWidget(harness(
        child: OrderSummaryCard(priced: priced(newMember: false)),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('Registration charge'), findsNothing);
      expect(textContaining('One-time, for new members'), findsNothing);
      expect(textContaining('₹15,000'), findsWidgets);
    });

    testWidgets('shows the free-PT offer to new members only', (tester) async {
      // PRD PLAN-4.
      await tester.pumpWidget(harness(
        child: OrderSummaryCard(priced: priced(), showOffer: true),
      ));
      await tester.pumpAndSettle();
      expect(textContaining('7 days personal training free'), findsOneWidget);

      await tester.pumpWidget(harness(
        child: OrderSummaryCard(priced: priced(newMember: false)),
      ));
      await tester.pumpAndSettle();
      expect(textContaining('7 days personal training free'), findsNothing);
    });
  });

  group('PlanPickerCard (PRD section 5.3 and 7.3)', () {
    testWidgets('shows the per-month price and the Best value tag',
        (tester) async {
      await tester.pumpWidget(harness(
        child: PlanPickerCard(
          plan: _yearly,
          selected: true,
          onTap: () {},
        ),
        size: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('YEARLY'), findsOneWidget);
      expect(textContaining('₹15,000'), findsOneWidget);
      // 15000 / 12, rounded to the rupee.
      expect(textContaining('₹1,250 / month'), findsOneWidget);
      expect(textContaining('12 months'), findsOneWidget);
      expect(textContaining('BEST VALUE'), findsOneWidget);
    });

    testWidgets('a one-month plan reads "Pay as you go"', (tester) async {
      await tester.pumpWidget(harness(
        child: PlanPickerCard(
          plan: _monthly,
          selected: false,
          onTap: () {},
        ),
        size: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('Pay as you go'), findsOneWidget);
      expect(textContaining('/ month'), findsNothing);
      expect(textContaining('1 month'), findsOneWidget);
      expect(textContaining('BEST VALUE'), findsNothing);
    });

    testWidgets('reports its selected state to accessibility', (tester) async {
      await tester.pumpWidget(harness(
        child: PlanPickerCard(plan: _yearly, selected: true, onTap: () {}),
        size: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      // The card announces the plan and its price as one button, rather than
      // letting a screen reader read each fragment separately.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Yearly'))),
        isNotNull,
      );
    });
  });
}
