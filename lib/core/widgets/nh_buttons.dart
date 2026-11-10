import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../motion.dart';

/// PRD section 5.3: "red fill, white text, 56 px tall, radius 14–16, uppercase
/// display font. Arrow icon slides right 5 px on hover."
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.showIcon = true,
    this.expand = true,
    this.loading = false,
    this.color = NHColors.red,
    this.pressedColor = NHColors.redDark,
    this.height = NHSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool showIcon;

  /// Fills the available width on mobile; hugs its label on web.
  final bool expand;
  final bool loading;
  final Color color;
  final Color pressedColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return HoverRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      builder: (context, hovered) {
        return Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Material(
                color: hovered ? pressedColor : color,
                borderRadius: BorderRadius.circular(NHSizes.buttonRadius),
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  borderRadius: BorderRadius.circular(NHSizes.buttonRadius),
                  child: Container(
                    height: height,
                    width: expand ? double.infinity : null,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          Flexible(
                            child: Text(
                              label.toUpperCase(),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: NHText.button(),
                            ),
                          ),
                          if (showIcon) ...[
                            const SizedBox(width: 10),
                            // The 5 px slide on hover (PRD section 5.3).
                            AnimatedSlide(
                              offset: hovered ? const Offset(0.28, 0) : Offset.zero,
                              duration: NHMotion.hover,
                              curve: NHMotion.curve,
                              child: Icon(icon, size: 18, color: Colors.white),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// PRD section 5.3: "transparent, 2 px `text` border; on hover border and text
/// turn yellow."
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.expand = false,
    this.loading = false,
    this.height = NHSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// For leading content an icon cannot express, such as the Google mark.
  final Widget? leading;
  final bool expand;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return HoverRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      builder: (context, hovered) {
        final accent = hovered ? NHColors.yellow : NHColors.text;
        return Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(NHSizes.buttonRadius),
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  borderRadius: BorderRadius.circular(NHSizes.buttonRadius),
                  child: AnimatedContainer(
                    duration: NHMotion.hover,
                    height: height,
                    width: expand ? double.infinity : null,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(NHSizes.buttonRadius),
                      border: Border.all(color: accent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: accent,
                            ),
                          )
                        else ...[
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 10),
                          ] else if (icon != null) ...[
                            Icon(icon, size: 18, color: accent),
                            const SizedBox(width: 9),
                          ],
                          Flexible(
                            child: Text(
                              label.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: NHText.button(color: accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// PRD section 5.3: "44×44 square, radius 12, `surface` fill."
class BackSquareButton extends StatelessWidget {
  const BackSquareButton({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: NHColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: NHSizes.minTouchTarget,
            height: NHSizes.minTouchTarget,
            child: Semantics(
              button: true,
              label: tooltip,
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text-only action, for "Forgot password?" and the "View all" links.
class NHTextLink extends StatelessWidget {
  const NHTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = NHColors.red,
    this.size = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) {
        return Semantics(
          button: true,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                // Keeps the tappable area at 44 px tall without making the
                // link look oversized (PRD section 5.3).
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Text(
                  label,
                  style: NHText.body(
                    size: size,
                    weight: FontWeight.w600,
                    color: hovered ? NHColors.yellow : color,
                  ).copyWith(
                    decoration: hovered ? TextDecoration.underline : null,
                    decorationColor: NHColors.yellow,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The destructive action in the admin panel (Reject). Uses `danger`, which
/// PRD section 5.1 reserves for rejection and errors.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: expand,
      showIcon: false,
      color: NHColors.danger,
      pressedColor: const Color(0xFFD94A4F),
      height: 48,
    );
  }
}

/// A compact neutral action for admin table rows.
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = NHColors.red,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon ?? Icons.arrow_forward,
      showIcon: icon != null,
      expand: false,
      color: color,
      height: 44,
    );
  }
}
