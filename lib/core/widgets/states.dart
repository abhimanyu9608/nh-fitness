import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../l10n/app_localizations.dart';
import 'nh_buttons.dart';

/// PRD section 13: "every screen has loading, empty and error states. Errors
/// say what happened and what to do."
///
/// Every async read in the app goes through this widget, so all three states
/// look the same everywhere.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.errorMessage,
    this.minHeight = 200,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Usually `() => ref.invalidate(theProvider)`.
  final VoidCallback? onRetry;
  final Widget? loading;

  /// Overrides the generic message, e.g. PRD HOME-2's
  /// "Prices could not load. Try again."
  final String? errorMessage;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    // While refreshing, keep showing the old data rather than flashing a
    // spinner — the member should not watch the page empty itself out.
    if (value.hasValue && !value.hasError) return data(value.value as T);

    if (value.hasError) {
      return NHErrorState(
        message: errorMessage ?? messageForError(context, value.error),
        onRetry: onRetry,
        minHeight: minHeight,
      );
    }

    return loading ?? NHLoading(minHeight: minHeight);
  }
}

/// Turns whatever a repository threw into something worth reading.
String messageForError(BuildContext context, Object? error) {
  final l = L.of(context);
  if (error is RepositoryException && error.isOffline) return l.stateNoInternet;
  if (error is AuthException && error.failure == AuthFailure.network) {
    return l.stateNoInternet;
  }
  return l.stateGenericError;
}

class NHLoading extends StatelessWidget {
  const NHLoading({super.key, this.minHeight = 200, this.label});

  final double minHeight;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Semantics(
          label: label ?? L.of(context).stateLoading,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

class NHErrorState extends StatelessWidget {
  const NHErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.minHeight = 200,
  });

  final String message;
  final VoidCallback? onRetry;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: NHColors.danger, size: 30),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: NHText.body(color: NHColors.muted),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                GhostButton(label: L.of(context).actionRetry, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NHEmptyState extends StatelessWidget {
  const NHEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.minHeight = 180,
  });

  final String message;
  final IconData icon;
  final Widget? action;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: NHColors.muted, size: 28),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: NHText.body(color: NHColors.muted),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A one-line note in the app's "something is not right" voice, for use inside
/// a form or a card rather than as a whole-screen state.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.color = NHColors.danger,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: NHText.body(size: 14.5, color: NHColors.text)),
          ),
        ],
      ),
    );
  }
}

/// Shows a message in the app's snack bar style. Used for "Coming soon",
/// "Copied", and write failures.
void showNHSnack(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 19,
              color: isError ? NHColors.danger : NHColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
}
