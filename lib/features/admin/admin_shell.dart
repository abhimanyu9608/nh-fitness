import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_logo.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/offline_bar.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_shell.dart';
import 'admin_providers.dart';

/// The admin panel frame.
///
/// PRD section 7.10: "side menu on web/tablet (Dashboard, Pending payments
/// (badge count), Members, Plans and prices, Online classes, Announcements,
/// Settings, Back to site, Log out); a drawer on mobile."
///
/// PRD ADM-5: it works on mobile, but it is designed for web first — hence the
/// wide table-like rows and the permanent side menu from 600 px up.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.titleTrailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// A search field or "Add" button beside the page title.
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    // The router already turns away non-admins; this covers the moment before
    // the `admins/{uid}` read lands, and the case where it fails.
    if (!isAdmin.hasValue) {
      return Scaffold(
        backgroundColor: NHColors.bg,
        body: isAdmin.hasError
            ? NHErrorState(
                message: messageForError(context, isAdmin.error),
                onRetry: () => ref.invalidate(isAdminProvider),
              )
            : const NHLoading(minHeight: 400),
      );
    }
    if (isAdmin.value == false) return const _NotAnAdmin();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeUp(
          index: 0,
          child: SectionTitle(
            title: title,
            subtitle: subtitle,
            trailing: titleTrailing,
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );

    return Scaffold(
      backgroundColor: NHColors.bg,
      endDrawer: context.bp.isMobile
          ? const Drawer(
              backgroundColor: NHColors.surface,
              child: SafeArea(child: AdminSideMenu(inDrawer: true)),
            )
          : null,
      body: Column(
        children: [
          const OfflineBar(),
          const _AdminTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: ContentWidth(
                maxWidth: 1320,
                padVertical: const EdgeInsets.only(top: 26, bottom: 56),
                child: context.bp.isMobile
                    ? content
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 252, child: AdminSideMenu()),
                          const SizedBox(width: 28),
                          Expanded(child: content),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: NHColors.bg,
        border: Border(bottom: BorderSide(color: NHColors.line, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: 1320,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                const NHLogo(size: 24, showWordmark: false),
                const SizedBox(width: 12),
                Text(
                  l.adminTitle,
                  style: NHText.display(size: 24, color: NHColors.red),
                ),
                const Spacer(),
                if (context.bp.isMobile)
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

class AdminSideMenu extends ConsumerWidget {
  const AdminSideMenu({super.key, this.inDrawer = false});

  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final path = GoRouterState.of(context).uri.path;
    final pendingCount = ref.watch(pendingCountProvider).value ?? 0;

    void go(String target) {
      if (inDrawer) Navigator.of(context).pop();
      context.go(target);
    }

    final items = <({String label, IconData icon, String path, Widget? badge})>[
      (
        label: l.adminNavDashboard,
        icon: Icons.dashboard_outlined,
        path: Routes.admin,
        badge: null,
      ),
      (
        label: l.adminNavPayments,
        icon: Icons.payments_outlined,
        path: Routes.adminPayments,
        badge: pendingCount > 0 ? _CountBadge(count: pendingCount) : null,
      ),
      (
        label: l.adminNavMembers,
        icon: Icons.people_outline,
        path: Routes.adminMembers,
        badge: null,
      ),
      (
        label: l.adminNavPlans,
        icon: Icons.sell_outlined,
        path: Routes.adminPlans,
        badge: null,
      ),
      (
        label: l.adminNavClasses,
        icon: Icons.play_circle_outline,
        path: Routes.adminClasses,
        badge: null,
      ),
      (
        label: l.adminNavAnnouncements,
        icon: Icons.campaign_outlined,
        path: Routes.adminAnnouncements,
        badge: null,
      ),
      (
        label: l.adminNavSettings,
        icon: Icons.settings_outlined,
        path: Routes.adminSettings,
        badge: null,
      ),
      // Staff access is an owner's job, so it only appears for owners. The
      // rules refuse the writes either way; this just keeps the menu honest.
      if (ref.watch(isOwnerProvider).value ?? false)
        (
          label: l.adminNavStaff,
          icon: Icons.shield_outlined,
          path: Routes.adminStaff,
          badge: null,
        ),
    ];

    final menu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          SideMenuTile(
            label: item.label,
            icon: item.icon,
            active:
                path == item.path ||
                (item.path != Routes.admin && path.startsWith('${item.path}/')),
            badge: item.badge,
            onTap: () => go(item.path),
          ),
        const Divider(height: 18),
        SideMenuTile(
          label: l.navBackToSite,
          icon: Icons.open_in_new,
          active: false,
          onTap: () => go(Routes.home),
        ),
        SideMenuTile(
          label: l.actionLogOut,
          icon: Icons.logout_outlined,
          active: false,
          onTap: () async {
            if (inDrawer) Navigator.of(context).pop();
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) context.go(Routes.home);
          },
        ),
      ],
    );

    if (inDrawer) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: menu,
      );
    }

    return NHCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: menu,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: NHColors.red,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        style: NHText.moneyBody(
          size: 12.5,
          color: Colors.white,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Shown to a signed-in member who opens `/admin/*` without access.
///
/// Says plainly what happened and which account they are using — the usual
/// cause is being signed in with a personal Google account rather than the
/// one the gym granted access to, and without the email on screen that is
/// invisible.
class _NotAnAdmin extends ConsumerWidget {
  const _NotAnAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final email = ref.watch(authStateProvider).value?.email;

    return NHScaffold(
      showFooter: false,
      children: [
        ContentWidth(
          maxWidth: 620,
          padVertical: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NHColors.selectedBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 28,
                    color: NHColors.red,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeUp(
                index: 1,
                child: SectionTitle(
                  title: l.guardAdminOnlyTitle,
                  subtitle: l.guardAdminOnlyBody,
                ),
              ),
              const SizedBox(height: 24),
              if (email != null)
                FadeUp(
                  index: 2,
                  child: NHCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: NHColors.muted,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                l.guardAdminSignedInAs(email),
                                style: NHText.body(
                                  size: 15,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.guardAdminWrongAccount,
                          style: NHText.body(size: 14, color: NHColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FadeUp(
                index: 3,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PrimaryButton(
                      label: l.navMyAccount,
                      expand: false,
                      onPressed: () => context.go(Routes.account),
                    ),
                    GhostButton(
                      label: l.guardAdminLogOutSwitch,
                      icon: Icons.logout_outlined,
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go(Routes.login);
                      },
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
