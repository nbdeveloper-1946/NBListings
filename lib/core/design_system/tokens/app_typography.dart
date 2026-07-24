import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Apple-inspired type scale.
/// SF Pro / system UI font on Apple platforms; bundled Inter elsewhere.
class CRMTypography {
  static const String interFamily = 'Inter';

  /// Resolved font family. Null on Apple = system SF Pro.
  static String? get fontFamily {
    if (kIsWeb) return interFamily;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return null;
      default:
        return interFamily;
    }
  }

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.35,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: const [interFamily, 'Segoe UI', 'Roboto', 'Arial'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get largeDisplay => _base(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        height: 1.15,
        letterSpacing: -1.0,
      );

  static TextStyle get largeTitle => _base(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        height: 1.18,
        letterSpacing: -0.8,
      );

  static TextStyle get display => _base(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.8,
      );

  static TextStyle get title => _base(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.6,
      );

  static TextStyle get pageTitle => _base(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get navigationTitle => _base(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get headline => _base(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionTitle => _base(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionHeader => _base(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.1,
      );

  static TextStyle get cardTitle => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get body => _base(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.45,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get subheadline => _base(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get caption => _base(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get captionBold => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get footnote => _base(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.35,
      );

  static TextStyle get label => _base(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get button => _base(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get statistics => _base(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.15,
        letterSpacing: -0.6,
      );

  static TextStyle get chartLabels => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get tableHeaders => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
      );

  /// Material [TextTheme] mapped from CRM tokens.
  static TextTheme get textTheme => TextTheme(
        displayLarge: largeDisplay,
        displayMedium: largeTitle,
        displaySmall: display,
        headlineLarge: title,
        headlineMedium: pageTitle,
        headlineSmall: sectionTitle,
        titleLarge: cardTitle,
        titleMedium: headline,
        titleSmall: sectionHeader,
        bodyLarge: body,
        bodyMedium: bodyMedium,
        bodySmall: footnote,
        labelLarge: button,
        labelMedium: label,
        labelSmall: caption,
      );
}
