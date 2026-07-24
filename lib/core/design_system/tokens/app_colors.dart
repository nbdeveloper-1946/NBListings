import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// Apple-inspired CRM color tokens. Brand green is preserved as primary.
class CRMColors {
  static bool get isDark => ThemeManager().isDarkMode;

  // --- Surfaces (cooler Apple-style grouped backgrounds) ---
  static Color get background =>
      isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF2F2F7);
  static Color get groupedBackground =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
  static Color get surface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
  static Color get cardBg => surfaceElevated;
  static Color get sidebarBg =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9FB);
  static Color get glassSurface => isDark
      ? const Color(0xCC1C1C1E)
      : const Color(0xCCF9F9FB);

  // --- Brand ---
  static Color get primary =>
      isDark ? const Color(0xFF5CA380) : const Color(0xFF688A75);
  static Color get primaryHover =>
      isDark ? const Color(0xFF4A8465) : const Color(0xFF53705E);
  static Color get secondary =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
  static Color get accent =>
      isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF);

  // --- Borders / dividers ---
  static Color get border =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);
  static Color get divider =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  // --- Text ---
  static Color get text =>
      isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E);
  static Color get textSecondary =>
      isDark ? const Color(0xFFAEAEB2) : const Color(0xFF636366);
  static Color get textMuted =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

  // --- Semantic ---
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF3B30);
  static const Color information = Color(0xFF007AFF);
  static const Color info = information;

  static Color get disabled =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC);

  static Color get overlay =>
      isDark ? const Color(0x99000000) : const Color(0x66000000);

  static Color get shadow =>
      isDark ? const Color(0x66000000) : const Color(0x1A000000);

  // --- Chart palette (accessible, mode-aware) ---
  static List<Color> get chartColors => isDark
      ? const [
          Color(0xFF5CA380),
          Color(0xFF64D2FF),
          Color(0xFFFF9F0A),
          Color(0xFFFF453A),
          Color(0xFFBF5AF2),
          Color(0xFF30D158),
          Color(0xFFFFD60A),
          Color(0xFFAC8E68),
        ]
      : const [
          Color(0xFF688A75),
          Color(0xFF007AFF),
          Color(0xFFFF9F0A),
          Color(0xFFFF3B30),
          Color(0xFFAF52DE),
          Color(0xFF34C759),
          Color(0xFFFFCC00),
          Color(0xFFA2845E),
        ];

  static List<Color> get graphColors => chartColors;

  // Backward compatibility with BuildContext lookups
  static Color backgroundOf(BuildContext context) => background;
  static Color cardBgOf(BuildContext context) => cardBg;
  static Color sidebarBgOf(BuildContext context) => sidebarBg;
  static Color primaryOf(BuildContext context) => primary;
  static Color primaryHoverOf(BuildContext context) => primaryHover;
  static Color borderOf(BuildContext context) => border;
  static Color textOf(BuildContext context) => text;
  static Color textSecondaryOf(BuildContext context) => textSecondary;
  static Color textMutedOf(BuildContext context) => textMuted;
}
