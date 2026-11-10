import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../core/responsive.dart';
import '../../data/models/announcement.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../l10n/app_localizations.dart';

/// PRD section 7.9: "Active announcements show as a strip at the top of Home
/// and the account dashboard. Dismissing hides it on that device (local
/// storage)."
///
/// Renders nothing — not even a gap — when there is no live announcement, so
/// it is safe to place above any hero.
class AnnouncementStrip extends ConsumerStatefulWidget {
  const AnnouncementStrip({super.key});

  /// One key per announcement id, so a new announcement is not hidden by an
  /// older dismissal.
  static String _prefsKey(String id) => 'announcement_dismissed_$id';

  @override
  ConsumerState<AnnouncementStrip> createState() => _AnnouncementStripState();
}

class _AnnouncementStripState extends ConsumerState<AnnouncementStrip> {
  /// Null until shared_preferences has been read; the strip stays hidden until
  /// then so a dismissed announcement never flashes back up.
  Set<String>? _dismissed;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs
        .getKeys()
        .where((k) => k.startsWith('announcement_dismissed_'))
        .where((k) => prefs.getBool(k) ?? false)
        .map((k) => k.replaceFirst('announcement_dismissed_', ''))
        .toSet();
    if (mounted) setState(() => _dismissed = dismissed);
  }

  Future<void> _dismiss(Announcement announcement) async {
    setState(() => _dismissed = {...?_dismissed, announcement.id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AnnouncementStrip._prefsKey(announcement.id), true);
  }

  @override
  Widget build(BuildContext context) {
    final dismissed = _dismissed;
    if (dismissed == null) return const SizedBox.shrink();

    // A failed read of `announcements` must never block the page, so errors
    // fall through to "no announcement".
    final announcements =
        ref.watch(liveAnnouncementsProvider).value ?? const <Announcement>[];
    final next = announcements.where((a) => !dismissed.contains(a.id)).firstOrNull;
    if (next == null) return const SizedBox.shrink();

    return _Strip(announcement: next, onDismiss: () => _dismiss(next));
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.announcement, required this.onDismiss});

  final Announcement announcement;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Container(
      color: NHColors.surface2,
      child: ContentWidth(
        padVertical: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.campaign_outlined, size: 19, color: NHColors.yellow),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (announcement.title.trim().isNotEmpty)
                    Text(
                      announcement.title,
                      style: NHText.body(size: 15, weight: FontWeight.w700),
                    ),
                  if (announcement.message.trim().isNotEmpty)
                    Text(
                      announcement.message,
                      style: NHText.body(size: 14.5, color: NHColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 19),
              tooltip: l.announcementDismiss,
              constraints: const BoxConstraints(
                minWidth: NHSizes.minTouchTarget,
                minHeight: NHSizes.minTouchTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
