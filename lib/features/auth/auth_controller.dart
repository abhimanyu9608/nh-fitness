import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/user_repository.dart';

/// What the auth forms need to render: are we busy, and did the last attempt
/// fail?
///
/// The failure is kept as an enum rather than a message so the screen can
/// localize it (PRD section 13 keeps every string in the ARB file).
class AuthUiState {
  const AuthUiState({this.busy = false, this.failure, this.writeFailed = false});

  final bool busy;
  final AuthFailure? failure;

  /// The sign-in worked but `users/{uid}` could not be written — almost always
  /// a dropped connection.
  final bool writeFailed;

  static const idle = AuthUiState();

  bool get hasError => failure != null || writeFailed;
}

/// Drives register, login, Google sign-in and password reset.
///
/// Also owns the one rule PRD section 7.5 attaches to every sign-in path: "On
/// first login (any method), create `users/{uid}` if it does not exist."
class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => AuthUiState.idle;

  /// Clears the error so it disappears as soon as the member edits a field.
  void clearError() {
    if (state.hasError) state = AuthUiState.idle;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return _attempt(() async {
      final auth = ref.read(authRepositoryProvider);
      final credential =
          await auth.registerWithEmail(email: email, password: password);
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthException(AuthFailure.unknown);

      await ref.read(userRepositoryProvider).createIfMissing(
            uid: uid,
            name: name,
            email: email,
            phone: phone,
          );

      // PRD AUTH-1: send a verification email on register. It never blocks use
      // of the app in Phase 1, so a failure here is not worth surfacing.
      try {
        await auth.sendEmailVerification();
      } on AuthException {
        // The banner in the account area offers a "Send again" button.
      }
    });
  }

  Future<bool> logIn({required String email, required String password}) {
    return _attempt(() async {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      await _ensureProfile(credential.user?.uid, credential.user?.email);
    });
  }

  Future<bool> continueWithGoogle() {
    return _attempt(() async {
      final credential =
          await ref.read(authRepositoryProvider).signInWithGoogle();
      final user = credential.user;
      await _ensureProfile(
        user?.uid,
        user?.email,
        // Google gives us a display name; the member can edit it in Profile.
        name: user?.displayName,
        phone: user?.phoneNumber,
      );
    });
  }

  Future<bool> sendPasswordReset(String email) {
    return _attempt(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  /// PRD section 7.5: a member who registered before this document existed —
  /// or who signed in with Google for the first time — gets one created now.
  Future<void> _ensureProfile(
    String? uid,
    String? email, {
    String? name,
    String? phone,
  }) async {
    if (uid == null) throw const AuthException(AuthFailure.unknown);
    await ref.read(userRepositoryProvider).createIfMissing(
          uid: uid,
          name: name ?? '',
          email: email ?? '',
          phone: phone,
        );
  }

  Future<bool> _attempt(Future<void> Function() action) async {
    state = const AuthUiState(busy: true);
    try {
      await action();
      state = AuthUiState.idle;
      return true;
    } on AuthException catch (e) {
      state = AuthUiState(failure: e.failure);
      return false;
    } on RepositoryException catch (e) {
      state = AuthUiState(
        writeFailed: true,
        failure: e.isOffline ? AuthFailure.network : null,
      );
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthUiState>(AuthController.new);
