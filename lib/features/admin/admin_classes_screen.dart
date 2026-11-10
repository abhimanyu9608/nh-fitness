import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/class_item.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../l10n/app_localizations.dart';
import '../classes/class_tile.dart';
import 'admin_shell.dart';
import 'review_sheets.dart';

/// `/admin/classes` — PRD section 7.10: "Create/edit: title, description,
/// category, duration (minutes), YouTube URL, thumbnail URL (default: the
/// YouTube thumbnail), published on/off, sort order. Preview before saving."
class AdminClassesScreen extends ConsumerWidget {
  const AdminClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final classes = ref.watch(allClassesProvider);

    return AdminShell(
      title: l.adminClassesTitle,
      titleTrailing: SmallButton(
        label: l.adminClassAdd,
        icon: Icons.add,
        onPressed: () => _openEditor(context, ref, null),
      ),
      children: [
        FadeUp(
          index: 1,
          child: InlineNotice(
            // PRD CLS-2 is a known limit worth repeating where classes are
            // added, not just in the PRD.
            message: l.adminClassUnlistedNote,
            icon: Icons.info_outline,
            color: NHColors.muted,
          ),
        ),
        const SizedBox(height: 16),
        AsyncSection<List<ClassItem>>(
          value: classes,
          onRetry: () => ref.invalidate(allClassesProvider),
          data: (list) {
            if (list.isEmpty) {
              return NHEmptyState(
                message: l.classesEmpty,
                icon: Icons.play_circle_outline,
                action: PrimaryButton(
                  label: l.adminClassAdd,
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
                      index: i < 6 ? i + 2 : 0,
                      child: ClassListTile(
                        item: list[i],
                        showDraftBadge: true,
                        onTap: () => _openEditor(context, ref, list[i]),
                        trailing: Row(
                          children: [
                            Semantics(
                              label: l.adminClassPublished,
                              toggled: list[i].published,
                              child: ExcludeSemantics(
                                child: Switch(
                                  value: list[i].published,
                                  onChanged: (value) => _setPublished(
                                    context,
                                    ref,
                                    list[i].id,
                                    value,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 6),
                          ],
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
    ClassItem? item,
  ) async {
    final saved = await showNHSheet<bool>(
      context: context,
      builder: (context) => _ClassEditor(item: item),
    );
    if (saved == true) {
      ref.invalidate(allClassesProvider);
      ref.invalidate(publishedClassesProvider);
    }
  }

  Future<void> _setPublished(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool published,
  ) async {
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;
    try {
      await ref.read(classRepositoryProvider).setPublished(
            id: id,
            published: published,
            adminUid: adminUid,
          );
      ref.invalidate(allClassesProvider);
      ref.invalidate(publishedClassesProvider);
    } on RepositoryException {
      if (context.mounted) {
        showNHSnack(context, L.of(context).adminWriteFailed, isError: true);
      }
    }
  }
}

class _ClassEditor extends ConsumerStatefulWidget {
  const _ClassEditor({this.item});

  final ClassItem? item;

  @override
  ConsumerState<_ClassEditor> createState() => _ClassEditorState();
}

class _ClassEditorState extends ConsumerState<_ClassEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _duration;
  late final TextEditingController _youtubeUrl;
  late final TextEditingController _thumbnailUrl;
  late final TextEditingController _sortOrder;

  late bool _published;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _duration = TextEditingController(text: '${item?.durationMin ?? 0}');
    _youtubeUrl = TextEditingController(text: item?.youtubeUrl ?? '');
    _thumbnailUrl = TextEditingController(text: item?.thumbnailUrl ?? '');
    _sortOrder = TextEditingController(text: '${item?.sortOrder ?? 1}');
    _published = item?.published ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _duration.dispose();
    _youtubeUrl.dispose();
    _thumbnailUrl.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  /// The live preview, built from whatever is typed so far.
  ClassItem get _draft => ClassItem(
    id: widget.item?.id ?? '',
    title: _title.text.trim().isEmpty ? L.of(context).adminClassPreview : _title.text.trim(),
    description: _description.text.trim(),
    category: _category.text.trim(),
    durationMin: int.tryParse(_duration.text.trim()) ?? 0,
    youtubeUrl: _youtubeUrl.text.trim(),
    thumbnailUrl: _thumbnailUrl.text.trim(),
    published: _published,
    sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 1,
  );

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final adminUid = ref.read(currentUidProvider);
    if (adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(classRepositoryProvider).save(_draft, adminUid: adminUid);
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

    return Form
      (
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (widget.item == null ? l.adminClassAdd : l.actionEdit).toUpperCase(),
            style: NHText.display(size: 28),
          ),
          const SizedBox(height: 18),
          NHTextField(
            label: l.adminClassTitleField,
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? l.adminErrorRequired : null,
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminClassYoutubeUrl,
            controller: _youtubeUrl,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            validator: (value) => youtubeVideoId(value ?? '') == null
                ? l.adminClassUrlInvalid
                : null,
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminClassDescription,
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NHTextField(
                  label: l.adminClassCategory,
                  controller: _category,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NHTextField(
                  label: l.adminClassDuration,
                  controller: _duration,
                  digitsOnly: true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminClassThumbnailUrl,
            controller: _thumbnailUrl,
            helper: l.adminClassThumbnailHelp,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NHTextField(
            label: l.adminPlanSortOrder,
            controller: _sortOrder,
            digitsOnly: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 6),
          NHSwitchRow(
            label: l.adminClassPublished,
            value: _published,
            onChanged: (value) => setState(() => _published = value),
          ),
          const SizedBox(height: 18),
          Text(l.adminClassPreview.toUpperCase(), style: NHText.label()),
          const SizedBox(height: 10),
          // PRD section 7.10: "Preview before saving."
          ClassGridCard(item: _draft, onTap: () {}),
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
