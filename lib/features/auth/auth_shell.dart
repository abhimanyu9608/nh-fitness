import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/section.dart';
import '../../l10n/app_localizations.dart';

/// The frame the three auth screens share: a narrow centred card under the
/// normal site header.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHScaffold(
      showFooter: false,
      children: [
        ContentWidth(
          maxWidth: 480,
          padVertical: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeUp(
                index: 0,
                child: SectionTitle(title: title, subtitle: subtitle),
              ),
              const SizedBox(height: 24),
              FadeUp(
                index: 1,
                child: NHCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 18),
                FadeUp(index: 2, child: footer!),
              ],
              const SizedBox(height: 20),
              // PRD section 7.5: "Small note on login: 'Phone OTP login coming
              // soon'."
              FadeUp(
                index: 3,
                child: Text(
                  l.authOtpSoon,
                  textAlign: TextAlign.center,
                  style: NHText.body(size: 13, color: NHColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "or" with a rule on each side, between the email form and the Google button.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              L.of(context).authOr.toUpperCase(),
              style: NHText.label(size: 11),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// The Google "G" badge for the sign-in button. Drawn rather than bundled, so
/// the repo ships no third-party brand asset.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(
        'G',
        style: NHText.body(
          size: size * 0.68,
          weight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
