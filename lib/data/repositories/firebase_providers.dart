import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two Firebase SDKs the app uses (PRD section 3). Overriding these in
/// `ProviderScope` is how tests and the widget previews run without a real
/// Firebase project.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Collection names, in one place so a typo cannot drift between repositories.
abstract final class Col {
  static const users = 'users';
  static const admins = 'admins';
  static const owners = 'owners';
  static const plans = 'plans';
  static const settings = 'settings';
  static const paymentRequests = 'paymentRequests';
  static const memberships = 'memberships';
  static const classes = 'classes';
  static const announcements = 'announcements';

  /// `settings` holds exactly one document (PRD section 8.1).
  static const settingsDoc = 'app';
}

/// PRD section 13: every list is paginated, 20 per page, to stay inside the
/// Spark plan's daily read cap.
const pageSize = 20;

/// Something went wrong writing to Firestore — almost always no connection, or
/// the security rules said no.
class RepositoryException implements Exception {
  const RepositoryException(this.code, [this.message]);

  final String code;
  final String? message;

  bool get isPermissionDenied => code == 'permission-denied';
  bool get isOffline => code == 'unavailable' || code == 'network-request-failed';

  @override
  String toString() => 'RepositoryException($code${message == null ? '' : ': $message'})';
}

/// Wraps a Firestore call so callers only ever have to catch one type.
Future<T> guardFirestore<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    throw RepositoryException(e.code, e.message);
  }
}
