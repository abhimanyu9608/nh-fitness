import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens from PRD section 5.1. Dark theme only.
abstract final class NHColors {
  static const bg = Color(0xFF0D0A0B);
  static const surface = Color(0xFF1A1516);
  static const surface2 = Color(0xFF221B1C);
  static const line = Color(0xFF33292B);
  static const red = Color(0xFFDC1F2E);
  static const redDark = Color(0xFFB81624);
  static const redDeep = Color(0xFF7A111A);
  static const selectedBg = Color(0xFF3A0F14);
  static const text = Color(0xFFF5F1F1);
  static const muted = Color(0xFFC9BEC0);
  static const yellow = Color(0xFFFFD429);
  static const ink = Color(0xFF1A1516);

  /// Approved status only (PRD section 5.1).
  static const success = Color(0xFF2FBF71);

  /// Rejected status and errors only (PRD section 5.1).
  static const danger = Color(0xFFFF5A5F);
}

/// Shape and spacing constants used across the design system.
abstract final class NHSizes {
  static const buttonHeight = 56.0;
  static const buttonRadius = 15.0;
  static const cardRadius = 17.0;
  static const inputRadius = 14.0;
  static const minTouchTarget = 44.0;

  /// Desktop content width (PRD section 5.5).
  static const maxContentWidth = 1200.0;

  static const gutterMobile = 20.0;
  static const gutterTablet = 32.0;
  static const gutterDesktop = 40.0;
}

/// Text styles from PRD section 5.2.
///
/// Display is Barlow Condensed, italic, 800, uppercase, tight line height.
/// Body is Barlow. Labels are Barlow 600, uppercase, wide letter spacing.
abstract final class NHText {
  static TextStyle display({
    required double size,
    Color color = NHColors.text,
    double height = 0.93,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      fontStyle: FontStyle.italic,
      height: height,
      color: color,
      letterSpacing: 0.5,
    );
  }

  /// Buttons use weight 700 and are not italic (PRD section 5.2).
  static TextStyle button({double size = 17, Color color = Colors.white}) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: color,
      letterSpacing: 1.1,
    );
  }

  static TextStyle body({
    double size = 16,
    Color color = NHColors.text,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
  }) {
    return GoogleFonts.barlow(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle label({
    double size = 12,
    Color color = NHColors.muted,
    double letterSpacing = 2.4,
  }) {
    return GoogleFonts.barlow(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Money uses tabular figures so totals do not jiggle while animating
  /// (PRD section 5.2).
  static TextStyle money({
    double size = 54,
    Color color = NHColors.text,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      fontStyle: FontStyle.italic,
      height: 0.95,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle moneyBody({
    double size = 16,
    Color color = NHColors.text,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.barlow(
      fontSize: size,
      fontWeight: weight,
      height: 1.3,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

ThemeData buildNHTheme() {
  const scheme = ColorScheme.dark(
    primary: NHColors.red,
    onPrimary: Colors.white,
    secondary: NHColors.yellow,
    onSecondary: NHColors.ink,
    surface: NHColors.surface,
    onSurface: NHColors.text,
    error: NHColors.danger,
    onError: Colors.white,
    outline: NHColors.line,
    surfaceContainerHighest: NHColors.surface2,
  );

  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: NHColors.bg,
    canvasColor: NHColors.bg,
    dividerColor: NHColors.line,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.barlow().fontFamily,
      bodyColor: NHColors.text,
      displayColor: NHColors.text,
    ),
    // Yellow focus ring for keyboard users on web (PRD section 13).
    focusColor: NHColors.yellow,
    dividerTheme: const DividerThemeData(color: NHColors.line, thickness: 1),
    iconTheme: const IconThemeData(color: NHColors.text, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: NHColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: NHText.display(size: 24),
      iconTheme: const IconThemeData(color: NHColors.text),
    ),
    cardTheme: CardThemeData(
      color: NHColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NHSizes.cardRadius),
        side: const BorderSide(color: NHColors.line, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NHColors.surface2,
      contentTextStyle: NHText.body(size: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NHColors.line, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: NHColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NHSizes.cardRadius),
        side: const BorderSide(color: NHColors.line, width: 2),
      ),
      titleTextStyle: NHText.display(size: 26),
      contentTextStyle: NHText.body(color: NHColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: NHColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: NHColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: NHText.body(color: NHColors.muted.withValues(alpha: 0.7)),
      labelStyle: NHText.body(size: 15, color: NHColors.muted),
      floatingLabelStyle: NHText.body(size: 14, color: NHColors.muted),
      helperStyle: NHText.body(size: 13, color: NHColors.muted),
      helperMaxLines: 3,
      errorStyle: NHText.body(size: 13, color: NHColors.danger),
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NHSizes.inputRadius),
        borderSide: const BorderSide(color: NHColors.line, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NHSizes.inputRadius),
        borderSide: const BorderSide(color: NHColors.line, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NHSizes.inputRadius),
        borderSide: const BorderSide(color: NHColors.red, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NHSizes.inputRadius),
        borderSide: const BorderSide(color: NHColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NHSizes.inputRadius),
        borderSide: const BorderSide(color: NHColors.danger, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : NHColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? NHColors.red : NHColors.surface2,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(NHColors.line),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? NHColors.red : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: NHColors.muted, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NHColors.red,
      linearTrackColor: NHColors.line,
      circularTrackColor: Colors.transparent,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: NHColors.red,
      selectionColor: NHColors.redDeep,
      selectionHandleColor: NHColors.red,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: NHColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NHColors.line, width: 1),
      ),
      textStyle: NHText.body(size: 13),
    ),
  );
}
