import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_providers.dart';

/// Every way signing in can fail that the member should hear about in plain
/// words (PRD section 7.5: "Errors are shown in plain words").
///
/// The repository never builds the message itself — the screen maps the failure
/// to a localized string, so the strings stay in one ARB file
/// (PRD section 13).
enum AuthFailure {
  wrongPassword,
  userNotFound,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
  cancelled,
  requiresRecentLogin,

  /// The project's Authentication is not set up, or this sign-in method is
  /// switched off in the Firebase Console.
  signInNotEnabled,

  /// The app is being served from a domain Firebase Auth does not allow.
  domainNotAuthorized,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.code]);

  final AuthFailure failure;
  final String? code;

  @override
  String toString() => 'AuthException(${failure.name}${code == null ? '' : ', $code'})';
}

AuthFailure _failureFor(String code) => switch (code) {
  // Firebase returns `invalid-credential` for a wrong password when email
  // enumeration protection is on, so both land on the same message.
  'wrong-password' || 'invalid-credential' => AuthFailure.wrongPassword,
  'user-not-found' => AuthFailure.userNotFound,
  'email-already-in-use' || 'account-exists-with-different-credential' =>
    AuthFailure.emailInUse,
  'weak-password' => AuthFailure.weakPassword,
  'invalid-email' => AuthFailure.invalidEmail,
  'too-many-requests' => AuthFailure.tooManyRequests,
  'network-request-failed' => AuthFailure.network,
  'requires-recent-login' => AuthFailure.requiresRecentLogin,
  'popup-closed-by-user' || 'cancelled-popup-request' || 'web-context-canceled' =>
    AuthFailure.cancelled,
  // Setup problems, not member mistakes: `operation-not-allowed` means the
  // sign-in method is switched off in the Console, and
  // `configuration-not-found` means Authentication was never set up for the
  // project at all. Worth their own message, because "something went wrong"
  // sends whoever is configuring the project hunting in the wrong place.
  'operation-not-allowed' || 'configuration-not-found' =>
    AuthFailure.signInNotEnabled,
  // The domain the app is served from is not in Firebase Auth's authorized
  // list, so the Google popup is refused. Bites during setup, because
  // `127.0.0.1` is *not* authorized by default even though `localhost` is.
  'unauthorized-domain' => AuthFailure.domainNotAuthorized,
  _ => AuthFailure.unknown,
};

/// Firebase Authentication, wrapped so the rest of the app never imports
/// `firebase_auth` directly (PRD section 14).
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Set this only if Google sign-in on Android cannot find an ID token.
  ///
  /// `flutterfire configure` puts the OAuth web client id into
  /// `android/app/google-services.json`, and google_sign_in reads it from
  /// there, so this is normally left empty.
  static const googleServerClientId = '';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Fires on sign-in/out *and* on token refresh, so the "Verify your email"
  /// banner disappears once the member reloads after verifying.
  Stream<User?> userChanges() => _auth.userChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  /// Google login: `google_sign_in` on mobile, a Firebase Auth popup on web
  /// (PRD section 3).
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _run(() => _auth.signInWithPopup(provider));
    }

    final google = GoogleSignIn.instance;
    try {
      await google.initialize(
        serverClientId:
            googleServerClientId.isEmpty ? null : googleServerClientId,
      );
      final account = await google.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // Without an ID token Firebase cannot verify the account. This happens
        // when the OAuth web client id is missing from google-services.json.
        throw const AuthException(AuthFailure.unknown, 'missing-google-id-token');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _run(() => _auth.signInWithCredential(credential));
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown,
        e.code.name,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _run(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  /// PRD AUTH-1: sent on register, and again from the banner in the account
  /// area. Never blocks use of the app in Phase 1.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    await _run(() => user.sendEmailVerification());
  }

  /// Pulls fresh claims so `emailVerified` stops being stale after the member
  /// clicks the link in their inbox.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _run(() => user.reload());
  }

  /// PRD section 7.8: change password, for members who signed up with email.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException(AuthFailure.unknown, 'no-current-user');
    }
    await _run(() async {
      // Firebase needs a recent login before a password change.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
    });
  }

  /// True when the member has a password to change — Google-only accounts do
  /// not (PRD section 7.8).
  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  Future<void> signOut() async {
    if (!kIsWeb) {
      // Clear the cached Google account too, so the next login shows the
      // account picker instead of silently reusing the last one.
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // Not signed in with Google, or the plugin was never initialized.
      }
    }
    await _run(_auth.signOut);
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_failureFor(e.code), e.code);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

/// The signed-in Firebase user, or null. Everything that needs to know "am I
/// logged in?" watches this, including the router's guards.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// The uid, or null when logged out. A separate provider so the many
/// per-member queries only rebuild when the *identity* changes, not on every
/// token refresh.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});
