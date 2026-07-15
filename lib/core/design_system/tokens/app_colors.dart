import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

class CRMColors {
  static bool get isDark => ThemeManager().isDarkMode;

  // Medium Light palette (warm cream/slate, brand green accents)
  static Color get background => isDark ? const Color(0xFF090D16) : const Color(0xFFF5F4EE);
  static Color get cardBg => isDark ? const Color(0xFF131A26) : const Color(0xFFFFFFFF);
  static Color get sidebarBg => isDark ? const Color(0xFF0E131F) : const Color(0xFFEDEBE2);
  
  static Color get primary => isDark ? const Color(0xFF5CA380) : const Color(0xFF688A75); // Brand green
  static Color get primaryHover => isDark ? const Color(0xFF4A8465) : const Color(0xFF53705E);
  static Color get border => isDark ? const Color(0xFF262E3B) : const Color(0xFFE4E2D8);
  
  static Color get text => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF2E3331);
  static Color get textSecondary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5A605D);
  static Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF8C928F);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF6366F1);

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
