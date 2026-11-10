import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/format.dart';
import 'converters.dart';

/// A membership plan (`plans/{planId}`, PRD section 8.1).
///
/// Plans are never deleted — only switched to `active: false` — because old
/// payment records point at them (PRD section 7.10).
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.months,
    required this.price,
    required this.sortOrder,
    required this.isBestValue,
    required this.active,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String name;
  final int months;

  /// Whole rupees (PRD section 8).
  final int price;
  final int sortOrder;
  final bool isBestValue;
  final bool active;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// Price per month rounded to the rupee (PRD section 7.3).
  int get pricePerMonth => perMonthPrice(price, months);

  /// A one-month plan shows "Pay as you go" instead of a per-month price
  /// (PRD section 7.3).
  bool get isPayAsYouGo => months <= 1;

  factory Plan.fromMap(String id, Map<String, dynamic> data) {
    return Plan(
      id: id,
      name: asString(data['name'], id),
      months: asInt(data['months'], 1),
      price: asInt(data['price']),
      sortOrder: asInt(data['sortOrder'], 999),
      isBestValue: asBool(data['isBestValue']),
      active: asBool(data['active'], true),
      updatedAt: asDate(data['updatedAt']),
      updatedBy: asStringOrNull(data['updatedBy']),
    );
  }

  factory Plan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Plan.fromMap(doc.id, doc.data() ?? const {});

  /// `updatedAt`/`updatedBy` are added by the repository (PRD ADM-4), not here.
  Map<String, Object?> toMap() => {
    'name': name,
    'months': months,
    'price': price,
    'sortOrder': sortOrder,
    'isBestValue': isBestValue,
    'active': active,
  };

  Plan copyWith({
    String? name,
    int? months,
    int? price,
    int? sortOrder,
    bool? isBestValue,
    bool? active,
  }) {
    return Plan(
      id: id,
      name: name ?? this.name,
      months: months ?? this.months,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      isBestValue: isBestValue ?? this.isBestValue,
      active: active ?? this.active,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// Seed data from PRD section 8.2, written by the admin panel's
  /// "Create default plans" button.
  static const defaults = <Plan>[
    Plan(id: 'monthly', name: 'Monthly', months: 1, price: 1500, sortOrder: 1, isBestValue: false, active: true),
    Plan(id: 'quarterly', name: 'Quarterly', months: 3, price: 4000, sortOrder: 2, isBestValue: false, active: true),
    Plan(id: 'half_yearly', name: 'Half yearly', months: 6, price: 7800, sortOrder: 3, isBestValue: false, active: true),
    Plan(id: 'yearly', name: 'Yearly', months: 12, price: 15000, sortOrder: 4, isBestValue: true, active: true),
  ];
}
