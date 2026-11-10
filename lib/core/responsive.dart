import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Breakpoints from PRD section 5.5. The same screens and features exist at
/// every size — only the layout changes.
enum NHBreakpoint { mobile, tablet, desktop }

extension NHBreakpointX on NHBreakpoint {
  bool get isMobile => this == NHBreakpoint.mobile;
  bool get isTablet => this == NHBreakpoint.tablet;
  bool get isDesktop => this == NHBreakpoint.desktop;

  /// The top nav, ticker band and side menus appear from tablet up.
  bool get isWide => this != NHBreakpoint.mobile;

  double get gutter => switch (this) {
    NHBreakpoint.mobile => NHSizes.gutterMobile,
    NHBreakpoint.tablet => NHSizes.gutterTablet,
    NHBreakpoint.desktop => NHSizes.gutterDesktop,
  };

  /// Columns for the "Why NH Fitness" / plan / class grids.
  int get gridColumns => switch (this) {
    NHBreakpoint.mobile => 2,
    NHBreakpoint.tablet => 2,
    NHBreakpoint.desktop => 4,
  };
}

NHBreakpoint breakpointForWidth(double width) {
  if (width < 600) return NHBreakpoint.mobile;
  if (width < 1024) return NHBreakpoint.tablet;
  return NHBreakpoint.desktop;
}

extension NHContextX on BuildContext {
  NHBreakpoint get bp => breakpointForWidth(MediaQuery.sizeOf(this).width);

  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// PRD section 5.4: with "reduce motion" on, skip every looping and entrance
  /// animation.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Centres page content and caps it at 1200 px on desktop (PRD section 5.5).
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = NHSizes.maxContentWidth,
    this.padHorizontal = true,
    this.padVertical = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final bool padHorizontal;
  final EdgeInsets padVertical;

  @override
  Widget build(BuildContext context) {
    final gutter = context.bp.gutter;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padHorizontal ? gutter : 0)
              .add(padVertical),
          child: child,
        ),
      ),
    );
  }
}

/// Picks one of three builders by breakpoint, so a screen can keep its mobile
/// and desktop layouts side by side.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) {
    return switch (context.bp) {
      NHBreakpoint.mobile => mobile(context),
      NHBreakpoint.tablet => (tablet ?? desktop)(context),
      NHBreakpoint.desktop => desktop(context),
    };
  }
}
