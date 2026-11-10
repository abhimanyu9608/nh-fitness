import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/states.dart';
import '../../data/models/class_item.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_shell.dart';

/// `/account/classes/:id` — PRD section 7.7: "YouTube player, title,
/// description."
///
/// PRD CLS-2: videos are unlisted YouTube links. Anyone with the link can
/// watch — accepted for Phase 1.
class ClassPlayerScreen extends ConsumerWidget {
  const ClassPlayerScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider).value;

    if (user != null && !user.isActive) {
      // PRD CLS-1. Sending them to the list keeps the locked message in one
      // place.
      return AccountShell(
        title: l.classesTitle,
        children: [
          NHEmptyState(
            message: l.classesLockedTitle,
            icon: Icons.lock_outline,
            action: PrimaryButton(
              label: l.accountChoosePlan,
              expand: false,
              onPressed: () => context.go(Routes.plans),
            ),
          ),
        ],
      );
    }

    final classes = ref.watch(publishedClassesProvider);

    return AsyncSection<List<ClassItem>>(
      value: classes,
      minHeight: 400,
      onRetry: () => ref.invalidate(publishedClassesProvider),
      loading: AccountShell(
        title: l.classesTitle,
        children: const [NHLoading(minHeight: 320)],
      ),
      data: (list) {
        // The session already holds the published list, so opening a class
        // costs no extra reads.
        final item = list.where((c) => c.id == classId).firstOrNull;
        if (item == null) {
          return AccountShell(
            title: l.classesTitle,
            children: [
              NHEmptyState(
                message: l.classesNotFound,
                icon: Icons.play_disabled_outlined,
                action: GhostButton(
                  label: l.navOnlineClasses,
                  onPressed: () => context.go(Routes.accountClasses),
                ),
              ),
            ],
          );
        }
        return _Player(item: item);
      },
    );
  }
}

class _Player extends StatefulWidget {
  const _Player({required this.item});

  final ClassItem item;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = widget.item.videoId;
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          // Keep the chrome minimal so the class, not YouTube, is the subject.
          showControls: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final item = widget.item;
    final controller = _controller;

    return AccountShell(
      title: item.title,
      children: [
        FadeUp(
          index: 1,
          child: Row(
            children: [
              BackSquareButton(
                tooltip: l.actionBack,
                onPressed: () => context.go(Routes.accountClasses),
              ),
              const SizedBox(width: 12),
              if (item.category.trim().isNotEmpty)
                EyebrowLabel(text: item.category),
              const Spacer(),
              if (item.durationMin > 0)
                Text(
                  l.classesDuration('${item.durationMin}'),
                  style: NHText.label(size: 11),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeUp(
          index: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: controller == null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: NHColors.surface,
                      child: Center(
                        child: Text(
                          l.classesNotFound,
                          style: NHText.body(color: NHColors.muted),
                        ),
                      ),
                    ),
                  )
                : YoutubePlayer(
                    controller: controller,
                    aspectRatio: 16 / 9,
                  ),
          ),
        ),
        if (item.description.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          FadeUp(
            index: 3,
            child: NHCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.classesAbout.toUpperCase(),
                    style: NHText.display(size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: NHText.body(size: 15.5, color: NHColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
