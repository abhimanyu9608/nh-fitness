import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/assets.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_image.dart';
import '../../core/widgets/nh_logo.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/ticker_band.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../explore/path_cards.dart';

/// `/` — PRD section 7.1.
///
/// The content order is fixed by the PRD: hero, ticker, Why NH Fitness, Gym
/// membership, Pick your path, offer band, footer. Below 600 px the layout
/// switches to the mobile sample: logo, hero text, a 2×2 feature grid, the
/// offer badge and the two buttons, with plans and paths on their own screens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (context) =>
          const NHScaffold(showAnnouncement: true, children: [_MobileHome()]),
      desktop: (context) => const NHScaffold(
        showAnnouncement: true,
        children: [
          _HeroSection(),
          _TickerSection(),
          _WhySection(),
          _MembershipSection(),
          _PathSection(),
          _OfferBand(),
        ],
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // PRD section 5.2: hero 64–136 px on web, responsive.
    final headlineSize = context.bp.isDesktop ? 118.0 : 72.0;

    // A minimum rather than a fixed height: the headline is 118 px and the
    // block below it grows with the member's text-scale setting, so a hard
    // height overflows on a short window. The background layers are positioned,
    // so the text block is what sizes the hero.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.bp.isDesktop ? 620 : 540),
      child: Stack(
        children: [
          // PRD section 5.4: background photo slow zoom (Ken Burns), 18 s.
          Positioned.fill(
            child: KenBurns(
              child: NHImage(
                url: NHAssets.heroPhoto,
                semanticLabel: '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE60D0A0B), Color(0x990D0A0B)],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _HeroStripes()),
          ContentWidth(
            padVertical: const EdgeInsets.symmetric(vertical: 56),
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeUp(
                          index: 0,
                          child: EyebrowLabel(text: l.homeHeroLabel),
                        ),
                        const SizedBox(height: 14),
                        // PRD section 5.4: headline lines rise one by one.
                        FadeUp(
                          index: 1,
                          child: Text(
                            l.homeHeroLine1,
                            style: NHText.display(size: headlineSize),
                          ),
                        ),
                        FadeUp(
                          index: 2,
                          child: Text(
                            l.homeHeroLine2,
                            style: NHText.display(
                              size: headlineSize,
                              color: NHColors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeUp(
                          index: 3,
                          child: Text(
                            l.tagline,
                            style: NHText.body(size: 18, color: NHColors.muted),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeUp(index: 4, child: const _HeroButtons()),
                        const SizedBox(height: 26),
                        FadeUp(
                          index: 5,
                          child: OfferBadge(
                            title: l.homeOfferBadgeTitle,
                            subtitle: l.homeOfferBadgeSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButtons extends StatelessWidget {
  const _HeroButtons();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        // PRD section 5.4: a red pulse ring around the main CTA.
        PulseRing(
          child: PrimaryButton(
            label: l.homeCtaStart,
            expand: false,
            onPressed: () => context.go('/explore'),
          ),
        ),
        GhostButton(
          label: l.navRegisterNow,
          onPressed: () => context.go('/plans'),
        ),
      ],
    );
  }
}

/// PRD section 5.4: "Three red slanted stripes slide in from the right."
class _HeroStripes extends StatelessWidget {
  const _HeroStripes();

  @override
  Widget build(BuildContext context) {
    const widths = [210.0, 150.0, 92.0];

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (var i = 0; i < widths.length; i++)
              Positioned(
                top: -120,
                bottom: -120,
                right: -40 + i * 170.0,
                child: FadeUp(
                  index: i,
                  offset: 0,
                  child: _SlantStripe(width: widths[i], index: i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlantStripe extends StatelessWidget {
  const _SlantStripe({required this.width, required this.index});

  final double width;
  final int index;

  @override
  Widget build(BuildContext context) {
    final offset = context.reduceMotion ? 0.0 : 1.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0),
      duration: Duration(milliseconds: 900 + index * 140),
      curve: NHMotion.curve,
      builder: (context, slide, child) =>
          Transform.translate(offset: Offset(slide * 320, 0), child: child),
      child: Transform.rotate(
        angle: 0.22,
        child: Container(
          width: width,
          color: NHColors.redDeep.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// ── Ticker ───────────────────────────────────────────────────────────────────

/// PRD section 7.1 item 2: the ticker band is web and tablet only.
class _TickerSection extends StatelessWidget {
  const _TickerSection();

  @override
  Widget build(BuildContext context) {
    if (!context.bp.isWide) return const SizedBox.shrink();
    return Padding(
      // The band is tilted, so it needs vertical room for its corners.
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: TickerBand(text: L.of(context).homeTicker),
    );
  }
}

// ── Why NH Fitness ───────────────────────────────────────────────────────────

/// The four reasons from PRD section 7.1 item 3.
class _Feature {
  const _Feature(this.title, this.body, this.icon, this.photo);

  final String title;
  final String body;
  final IconData icon;
  final String photo;
}

List<_Feature> _features(L l) => [
  _Feature(
    l.homeWhyEquipment,
    l.homeWhyEquipmentBody,
    Icons.fitness_center_outlined,
    NHAssets.whyEquipment,
  ),
  _Feature(
    l.homeWhyTrainers,
    l.homeWhyTrainersBody,
    Icons.sports_outlined,
    NHAssets.whyTrainers,
  ),
  _Feature(
    l.homeWhyDiet,
    l.homeWhyDietBody,
    Icons.restaurant_outlined,
    NHAssets.whyDiet,
  ),
  _Feature(
    l.homeWhyHygiene,
    l.homeWhyHygieneBody,
    Icons.cleaning_services_outlined,
    NHAssets.whyHygiene,
  ),
];

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return PageSection(
      top: 40,
      bottom: 60,
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: l.homeWhyTitle),
            const SizedBox(height: 30),
            NHGrid(
              children: [
                for (final feature in _features(l))
                  _FeatureCard(feature: feature),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      builder: (context, hovered) {
        return NHCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PRD section 5.4: the photo zooms to 108% on hover.
              PhotoPanel(
                url: feature.photo,
                semanticLabel: feature.title,
                aspectRatio: 16 / 10,
                zoomOnHover: true,
                hovered: hovered,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(feature.icon, size: 22, color: NHColors.red),
                    const SizedBox(height: 10),
                    Text(feature.title, style: NHText.display(size: 24)),
                    const SizedBox(height: 6),
                    Text(
                      feature.body,
                      style: NHText.body(size: 14.5, color: NHColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Gym membership ───────────────────────────────────────────────────────────

/// PRD section 7.1 item 4 and HOME-1: "Prices and plan list come from
/// Firestore, never hard-coded."
class _MembershipSection extends ConsumerWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final plans = ref.watch(activePlansProvider);
    final settings = ref.watch(settingsProvider);

    return PageSection(
      bottom: 60,
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: l.homeMembershipTitle),
            const SizedBox(height: 30),
            // PRD HOME-2: if Firestore cannot be reached, keep the layout and
            // offer a Retry.
            AsyncSection<List<Plan>>(
              value: plans,
              errorMessage: l.homePricesError,
              onRetry: () {
                ref.invalidate(activePlansProvider);
                ref.invalidate(settingsProvider);
              },
              data: (list) {
                if (list.isEmpty) {
                  return NHEmptyState(
                    message: l.homeNoPlans,
                    icon: Icons.card_membership_outlined,
                  );
                }
                return NHGrid(
                  columns: context.bp.isDesktop ? 4 : 2,
                  children: [
                    for (final plan in list) _HomePlanCard(plan: plan),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            AsyncSection<AppSettings>(
              value: settings,
              minHeight: 80,
              onRetry: () => ref.invalidate(settingsProvider),
              data: (s) => _ChargesPanel(settings: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePlanCard extends StatelessWidget {
  const _HomePlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // Clicking a card carries the choice into /plans (PRD section 7.1).
    void choose() => context.go('/plans?plan=${plan.id}');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name.toUpperCase(),
                style: NHText.display(
                  size: 26,
                  color: plan.isBestValue ? Colors.white : NHColors.text,
                ),
              ),
            ),
            if (plan.isBestValue) YellowTag(label: l.plansBestValue),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          formatRupees(plan.price),
          style: NHText.money(
            size: 50,
            color: plan.isBestValue ? Colors.white : NHColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          plan.isPayAsYouGo
              ? l.plansPayAsYouGo
              : l.plansPerMonth(formatRupees(plan.pricePerMonth)),
          style: NHText.body(
            size: 14.5,
            color: plan.isBestValue
                ? Colors.white.withValues(alpha: 0.85)
                : NHColors.muted,
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: l.plansChoosePlan,
          height: 48,
          onPressed: choose,
          color: plan.isBestValue ? NHColors.bg : NHColors.red,
          pressedColor: plan.isBestValue ? NHColors.ink : NHColors.redDark,
        ),
      ],
    );

    // PRD section 7.1: "Best-value plan uses the red card style."
    return plan.isBestValue
        ? RedCard(onTap: choose, lift: true, child: content)
        : NHCard(onTap: choose, lift: true, child: content);
  }
}

/// The three lines under the plan cards (PRD section 7.1 item 4), all read
/// from `settings/app`.
class _ChargesPanel extends StatelessWidget {
  const _ChargesPanel({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return RaisedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          DetailRow(
            label: l.plansSummaryRegistration,
            value: formatRupees(settings.registrationFee),
          ),
          DetailRow(
            label: l.plansPtFreeDaysLabel('${settings.ptFreeDays}'),
            value: l.stateFree,
            valueStyle: NHText.moneyBody(size: 15, color: NHColors.yellow),
          ),
          DetailRow(
            label: l.plansPtCharge,
            value: formatRupees(settings.ptFee),
          ),
        ],
      ),
    );
  }
}

// ── Pick your path ───────────────────────────────────────────────────────────

class _PathSection extends StatelessWidget {
  const _PathSection();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return PageSection(
      bottom: 60,
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: l.homePathTitle),
            const SizedBox(height: 30),
            const PathCards(),
          ],
        ),
      ),
    );
  }
}

// ── Offer band ───────────────────────────────────────────────────────────────

/// PRD section 7.1 item 6.
class _OfferBand extends StatelessWidget {
  const _OfferBand();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return PageSection(
      bottom: 0,
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NHImage(url: NHAssets.offerBand, semanticLabel: ''),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xCC0D0A0B)),
            ),
            ContentWidth(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.homeOfferBandTitle,
                    textAlign: TextAlign.center,
                    style: NHText.display(
                      size: context.bp.isDesktop ? 58 : 40,
                      color: NHColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: l.navRegisterNow,
                    expand: false,
                    onPressed: () => context.go('/plans'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile home ──────────────────────────────────────────────────────────────

/// PRD section 7.1, last paragraph: "On mobile (< 600 px) Home follows the
/// mobile sample: logo, hero text, 4 feature tiles in a 2×2 grid, offer badge,
/// the two buttons at the bottom. Plans and paths are on their own screens."
class _MobileHome extends StatelessWidget {
  const _MobileHome();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Stack(
      children: [
        // A faint photo keeps the mobile hero from being a flat colour.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 420,
          child: Opacity(
            opacity: 0.30,
            child: KenBurns(
              child: NHImage(url: NHAssets.heroPhotoMobile, semanticLabel: ''),
            ),
          ),
        ),
        ContentWidth(
          padVertical: const EdgeInsets.only(top: 26, bottom: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(index: 0, child: const NHLogo(size: 30)),
              const SizedBox(height: 30),
              FadeUp(index: 1, child: EyebrowLabel(text: l.homeHeroLabel)),
              const SizedBox(height: 12),
              // PRD section 5.2: 68 px hero on mobile.
              FadeUp(
                index: 2,
                child: Text(l.homeHeroLine1, style: NHText.display(size: 58)),
              ),
              FadeUp(
                index: 3,
                child: Text(
                  l.homeHeroLine2,
                  style: NHText.display(size: 58, color: NHColors.red),
                ),
              ),
              const SizedBox(height: 14),
              FadeUp(
                index: 4,
                child: Text(
                  l.tagline,
                  style: NHText.body(size: 16, color: NHColors.muted),
                ),
              ),
              const SizedBox(height: 30),
              FadeUp(index: 5, child: const _MobileFeatureGrid()),
              const SizedBox(height: 24),
              FadeUp(
                index: 6,
                child: OfferBadge(
                  title: l.homeOfferBadgeTitle,
                  subtitle: l.homeOfferBadgeSubtitle,
                ),
              ),
              const SizedBox(height: 28),
              FadeUp(
                index: 7,
                child: Column(
                  children: [
                    PulseRing(
                      child: PrimaryButton(
                        label: l.homeCtaStart,
                        onPressed: () => context.go('/explore'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GhostButton(
                      label: l.navRegisterNow,
                      expand: true,
                      onPressed: () => context.go('/plans'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The 2×2 grid of feature tiles on mobile — icon and title only, no photos,
/// to keep the first screen light on a 4G phone (PRD section 13).
class _MobileFeatureGrid extends StatelessWidget {
  const _MobileFeatureGrid();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHGrid(
      columns: 2,
      spacing: 12,
      children: [
        for (final feature in _features(l))
          NHCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(feature.icon, size: 24, color: NHColors.red),
                const SizedBox(height: 12),
                Text(feature.title, style: NHText.display(size: 21)),
              ],
            ),
          ),
      ],
    );
  }
}
