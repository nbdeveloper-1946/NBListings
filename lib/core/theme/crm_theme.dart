import 'package:flutter/material.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// Builds light/dark [ThemeData] from CRM design tokens.
class CRMTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Temporarily align ThemeManager so token getters resolve correctly
    // while building ColorScheme from the token layer.
    final background = isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF2F2F7);
    final surface = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final primary = isDark ? const Color(0xFF5CA380) : const Color(0xFF688A75);
    final onPrimary = Colors.white;
    final text = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final border = isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);
    final danger = CRMColors.danger;
    final success = CRMColors.success;
    final warning = CRMColors.warning;
    final info = CRMColors.information;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
      onSecondary: onPrimary,
      error: danger,
      onError: onPrimary,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      outline: border,
      outlineVariant: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      tertiary: info,
      onTertiary: onPrimary,
    );

    final textTheme = CRMTypography.textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: CRMTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surface.withOpacity(0.92),
        foregroundColor: text,
        titleTextStyle: CRMTypography.navigationTitle.copyWith(color: text),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          side: BorderSide(color: border.withOpacity(0.6), width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
        ),
        titleTextStyle: CRMTypography.sectionTitle.copyWith(color: text),
        contentTextStyle: CRMTypography.body.copyWith(color: muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CRMBorderRadius.r24),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: muted.withOpacity(0.4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.m,
          vertical: CRMSpacing.s,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          borderSide: BorderSide(color: border.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          borderSide: BorderSide(color: danger),
        ),
        hintStyle: CRMTypography.body.copyWith(color: muted),
        labelStyle: CRMTypography.label.copyWith(color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(44, 44),
          textStyle: CRMTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(44, 44),
          textStyle: CRMTypography.button,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: CRMTypography.button,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.l),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
        contentTextStyle: CRMTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        selectedColor: primary.withOpacity(0.18),
        labelStyle: CRMTypography.captionBold.copyWith(color: text),
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: border.withOpacity(0.7),
        thickness: 0.5,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border.withOpacity(0.4),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        textStyle: CRMTypography.caption.copyWith(color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withOpacity(0.92),
        indicatorColor: primary.withOpacity(0.15),
        labelTextStyle: WidgetStatePropertyAll(
          CRMTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: muted, size: 24);
        }),
      ),
      // Semantic extensions used by charts/status
      extensions: <ThemeExtension<dynamic>>[
        CRMSemanticColors(
          success: success,
          warning: warning,
          danger: danger,
          information: info,
        ),
      ],
    );
  }
}

@immutable
class CRMSemanticColors extends ThemeExtension<CRMSemanticColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color information;

  const CRMSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.information,
  });

  @override
  CRMSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? information,
  }) {
    return CRMSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      information: information ?? this.information,
    );
  }

  @override
  CRMSemanticColors lerp(ThemeExtension<CRMSemanticColors>? other, double t) {
    if (other is! CRMSemanticColors) return this;
    return CRMSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      information: Color.lerp(information, other.information, t)!,
    );
  }
}
