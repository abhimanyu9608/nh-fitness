import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/assets.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_image.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/states.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';

/// Height of one of the three smaller path cards.
///
/// The desktop layout needs this to size the row, so it lives here rather than
/// inside the card — otherwise the two could drift apart and the big red card
/// would stop lining up with the stack beside it.
const pathCardHeight = 118.0;

/// Vertical gap between the stacked cards.
const _stackGap = 14.0;

/// The four "Pick your path" cards (PRD section 7.2), shared by `/explore` and
/// the matching section on Home (PRD section 7.1 item 5).
///
/// PRD EXP-1: Supplements and Clothes read `settings/app.supplementsEnabled`
/// and `clothesEnabled`. Both are false in Phase 1, so they render as Coming
/// soon and a tap only shows a toast.
class PathCards extends ConsumerWidget {
  const PathCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider).value;
    final lowestMonthly = ref.watch(lowestMonthlyPriceProvider);

    final membership = _MembershipPathCard(
      fromLine: lowestMonthly == null
          ? null
          : l.exploreMembershipFrom(formatRupees(lowestMonthly)),
    );

    final others = [
      _PathCard(
        title: l.exploreClasses,
        body: l.exploreClassesBody,
        photo: NHAssets.pathClasses,
        icon: Icons.play_circle_outline,
        onTap: () => context.go('/account/classes'),
      ),
      _PathCard(
        title: l.navSupplements,
        body: l.exploreSupplementsBody,
        photo: NHAssets.pathSupplements,
        icon: Icons.local_drink_outlined,
        comingSoon: !(settings?.supplementsEnabled ?? false),
      ),
      _PathCard(
        title: l.navClothes,
        body: l.exploreClothesBody,
        photo: NHAssets.pathClothes,
        icon: Icons.shopping_bag_outlined,
        comingSoon: !(settings?.clothesEnabled ?? false),
      ),
    ];

    // The membership card is the big one, so on wide screens it takes half the
    // row and the other three stack beside it.
    if (context.bp.isDesktop) {
      // `CrossAxisAlignment.stretch` makes a Row size its children to its own
      // height, and this one sits in a scroll view where the available height
      // is infinite. Without a bound the layout throws — and because it throws
      // inside the parent Column, every section on the page goes blank, not
      // just this one.
      //
      // IntrinsicHeight measures the taller side and gives the Row that height,
      // so the big red card and the stack beside it always line up. A fixed
      // height would need adjusting whenever the card's content or the user's
      // text scale changes.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: membership),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  for (var i = 0; i < others.length; i++) ...[
                    if (i > 0) const SizedBox(height: _stackGap),
                    others[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        membership,
        for (final card in others) ...[const SizedBox(height: _stackGap), card],
      ],
    );
  }
}

/// PRD section 7.2: "Membership plans (big red card, '7 days PT free' tag,
/// 'From ₹{lowest monthly-equivalent price} a month')".
class _MembershipPathCard extends StatelessWidget {
  const _MembershipPathCard({required this.fromLine});

  final String? fromLine;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return HoverRegion(
      builder: (context, hovered) {
        return RedCard(
          lift: true,
          padding: EdgeInsets.zero,
          onTap: () => context.go('/plans'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(NHSizes.cardRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.35,
                    child: NHImage(
                      url: NHAssets.pathMembership,
                      semanticLabel: '',
                      zoomOnHover: true,
                      hovered: hovered,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YellowTag(label: l.explorePtFreeTag),
                      const SizedBox(height: 40),
                      Text(
                        l.exploreMembership.toUpperCase(),
                        style: NHText.display(size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      if (fromLine != null)
                        Text(
                          fromLine!,
                          style: NHText.moneyBody(
                            size: 17,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            l.plansChoosePlan.toUpperCase(),
                            style: NHText.button(),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            offset: hovered
                                ? const Offset(0.3, 0)
                                : Offset.zero,
                            duration: NHMotion.hover,
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.body,
    required this.photo,
    required this.icon,
    this.onTap,
    this.comingSoon = false,
  });

  final String title;
  final String body;
  final String photo;
  final IconData icon;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return HoverRegion(
      builder: (context, hovered) {
        return NHCard(
          lift: !comingSoon,
          padding: EdgeInsets.zero,
          clip: true,
          // PRD section 7.2: a tap on a Coming soon card shows a toast.
          onTap: comingSoon
              ? () => showNHSnack(context, l.stateComingSoon)
              : onTap,
          child: SizedBox(
            height: pathCardHeight,
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NHImage(
                        url: photo,
                        semanticLabel: '',
                        // PRD section 5.3: a Coming soon card uses a
                        // grayscale photo.
                        grayscale: comingSoon,
                        zoomOnHover: !comingSoon,
                        hovered: hovered,
                      ),
                      if (comingSoon)
                        Center(child: ComingSoonTape(label: l.stateComingSoon)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 19, color: NHColors.red),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                title.toUpperCase(),
                                style: NHText.display(size: 24),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (comingSoon)
                              YellowTag(
                                label: l.navSoon,
                                blink: context.bp.isMobile,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: NHText.body(size: 14, color: NHColors.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!comingSoon)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.arrow_forward, size: 18),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
