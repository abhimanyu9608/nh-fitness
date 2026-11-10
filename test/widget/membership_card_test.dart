import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/core/format.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/app_user.dart';
import 'package:nh_fitness/data/models/membership.dart';
import 'package:nh_fitness/data/models/payment_request.dart';
import 'package:nh_fitness/data/repositories/membership_repository.dart';
import 'package:nh_fitness/data/repositories/payment_repository.dart';
import 'package:nh_fitness/data/repositories/settings_repository.dart';
import 'package:nh_fitness/data/repositories/user_repository.dart';
import 'package:nh_fitness/features/account/membership_card.dart';

import 'harness.dart';

Membership membership({
  required DateTime start,
  required DateTime end,
  bool withPT = false,
}) {
  return Membership.fromMap('m1', {
    'uid': 'u1',
    'planId': 'yearly',
    'planName': 'Yearly',
    'months': 12,
    'withPT': withPT,
    'startDate': Timestamp.fromDate(start),
    'endDate': Timestamp.fromDate(end),
    'paymentRequestId': 'r1',
  });
}

PaymentRequest request({
  required PaymentStatus status,
  String? rejectReason,
}) {
  return PaymentRequest.fromMap('r1', {
    'uid': 'u1',
    'userName': 'Ravi',
    'planId': 'yearly',
    'planName': 'Yearly',
    'months': 12,
    'planPrice': 15000,
    'registrationFee': 500,
    'ptFee': 5000,
    'withPT': true,
    'total': 20500,
    'method': 'upi',
    'upiRef': '123456789012',
    'status': status.wire,
    'createdBy': 'u1',
    'createdAt': Timestamp.now(),
    'rejectReason': ?rejectReason,
  });
}

List<Override> overrides({
  Membership? current,
  List<PaymentRequest> requests = const [],
  AppUser? user,
}) {
  return [
    myMembershipProvider.overrideWith((ref) => Stream.value(current)),
    myRecentPaymentsProvider.overrideWith((ref) => Stream.value(requests)),
    settingsProvider.overrideWith((ref) async => AppSettings.defaults),
    currentUserProvider.overrideWith((ref) => Stream.value(user)),
  ];
}

void main() {
  setUpAll(useOfflineFonts);

  group('MembershipStatusCard (PRD section 7.6 item 2)', () {
    testWidgets('shows "no plan yet" for a member who never joined',
        (tester) async {
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('DON’T HAVE A PLAN'), findsOneWidget);
      expect(textContaining('CHOOSE A PLAN'), findsOneWidget);
    });

    testWidgets('shows days left and the valid-till date while active',
        (tester) async {
      final end = istToday().add(const Duration(days: 29));
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 1)),
            end: end,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('YEARLY'), findsOneWidget);
      expect(textContaining('ACTIVE'), findsOneWidget);
      // PRD ACC-1: inclusive of the end date, so 29 days ahead reads as 30.
      expect(find.text('30'), findsOneWidget);
      expect(textContaining('days left'), findsOneWidget);
      expect(textContaining(formatDate(end)), findsOneWidget);
      expect(textContaining('Renew plan'.toUpperCase()), findsOneWidget);
    });

    testWidgets('shows "waiting for approval" while a request is pending',
        (tester) async {
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          requests: [request(status: PaymentStatus.pending)],
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('WAITING FOR APPROVAL'), findsOneWidget);
      expect(textContaining('₹20,500'), findsOneWidget);
      expect(textContaining('UPI'), findsWidgets);
    });

    testWidgets('shows the admin\'s reason and Try again after a rejection',
        (tester) async {
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          requests: [
            request(
              status: PaymentStatus.rejected,
              rejectReason: 'Payment not received',
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('NOT APPROVED'), findsOneWidget);
      expect(textContaining('Payment not received'), findsOneWidget);
      expect(textContaining('Try again'.toUpperCase()), findsOneWidget);
    });

    testWidgets('shows the end date and Renew once a plan has expired',
        (tester) async {
      final end = istToday().subtract(const Duration(days: 3));
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 370)),
            end: end,
          ),
          requests: [request(status: PaymentStatus.approved)],
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ENDED ON'), findsOneWidget);
      expect(textContaining(formatDate(end).toUpperCase()), findsOneWidget);
    });

    testWidgets('keeps the active card and notes a renewal that is waiting',
        (tester) async {
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 300)),
            end: istToday().add(const Duration(days: 5)),
          ),
          requests: [request(status: PaymentStatus.pending)],
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ACTIVE'), findsOneWidget);
      expect(textContaining('WAITING FOR APPROVAL'), findsOneWidget);
    });

    testWidgets('shows a start date for a membership that has not begun',
        (tester) async {
      final start = istToday().add(const Duration(days: 4));
      await tester.pumpWidget(harness(
        child: const MembershipStatusCard(),
        overrides: overrides(
          current: membership(
            start: start,
            end: start.add(const Duration(days: 364)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('Starts on'), findsOneWidget);
      expect(textContaining(formatDate(start)), findsWidgets);
    });
  });

  group('ExpiryBanner (PRD section 7.6 item 3)', () {
    testWidgets('appears with 7 days or fewer left', (tester) async {
      await tester.pumpWidget(harness(
        child: const ExpiryBanner(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 300)),
            end: istToday().add(const Duration(days: 4)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ends in 5 days'), findsOneWidget);
    });

    testWidgets('says "ends today" on the last day', (tester) async {
      await tester.pumpWidget(harness(
        child: const ExpiryBanner(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 300)),
            end: istToday(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ends today'), findsOneWidget);
    });

    testWidgets('stays hidden with more than 7 days left', (tester) async {
      await tester.pumpWidget(harness(
        child: const ExpiryBanner(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 10)),
            end: istToday().add(const Duration(days: 40)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ends in'), findsNothing);
    });

    testWidgets('stays hidden when there is no membership at all',
        (tester) async {
      await tester.pumpWidget(harness(
        child: const ExpiryBanner(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('ends in'), findsNothing);
    });
  });

  group('FreePtCard (PRD section 7.6 item 4)', () {
    testWidgets('counts the free days still left', (tester) async {
      await tester.pumpWidget(harness(
        child: const FreePtCard(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 2)),
            end: istToday().add(const Duration(days: 300)),
            withPT: true,
          ),
          user: const AppUser(
            uid: 'u1',
            name: 'Ravi',
            email: 'ravi@example.com',
            hasJoined: true,
            ptFreeDaysUsed: 2,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('5 of 7 free days left'), findsOneWidget);
    });

    testWidgets('says so once every free day has been used', (tester) async {
      await tester.pumpWidget(harness(
        child: const FreePtCard(),
        overrides: overrides(
          current: membership(
            start: istToday().subtract(const Duration(days: 20)),
            end: istToday().add(const Duration(days: 300)),
            withPT: true,
          ),
          user: const AppUser(
            uid: 'u1',
            name: 'Ravi',
            email: 'ravi@example.com',
            hasJoined: true,
            ptFreeDaysUsed: 7,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('used all 7 free days'), findsOneWidget);
    });

    testWidgets('stays hidden without a membership', (tester) async {
      await tester.pumpWidget(harness(
        child: const FreePtCard(),
        overrides: overrides(
          user: const AppUser(uid: 'u1', name: 'Ravi', email: 'r@example.com'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(textContaining('free days'), findsNothing);
    });
  });
}
