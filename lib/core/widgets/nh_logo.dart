import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../motion.dart';

/// PRD section 5.3: text "N**H**" (H in red) + barbell icon + "FITNESS",
/// italic display font. The barbell floats up and down 6 px on a 2.6 s loop
/// (PRD section 5.4).
///
/// Replace this widget's innards with the real logo file when the gym provides
/// one — nothing else references the mark directly.
class NHLogo extends StatelessWidget {
  const NHLogo({super.key, this.size = 26, this.showWordmark = true});

  final double size;

  /// On narrow mobile headers only "NH" plus the barbell is shown.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NH Fitness',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'N', style: NHText.display(size: size)),
                  TextSpan(
                    text: 'H',
                    style: NHText.display(size: size, color: NHColors.red),
                  ),
                ],
              ),
            ),
            SizedBox(width: size * 0.18),
            Floating(
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(
                  Icons.fitness_center_outlined,
                  size: size * 0.78,
                  color: NHColors.text,
                ),
              ),
            ),
            if (showWordmark) ...[
              SizedBox(width: size * 0.18),
              Text('FITNESS', style: NHText.display(size: size * 0.74)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The footer mark: the logo with the motto underneath.
class NHLogoBlock extends StatelessWidget {
  const NHLogoBlock({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NHLogo(size: size),
        const SizedBox(height: 10),
        Text(
          'BE FIT. BE STRONG. BE YOU.',
          style: NHText.label(size: 12, color: NHColors.muted),
        ),
      ],
    );
  }
}
