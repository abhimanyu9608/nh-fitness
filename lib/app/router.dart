import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.explore,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: Routes.plans,
        builder: (context, state) => PlansScreen(
          planIdFromQuery: state.uri.queryParameters['plan'],
          withPtFromQuery: _boolQuery(state.uri.queryParameters['pt']),
        ),
      ),
      GoRoute(
        path: Routes.checkout,
        builder: (context, state) => CheckoutScreen(
          planIdFromQuery: state.uri.queryParameters['plan'],
          withPtFromQuery: _boolQuery(state.uri.queryParameters['pt']),
        ),
      ),
      GoRoute(
        path: Routes.checkoutSubmitted,
        builder: (context, state) => const SubmittedScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) =>
            LoginScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) =>
            RegisterScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.account,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.accountClasses,
        builder: (context, state) => const ClassesScreen(),
      ),
      GoRoute(
        path: '${Routes.accountClasses}/:id',
        builder: (context, state) =>
            ClassPlayerScreen(classId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.accountPayments,
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: Routes.accountProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminPayments,
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: Routes.adminMembers,
        builder: (context, state) => AdminMembersScreen(
          initialFilter: state.uri.queryParameters['filter'],
        ),
      ),
      GoRoute(
        path: '${Routes.adminMembers}/:uid',
        builder: (context, state) =>
            AdminMemberDetailScreen(uid: state.pathParameters['uid'] ?? ''),
      ),
      GoRoute(
        path: Routes.adminPlans,
        builder: (context, state) => const AdminPlansScreen(),
      ),
      GoRoute(
        path: Routes.adminClasses,
        builder: (context, state) => const AdminClassesScreen(),
      ),
      GoRoute(
        path: Routes.adminAnnouncements,
        builder: (context, state) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: Routes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: Routes.adminStaff,
        builder: (context, state) => const AdminStaffScreen(),
      ),
      GoRoute(
        path: Routes.privacy,
        builder: (context, state) => const LegalScreen(page: LegalPage.privacy),
      ),
      GoRoute(
        path: Routes.terms,
        builder: (context, state) => const LegalScreen(page: LegalPage.terms),
      ),
      GoRoute(
        path: Routes.refundPolicy,
        builder: (context, state) => const LegalScreen(page: LegalPage.refund),
      ),
    ],
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final loggedIn = ref.read(currentUidProvider) != null;
  final path = state.uri.path;

  final needsMember = Routes.memberPrefixes.any(path.startsWith);
  final needsAdmin = path == Routes.admin || path.startsWith('${Routes.admin}/');

  if (!loggedIn && (needsMember || needsAdmin)) {
    // The whole location, query included, so PRD PAY-5 can bring the member
    // back to checkout with the same plan selected.
    final next = Uri.encodeComponent(state.uri.toString());
    return '${Routes.login}?next=$next';
  }

  if (loggedIn && needsAdmin) {
    final isAdmin = ref.read(isAdminProvider);
    // While the `admins/{uid}` read is still in flight, stay put — the
    // redirect runs again when it lands.
    if (isAdmin.hasValue && isAdmin.value == false) return Routes.account;
  }

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
