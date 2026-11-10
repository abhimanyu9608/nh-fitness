import 'package:flutter/widgets.dart';

import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';

/// PRD section 7.5: "Errors are shown in plain words (wrong password, email
/// already used, no internet)."
String authFailureMessage(BuildContext context, AuthFailure failure) {
  final l = L.of(context);
  return switch (failure) {
    AuthFailure.wrongPassword => l.authErrorWrongPassword,
    AuthFailure.userNotFound => l.authErrorUserNotFound,
    AuthFailure.emailInUse => l.authErrorEmailInUse,
    AuthFailure.weakPassword => l.authErrorWeakPassword,
    AuthFailure.invalidEmail => l.authErrorEmailInvalid,
    AuthFailure.tooManyRequests => l.authErrorTooManyRequests,
    AuthFailure.network => l.authErrorNetwork,
    AuthFailure.cancelled => l.authErrorGoogleCancelled,
    AuthFailure.signInNotEnabled => l.authErrorSignInNotEnabled,
    AuthFailure.domainNotAuthorized => l.authErrorDomainNotAuthorized,
    AuthFailure.requiresRecentLogin => l.authErrorRecentLogin,
    AuthFailure.unknown => l.stateGenericError,
  };
}

/// The message for whatever went wrong on the last attempt, or null if nothing
/// did.
String? authStateMessage(BuildContext context, AuthUiState state) {
  final failure = state.failure;
  if (failure != null) return authFailureMessage(context, failure);
  if (state.writeFailed) return L.of(context).stateGenericError;
  return null;
}
