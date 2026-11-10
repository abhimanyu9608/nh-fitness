import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../motion.dart';
import '../responsive.dart';

/// PRD section 5.3: "Pending = yellow outline; Approved/Active = green;
/// Rejected/Expired = red."
enum PillKind { pending, success, danger, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.kind});

  final String label;
  final PillKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      PillKind.pending => NHColors.yellow,
      PillKind.success => NHColors.success,
      PillKind.danger => NHColors.danger,
      PillKind.neutral => NHColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Text(
        label.toUpperCase(),
        style: NHText.label(size: 11, color: color, letterSpacing: 1.4),
      ),
    );
  }
}

/// The yellow offer tag: "Best value", "Coming soon", "7 days PT free"
/// (PRD section 5.1 — yellow is reserved for offers).
class YellowTag extends StatelessWidget {
  const YellowTag({
    super.key,
    required this.label,
    this.blink = false,
    this.icon,
  });

  final String label;

  /// PRD section 5.4: the "Coming soon" tag blinks on mobile.
  final bool blink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: NHColors.yellow,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: NHColors.ink),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: NHText.label(size: 11, color: NHColors.ink, letterSpacing: 1.3),
          ),
        ],
      ),
    );

    if (!blink || context.reduceMotion) return tag;
    return tag
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: const Duration(milliseconds: 900), begin: 0.45);
  }
}

/// PRD section 5.3: "2 px dashed yellow border, '7 days personal training
/// FREE'."
class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.redeem_outlined, size: 20, color: NHColors.yellow),
            const SizedBox(width: 11),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: NHText.body(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: NHColors.yellow,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: NHText.body(size: 13, color: NHColors.muted, height: 1.3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the dashed yellow outline for [OfferBadge]. Flutter has no dashed
/// border, so it is painted by hand.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NHColors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(12),
        ),
      );

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

/// PRD section 5.4: a live dot that blinks next to "Online".
class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.color = NHColors.success, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (context.reduceMotion) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: const Duration(milliseconds: 800), begin: 0.25);
  }
}

/// The "Coming soon" diagonal tape on the Supplements and Clothes cards
/// (PRD section 5.3). Sways gently (PRD section 5.4).
class ComingSoonTape extends StatelessWidget {
  const ComingSoonTape({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tape = Transform.rotate(
      angle: -0.36,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 7),
        color: NHColors.yellow,
        child: Text(
          label.toUpperCase(),
          style: NHText.label(size: 12, color: NHColors.ink, letterSpacing: 2),
        ),
      ),
    );

    if (context.reduceMotion) return tape;
    return tape
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .rotate(begin: -0.012, end: 0.012, duration: const Duration(seconds: 3), curve: Curves.easeInOut);
  }
}

/// A small uppercase label above a section title (PRD section 5.2).
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel({super.key, required this.text, this.color = NHColors.red});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: NHText.label(size: 12.5, color: color));
  }
}

/// Reusable red/yellow progress bar, used by the membership card and the free
/// PT days card.
class NHProgressBar extends StatelessWidget {
  const NHProgressBar({
    super.key,
    required this.value,
    this.color = NHColors.red,
    this.height = 8,
    this.semanticsLabel,
  });

  final double value;
  final Color color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: context.reduceMotion ? Duration.zero : NHMotion.entrance,
          curve: NHMotion.curve,
          builder: (context, animated, _) => LinearProgressIndicator(
            value: animated,
            minHeight: height,
            backgroundColor: NHColors.line,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    );
  }
}
