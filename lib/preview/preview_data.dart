import '../core/format.dart';
import '../data/models/announcement.dart';
import '../data/models/app_settings.dart';
import '../data/models/app_user.dart';
import '../data/models/class_item.dart';
import '../data/models/membership.dart';
import '../data/models/payment_request.dart';
import '../data/models/plan.dart';

/// Made-up data for the design preview (`lib/main_preview.dart`).
///
/// None of this ships in a real build — nothing under `lib/` imports it except
/// the preview entrypoint, so the tree shaker drops it from `flutter build web`.
/// It exists so the whole app can be looked at before Firebase is connected.
abstract final class PreviewData {
  /// The signed-in member in the preview.
  static const uid = 'preview-member';

  static final settings = AppSettings.defaults.copyWith(
    upiId: 'nhfitness@okhdfcbank',
    upiName: 'NH Fitness',
    address: '2nd Floor, Shanti Complex, MG Road, Indore 452001',
    timings: 'Mon–Sat 6am–10pm · Sun 7am–12pm',
    phone: '9876543210',
    email: 'hello@nhfitness.in',
    instagramUrl: 'https://instagram.com/nhfitness',
  );

  static const plans = Plan.defaults;

  /// The member who is logged in: joined a while ago, mid-membership.
  static AppUser get member => AppUser(
    uid: uid,
    name: 'Ravi Sharma',
    email: 'ravi.sharma@example.com',
    phone: '9876543211',
    createdAt: istToday().subtract(const Duration(days: 120)),
    hasJoined: true,
    activeUntil: istToday().add(const Duration(days: 46)),
    currentMembershipId: 'mem-1',
    ptFreeDaysUsed: 2,
  );

  static Membership get membership => Membership(
    id: 'mem-1',
    uid: uid,
    planId: 'yearly',
    planName: 'Yearly',
    months: 12,
    withPT: true,
    startDate: istToday().subtract(const Duration(days: 319)),
    endDate: istToday().add(const Duration(days: 46)),
    paymentRequestId: 'req-1',
    createdAt: istToday().subtract(const Duration(days: 319)),
    createdBy: 'preview-admin',
  );

  /// The member's own payment history: one approved, one rejected, one waiting.
  static List<PaymentRequest> get myPayments => [
    PaymentRequest(
      id: 'req-3',
      uid: uid,
      userName: 'Ravi Sharma',
      userPhone: '9876543211',
      planId: 'yearly',
      planName: 'Yearly',
      months: 12,
      planPrice: 15000,
      registrationFee: 0,
      ptFee: 5000,
      withPT: true,
      total: 20000,
      method: PaymentMethod.upi,
      upiRef: '419283746501',
      status: PaymentStatus.pending,
      createdBy: uid,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PaymentRequest(
      id: 'req-2',
      uid: uid,
      userName: 'Ravi Sharma',
      userPhone: '9876543211',
      planId: 'monthly',
      planName: 'Monthly',
      months: 1,
      planPrice: 1500,
      registrationFee: 0,
      ptFee: 0,
      withPT: false,
      total: 1500,
      method: PaymentMethod.upi,
      upiRef: '882910475632',
      status: PaymentStatus.rejected,
      rejectReason: 'Payment not received. Please check the reference number.',
      createdBy: uid,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 39)),
      reviewedBy: 'preview-admin',
    ),
    PaymentRequest(
      id: 'req-1',
      uid: uid,
      userName: 'Ravi Sharma',
      userPhone: '9876543211',
      planId: 'yearly',
      planName: 'Yearly',
      months: 12,
      planPrice: 15000,
      registrationFee: 500,
      ptFee: 5000,
      withPT: true,
      total: 20500,
      method: PaymentMethod.upi,
      upiRef: '770192845611',
      status: PaymentStatus.approved,
      membershipId: 'mem-1',
      createdBy: uid,
      createdAt: istToday().subtract(const Duration(days: 320)),
      reviewedAt: istToday().subtract(const Duration(days: 319)),
      reviewedBy: 'preview-admin',
    ),
  ];

  /// Other members, for the admin lists.
  static List<AppUser> get members => [
    member,
    AppUser(
      uid: 'u-anita',
      name: 'Anita Verma',
      email: 'anita.verma@example.com',
      phone: '9812345670',
      createdAt: istToday().subtract(const Duration(days: 200)),
      hasJoined: true,
      activeUntil: istToday().add(const Duration(days: 4)),
      currentMembershipId: 'mem-2',
      ptFreeDaysUsed: 7,
    ),
    AppUser(
      uid: 'u-imran',
      name: 'Imran Qureshi',
      email: 'imran.q@example.com',
      phone: '9898989898',
      createdAt: istToday().subtract(const Duration(days: 400)),
      hasJoined: true,
      activeUntil: istToday().subtract(const Duration(days: 12)),
      currentMembershipId: 'mem-3',
      ptFreeDaysUsed: 7,
    ),
    AppUser(
      uid: 'u-sneha',
      name: 'Sneha Patil',
      email: 'sneha.patil@example.com',
      phone: '9765432108',
      createdAt: istToday().subtract(const Duration(days: 3)),
    ),
    AppUser(
      uid: 'u-vikram',
      name: 'Vikram Rao',
      email: 'vikram.rao@example.com',
      phone: '9700112233',
      createdAt: istToday().subtract(const Duration(days: 60)),
      hasJoined: true,
      activeUntil: istToday().add(const Duration(days: 120)),
      currentMembershipId: 'mem-4',
      ptFreeDaysUsed: 1,
    ),
  ];

  static List<Membership> get memberships => [
    membership,
    Membership(
      id: 'mem-2',
      uid: 'u-anita',
      planId: 'quarterly',
      planName: 'Quarterly',
      months: 3,
      withPT: false,
      startDate: istToday().subtract(const Duration(days: 86)),
      endDate: istToday().add(const Duration(days: 4)),
      paymentRequestId: 'req-a1',
    ),
    Membership(
      id: 'mem-3',
      uid: 'u-imran',
      planId: 'half_yearly',
      planName: 'Half yearly',
      months: 6,
      withPT: true,
      startDate: istToday().subtract(const Duration(days: 194)),
      endDate: istToday().subtract(const Duration(days: 12)),
      paymentRequestId: 'req-i1',
    ),
    Membership(
      id: 'mem-4',
      uid: 'u-vikram',
      planId: 'half_yearly',
      planName: 'Half yearly',
      months: 6,
      withPT: false,
      startDate: istToday().subtract(const Duration(days: 60)),
      endDate: istToday().add(const Duration(days: 120)),
      paymentRequestId: 'req-v1',
    ),
  ];

  /// The admin's pending queue. Two of these share a UTR on purpose, so the
  /// "UTR already used" warning from PRD section 7.10 is visible.
  static List<PaymentRequest> get pendingPayments => [
    myPayments.first,
    PaymentRequest(
      id: 'req-s1',
      uid: 'u-sneha',
      userName: 'Sneha Patil',
      userPhone: '9765432108',
      planId: 'quarterly',
      planName: 'Quarterly',
      months: 3,
      planPrice: 4000,
      registrationFee: 500,
      ptFee: 0,
      withPT: false,
      total: 4500,
      method: PaymentMethod.upi,
      upiRef: '551122339988',
      status: PaymentStatus.pending,
      createdBy: 'u-sneha',
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    PaymentRequest(
      id: 'req-i2',
      uid: 'u-imran',
      userName: 'Imran Qureshi',
      userPhone: '9898989898',
      planId: 'half_yearly',
      planName: 'Half yearly',
      months: 6,
      planPrice: 7800,
      registrationFee: 0,
      ptFee: 0,
      withPT: false,
      total: 7800,
      method: PaymentMethod.upi,
      // Same reference number as Sneha's — the duplicate warning should fire.
      upiRef: '551122339988',
      status: PaymentStatus.pending,
      createdBy: 'u-imran',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PaymentRequest(
      id: 'req-v2',
      uid: 'u-vikram',
      userName: 'Vikram Rao',
      userPhone: '9700112233',
      planId: 'monthly',
      planName: 'Monthly',
      months: 1,
      planPrice: 1500,
      registrationFee: 0,
      ptFee: 0,
      withPT: false,
      total: 1500,
      method: PaymentMethod.cash,
      status: PaymentStatus.pending,
      createdBy: 'u-vikram',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static List<PaymentRequest> get allPayments => [
    ...pendingPayments,
    ...myPayments.where((r) => !r.isPending),
  ];

  static const classes = [
    ClassItem(
      id: 'c1',
      title: 'Full body strength',
      description:
          'A 40-minute full body session you can do with a pair of dumbbells. '
          'Warm up first, and stop if anything hurts.',
      category: 'Strength',
      durationMin: 40,
      youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
      thumbnailUrl: '',
      published: true,
      sortOrder: 1,
    ),
    ClassItem(
      id: 'c2',
      title: 'Morning mobility',
      description: 'Loosen up your hips and shoulders before you train.',
      category: 'Mobility',
      durationMin: 15,
      youtubeUrl: 'https://youtu.be/aqz-KE-bpKQ',
      thumbnailUrl: '',
      published: true,
      sortOrder: 2,
    ),
    ClassItem(
      id: 'c3',
      title: 'HIIT: 20 minutes, no equipment',
      description: 'Short, hard and done. Keep water next to you.',
      category: 'Cardio',
      durationMin: 20,
      youtubeUrl: 'https://youtu.be/ScMzIvxBSi4',
      thumbnailUrl: '',
      published: true,
      sortOrder: 3,
    ),
    ClassItem(
      id: 'c4',
      title: 'Core and lower back',
      description: 'Build a core that protects your back under heavy weight.',
      category: 'Strength',
      durationMin: 25,
      youtubeUrl: 'https://youtu.be/jNQXAC9IVRw',
      thumbnailUrl: '',
      published: true,
      sortOrder: 4,
    ),
    ClassItem(
      id: 'c5',
      title: 'Beginner routine (draft)',
      description: 'Not finished yet.',
      category: 'Strength',
      durationMin: 30,
      youtubeUrl: 'https://youtu.be/9bZkp7q19f0',
      thumbnailUrl: '',
      published: false,
      sortOrder: 5,
    ),
  ];

  static List<Announcement> get announcements => [
    Announcement(
      id: 'a1',
      title: 'Gym closed on 26 January',
      message: 'We are closed for Republic Day. Online classes stay available.',
      active: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Announcement(
      id: 'a2',
      title: 'New squat rack',
      message: 'Two new racks are in. Ask a trainer to check your form.',
      active: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];
}
