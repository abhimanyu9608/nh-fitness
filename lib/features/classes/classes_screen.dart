import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/chip_row.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/models/class_item.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_shell.dart';
import 'class_tile.dart';

/// Which category chip is selected. Lives outside the screen so going into a
/// class and back keeps the filter.
final selectedClassCategoryProvider = NotifierProvider<_SelectedCategory, String?>(
  _SelectedCategory.new,
);

class _SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

/// `/account/classes` — PRD section 7.7.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider).value;

    // PRD CLS-1: only members with an active membership can open classes. The
    // rules enforce it too, so this is the friendly face of the same wall.
    if (user != null && !user.isActive) {
      return AccountShell(
        title: l.classesTitle,
        children: [FadeUp(index: 1, child: const _LockedCard())],
      );
    }

    final classes = ref.watch(publishedClassesProvider);
    final categories = ref.watch(classCategoriesProvider);
    final selected = ref.watch(selectedClassCategoryProvider);

    return AccountShell(
      title: l.classesTitle,
      children: [
        if (categories.isNotEmpty)
          FadeUp(
            index: 1,
            child: _CategoryChips(
              categories: categories,
              selected: selected,
              onSelected: (value) =>
                  ref.read(selectedClassCategoryProvider.notifier).select(value),
            ),
          ),
        const SizedBox(height: 18),
        AsyncSection<List<ClassItem>>(
          value: classes,
          onRetry: () => ref.invalidate(publishedClassesProvider),
          data: (list) {
            final shown = selected == null
                ? list
                : list.where((c) => c.category.trim() == selected).toList();

            if (shown.isEmpty) {
              return NHEmptyState(
                message: l.classesEmpty,
                icon: Icons.play_circle_outline,
              );
            }

            return FadeUp(
              index: 2,
              child: NHGrid(
                columns: context.bp.isDesktop ? 3 : 2,
                children: [
                  for (final item in shown)
                    ClassGridCard(
                      item: item,
                      onTap: () =>
                          context.go('${Routes.accountClasses}/${item.id}'),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        NHChip(
          label: l.classesAll,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final category in categories)
          NHChip(
            label: category,
            selected: selected == category,
            onTap: () => onSelected(category),
          ),
      ],
    );
  }
}

/// PRD CLS-1: "Others see 'Online classes are for active members' + 'Choose a
/// plan'."
class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 28, color: NHColors.red),
          const SizedBox(height: 14),
          Text(
            l.classesLockedTitle.toUpperCase(),
            style: NHText.display(size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            l.classesLockedBody,
            style: NHText.body(size: 15, color: NHColors.muted),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: l.accountChoosePlan,
              expand: false,
              onPressed: () => context.go(Routes.plans),
            ),
          ),
        ],
      ),
    );
  }
}
