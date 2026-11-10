import 'package:cloud_firestore/cloud_firestore.dart';

/// Tolerant readers for Firestore maps.
///
/// Documents in a live database are often partial — a field added later is
/// simply missing on older documents, and an admin editing by hand in the
/// Console can type a string where an int belongs. Every model reads through
/// these so one odd document shows a sensible default instead of crashing a
/// whole list.
String asString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

String? asStringOrNull(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int asInt(Object? value, [int fallback = 0]) => switch (value) {
  int v => v,
  // An admin editing in the Console can type 1500.0 into an int field.
  num v => v.round(),
  String v => int.tryParse(v.trim()) ?? fallback,
  _ => fallback,
};

bool asBool(Object? value, [bool fallback = false]) => switch (value) {
  bool v => v,
  String v => v.toLowerCase() == 'true',
  _ => fallback,
};

DateTime? asDate(Object? value) => switch (value) {
  Timestamp v => v.toDate(),
  DateTime v => v,
  _ => null,
};

/// For fields the UI always needs a date for; falls back to the epoch so a
/// broken document sorts last instead of throwing.
DateTime asDateOr(Object? value, DateTime fallback) => asDate(value) ?? fallback;
