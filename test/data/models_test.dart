import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/core/format.dart';
import 'package:nh_fitness/data/models/announcement.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/data/models/app_user.dart';
import 'package:nh_fitness/data/models/class_item.dart';
import 'package:nh_fitness/data/models/membership.dart';
import 'package:nh_fitness/data/models/payment_request.dart';
import 'package:nh_fitness/data/models/plan.dart';

void main() {
  group('Plan', () {
    test('parses a seed document', () {
      final plan = Plan.fromMap('yearly', {
        'name': 'Yearly',
        'months': 12,
        'price': 15000,
        'sortOrder': 4,
        'isBestValue': true,
        'active': true,
      });
      expect(plan.id, 'yearly');
      expect(plan.pricePerMonth, 1250);
      expect(plan.isPayAsYouGo, isFalse);
    });

    test('a one-month plan is pay as you go (PRD section 7.3)', () {
      final plan = Plan.fromMap('monthly', {'months': 1, 'price': 1500});
      expect(plan.isPayAsYouGo, isTrue);
    });

    test('survives a partially filled document', () {
      // An admin editing by hand in the Console can leave fields out.
      final plan = Plan.fromMap('odd', const {});
      expect(plan.name, 'odd');
      expect(plan.months, 1);
      expect(plan.price, 0);
      // Defaults to visible rather than silently hiding a real plan.
      expect(plan.active, isTrue);
    });

    test('reads a price typed as a decimal or a string', () {
      expect(Plan.fromMap('a', {'price': 1500.0}).price, 1500);
      expect(Plan.fromMap('a', {'price': '1500'}).price, 1500);
    });

    test('the seed defaults match PRD section 8.2', () {
      expect(Plan.defaults.map((p) => p.id).toList(),
          ['monthly', 'quarterly', 'half_yearly', 'yearly']);
      expect(Plan.defaults.map((p) => p.price).toList(),
          [1500, 4000, 7800, 15000]);
      expect(Plan.defaults.where((p) => p.isBestValue).single.id, 'yearly');
    });
  });

  group('AppSettings', () {
    test('falls back to the PRD section 8.2 defaults when a field is missing', () {
      final settings = AppSettings.fromMap(const {});
      expect(settings.registrationFee, 500);
      expect(settings.ptFee, 5000);
      expect(settings.ptFreeDays, 7);
      expect(settings.upiName, 'NH Fitness');
    });

    test('treats a bracketed seed value as "not filled in yet"', () {
      final settings = AppSettings.fromMap(const {
        'upiId': '[GYM UPI ID]',
        'phone': '9876543210',
        'address': '',
      });
      expect(settings.hasUpiId, isFalse);
      expect(settings.hasPhone, isTrue);
      expect(settings.hasAddress, isFalse);
    });
  });

  group('AppUser', () {
    test('is active while activeUntil is in the future', () {
      final active = AppUser.fromMap('u', {
        'activeUntil': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
      });
      expect(active.isActive, isTrue);
    });

    test('is not active with no membership or a past one', () {
      expect(AppUser.fromMap('u', const {}).isActive, isFalse);
      final lapsed = AppUser.fromMap('u', {
        'activeUntil': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      });
      expect(lapsed.isActive, isFalse);
    });

    test('starts a new member at hasJoined false and zero free days used', () {
      final user = AppUser.fromMap('u', const {'name': 'Ravi'});
      expect(user.hasJoined, isFalse);
      expect(user.ptFreeDaysUsed, 0);
    });

    test('reads an empty phone as null', () {
      expect(AppUser.fromMap('u', const {'phone': ''}).phone, isNull);
      expect(AppUser.fromMap('u', const {'phone': '9876543210'}).phone,
          '9876543210');
    });
  });

  group('Membership state (PRD ACC-2)', () {
    Membership build(DateTime start, DateTime end) => Membership.fromMap('m', {
      'uid': 'u',
      'planId': 'yearly',
      'planName': 'Yearly',
      'months': 12,
      'withPT': false,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'paymentRequestId': 'r',
    });

    test('is active when today falls inside the range', () {
      final membership = build(
        istToday().subtract(const Duration(days: 10)),
        istToday().add(const Duration(days: 10)),
      );
      expect(membership.state, MembershipState.active);
      expect(membership.isActive, isTrue);
      expect(membership.daysLeft, 11);
    });

    test('is active on its first and last day', () {
      expect(build(istToday(), istToday()).state, MembershipState.active);
      expect(build(istToday(), istToday()).daysLeft, 1);
    });

    test('is upcoming before the start date', () {
      final membership = build(
        istToday().add(const Duration(days: 2)),
        istToday().add(const Duration(days: 40)),
      );
      expect(membership.state, MembershipState.upcoming);
      expect(membership.daysUsed, 0);
      expect(membership.progress, 0);
    });

    test('is expired after the end date', () {
      final membership = build(
        istToday().subtract(const Duration(days: 40)),
        istToday().subtract(const Duration(days: 1)),
      );
      expect(membership.state, MembershipState.expired);
      expect(membership.daysLeft, 0);
    });

    test('progress never runs past the end of the bar', () {
      final membership = build(
        istToday().subtract(const Duration(days: 400)),
        istToday().subtract(const Duration(days: 30)),
      );
      expect(membership.daysUsed, membership.totalDays);
      expect(membership.progress, 1.0);
    });

    test('totalDays counts both end days', () {
      final membership = build(istDay(2026, 1, 1), istDay(2026, 1, 31));
      expect(membership.totalDays, 31);
    });
  });

  group('PaymentRequest', () {
    test('parses a pending UPI request', () {
      final request = PaymentRequest.fromMap('r1', {
        'uid': 'u',
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
        'status': 'pending',
        'createdBy': 'u',
      });
      expect(request.method, PaymentMethod.upi);
      expect(request.status, PaymentStatus.pending);
      expect(request.isPending, isTrue);
      expect(request.upiRef, '123456789012');
    });

    test('an unknown method or status falls back to the safest value', () {
      final request = PaymentRequest.fromMap('r1', const {
        'method': 'crypto',
        'status': 'whatever',
      });
      expect(request.method, PaymentMethod.upi);
      expect(request.status, PaymentStatus.pending);
    });

    test('a cash request has no UTR', () {
      final request = PaymentRequest.fromMap('r1', const {
        'method': 'cash',
        'upiRef': null,
      });
      expect(request.method, PaymentMethod.cash);
      expect(request.upiRef, isNull);
    });
  });

  group('PaymentDraft total (PRD PLAN-1)', () {
    test('adds the plan price, registration fee and PT fee', () {
      const draft = PaymentDraft(
        planId: 'yearly',
        planName: 'Yearly',
        months: 12,
        planPrice: 15000,
        registrationFee: 500,
        ptFee: 5000,
        withPT: true,
      );
      // The worked example in PRD section 11.
      expect(draft.total, 20500);
    });

    test('a renewal without the add-on is just the plan price', () {
      const draft = PaymentDraft(
        planId: 'yearly',
        planName: 'Yearly',
        months: 12,
        planPrice: 15000,
        registrationFee: 0,
        ptFee: 0,
        withPT: false,
      );
      expect(draft.total, 15000);
    });
  });

  group('ClassItem', () {
    test('falls back to the YouTube thumbnail when none is given', () {
      final item = ClassItem.fromMap('c1', const {
        'title': 'Full body',
        'youtubeUrl': 'https://youtu.be/dQw4w9WgXcQ',
        'thumbnailUrl': '',
      });
      expect(item.videoId, 'dQw4w9WgXcQ');
      expect(item.effectiveThumbnailUrl, contains('dQw4w9WgXcQ'));
    });

    test('prefers the admin\'s thumbnail when one is set', () {
      final item = ClassItem.fromMap('c1', const {
        'youtubeUrl': 'https://youtu.be/dQw4w9WgXcQ',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
      });
      expect(item.effectiveThumbnailUrl, 'https://example.com/thumb.jpg');
    });

    test('still renders something for an unusable link', () {
      final item = ClassItem.fromMap('c1', const {'youtubeUrl': 'not-a-link'});
      expect(item.videoId, isNull);
      expect(item.effectiveThumbnailUrl, isNotEmpty);
    });
  });

  group('Announcement', () {
    test('is live while active and before any end date', () {
      final live = Announcement.fromMap('a1', {
        'active': true,
        'endsAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
      });
      expect(live.isLive, isTrue);
    });

    test('an open-ended active announcement is live', () {
      expect(Announcement.fromMap('a1', const {'active': true}).isLive, isTrue);
    });

    test('is not live once switched off or past its end date', () {
      expect(
        Announcement.fromMap('a1', const {'active': false}).isLive,
        isFalse,
      );
      final ended = Announcement.fromMap('a1', {
        'active': true,
        'endsAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      });
      expect(ended.isLive, isFalse);
    });
  });
}
