import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_shell.dart';

/// `/admin/settings` — PRD section 7.10: "registration fee, PT fee, PT free
/// days, UPI ID, UPI name, approval time text, gym address, timings, phone,
/// email, Instagram URL, supplements/clothes enabled flags."
///
/// Everything here changes what members see without a new app release
/// (PRD goal 1.3).
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);

    return AdminShell(
      title: l.adminSettingsTitle,
      children: [
        AsyncSection<AppSettings>(
          value: settings,
          onRetry: () => ref.invalidate(settingsProvider),
          // A fresh key makes the form reload its controllers after a save.
          data: (value) => _SettingsForm(
            key: ValueKey(value.updatedAt ?? DateTime(0)),
            settings: value,
          ),
        ),
      ],
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key, required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _form = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _fields;
  late bool _supplementsEnabled;
  late bool _clothesEnabled;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _fields = {
      'registrationFee': TextEditingController(text: '${s.registrationFee}'),
      'ptFee': TextEditingController(text: '${s.ptFee}'),
      'ptFreeDays': TextEditingController(text: '${s.ptFreeDays}'),
      'upiId': TextEditingController(text: s.upiId),
      'upiName': TextEditingController(text: s.upiName),
      'approvalTimeText': TextEditingController(text: s.approvalTimeText),
      'address': TextEditingController(text: s.address),
      'timings': TextEditingController(text: s.timings),
      'phone': TextEditingController(text: s.phone),
      'email': TextEditingController(text: s.email),
      'instagramUrl': TextEditingController(text: s.instagramUrl),
    };
    _supplementsEnabled = s.supplementsEnabled;
    _clothesEnabled = s.clothesEnabled;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _fields[key]!.text.trim();

  int _int(String key) => int.tryParse(_text(key)) ?? 0;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(settingsRepositoryProvider).save(
            widget.settings.copyWith(
              registrationFee: _int('registrationFee'),
              ptFee: _int('ptFee'),
              ptFreeDays: _int('ptFreeDays'),
              upiId: _text('upiId'),
              upiName: _text('upiName'),
              approvalTimeText: _text('approvalTimeText'),
              address: _text('address'),
              timings: _text('timings'),
              phone: _text('phone'),
              email: _text('email'),
              instagramUrl: _text('instagramUrl'),
              supplementsEnabled: _supplementsEnabled,
              clothesEnabled: _clothesEnabled,
            ),
            adminUid: adminUid,
          );
      // Members cache settings for the session; invalidating makes the change
      // visible on the next read in this session too.
      ref.invalidate(settingsProvider);
      if (mounted) {
        setState(() => _saving = false);
        showNHSnack(context, L.of(context).stateSaved);
      }
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).adminWriteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeUp(
            index: 1,
            child: _Group(
              title: l.adminSettingsMoneyGroup,
              children: [
                _NumberField(
                  label: l.adminSetRegistrationFee,
                  controller: _fields['registrationFee']!,
                ),
                _NumberField(
                  label: l.adminSetPtFee,
                  controller: _fields['ptFee']!,
                ),
                _NumberField(
                  label: l.adminSetPtFreeDays,
                  controller: _fields['ptFreeDays']!,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeUp(
            index: 2,
            child: _Group(
              title: l.adminSettingsUpiGroup,
              children: [
                NHTextField(
                  label: l.adminSetUpiId,
                  controller: _fields['upiId']!,
                  prefixIcon: Icons.qr_code_2_outlined,
                  validator: _required,
                ),
                NHTextField(
                  label: l.adminSetUpiName,
                  controller: _fields['upiName']!,
                  validator: _required,
                ),
                NHTextField(
                  label: l.adminSetApprovalTime,
                  controller: _fields['approvalTimeText']!,
                  helper: l.adminSetApprovalTimeHelp,
                  validator: _required,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeUp(
            index: 3,
            child: _Group(
              title: l.adminSettingsContactGroup,
              children: [
                NHTextField(
                  label: l.adminSetAddress,
                  controller: _fields['address']!,
                  maxLines: 3,
                  prefixIcon: Icons.location_on_outlined,
                ),
                NHTextField(
                  label: l.adminSetTimings,
                  controller: _fields['timings']!,
                  prefixIcon: Icons.schedule_outlined,
                ),
                NHTextField(
                  label: l.adminSetPhone,
                  controller: _fields['phone']!,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.call_outlined,
                ),
                NHTextField(
                  label: l.adminSetEmail,
                  controller: _fields['email']!,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                ),
                NHTextField(
                  label: l.adminSetInstagram,
                  controller: _fields['instagramUrl']!,
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.camera_alt_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeUp(
            index: 4,
            child: _Group(
              title: l.adminSettingsStoreGroup,
              children: [
                // PRD EXP-1: the flags exist for Phase 2; both stay off for now.
                NHSwitchRow(
                  label: l.adminSetSupplementsEnabled,
                  value: _supplementsEnabled,
                  onChanged: (value) =>
                      setState(() => _supplementsEnabled = value),
                ),
                NHSwitchRow(
                  label: l.adminSetClothesEnabled,
                  value: _clothesEnabled,
                  onChanged: (value) => setState(() => _clothesEnabled = value),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineNotice(message: _error!),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: l.actionSaveChanges,
            showIcon: false,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? L.of(context).adminErrorRequired : null;
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NHCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: NHText.display(size: 24)),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHTextField(
      label: label,
      controller: controller,
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        return parsed != null && parsed >= 0 ? null : l.adminErrorNumber;
      },
    );
  }
}
