import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_messages.dart';
import 'auth_shell.dart';

/// `/forgot-password` — PRD section 7.5: "email → Firebase password reset
/// email".
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// The address we told the member to check, or null before sending.
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final ok =
        await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (ok && mounted) setState(() => _sentTo = email);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final state = ref.watch(authControllerProvider);
    final error = authStateMessage(context, state);
    final sentTo = _sentTo;

    return AuthShell(
      title: l.authForgotTitle,
      subtitle: l.authForgotSubtitle,
      footer: Center(
        child: NHTextLink(
          label: l.authLogIn,
          onPressed: () => context.go(Routes.login),
        ),
      ),
      children: [
        if (sentTo != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InlineNotice(
                message: l.authResetLinkSent(sentTo),
                icon: Icons.mark_email_read_outlined,
                color: NHColors.success,
              ),
              const SizedBox(height: 18),
              GhostButton(
                label: l.actionBackToHome,
                expand: true,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          )
        else
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NHTextField(
                  label: l.authFieldEmail,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.mail_outline,
                  onChanged: (_) =>
                      ref.read(authControllerProvider.notifier).clearError(),
                  onSubmitted: (_) => _submit(),
                  validator: (value) => Validate.email(value ?? '')
                      ? null
                      : l.authErrorEmailInvalid,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  InlineNotice(message: error),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: l.authSendResetLink,
                  loading: state.busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
