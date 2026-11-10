import 'package:cloud_firestore/cloud_firestore.dart';

import 'converters.dart';

/// A strip shown at the top of Home and the member dashboard
/// (`announcements/{id}`, PRD section 7.9).
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.active,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final bool active;

  /// Optional end date; after it passes the strip hides itself without the
  /// admin having to switch it off.
  final DateTime? endsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLive =>
      active && (endsAt == null || endsAt!.isAfter(DateTime.now()));

  factory Announcement.fromMap(String id, Map<String, dynamic> data) {
    return Announcement(
      id: id,
      title: asString(data['title']),
      message: asString(data['message']),
      active: asBool(data['active']),
      endsAt: asDate(data['endsAt']),
      createdAt: asDate(data['createdAt']),
      updatedAt: asDate(data['updatedAt']),
    );
  }

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Announcement.fromMap(doc.id, doc.data() ?? const {});

  Map<String, Object?> toMap() => {
    'title': title,
    'message': message,
    'active': active,
    'endsAt': endsAt == null ? null : Timestamp.fromDate(endsAt!),
  };

  Announcement copyWith({
    String? title,
    String? message,
    bool? active,
    DateTime? endsAt,
    bool clearEndsAt = false,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      active: active ?? this.active,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
