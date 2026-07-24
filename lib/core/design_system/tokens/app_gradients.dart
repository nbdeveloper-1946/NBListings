import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft gradient tokens for premium accents (use sparingly).
class CRMGradients {
  static LinearGradient get primarySoft => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          CRMColors.primary.withOpacity(0.18),
          CRMColors.primary.withOpacity(0.04),
        ],
      );

  static LinearGradient get surfaceSheen => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: CRMColors.isDark
            ? [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.0),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.4),
              ],
      );

  static LinearGradient get glass => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: CRMColors.isDark
            ? [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ]
            : [
                Colors.white.withOpacity(0.72),
                Colors.white.withOpacity(0.40),
              ],
      );

  static LinearGradient chartFade(Color color) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.85),
          color.withOpacity(0.15),
        ],
      );
}
