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

/// `/register` — PRD section 7.5.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _agreed = false;

  /// Only shown after a submit attempt, so the checkbox does not start red.
  bool _showAgreeError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    context.go(safeNextPath(widget.next) ?? Routes.account);
  }

  Future<void> _submit() async {
    final formOk = _form.currentState?.validate() ?? false;
    // PRD section 7.5: the terms checkbox is required.
    setState(() => _showAgreeError = !_agreed);
    if (!formOk || !_agreed) return;

    final phone = Validate.digitsOnly(_phone.text);
    final ok = await ref.read(authControllerProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: phone.isEmpty ? null : phone,
        );
    if (ok) _goNext();
  }

  Future<void> _google() async {
    setState(() => _showAgreeError = !_agreed);
    if (!_agreed) return;
    final ok =
        await ref.read(authControllerProvider.notifier).continueWithGoogle();
    if (ok) _goNext();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final state = ref.watch(authControllerProvider);
    final error = authStateMessage(context, state);

    void clear() => ref.read(authControllerProvider.notifier).clearError();

    return AuthShell(
      title: l.authRegisterTitle,
      subtitle: l.authRegisterSubtitle,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.authHaveAccount, style: NHText.body(size: 14, color: NHColors.muted)),
          NHTextLink(
            label: l.authLogIn,
            onPressed: () => context.go(
              widget.next == null
                  ? Routes.login
                  : '${Routes.login}?next=${Uri.encodeComponent(widget.next!)}',
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
                label: l.authFieldName,
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                onChanged: (_) => clear(),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l.authErrorNameRequired
                    : null,
              ),
              const SizedBox(height: 14),
              NHTextField(
                label: l.authFieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                onChanged: (_) => clear(),
                validator: (value) =>
                    Validate.email(value ?? '') ? null : l.authErrorEmailInvalid,
              ),
              const SizedBox(height: 14),
              NHTextField(
                label: l.authFieldPhone,
                controller: _phone,
                helper: l.authFieldPhoneHelp,
                keyboardType: TextInputType.phone,
                digitsOnly: true,
                maxLength: 10,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.call_outlined,
                onChanged: (_) => clear(),
                // PRD section 7.5: optional, so an empty field passes — but a
                // half-typed number does not.
                validator: (value) {
                  final digits = Validate.digitsOnly(value ?? '');
                  if (digits.isEmpty) return null;
                  return Validate.phone(digits) ? null : l.authErrorPhoneInvalid;
                },
              ),
              const SizedBox(height: 14),
              NHTextField(
                label: l.authFieldPassword,
                controller: _password,
                helper: l.authFieldPasswordHelp,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outline,
                onChanged: (_) => clear(),
                validator: (value) => Validate.password(value ?? '')
                    ? null
                    : l.authErrorPasswordShort,
              ),
              const SizedBox(height: 14),
              NHTextField(
                label: l.authFieldConfirmPassword,
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                onChanged: (_) => clear(),
                onSubmitted: (_) => _submit(),
                validator: (value) => value == _password.text
                    ? null
                    : l.authErrorPasswordMismatch,
              ),
              const SizedBox(height: 16),
              _TermsCheckbox(
                value: _agreed,
                showError: _showAgreeError,
                onChanged: (value) => setState(() {
                  _agreed = value;
                  if (value) _showAgreeError = false;
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                InlineNotice(message: error),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: l.authCreateAccount,
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

/// PRD section 7.5: 'checkbox "I agree to the Terms and Privacy Policy"
/// (required)'.
///
/// The two documents are separate links under the checkbox rather than inline,
/// so the whole row stays one 44 px touch target.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: value,
          label: l.authAgreeTerms,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  SizedBox(
                    width: NHSizes.minTouchTarget,
                    height: NHSizes.minTouchTarget,
                    child: Center(
                      child: Checkbox(
                        value: value,
                        onChanged: (v) => onChanged(v ?? false),
                        side: BorderSide(
                          color: showError ? NHColors.danger : NHColors.muted,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l.authAgreeTerms,
                      style: NHText.body(size: 14.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: Row(
            children: [
              NHTextLink(
                label: l.legalTerms,
                size: 13,
                color: NHColors.muted,
                onPressed: () => context.go(Routes.terms),
              ),
              const SizedBox(width: 4),
              NHTextLink(
                label: l.legalPrivacy,
                size: 13,
                color: NHColors.muted,
                onPressed: () => context.go(Routes.privacy),
              ),
            ],
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              l.authAgreeTermsError,
              style: NHText.body(size: 13, color: NHColors.danger),
            ),
          ),
      ],
    );
  }
}
