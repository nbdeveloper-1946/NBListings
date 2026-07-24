import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft, premium elevation shadows (mode-aware).
class CRMShadows {
  static double get _opacityBoost => CRMColors.isDark ? 1.6 : 1.0;

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04 * _opacityBoost),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02 * _opacityBoost),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06 * _opacityBoost),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03 * _opacityBoost),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08 * _opacityBoost),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04 * _opacityBoost),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10 * _opacityBoost),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04 * _opacityBoost),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05 * _opacityBoost),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get modal => [
        BoxShadow(
          color: Colors.black.withOpacity(0.14 * _opacityBoost),
          blurRadius: 48,
          offset: const Offset(0, 24),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06 * _opacityBoost),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
