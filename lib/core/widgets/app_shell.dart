import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../features/announcements/announcement_strip.dart';
import '../../l10n/app_localizations.dart';
import '../motion.dart';
import '../responsive.dart';
import 'nh_buttons.dart';
import 'nh_logo.dart';
import 'nh_pill.dart';
import 'offline_bar.dart';
import 'states.dart';

/// One nav entry in the header, drawer and footer.
class NavItem {
  const NavItem({
    required this.label,
    required this.path,
    this.comingSoon = false,
  });

  final String label;
  final String path;

  /// Supplements and Clothes are shown but inert in Phase 1 (PRD section 6).
  final bool comingSoon;
}

List<NavItem> mainNavItems(L l) => [
  NavItem(label: l.navHome, path: '/'),
  NavItem(label: l.navPlans, path: '/plans'),
  NavItem(label: l.navOnlineClasses, path: '/account/classes'),
  NavItem(label: l.navSupplements, path: '/explore', comingSoon: true),
  NavItem(label: l.navClothes, path: '/explore', comingSoon: true),
];

/// The page frame every screen outside the admin panel sits in: offline bar,
/// header, scrolling content, footer, and the mobile bottom nav for members
/// (PRD sections 5.5 and 6).
class NHScaffold extends ConsumerWidget {
  const NHScaffold({
    super.key,
    required this.children,
    this.showFooter = true,
    this.showAnnouncement = false,
    this.scrollController,
    this.maxContentOnly = false,
  });

  /// Full-width page blocks. Each block handles its own horizontal padding,
  /// usually with [ContentWidth], so sections can bleed to the edges.
  final List<Widget> children;

  final bool showFooter;

  /// PRD section 7.9: the announcement strip belongs on Home and the member
  /// dashboard, so those two screens opt in.
  final bool showAnnouncement;
  final ScrollController? scrollController;

  /// Convenience for simple pages (login, legal): wraps every child in
  /// [ContentWidth] instead of making each one do it.
  final bool maxContentOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(currentUidProvider) != null;
    final showBottomNav = context.bp.isMobile && loggedIn;

    return Scaffold(
      backgroundColor: NHColors.bg,
      endDrawer: context.bp.isMobile ? const NHDrawer() : null,
      body: Column(
        children: [
          const OfflineBar(),
          const NHHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showAnnouncement) const AnnouncementStrip(),
                  for (final child in children)
                    maxContentOnly ? ContentWidth(child: child) : child,
                  if (showFooter) const NHFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav ? const NHBottomNav() : null,
    );
  }
}

/// PRD section 6: "logo, Home, Plans, Online classes, Supplements (Soon),
/// Clothes (Soon), then Login + Register now when logged out, or My account
/// (+ Admin for admins) when logged in."
class NHHeader extends ConsumerWidget {
  const NHHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final loggedIn = ref.watch(currentUidProvider) != null;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final path = GoRouterState.of(context).uri.path;

    return Container(
      decoration: const BoxDecoration(
        color: NHColors.bg,
        border: Border(bottom: BorderSide(color: NHColors.line, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _LogoLink(compact: context.bp.isMobile),
                const Spacer(),
                if (context.bp.isWide) ...[
                  for (final item in mainNavItems(l))
                    _HeaderLink(item: item, active: path == item.path),
                  const SizedBox(width: 14),
                  if (loggedIn) ...[
                    if (isAdmin)
                      GhostButton(
                        label: l.navAdmin,
                        height: 44,
                        onPressed: () => context.go('/admin'),
                      ),
                    if (isAdmin) const SizedBox(width: 10),
                    PrimaryButton(
                      label: l.navMyAccount,
                      expand: false,
                      height: 44,
                      showIcon: false,
                      onPressed: () => context.go('/account'),
                    ),
                  ] else ...[
                    GhostButton(
                      label: l.navLogin,
                      height: 44,
                      onPressed: () => context.go('/login'),
                    ),
                    const SizedBox(width: 10),
                    PrimaryButton(
                      label: l.navRegisterNow,
                      expand: false,
                      height: 44,
                      showIcon: false,
                      onPressed: () => context.go('/register'),
                    ),
                  ],
                ] else
                  // Mobile: everything lives behind the menu button.
                  IconButton(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.menu),
                    tooltip: l.navMenu,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoLink extends StatelessWidget {
  const _LogoLink({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${L.of(context).appName}, ${L.of(context).navHome}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: NHLogo(size: compact ? 23 : 26, showWordmark: !compact),
          ),
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return HoverRegion(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) {
        final color = active
            ? NHColors.red
            : (hovered ? NHColors.yellow : NHColors.text);
        return Semantics(
          button: true,
          selected: active,
          label: item.comingSoon ? '${item.label} (${l.navSoon})' : item.label,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () {
                if (item.comingSoon) {
                  showNHSnack(context, l.stateComingSoon);
                } else {
                  context.go(item.path);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: NHSizes.minTouchTarget,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  children: [
                    Text(
                      item.label,
                      style: NHText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: item.comingSoon ? NHColors.muted : color,
                      ),
                    ),
                    if (item.comingSoon) ...[
                      const SizedBox(width: 6),
                      YellowTag(label: l.navSoon),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The mobile menu. Same links as the desktop header, plus log out.
class NHDrawer extends ConsumerWidget {
  const NHDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final loggedIn = ref.watch(currentUidProvider) != null;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: NHColors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: NHLogo(size: 26),
            ),
            for (final item in mainNavItems(l))
              ListTile(
                title: Text(item.label, style: NHText.body(size: 16)),
                trailing: item.comingSoon ? YellowTag(label: l.navSoon) : null,
                onTap: () {
                  if (item.comingSoon) {
                    Navigator.of(context).pop();
                    showNHSnack(context, l.stateComingSoon);
                  } else {
                    go(item.path);
                  }
                },
              ),
            const Divider(height: 24),
            if (loggedIn) ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l.navMyAccount, style: NHText.body(size: 16)),
                onTap: () => go('/account'),
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l.navAdmin, style: NHText.body(size: 16)),
                  onTap: () => go('/admin'),
                ),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: Text(l.actionLogOut, style: NHText.body(size: 16)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: l.navRegisterNow,
                      onPressed: () => go('/register'),
                    ),
                    const SizedBox(height: 10),
                    GhostButton(
                      label: l.navLogin,
                      expand: true,
                      onPressed: () => go('/login'),
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

/// PRD section 5.5: "Logged-in members get a bottom nav: Home, Plans, Classes,
/// Profile" below 600 px.
class NHBottomNav extends StatelessWidget {
  const NHBottomNav({super.key});

  static const _paths = ['/', '/plans', '/account/classes', '/account/profile'];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final path = GoRouterState.of(context).uri.path;
    final index = _paths.indexOf(path);

    return Container(
      decoration: const BoxDecoration(
        color: NHColors.surface,
        border: Border(top: BorderSide(color: NHColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: NHColors.selectedBg,
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStatePropertyAll(
              NHText.body(size: 12, weight: FontWeight.w600),
            ),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) => context.go(_paths[i]),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: NHColors.red),
                label: l.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.card_membership_outlined),
                selectedIcon: const Icon(Icons.card_membership, color: NHColors.red),
                label: l.navPlans,
              ),
              NavigationDestination(
                icon: const Icon(Icons.play_circle_outline),
                selectedIcon: const Icon(Icons.play_circle, color: NHColors.red),
                label: l.navClasses,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person, color: NHColors.red),
                label: l.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PRD section 7.1 item 7: "logo, 'Thank you!', links, address, timings,
/// phone, email, Instagram (from `settings/app`), 'BE FIT. BE STRONG. BE YOU.',
/// legal links."
class NHFooter extends ConsumerWidget {
  const NHFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider).value;
    final wide = context.bp.isWide;

    final contact = <Widget>[
      if (settings?.hasAddress ?? false)
        _FooterFact(
          icon: Icons.location_on_outlined,
          label: l.footerAddress,
          value: settings!.address,
        ),
      if (settings?.hasTimings ?? false)
        _FooterFact(
          icon: Icons.schedule_outlined,
          label: l.footerTimings,
          value: settings!.timings,
        ),
      if (settings?.hasPhone ?? false)
        _FooterFact(
          icon: Icons.call_outlined,
          label: l.footerPhone,
          value: settings!.phone,
          url: 'tel:${settings.phone.replaceAll(RegExp(r'[^0-9+]'), '')}',
        ),
      if (settings?.hasEmail ?? false)
        _FooterFact(
          icon: Icons.mail_outline,
          label: l.footerEmail,
          value: settings!.email,
          url: 'mailto:${settings.email}',
        ),
      if (settings?.hasInstagram ?? false)
        _FooterFact(
          icon: Icons.camera_alt_outlined,
          label: l.footerInstagram,
          value: l.appName,
          url: settings!.instagramUrl,
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: NHColors.surface,
        border: Border(top: BorderSide(color: NHColors.line, width: 1)),
      ),
      child: ContentWidth(
        padVertical: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 3 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NHLogoBlock(),
                      const SizedBox(height: 16),
                      Text(
                        l.footerThanks,
                        style: NHText.display(size: 34, color: NHColors.red),
                      ),
                    ],
                  ),
                ),
                if (!wide) const SizedBox(height: 30),
                Expanded(
                  flex: wide ? 2 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.footerLinks, style: NHText.label()),
                      const SizedBox(height: 10),
                      for (final item in mainNavItems(l))
                        _FooterLink(
                          label: item.comingSoon
                              ? '${item.label} (${l.navSoon})'
                              : item.label,
                          onTap: item.comingSoon
                              ? () => showNHSnack(context, l.stateComingSoon)
                              : () => context.go(item.path),
                        ),
                    ],
                  ),
                ),
                if (!wide) const SizedBox(height: 30),
                Expanded(
                  flex: wide ? 3 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: contact.isEmpty
                        ? [
                            Text(l.footerAddress, style: NHText.label()),
                            const SizedBox(height: 8),
                            // Before the owner fills Settings there is nothing
                            // to show, so say so rather than print "[...]".
                            Text(
                              l.legalPlaceholder,
                              style: NHText.body(size: 14, color: NHColors.muted),
                            ),
                          ]
                        : contact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            const Divider(),
            const SizedBox(height: 16),
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.motto, style: NHText.label(size: 12)),
                if (wide) const Spacer() else const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    _FooterLink(
                      label: l.legalPrivacy,
                      onTap: () => context.go('/privacy'),
                      dense: true,
                    ),
                    _FooterLink(
                      label: l.legalTerms,
                      onTap: () => context.go('/terms'),
                      dense: true,
                    ),
                    _FooterLink(
                      label: l.legalRefund,
                      onTap: () => context.go('/refund-policy'),
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterFact extends StatelessWidget {
  const _FooterFact({
    required this.icon,
    required this.label,
    required this.value,
    this.url,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: NHColors.muted),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NHText.label(size: 11)),
              const SizedBox(height: 2),
              Text(value, style: NHText.body(size: 14.5)),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: url == null
          ? body
          : InkWell(
              onTap: () => openExternalUrl(context, url!),
              borderRadius: BorderRadius.circular(8),
              child: body,
            ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap, this.dense = false});

  final String label;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) {
        return Semantics(
          button: true,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: dense ? 8 : 7, horizontal: 2),
                child: Text(
                  label,
                  style: NHText.body(
                    size: dense ? 13.5 : 15,
                    color: hovered ? NHColors.yellow : NHColors.muted,
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

/// Opens a link outside the app, telling the member plainly when it cannot.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final opened = uri == null
      ? false
      : await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    showNHSnack(context, L.of(context).stateGenericError, isError: true);
  }
}
