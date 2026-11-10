import 'package:cloud_firestore/cloud_firestore.dart';

import 'converters.dart';

/// The single `settings/app` document (PRD section 8.1).
///
/// Everything the owner can change without a new app release lives here:
/// prices, UPI details and contact details (PRD goal 1.3).
class AppSettings {
  const AppSettings({
    required this.registrationFee,
    required this.ptFee,
    required this.ptFreeDays,
    required this.upiId,
    required this.upiName,
    required this.approvalTimeText,
    required this.address,
    required this.timings,
    required this.phone,
    required this.email,
    required this.instagramUrl,
    required this.supplementsEnabled,
    required this.clothesEnabled,
    this.updatedAt,
    this.updatedBy,
  });

  /// Charged once, on a member's first membership (PRD PLAN-3).
  final int registrationFee;
  final int ptFee;
  final int ptFreeDays;
  final String upiId;
  final String upiName;

  /// Shown to members as "This usually takes …".
  final String approvalTimeText;
  final String address;
  final String timings;
  final String phone;
  final String email;
  final String instagramUrl;

  /// Phase 1 keeps both false; the flags exist for Phase 2 (PRD EXP-1).
  final bool supplementsEnabled;
  final bool clothesEnabled;

  final DateTime? updatedAt;
  final String? updatedBy;

  /// Placeholder values are written as `[...]` by the seed, so the UI can tell
  /// "not filled in yet" from a real value.
  static bool _isPlaceholder(String value) {
    final v = value.trim();
    return v.isEmpty || (v.startsWith('[') && v.endsWith(']'));
  }

  bool get hasUpiId => !_isPlaceholder(upiId);
  bool get hasAddress => !_isPlaceholder(address);
  bool get hasTimings => !_isPlaceholder(timings);
  bool get hasPhone => !_isPlaceholder(phone);
  bool get hasEmail => !_isPlaceholder(email);
  bool get hasInstagram => !_isPlaceholder(instagramUrl);

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      registrationFee: asInt(data['registrationFee'], defaults.registrationFee),
      ptFee: asInt(data['ptFee'], defaults.ptFee),
      ptFreeDays: asInt(data['ptFreeDays'], defaults.ptFreeDays),
      upiId: asString(data['upiId'], defaults.upiId),
      upiName: asString(data['upiName'], defaults.upiName),
      approvalTimeText:
          asString(data['approvalTimeText'], defaults.approvalTimeText),
      address: asString(data['address'], defaults.address),
      timings: asString(data['timings'], defaults.timings),
      phone: asString(data['phone'], defaults.phone),
      email: asString(data['email'], defaults.email),
      instagramUrl: asString(data['instagramUrl'], defaults.instagramUrl),
      supplementsEnabled: asBool(data['supplementsEnabled']),
      clothesEnabled: asBool(data['clothesEnabled']),
      updatedAt: asDate(data['updatedAt']),
      updatedBy: asStringOrNull(data['updatedBy']),
    );
  }

  factory AppSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppSettings.fromMap(doc.data() ?? const {});

  Map<String, Object?> toMap() => {
    'registrationFee': registrationFee,
    'ptFee': ptFee,
    'ptFreeDays': ptFreeDays,
    'upiId': upiId,
    'upiName': upiName,
    'approvalTimeText': approvalTimeText,
    'address': address,
    'timings': timings,
    'phone': phone,
    'email': email,
    'instagramUrl': instagramUrl,
    'supplementsEnabled': supplementsEnabled,
    'clothesEnabled': clothesEnabled,
  };

  AppSettings copyWith({
    int? registrationFee,
    int? ptFee,
    int? ptFreeDays,
    String? upiId,
    String? upiName,
    String? approvalTimeText,
    String? address,
    String? timings,
    String? phone,
    String? email,
    String? instagramUrl,
    bool? supplementsEnabled,
    bool? clothesEnabled,
  }) {
    return AppSettings(
      registrationFee: registrationFee ?? this.registrationFee,
      ptFee: ptFee ?? this.ptFee,
      ptFreeDays: ptFreeDays ?? this.ptFreeDays,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
      approvalTimeText: approvalTimeText ?? this.approvalTimeText,
      address: address ?? this.address,
      timings: timings ?? this.timings,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      supplementsEnabled: supplementsEnabled ?? this.supplementsEnabled,
      clothesEnabled: clothesEnabled ?? this.clothesEnabled,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// Seed values from PRD section 8.2.
  static const defaults = AppSettings(
    registrationFee: 500,
    ptFee: 5000,
    ptFreeDays: 7,
    upiId: '[GYM UPI ID]',
    upiName: 'NH Fitness',
    approvalTimeText: 'within a few hours during gym timings',
    address: '[TO BE FILLED]',
    timings: '[TO BE FILLED]',
    phone: '[TO BE FILLED]',
    email: '[TO BE FILLED]',
    instagramUrl: '[TO BE FILLED]',
    supplementsEnabled: false,
    clothesEnabled: false,
  );
}
