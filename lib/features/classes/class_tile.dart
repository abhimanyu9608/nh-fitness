import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_image.dart';
import '../../core/widgets/nh_pill.dart';
import '../../data/models/class_item.dart';
import '../../l10n/app_localizations.dart';

/// A class in the grid: "thumbnail, title, category, duration"
/// (PRD section 7.7).
class ClassGridCard extends StatelessWidget {
  const ClassGridCard({super.key, required this.item, required this.onTap});

  final ClassItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return HoverRegion(
      builder: (context, hovered) {
        return NHCard(
          onTap: onTap,
          lift: true,
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPanel(
                url: item.effectiveThumbnailUrl,
                semanticLabel: item.title,
                aspectRatio: 16 / 9,
                zoomOnHover: true,
                hovered: hovered,
                overlay: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Icon(Icons.play_circle_outline,
                            size: 42, color: Colors.white),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const LiveDot(),
                            const SizedBox(width: 6),
                            Text(l.classesLive, style: NHText.label(size: 11)),
                          ],
                        ),
                      ),
                      if (item.durationMin > 0)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: NHColors.bg.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              l.classesDuration('${item.durationMin}'),
                              style: NHText.label(size: 11, color: NHColors.text),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category.trim().isNotEmpty) ...[
                      EyebrowLabel(text: item.category),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      item.title.toUpperCase(),
                      style: NHText.display(size: 22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The compact row used by the dashboard preview and the admin list.
class ClassListTile extends StatelessWidget {
  const ClassListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
    this.showDraftBadge = false,
  });

  final ClassItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// The admin list marks unpublished classes; the member list never sees them.
  final bool showDraftBadge;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 92,
              height: 56,
              child: NHImage(
                url: item.effectiveThumbnailUrl,
                semanticLabel: item.title,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: NHText.body(size: 15.5, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (item.category.trim().isNotEmpty) item.category,
                    if (item.durationMin > 0)
                      l.classesDuration('${item.durationMin}'),
                  ].join(' · '),
                  style: NHText.body(size: 13, color: NHColors.muted),
                ),
              ],
            ),
          ),
          if (showDraftBadge && !item.published) ...[
            const SizedBox(width: 8),
            StatusPill(label: l.accountStatusPending, kind: PillKind.neutral),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
