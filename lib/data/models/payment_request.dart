import 'package:cloud_firestore/cloud_firestore.dart';

import 'converters.dart';

/// Phase 1 payment methods (PRD section 7.4). Card and net banking are Phase 2.
enum PaymentMethod {
  upi('upi'),
  cash('cash');

  const PaymentMethod(this.wire);

  /// The exact string stored in Firestore and checked by the rules.
  final String wire;

  static PaymentMethod fromWire(Object? value) =>
      value == cash.wire ? cash : upi;
}

enum PaymentStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const PaymentStatus(this.wire);

  final String wire;

  static PaymentStatus fromWire(Object? value) => switch (value) {
    'approved' => approved,
    'rejected' => rejected,
    _ => pending,
  };
}

/// A member's request for the gym to activate a membership
/// (`paymentRequests/{id}`, PRD section 8.1).
///
/// The prices are copied in at the moment of submission (PRD PAY-2) and the
/// security rules reject a request whose prices do not match Firestore.
class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userPhone,
    required this.planId,
    required this.planName,
    required this.months,
    required this.planPrice,
    required this.registrationFee,
    required this.ptFee,
    required this.withPT,
    required this.total,
    required this.method,
    required this.status,
    required this.createdBy,
    this.upiRef,
    this.rejectReason,
    this.membershipId,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String uid;

  /// Copied at submit so the admin list needs one read, not two
  /// (PRD section 8.1).
  final String userName;
  final String userPhone;

  final String planId;
  final String planName;
  final int months;
  final int planPrice;
  final int registrationFee;
  final int ptFee;
  final bool withPT;
  final int total;
  final PaymentMethod method;

  /// 12 digits for UPI, null for cash (PRD PAY-3).
  final String? upiRef;
  final PaymentStatus status;
  final String? rejectReason;
  final String? membershipId;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// The member's uid, or an admin's uid for a cash payment taken at the desk.
  final String createdBy;

  bool get isPending => status == PaymentStatus.pending;

  factory PaymentRequest.fromMap(String id, Map<String, dynamic> data) {
    return PaymentRequest(
      id: id,
      uid: asString(data['uid']),
      userName: asString(data['userName']),
      userPhone: asString(data['userPhone']),
      planId: asString(data['planId']),
      planName: asString(data['planName']),
      months: asInt(data['months'], 1),
      planPrice: asInt(data['planPrice']),
      registrationFee: asInt(data['registrationFee']),
      ptFee: asInt(data['ptFee']),
      withPT: asBool(data['withPT']),
      total: asInt(data['total']),
      method: PaymentMethod.fromWire(data['method']),
      upiRef: asStringOrNull(data['upiRef']),
      status: PaymentStatus.fromWire(data['status']),
      rejectReason: asStringOrNull(data['rejectReason']),
      membershipId: asStringOrNull(data['membershipId']),
      createdAt: asDate(data['createdAt']),
      reviewedAt: asDate(data['reviewedAt']),
      reviewedBy: asStringOrNull(data['reviewedBy']),
      createdBy: asString(data['createdBy']),
    );
  }

  factory PaymentRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      PaymentRequest.fromMap(doc.id, doc.data() ?? const {});
}

/// What a member is about to pay for, carried from `/plans` into `/checkout`.
///
/// Kept separate from [PaymentRequest] because it exists before anything is
/// written, and because the checkout screen needs to recompute the total as the
/// member toggles the add-on (PRD PLAN-1).
class PaymentDraft {
  const PaymentDraft({
    required this.planId,
    required this.planName,
    required this.months,
    required this.planPrice,
    required this.registrationFee,
    required this.ptFee,
    required this.withPT,
  });

  final String planId;
  final String planName;
  final int months;
  final int planPrice;
  final int registrationFee;
  final int ptFee;
  final bool withPT;

  /// PRD PLAN-1: plan price + registration fee (if applicable) + PT fee
  /// (if selected).
  int get total => planPrice + registrationFee + ptFee;
}
