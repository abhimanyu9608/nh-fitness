// Design preview entrypoint. Run with:
//
//   flutter run -d chrome -t lib/main_preview.dart
//
// It renders the whole app against the made-up data in `lib/preview/`, so the
// layout, colours and motion can be checked before Firebase is connected.
//
// What it is not: a working app. Every read is faked and every write is a
// no-op, so Save and Approve buttons do nothing. Use `lib/main.dart` once
// `flutterfire configure` has run.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/path_url_strategy.dart';
import 'core/widgets/offline_bar.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/announcement_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/class_repository.dart';
import 'data/repositories/membership_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/user_repository.dart';
import 'features/admin/admin_providers.dart';
import 'preview/preview_data.dart';
import 'preview/preview_repositories.dart';

/// Flip to false to see the site the way a visitor who is not logged in does.
const previewLoggedIn = true;

/// Flip to false to see the member's view without the Admin link.
const previewAsAdmin = true;

/// Throwaway values, so that a write action reaches a Firestore that simply
/// rejects it instead of throwing "no Firebase app". Nothing here is read:
/// every provider the UI actually uses is overridden below.
const _previewOptions = FirebaseOptions(
  apiKey: 'preview-only-not-a-real-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'nh-fitness-preview',
  authDomain: 'nh-fitness-preview.firebaseapp.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configurePathUrlStrategy();

  // Best effort only. A bad config can throw a plain JS `Error` or simply
  // never settle, and either one would stop `runApp` from ever being called —
  // which looks to the user like an app that hangs on a blank screen.
  try {
    await Firebase.initializeApp(options: _previewOptions)
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // Fine. Nothing the preview renders needs a live Firebase app.
  }

  runApp(ProviderScope(overrides: previewOverrides, child: const NHApp()));
}

/// Everything the app would normally read from Firebase, served from
/// `PreviewData` instead.
final previewOverrides = [
  // ── Session ────────────────────────────────────────────────────────────────
  // NHApp waits for the first auth answer before it builds the router, so this
  // has to emit — null means "nobody is signed in with Firebase", and
  // `currentUidProvider` below is what the app actually reads.
  authStateProvider.overrideWith((ref) => Stream.value(null)),
  // Without this, the profile screen and the verify-email banner would reach
  // for `FirebaseAuth.instance` during build and take the whole preview down.
  authRepositoryProvider.overrideWith((ref) => PreviewAuthRepository()),
  currentUidProvider.overrideWith((ref) => previewLoggedIn ? PreviewData.uid : null),
  isAdminProvider.overrideWith((ref) async => previewLoggedIn && previewAsAdmin),
  isOfflineProvider.overrideWith((ref) => Stream.value(false)),

  // ── Public data ────────────────────────────────────────────────────────────
  settingsProvider.overrideWith((ref) async => PreviewData.settings),
  activePlansProvider.overrideWith(
    (ref) async => PreviewData.plans.where((p) => p.active).toList(),
  ),
  allPlansProvider.overrideWith((ref) async => PreviewData.plans),
  liveAnnouncementsProvider.overrideWith(
    (ref) async => PreviewData.announcements.where((a) => a.isLive).toList(),
  ),
  allAnnouncementsProvider.overrideWith((ref) async => PreviewData.announcements),

  // ── The signed-in member ───────────────────────────────────────────────────
  currentUserProvider.overrideWith(
    (ref) => Stream.value(previewLoggedIn ? PreviewData.member : null),
  ),
  myMembershipProvider.overrideWith(
    (ref) => Stream.value(previewLoggedIn ? PreviewData.membership : null),
  ),
  myRecentPaymentsProvider.overrideWith(
    (ref) => Stream.value(previewLoggedIn ? PreviewData.myPayments : const []),
  ),

  // ── Classes ────────────────────────────────────────────────────────────────
  publishedClassesProvider.overrideWith(
    (ref) async => PreviewData.classes.where((c) => c.published).toList(),
  ),
  allClassesProvider.overrideWith((ref) async => PreviewData.classes),

  // ── Admin ──────────────────────────────────────────────────────────────────
  pendingPaymentsProvider.overrideWith(
    (ref) => Stream.value(PreviewData.pendingPayments),
  ),
  pendingCountProvider.overrideWith(
    (ref) async => PreviewData.pendingPayments.length,
  ),
  adminStatsProvider.overrideWith(
    (ref) async => const AdminStats(
      activeMembers: 3,
      expiringSoon: 1,
      pendingApprovals: 4,
      incomeThisMonth: 42300,
    ),
  ),
  expiringSoonProvider.overrideWith((ref) async {
    final repo = PreviewMembershipRepository();
    final expiring = await repo.fetchExpiringSoon();
    final members = await PreviewUserRepository()
        .fetchByUids(expiring.map((m) => m.uid));
    return [
      for (final membership in expiring)
        ExpiringRow(membership: membership, member: members[membership.uid]),
    ];
  }),

  // ── Repositories the screens call straight from initState ──────────────────
  userRepositoryProvider.overrideWith((ref) => PreviewUserRepository()),
  paymentRepositoryProvider.overrideWith((ref) => PreviewPaymentRepository()),
  membershipRepositoryProvider.overrideWith(
    (ref) => PreviewMembershipRepository(),
  ),
];
