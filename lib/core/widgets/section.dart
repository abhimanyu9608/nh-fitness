import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../motion.dart';
import '../responsive.dart';
import 'nh_pill.dart';

/// A big italic section heading. Sizes follow PRD section 5.2: 44–76 px on
/// web, 40–46 px on mobile.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.highlight,
    this.align = TextAlign.left,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  /// A trailing word rendered in red, the way "YESTERDAY" is in the hero.
  final String? highlight;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final size = switch (context.bp) {
      NHBreakpoint.mobile => 42.0,
      NHBreakpoint.tablet => 54.0,
      NHBreakpoint.desktop => 66.0,
    };

    final heading = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title.toUpperCase(), style: NHText.display(size: size)),
          if (highlight != null)
            TextSpan(
              text: ' ${highlight!.toUpperCase()}',
              style: NHText.display(size: size, color: NHColors.red),
            ),
        ],
      ),
      textAlign: align,
    );

    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          EyebrowLabel(text: eyebrow!),
          const SizedBox(height: 10),
        ],
        if (trailing == null)
          heading
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              trailing!,
            ],
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: align,
            style: NHText.body(size: 16.5, color: NHColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Vertical rhythm between the big blocks on the public pages, plus the
/// scroll reveal from PRD section 5.4.
class PageSection extends StatelessWidget {
  const PageSection({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
    this.reveal = true,
    this.index = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  /// Off for the hero, which plays its own entrance instead.
  final bool reveal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scale = context.bp.isMobile ? 0.68 : 1.0;
    final padded = Padding(
      padding: EdgeInsets.only(top: top * scale, bottom: bottom * scale),
      child: child,
    );
    return reveal ? RevealOnScroll(index: index, child: padded) : padded;
  }
}

/// A responsive grid that keeps a fixed number of columns per breakpoint, used
/// by the feature cards, plan cards and class grid.
class NHGrid extends StatelessWidget {
  const NHGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing = 16,
    this.childAspectRatio,
  });

  final List<Widget> children;

  /// Defaults to the breakpoint's column count.
  final int? columns;
  final double spacing;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? context.bp.gridColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width > 0 ? width : constraints.maxWidth,
                child: childAspectRatio == null
                    ? child
                    : AspectRatio(aspectRatio: childAspectRatio!, child: child),
              ),
          ],
        );
      },
    );
  }
}
