import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/states.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';

/// PRD AUTH-1: "send a verification email on register; show a banner 'Verify
/// your email' in the account area until verified. Do not block use in
/// Phase 1."
///
/// Renders nothing for a verified member or a Google account (Google addresses
/// arrive verified).
class VerifyEmailBanner extends ConsumerStatefulWidget {
  const VerifyEmailBanner({super.key});

  @override
  ConsumerState<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<VerifyEmailBanner> {
  bool _sending = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.sendEmailVerification();
      if (mounted) showNHSnack(context, L.of(context).authVerifyEmailSent);
    } on AuthException {
      if (mounted) {
        showNHSnack(context, L.of(context).stateGenericError, isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // `emailVerified` is cached in the ID token, so it stays stale until the
    // user object is reloaded. Doing it once on open means a member who just
    // clicked the link does not see the banner again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authRepositoryProvider).reloadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = ref.watch(authStateProvider).value;
    final email = user?.email;
    if (user == null || email == null || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NHColors.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: NHColors.yellow, width: 1.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.mark_email_unread_outlined,
                size: 20, color: NHColors.yellow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.authVerifyEmailTitle,
                  style: NHText.body(size: 15.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  l.authVerifyEmailBody(email),
                  style: NHText.body(size: 14, color: NHColors.muted),
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: l.authVerifyEmailResend,
                  height: 42,
                  loading: _sending,
                  onPressed: _sending ? null : _resend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
