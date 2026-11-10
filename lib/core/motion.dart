import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'format.dart';
import 'responsive.dart';

/// Motion tokens from PRD section 5.4.
abstract final class NHMotion {
  /// Entrance curve for every screen load.
  static const curve = Cubic(0.2, 0.7, 0.2, 1);

  static const entrance = Duration(milliseconds: 650);
  static const stagger = Duration(milliseconds: 100);

  /// Gap between items revealing inside one grid or row.
  static const revealStagger = Duration(milliseconds: 80);

  /// Cross-fade when moving between routes.
  static const pageTransition = Duration(milliseconds: 320);

  /// Logo barbell float.
  static const float = Duration(milliseconds: 2600);

  /// Pulse ring around the main call to action.
  static const pulse = Duration(milliseconds: 1800);

  /// Hero Ken Burns zoom.
  static const kenBurns = Duration(seconds: 18);

  /// Checkout total count up/down.
  static const countUp = Duration(milliseconds: 450);

  static const hover = Duration(milliseconds: 220);
}

/// PRD section 5.4: "Content fades up 22–34 px, 650 ms, staggered 100 ms per
/// block" on every screen load.
///
/// `index` is the block's position in the stagger order.
class FadeUp extends StatelessWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 26,
    this.duration = NHMotion.entrance,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return child
        .animate()
        .fadeIn(
          duration: duration,
          delay: NHMotion.stagger * index,
          curve: NHMotion.curve,
        )
        .moveY(
          begin: offset,
          end: 0,
          duration: duration,
          delay: NHMotion.stagger * index,
          curve: NHMotion.curve,
        );
  }
}

/// Convenience for laying out a column of blocks that fade up one after the
/// other, without hand-numbering every index.
List<Widget> staggered(List<Widget> children, {int from = 0}) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeUp(index: from + i, child: children[i]),
  ];
}

/// PRD section 5.4: web sections reveal (fade up) as they scroll into view.
///
/// Reveals once and stays revealed. Falls back to showing the child straight
/// away when there is no scrollable ancestor or reduce-motion is on.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.offset = 30,
    this.index = 0,
  });

  final Widget child;
  final double offset;
  final int index;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll> {
  ScrollPosition? _position;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    if (_position == null || context.reduceMotion) {
      _revealed = true;
      return;
    }
    _position!.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    // Trigger a little before the block reaches the bottom edge so the motion
    // finishes while it is on screen.
    if (top >= MediaQuery.sizeOf(context).height * 0.92) return;

    _position?.removeListener(_check);

    // Items in a row arrive one after another rather than all at once, which
    // reads as deliberate instead of abrupt. Shorter than the entrance stagger
    // because a grid can hold four of them.
    final delay = NHMotion.revealStagger * widget.index;
    if (delay == Duration.zero) {
      setState(() => _revealed = true);
      return;
    }
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return AnimatedSlide(
      offset: _revealed ? Offset.zero : Offset(0, widget.offset / 100),
      duration: NHMotion.entrance,
      curve: NHMotion.curve,
      child: AnimatedOpacity(
        opacity: _revealed ? 1 : 0,
        duration: NHMotion.entrance,
        curve: NHMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// PRD section 5.4: the barbell floats up and down 6 px on a 2.6 s loop.
class Floating extends StatelessWidget {
  const Floating({super.key, required this.child, this.distance = 6});

  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -distance,
          duration: NHMotion.float,
          curve: Curves.easeInOut,
        );
  }
}

/// PRD section 5.4: a red pulse ring around the main CTA on a 1.8 s loop.
class PulseRing extends StatelessWidget {
  const PulseRing({
    super.key,
    required this.child,
    this.radius = 15,
    this.color = const Color(0xFFDC1F2E),
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return Stack(
      alignment: Alignment.center,
      children: [
        // The ring is decoration only; the button underneath owns the semantics.
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: color, width: 2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 1, end: 1.14, duration: NHMotion.pulse, curve: Curves.easeOut)
                  .fadeOut(duration: NHMotion.pulse, curve: Curves.easeOut),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// PRD section 5.4: hero background photo slow zoom (Ken Burns), 18 s,
/// alternating.
class KenBurns extends StatelessWidget {
  const KenBurns({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.12,
          duration: NHMotion.kenBurns,
          curve: Curves.easeInOut,
        );
  }
}

/// PRD section 5.4 (Checkout): "Total counts up/down to the new value in
/// 450 ms when plan or add-on changes."
class CountUpRupees extends StatelessWidget {
  const CountUpRupees({
    super.key,
    required this.amount,
    required this.style,
    this.textAlign,
  });

  final int amount;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final label = formatRupees(amount);
    if (context.reduceMotion) {
      return Text(label, style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: amount.toDouble()),
      duration: NHMotion.countUp,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          formatRupees(value.round()),
          style: style,
          textAlign: textAlign,
          // Screen readers announce the settled value, not every frame.
          semanticsLabel: label,
        );
      },
    );
  }
}

/// Tracks pointer hover so cards can lift and photos can zoom on web
/// (PRD section 5.4). Reports `false` forever when reduce-motion is on.
class HoverRegion extends StatefulWidget {
  const HoverRegion({super.key, required this.builder, this.cursor});

  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor? cursor;

  @override
  State<HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<HoverRegion> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor ?? SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered && !context.reduceMotion),
    );
  }
}
