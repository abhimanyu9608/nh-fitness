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

/// `/login` — PRD section 7.5.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.next});

  /// Where to land after logging in (PRD PAY-5 sends checkout here).
  final String? next;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    context.go(safeNextPath(widget.next) ?? Routes.account);
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authControllerProvider.notifier).logIn(
          email: _email.text,
          password: _password.text,
        );
    if (ok) _goNext();
  }

  Future<void> _google() async {
    final ok =
        await ref.read(authControllerProvider.notifier).continueWithGoogle();
    if (ok) _goNext();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final state = ref.watch(authControllerProvider);
    final error = authStateMessage(context, state);

    return AuthShell(
      title: l.authLoginTitle,
      subtitle: l.authLoginSubtitle,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.authNoAccount, style: NHText.body(size: 14, color: NHColors.muted)),
          NHTextLink(
            label: l.authCreateAccount,
            onPressed: () => context.go(
              widget.next == null
                  ? Routes.register
                  : '${Routes.register}?next=${Uri.encodeComponent(widget.next!)}',
            ),
          ),
        ],
      ),
      children: [
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
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                onChanged: (_) =>
                    ref.read(authControllerProvider.notifier).clearError(),
                validator: (value) => Validate.email(value ?? '')
                    ? null
                    : l.authErrorEmailInvalid,
              ),
              const SizedBox(height: 14),
              NHTextField(
                label: l.authFieldPassword,
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                onChanged: (_) =>
                    ref.read(authControllerProvider.notifier).clearError(),
                onSubmitted: (_) => _submit(),
                validator: (value) => (value ?? '').isEmpty
                    ? l.authErrorPasswordShort
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: NHTextLink(
                  label: l.authForgotPasswordLink,
                  color: NHColors.muted,
                  size: 14,
                  onPressed: () => context.go(Routes.forgotPassword),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                InlineNotice(message: error),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: l.authLogIn,
                loading: state.busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const OrDivider(),
        GhostButton(
          label: l.authContinueWithGoogle,
          leading: const GoogleMark(),
          expand: true,
          onPressed: state.busy ? null : _google,
        ),
      ],
    );
  }
}
