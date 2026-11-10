/// Every image URL in the app lives here (PRD section 5.6).
///
/// Phase 1 has no Firebase Storage, so images are plain URLs. These are free
/// Unsplash placeholders sized with `w=` so each one stays under ~300 KB
/// (PRD section 13). When the gym's own photos are ready, swap the URLs in this
/// file and nothing else changes.
abstract final class NHAssets {
  static const _unsplash = 'https://images.unsplash.com/photo';

  /// `w` caps the width, `q` the quality; `auto=format` serves WebP where it can.
  static String _u(String id, {int w = 1200, int q = 70}) =>
      '$_unsplash-$id?auto=format&fit=crop&w=$w&q=$q';

  // ── Home ───────────────────────────────────────────────────────────────────
  static String get heroPhoto => _u('1534438327276-14e5300c3a48', w: 1800);
  static String get heroPhotoMobile => _u('1534438327276-14e5300c3a48', w: 900);

  // "Why NH Fitness" cards.
  static String get whyEquipment => _u('1570829460005-c840387bb1ca', w: 700);
  static String get whyTrainers => _u('1517836357463-d25dfeac3438', w: 700);
  static String get whyDiet => _u('1512621776951-a57141f2eefd', w: 700);
  static String get whyHygiene => _u('1580086319619-3ed498161c77', w: 700);

  // ── Explore / Pick your path ───────────────────────────────────────────────
  static String get pathMembership => _u('1581009146145-b5ef050c2e1e', w: 1000);
  static String get pathClasses => _u('1518611012118-696072aa579a', w: 800);
  static String get pathSupplements => _u('1593095948071-474c5cc2989d', w: 800);
  static String get pathClothes => _u('1556906781-9a412961c28c', w: 800);

  // ── Offer band ─────────────────────────────────────────────────────────────
  static String get offerBand => _u('1581009137042-c552e485697a', w: 1600);

  /// Fallback thumbnail for a class with no `thumbnailUrl` and an
  /// unparseable YouTube link.
  static String get classFallback => _u('1518611012118-696072aa579a', w: 600);

  /// YouTube serves a thumbnail for every video id, so a class needs no upload
  /// (PRD section 7.10: "default: the YouTube thumbnail").
  static String youtubeThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
}
