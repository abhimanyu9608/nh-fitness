import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/announcement.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../l10n/app_localizations.dart';
import 'admin_shell.dart';
import 'review_sheets.dart';

/// `/admin/announcements` — PRD section 7.10: "create, edit, turn on/off".
class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final announcements = ref.watch(allAnnouncementsProvider);

    return AdminShell(
      title: l.adminAnnouncementsTitle,
      titleTrailing: SmallButton(
        label: l.adminAnnouncementAdd,
        icon: Icons.add,
        onPressed: () => _openEditor(context, ref, null),
      ),
      children: [
        AsyncSection<List<Announcement>>(
          value: announcements,
          onRetry: () => ref.invalidate(allAnnouncementsProvider),
          data: (list) {
            if (list.isEmpty) {
              return NHEmptyState(
                message: l.stateNothingHere,
                icon: Icons.campaign_outlined,
                action: PrimaryButton(
                  label: l.adminAnnouncementAdd,
                  expand: false,
                  showIcon: false,
                  onPressed: () => _openEditor(context, ref, null),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeUp(
                      index: i < 6 ? i + 1 : 0,
                      child: _AnnouncementRow(
                        announcement: list[i],
                        onEdit: () => _openEditor(context, ref, list[i]),
                        onToggle: (active) => _setActive(
                          context,
                          ref,
                          list[i].id,
                          active,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Announcement? announcement,
  ) async {
    final saved = await showNHSheet<bool>(
      context: context,
      builder: (context) => _AnnouncementEditor(announcement: announcement),
    );
    if (saved == true) {
      ref.invalidate(allAnnouncementsProvider);
      ref.invalidate(liveAnnouncementsProvider);
    }
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool active,
  ) async {
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;
    try {
      await ref.read(announcementRepositoryProvider).setActive(
            id: id,
            active: active,
            adminUid: adminUid,
          );
      ref.invalidate(allAnnouncementsProvider);
      ref.invalidate(liveAnnouncementsProvider);
    } on RepositoryException {
      if (context.mounted) {
        showNHSnack(context, L.of(context).adminWriteFailed, isError: true);
      }
    }
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({
    required this.announcement,
    required this.onEdit,
    required this.onToggle,
  });

  final Announcement announcement;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        announcement.title,
                        style: NHText.body(size: 15.5, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // "Active" in the admin list means the switch is on; a past
                    // end date makes it inactive for members regardless.
                    StatusPill(
                      label: announcement.isLive
                          ? l.accountStatusActive
                          : l.accountStatusExpired,
                      kind: announcement.isLive
                          ? PillKind.success
                          : PillKind.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  announcement.message,
                  style: NHText.body(size: 13.5, color: NHColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (announcement.endsAt != null)
                  Text(
                    '${l.adminAnnouncementEndsAt}: '
                    '${formatDate(announcement.endsAt!)}',
                    style: NHText.body(size: 12.5, color: NHColors.muted),
                  ),
              ],
            ),
          ),
          Semantics(
            label: l.adminAnnouncementActive,
            toggled: announcement.active,
            child: ExcludeSemantics(
              child: Switch(value: announcement.active, onChanged: onToggle),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: l.actionEdit,
            constraints: const BoxConstraints(
              minWidth: NHSizes.minTouchTarget,
              minHeight: NHSizes.minTouchTarget,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementEditor extends ConsumerStatefulWidget {
  const _AnnouncementEditor({this.announcement});

  final Announcement? announcement;

  @override
  ConsumerState<_AnnouncementEditor> createState() =>
      _AnnouncementEditorState();
}

class _AnnouncementEditorState extends ConsumerState<_AnnouncementEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _message;

  late bool _active;
  DateTime? _endsAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final announcement = widget.announcement;
    _title = TextEditingController(text: announcement?.title ?? '');
    _message = TextEditingController(text: announcement?.message ?? '');
    _active = announcement?.active ?? true;
    _endsAt = announcement?.endsAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final now = istCivil(DateTime.now());
    final current = _endsAt == null ? null : istCivil(_endsAt!);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        current?.year ?? now.year,
        current?.month ?? now.month,
        current?.day ?? now.day,
      ),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    // Hide it from the start of the day *after* the chosen date, so "hide
    // after 20 Nov" keeps it visible all of 20 Nov.
    setState(() => _endsAt = istDay(picked.year, picked.month, picked.day)
        .add(const Duration(days: 1)));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(announcementRepositoryProvider).save(
            Announcement(
              id: widget.announcement?.id ?? '',
              title: _title.text.trim(),
              message: _message.text.trim(),
              active: _active,
              endsAt: _endsAt,
              createdAt: widget.announcement?.createdAt,
            ),
            adminUid: adminUid,
          );
      if (mounted) Navigator.of(context).pop(true);
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
    final endsAt = _endsAt;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (widget.announcement == null
                    ? l.adminAnnouncementAdd
                    : l.actionEdit)
                .toUpperCase(),
            style: NHText.display(size: 28),
          ),
          const SizedBox(height: 18),
          NHTextField(
            label: l.adminAnnouncementTitleField,
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? l.adminErrorRequired : null,
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminAnnouncementMessage,
            controller: _message,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? l.adminErrorRequired : null,
          ),
          const SizedBox(height: 14),
          NHCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.adminAnnouncementEndsAt, style: NHText.label(size: 11)),
                      const SizedBox(height: 3),
                      Text(
                        endsAt == null
                            ? l.stateNothingHere
                            : formatDate(
                                endsAt.subtract(const Duration(days: 1)),
                              ),
                        style: NHText.body(size: 15, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (endsAt != null)
                  IconButton(
                    onPressed: () => setState(() => _endsAt = null),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l.actionCancel,
                  ),
                IconButton(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 19),
                  tooltip: l.actionEdit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          NHSwitchRow(
            label: l.adminAnnouncementActive,
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineNotice(message: _error!),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l.actionSave,
            showIcon: false,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: l.actionCancel,
            expand: true,
            height: 48,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
