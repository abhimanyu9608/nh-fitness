import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/app_user.dart';
import 'package:nh_fitness/data/models/plan.dart';
import 'package:nh_fitness/data/repositories/plan_repository.dart';
import 'package:nh_fitness/data/repositories/settings_repository.dart';
import 'package:nh_fitness/data/repositories/user_repository.dart';
import 'package:nh_fitness/features/plans/plan_selection.dart';

const _newMember = AppUser(
  uid: 'new',
  name: 'Newbie',
  email: 'newbie@example.com',
  hasJoined: false,
);

const _returningMember = AppUser(
  uid: 'old',
  name: 'Renewer',
  email: 'renewer@example.com',
  hasJoined: true,
);

/// A container wired to fixed plans, settings and member, so the pricing rules
/// can be exercised without Firebase.
Future<ProviderContainer> containerFor({
  AppUser? member,
  List<Plan> plans = Plan.defaults,
  AppSettings settings = AppSettings.defaults,
}) async {
  final container = ProviderContainer(
    overrides: [
      activePlansProvider.overrideWith((ref) async => plans),
      settingsProvider.overrideWith((ref) async => settings),
      currentUserProvider.overrideWith((ref) => Stream.value(member)),
    ],
  );

  // Keep every provider alive while the test reads them, then let the
  // overridden futures and streams settle.
  container.listen(activePlansProvider, (_, _) {});
  container.listen(settingsProvider, (_, _) {});
  container.listen(currentUserProvider, (_, _) {});
  container.listen(pricedSelectionProvider, (_, _) {});
  await pumpEventQueue();

  return container;
}

void main() {
  group('resolveSelectedPlan (PRD section 7.3)', () {
    test('honours the plan id from ?plan=', () {
      expect(resolveSelectedPlan(Plan.defaults, 'quarterly')?.id, 'quarterly');
    });

    test('defaults to the best-value plan, which is Yearly in the seed data', () {
      expect(resolveSelectedPlan(Plan.defaults, null)?.id, 'yearly');
    });

    test('ignores a plan id that is no longer available', () {
      expect(resolveSelectedPlan(Plan.defaults, 'retired')?.id, 'yearly');
    });

    test('falls back to the longest plan when none is marked best value', () {
      final plans = [
        for (final plan in Plan.defaults) plan.copyWith(isBestValue: false),
      ];
      expect(resolveSelectedPlan(plans, null)?.id, 'yearly');
    });

    test('returns null when there are no plans at all', () {
      expect(resolveSelectedPlan(const [], 'yearly'), isNull);
    });
  });

  group('registration fee (PRD PLAN-3)', () {
    test('is charged on a first membership', () {
      expect(chargesRegistrationFee(_newMember), isTrue);
    });

    test('is not charged on a renewal', () {
      expect(chargesRegistrationFee(_returningMember), isFalse);
    });

    test('is shown to a visitor who is not logged in', () {
      expect(chargesRegistrationFee(null), isTrue);
    });
  });

  group('free PT days (PRD PLAN-4)', () {
    test('are offered to new members and to visitors', () {
      expect(offersFreePtDays(_newMember), isTrue);
      expect(offersFreePtDays(null), isTrue);
    });

    test('are not offered to a member who has already joined', () {
      expect(offersFreePtDays(_returningMember), isFalse);
    });
  });

  group('pricedSelectionProvider (PRD PLAN-1)', () {
    test('totals plan + registration for a new member with no add-on', () async {
      final container = await containerFor(member: _newMember);
      addTearDown(container.dispose);

      final priced = container.read(pricedSelectionProvider)!;
      expect(priced.plan.id, 'yearly');
      expect(priced.draft.planPrice, 15000);
      expect(priced.draft.registrationFee, 500);
      expect(priced.draft.ptFee, 0);
      expect(priced.total, 15500);
      expect(priced.showsRegistrationFee, isTrue);
      expect(priced.offersFreePt, isTrue);
    });

    test('adds the PT fee when the add-on is on — the PRD section 11 example',
        () async {
      final container = await containerFor(member: _newMember);
      addTearDown(container.dispose);

      container.read(planSelectionProvider.notifier).select('yearly');
      container.read(planSelectionProvider.notifier).setWithPT(true);

      final priced = container.read(pricedSelectionProvider)!;
      // ₹15,000 + ₹500 + ₹5,000.
      expect(priced.total, 20500);
    });

    test('drops the registration fee for a returning member', () async {
      final container = await containerFor(member: _returningMember);
      addTearDown(container.dispose);

      final priced = container.read(pricedSelectionProvider)!;
      expect(priced.draft.registrationFee, 0);
      expect(priced.total, 15000);
      expect(priced.showsRegistrationFee, isFalse);
      expect(priced.offersFreePt, isFalse);
    });

    test('recomputes when the member picks a different plan', () async {
      final container = await containerFor(member: _returningMember);
      addTearDown(container.dispose);

      container.read(planSelectionProvider.notifier).select('monthly');
      expect(container.read(pricedSelectionProvider)!.total, 1500);

      container.read(planSelectionProvider.notifier).select('quarterly');
      expect(container.read(pricedSelectionProvider)!.total, 4000);
    });

    test('uses the prices the owner has edited, never hard-coded ones', () async {
      // PRD HOME-1: prices come from Firestore.
      final container = await containerFor(
        member: _newMember,
        plans: [
          const Plan(
            id: 'yearly',
            name: 'Yearly',
            months: 12,
            price: 18000,
            sortOrder: 1,
            isBestValue: true,
            active: true,
          ),
        ],
        settings: AppSettings.defaults.copyWith(registrationFee: 700, ptFee: 4000),
      );
      addTearDown(container.dispose);

      container.read(planSelectionProvider.notifier).setWithPT(true);
      final priced = container.read(pricedSelectionProvider)!;
      expect(priced.total, 18000 + 700 + 4000);
    });

    test('is null while there are no plans to price', () async {
      final container = await containerFor(member: _newMember, plans: const []);
      addTearDown(container.dispose);
      expect(container.read(pricedSelectionProvider), isNull);
    });
  });

  group('plan selection state', () {
    test('seeding from the query does not overwrite a later choice', () async {
      final container = await containerFor(member: _newMember);
      addTearDown(container.dispose);

      final notifier = container.read(planSelectionProvider.notifier);
      notifier.select('monthly');
      notifier.setWithPT(true);

      // A rebuild re-seeds from the URL; the add-on must survive it.
      notifier.seedFromQuery(planId: 'quarterly', withPT: null);
      final selection = container.read(planSelectionProvider);
      expect(selection.planId, 'quarterly');
      expect(selection.withPT, isTrue);
    });

    test('an empty query leaves the selection alone', () async {
      final container = await containerFor(member: _newMember);
      addTearDown(container.dispose);

      final notifier = container.read(planSelectionProvider.notifier);
      notifier.select('monthly');
      notifier.seedFromQuery();
      expect(container.read(planSelectionProvider).planId, 'monthly');
    });
  });
}
