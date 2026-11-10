import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/section.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';

/// The member area frame.
///
/// PRD section 5.5: from 1024 px the account screens get a side menu; below
/// that the mobile bottom nav in [NHScaffold] does the job, so the menu is
/// left out rather than duplicated.
class AccountShell extends StatelessWidget {
  const AccountShell({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.showAnnouncement = false,
    this.aboveTitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showAnnouncement;

  /// The greeting on the dashboard sits above the page title.
  final Widget? aboveTitle;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (aboveTitle != null) ...[
          FadeUp(index: 0, child: aboveTitle!),
          const SizedBox(height: 6),
        ],
        FadeUp(
          index: 0,
          child: SectionTitle(title: title, subtitle: subtitle),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );

    return NHScaffold(
      showAnnouncement: showAnnouncement,
      children: [
        ContentWidth(
          padVertical: const EdgeInsets.only(top: 32, bottom: 56),
          child: context.bp.isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 248, child: AccountSideMenu()),
                    const SizedBox(width: 30),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ],
    );
  }
}

/// PRD AUTH-2: "Logout is in the profile screen and in the web account side
/// menu."
class AccountSideMenu extends ConsumerWidget {
  const AccountSideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final path = GoRouterState.of(context).uri.path;

    final items = <({String label, IconData icon, String path})>[
      (label: l.accountTitle, icon: Icons.card_membership_outlined, path: Routes.account),
      (label: l.navOnlineClasses, icon: Icons.play_circle_outline, path: Routes.accountClasses),
      (label: l.paymentsTitle, icon: Icons.receipt_long_outlined, path: Routes.accountPayments),
      (label: l.profileTitle, icon: Icons.person_outline, path: Routes.accountProfile),
    ];

    return NHCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            SideMenuTile(
              label: item.label,
              icon: item.icon,
              active: path == item.path,
              onTap: () => context.go(item.path),
            ),
          const Divider(height: 18),
          SideMenuTile(
            label: l.actionLogOut,
            icon: Icons.logout_outlined,
            active: false,
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(Routes.home);
            },
          ),
        ],
      ),
    );
  }
}

/// One row in the account or admin side menu.
class SideMenuTile extends StatelessWidget {
  const SideMenuTile({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// The pending-payments count in the admin menu (PRD section 7.10).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) {
        return Semantics(
          button: true,
          selected: active,
          label: label,
          child: ExcludeSemantics(
            child: Material(
              color: active ? NHColors.selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: NHSizes.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: active ? NHColors.red : NHColors.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: NHText.body(
                            size: 15,
                            weight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? NHColors.text
                                : (hovered ? NHColors.yellow : NHColors.muted),
                          ),
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
