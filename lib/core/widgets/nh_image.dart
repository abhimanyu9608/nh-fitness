import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../motion.dart';

/// PRD section 5.6: "Every image needs a dark fallback color and alt text
/// (`semanticLabel`)."
///
/// Also carries the hover zoom from PRD section 5.4 — "Photo zooms to 108% on
/// hover" — and the grayscale treatment for the Coming soon cards
/// (PRD section 5.3).
class NHImage extends StatelessWidget {
  const NHImage({
    super.key,
    required this.url,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.grayscale = false,
    this.zoomOnHover = false,
    this.hovered = false,
    this.width,
    this.height,
  });

  final String url;

  /// Alt text. Pass an empty string only for images that add nothing to the
  /// page, so a screen reader can skip them.
  final String semanticLabel;
  final BoxFit fit;
  final bool grayscale;

  /// When true the parent must pass [hovered] from a `HoverRegion`, so the
  /// whole card reacts to one pointer instead of each photo tracking its own.
  final bool zoomOnHover;
  final bool hovered;
  final double? width;
  final double? height;

  /// Luminance weights — the standard greyscale conversion.
  static const _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      // The dark fallback: shown while loading and if the URL ever breaks, so
      // the layout never flashes white.
      placeholder: (_, _) => const ColoredBox(color: NHColors.surface2),
      errorWidget: (_, _, _) => const ColoredBox(
        color: NHColors.surface2,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: NHColors.muted, size: 22),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 280),
    );

    if (grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: image,
      );
    }

    if (zoomOnHover) {
      image = AnimatedScale(
        scale: hovered ? 1.08 : 1.0,
        duration: NHMotion.hover,
        curve: NHMotion.curve,
        child: image,
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      excludeSemantics: true,
      child: ClipRect(child: image),
    );
  }
}

/// A photo in a fixed-aspect box with a dark gradient over the bottom, which
/// is how every card in the designs shows an image behind text.
class PhotoPanel extends StatelessWidget {
  const PhotoPanel({
    super.key,
    required this.url,
    required this.semanticLabel,
    this.aspectRatio = 16 / 10,
    this.grayscale = false,
    this.hovered = false,
    this.zoomOnHover = false,
    this.overlay,
    this.radius = 0,
    this.gradientStrength = 0.72,
  });

  final String url;
  final String semanticLabel;
  final double aspectRatio;
  final bool grayscale;
  final bool hovered;
  final bool zoomOnHover;
  final Widget? overlay;
  final double radius;
  final double gradientStrength;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NHImage(
              url: url,
              semanticLabel: semanticLabel,
              grayscale: grayscale,
              zoomOnHover: zoomOnHover,
              hovered: hovered,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    NHColors.bg.withValues(alpha: gradientStrength),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
