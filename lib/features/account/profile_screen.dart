import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/validators.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_messages.dart';
import 'account_shell.dart';

/// `/account/profile` — PRD section 7.8: "edit name and phone; show email
/// (read-only); change password (email users); logout."
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider);

    return AccountShell(
      title: l.profileTitle,
      children: [
        AsyncSection<AppUser?>(
          value: user,
          onRetry: () => ref.invalidate(currentUserProvider),
          data: (value) => value == null
              ? const NHLoading()
              : FadeUp(index: 1, child: _ProfileForm(user: value)),
        ),
        const SizedBox(height: 18),
        const FadeUp(index: 2, child: _PasswordCard()),
        const SizedBox(height: 18),
        const FadeUp(index: 3, child: _DataDeletionCard()),
        const SizedBox(height: 18),
        FadeUp(
          index: 4,
          child: GhostButton(
            label: l.actionLogOut,
            icon: Icons.logout_outlined,
            expand: true,
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(Routes.home);
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user});

  final AppUser user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(userRepositoryProvider).updateProfile(
            uid: widget.user.uid,
            name: _name.text,
            phone: Validate.digitsOnly(_phone.text),
          );
      if (mounted) {
        setState(() => _saving = false);
        showNHSnack(context, L.of(context).profileSaved);
      }
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).stateGenericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NHTextField(
              label: l.authFieldName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l.authErrorNameRequired
                  : null,
            ),
            const SizedBox(height: 14),
            NHTextField(
              label: l.authFieldPhone,
              controller: _phone,
              helper: l.authFieldPhoneHelp,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              maxLength: 10,
              prefixIcon: Icons.call_outlined,
              validator: (value) {
                final digits = Validate.digitsOnly(value ?? '');
                if (digits.isEmpty) return null;
                return Validate.phone(digits) ? null : l.authErrorPhoneInvalid;
              },
            ),
            const SizedBox(height: 14),
            // The email is the account's identity in Firebase Auth, so it is
            // shown but not editable (PRD section 7.8).
            NHTextField(
              label: l.authFieldEmail,
              initialValue: widget.user.email,
              helper: l.profileEmailReadOnly,
              enabled: false,
              prefixIcon: Icons.mail_outline,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              InlineNotice(message: _error!),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.actionSaveChanges,
              showIcon: false,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// PRD section 7.8: change password, for members who signed up with an email
/// and password. Google-only accounts have none.
class _PasswordCard extends ConsumerStatefulWidget {
  const _PasswordCard();

  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      _current.clear();
      _next.clear();
      setState(() => _saving = false);
      showNHSnack(context, L.of(context).authPasswordChanged);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = authFailureMessage(context, error.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final hasPassword = ref.watch(authRepositoryProvider).hasPasswordProvider;

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.authChangePassword.toUpperCase(), style: NHText.display(size: 24)),
          const SizedBox(height: 12),
          if (!hasPassword)
            Text(
              l.profileGoogleAccount,
              style: NHText.body(size: 14.5, color: NHColors.muted),
            )
          else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NHTextField(
                    label: l.authFieldCurrentPassword,
                    controller: _current,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) =>
                        (value ?? '').isEmpty ? l.adminErrorRequired : null,
                  ),
                  const SizedBox(height: 14),
                  NHTextField(
                    label: l.authFieldNewPassword,
                    controller: _next,
                    helper: l.authFieldPasswordHelp,
                    obscureText: true,
                    prefixIcon: Icons.lock_reset_outlined,
                    validator: (value) => Validate.password(value ?? '')
                        ? null
                        : l.authErrorPasswordShort,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    InlineNotice(message: _error!),
                  ],
                  const SizedBox(height: 16),
                  GhostButton(
                    label: l.authChangePassword,
                    expand: true,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// PRD section 13 (Privacy): a member must be able to ask for deletion. Phase 1
/// handles it by email to the gym, which an admin then actions by hand.
class _DataDeletionCard extends ConsumerWidget {
  const _DataDeletionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider).value;
    final email = (settings?.hasEmail ?? false)
        ? settings!.email
        : l.legalPlaceholder;

    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileDeleteDataTitle.toUpperCase(),
            style: NHText.display(size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            l.profileDeleteDataBody(email),
            style: NHText.body(size: 14.5, color: NHColors.muted),
          ),
          const SizedBox(height: 10),
          NHTextLink(
            label: l.legalPrivacy,
            onPressed: () => context.go(Routes.privacy),
          ),
        ],
      ),
    );
  }
}
