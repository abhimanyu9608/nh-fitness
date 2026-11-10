import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../motion.dart';

/// PRD section 5.3: `surface` fill, 2 px `line` border, radius 16–18.
///
/// `selected` switches to the picked-plan look: red border and `selectedBg`
/// fill. `lift` adds the web hover behaviour from PRD section 5.4 — "Lift 8 px
/// with red glow on hover".
class NHCard extends StatelessWidget {
  const NHCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.lift = false,
    this.padding = const EdgeInsets.all(18),
    this.radius = NHSizes.cardRadius,
    this.background,
    this.borderColor,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool lift;
  final EdgeInsets padding;
  final double radius;
  final Color? background;
  final Color? borderColor;

  /// Set for cards whose content is a photo that must be clipped to the radius.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder: (context, hovered) {
        final border = borderColor ??
            (selected
                ? NHColors.red
                : (hovered && lift ? NHColors.red : NHColors.line));

        return AnimatedContainer(
          duration: NHMotion.hover,
          curve: NHMotion.curve,
          transform: Matrix4.translationValues(0, hovered && lift ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: background ?? (selected ? NHColors.selectedBg : NHColors.surface),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 2),
            boxShadow: hovered && lift
                ? [
                    BoxShadow(
                      color: NHColors.red.withValues(alpha: 0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: clip ? Clip.antiAlias : Clip.none,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// The best-value plan card on Home: "Best value plan uses the red card style"
/// (PRD section 7.1).
class RedCard extends StatelessWidget {
  const RedCard({
    super.key,
    required this.child,
    this.onTap,
    this.lift = false,
    this.padding = const EdgeInsets.all(18),
    this.radius = NHSizes.cardRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool lift;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: NHMotion.hover,
          curve: NHMotion.curve,
          transform: Matrix4.translationValues(0, hovered && lift ? -8 : 0, 0),
          decoration: BoxDecoration(
            // `redDark` shades the red card (PRD section 5.1).
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NHColors.red, NHColors.redDark],
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: hovered && lift
                ? [
                    BoxShadow(
                      color: NHColors.red.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// A raised card on top of a card — `surface2` (PRD section 5.1).
class RaisedPanel extends StatelessWidget {
  const RaisedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 13,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NHColors.surface2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: NHColors.line, width: 1.5),
      ),
      child: child,
    );
  }
}

/// A label/value row, used all over the order summary, membership card and
/// admin detail screens.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.labelStyle,
    this.strong = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ??
                  NHText.body(
                    size: 15,
                    color: strong ? NHColors.text : NHColors.muted,
                    weight: strong ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                NHText.moneyBody(
                  size: 15,
                  weight: strong ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
