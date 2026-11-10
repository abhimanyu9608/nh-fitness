import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/section.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';

/// `/checkout/submitted` — PRD section 7.4.
///
/// PRD section 5.4 (Success): "Red circle pops in, tick draws, confetti (red,
/// yellow, white) for 3 s."
class SubmittedScreen extends ConsumerStatefulWidget {
  const SubmittedScreen({super.key});

  @override
  ConsumerState<SubmittedScreen> createState() => _SubmittedScreenState();
}

class _SubmittedScreenState extends ConsumerState<SubmittedScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    // `reduceMotion` needs a BuildContext with MediaQuery, so the decision
    // waits for the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.reduceMotion) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider).value;
    final approvalTime = settings?.approvalTimeText ??
        'within a few hours during gym timings';

    return NHScaffold(
      showFooter: false,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            ContentWidth(
              maxWidth: 620,
              padVertical: const EdgeInsets.symmetric(vertical: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SuccessTick(),
                  const SizedBox(height: 30),
                  FadeUp(
                    index: 2,
                    child: SectionTitle(
                      title: l.submittedTitle,
                      align: TextAlign.center,
                      subtitle: l.submittedBody(approvalTime),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeUp(
                    index: 3,
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: l.submittedGoToAccount,
                          expand: false,
                          onPressed: () => context.go(Routes.account),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          label: l.actionBackToHome,
                          onPressed: () => context.go(Routes.home),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Falls from the top of the page, over the content.
            IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 14,
                maxBlastForce: 18,
                minBlastForce: 6,
                gravity: 0.22,
                shouldLoop: false,
                colors: const [NHColors.red, NHColors.yellow, Colors.white],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The red circle that pops in with a tick drawing itself inside.
class SuccessTick extends StatelessWidget {
  const SuccessTick({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: NHColors.red, shape: BoxShape.circle),
      child: _DrawnTick(size: size),
    );

    if (context.reduceMotion) return circle;

    return circle.animate().scaleXY(
      begin: 0.4,
      end: 1,
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
    );
  }
}

class _DrawnTick extends StatelessWidget {
  const _DrawnTick({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return CustomPaint(painter: _TickPainter(progress: 1), size: Size.square(size));
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Starts after the circle has popped, so the tick reads as a second beat.
      duration: const Duration(milliseconds: 420),
      curve: NHMotion.curve,
      builder: (context, progress, _) => CustomPaint(
        painter: _TickPainter(progress: progress),
        size: Size.square(size),
      ),
    );
  }
}

/// Strokes the tick a fraction at a time, using path metrics to find the
/// partial path.
class _TickPainter extends CustomPainter {
  const _TickPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.29, w * 0.52)
      ..lineTo(w * 0.44, w * 0.67)
      ..lineTo(w * 0.72, w * 0.37);

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.progress != progress;
}
