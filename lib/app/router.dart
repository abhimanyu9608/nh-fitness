import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../features/account/dashboard_screen.dart';
import '../features/admin/admin_announcements_screen.dart';
import '../features/admin/admin_classes_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_member_detail_screen.dart';
import '../features/admin/admin_members_screen.dart';
import '../features/admin/admin_payments_screen.dart';
import '../features/admin/admin_plans_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/admin/admin_staff_screen.dart';
import '../features/account/payments_screen.dart';
import '../features/account/profile_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/classes/class_player_screen.dart';
import '../features/classes/classes_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/submitted_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/misc/not_found_screen.dart';
import '../features/plans/plans_screen.dart';

/// Route paths, so no screen has to hand-write a string that could drift from
/// the table in PRD section 6.
abstract final class Routes {
  static const home = '/';
  static const explore = '/explore';
  static const plans = '/plans';
  static const checkout = '/checkout';
  static const checkoutSubmitted = '/checkout/submitted';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const account = '/account';
  static const accountClasses = '/account/classes';
  static const accountPayments = '/account/payments';
  static const accountProfile = '/account/profile';
  static const admin = '/admin';
  static const adminPayments = '/admin/payments';
  static const adminMembers = '/admin/members';
  static const adminPlans = '/admin/plans';
  static const adminClasses = '/admin/classes';
  static const adminAnnouncements = '/admin/announcements';
  static const adminSettings = '/admin/settings';
  static const adminStaff = '/admin/staff';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const refundPolicy = '/refund-policy';

  /// Member-only areas (PRD section 6).
  static const memberPrefixes = [account, checkout];
}

/// PRD section 6: "Route guards in `go_router` `redirect`: not logged in →
/// `/login?next=…`; logged in but not admin on `/admin/*` → `/account`."
final routerProvider = Provider<GoRouter>((ref) {
  // go_router only re-runs `redirect` when this notifier fires, so logging in
  // or out has to poke it.
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(isAdminProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _page(state, const HomeScreen()),
      ),
      GoRoute(
        path: Routes.explore,
        pageBuilder: (context, state) => _page(state, const ExploreScreen()),
      ),
      GoRoute(
        path: Routes.plans,
        pageBuilder: (context, state) => _page(
          state,
          PlansScreen(
            planIdFromQuery: state.uri.queryParameters['plan'],
            withPtFromQuery: _boolQuery(state.uri.queryParameters['pt']),
          ),
        ),
      ),
      GoRoute(
        path: Routes.checkout,
        pageBuilder: (context, state) => _page(
          state,
          CheckoutScreen(
            planIdFromQuery: state.uri.queryParameters['plan'],
            withPtFromQuery: _boolQuery(state.uri.queryParameters['pt']),
          ),
        ),
      ),
      GoRoute(
        path: Routes.checkoutSubmitted,
        pageBuilder: (context, state) => _page(state, const SubmittedScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) =>
            _page(state, LoginScreen(next: state.uri.queryParameters['next'])),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => _page(
          state,
          RegisterScreen(next: state.uri.queryParameters['next']),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) =>
            _page(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.account,
        pageBuilder: (context, state) => _page(state, const DashboardScreen()),
      ),
      GoRoute(
        path: Routes.accountClasses,
        pageBuilder: (context, state) => _page(state, const ClassesScreen()),
      ),
      GoRoute(
        path: '${Routes.accountClasses}/:id',
        pageBuilder: (context, state) => _page(
          state,
          ClassPlayerScreen(classId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.accountPayments,
        pageBuilder: (context, state) => _page(state, const PaymentsScreen()),
      ),
      GoRoute(
        path: Routes.accountProfile,
        pageBuilder: (context, state) => _page(state, const ProfileScreen()),
      ),
      GoRoute(
        path: Routes.admin,
        pageBuilder: (context, state) =>
            _page(state, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: Routes.adminPayments,
        pageBuilder: (context, state) =>
            _page(state, const AdminPaymentsScreen()),
      ),
      GoRoute(
        path: Routes.adminMembers,
        pageBuilder: (context, state) => _page(
          state,
          AdminMembersScreen(
            initialFilter: state.uri.queryParameters['filter'],
          ),
        ),
      ),
      GoRoute(
        path: '${Routes.adminMembers}/:uid',
        pageBuilder: (context, state) => _page(
          state,
          AdminMemberDetailScreen(uid: state.pathParameters['uid'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.adminPlans,
        pageBuilder: (context, state) => _page(state, const AdminPlansScreen()),
      ),
      GoRoute(
        path: Routes.adminClasses,
        pageBuilder: (context, state) =>
            _page(state, const AdminClassesScreen()),
      ),
      GoRoute(
        path: Routes.adminAnnouncements,
        pageBuilder: (context, state) =>
            _page(state, const AdminAnnouncementsScreen()),
      ),
      GoRoute(
        path: Routes.adminSettings,
        pageBuilder: (context, state) =>
            _page(state, const AdminSettingsScreen()),
      ),
      GoRoute(
        path: Routes.adminStaff,
        pageBuilder: (context, state) => _page(state, const AdminStaffScreen()),
      ),
      GoRoute(
        path: Routes.privacy,
        pageBuilder: (context, state) =>
            _page(state, const LegalScreen(page: LegalPage.privacy)),
      ),
      GoRoute(
        path: Routes.terms,
        pageBuilder: (context, state) =>
            _page(state, const LegalScreen(page: LegalPage.terms)),
      ),
      GoRoute(
        path: Routes.refundPolicy,
        pageBuilder: (context, state) =>
            _page(state, const LegalScreen(page: LegalPage.refund)),
      ),
    ],
  );
});

/// Every route fades and lifts slightly into place instead of cutting.
///
/// Respects "reduce motion" (PRD section 5.4) by handing back the page
/// untouched, so the app still navigates instantly for anyone who asked for
/// that.
CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: NHMotion.pageTransition,
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: NHMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  final loggedIn = ref.read(currentUidProvider) != null;
  final path = state.uri.path;

  final needsMember = Routes.memberPrefixes.any(path.startsWith);
  final needsAdmin =
      path == Routes.admin || path.startsWith('${Routes.admin}/');

  if (!loggedIn && (needsMember || needsAdmin)) {
    // The whole location, query included, so PRD PAY-5 can bring the member
    // back to checkout with the same plan selected.
    final next = Uri.encodeComponent(state.uri.toString());
    return '${Routes.login}?next=$next';
  }

  // A signed-in non-admin is deliberately *not* redirected away. Bouncing them
  // to /account looks like the app is broken: the page they asked for silently
  // becomes a different one. The admin shell shows them a plain explanation
  // instead. The rules refuse every admin read and write regardless, so
  // letting the route render costs nothing.

  const authPaths = [Routes.login, Routes.register, Routes.forgotPassword];
  if (loggedIn && authPaths.contains(path)) {
    return safeNextPath(state.uri.queryParameters['next']) ?? Routes.account;
  }

  return null;
}

/// Only in-app paths are honoured, so a crafted `?next=` cannot bounce a
/// member off to another site after login.
String? safeNextPath(String? next) {
  if (next == null || next.isEmpty) return null;
  if (!next.startsWith('/') || next.startsWith('//')) return null;
  return next;
}

bool? _boolQuery(String? raw) {
  if (raw == null) return null;
  return raw == '1' || raw.toLowerCase() == 'true';
}
