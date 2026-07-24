import 'package:flutter/material.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_shadows.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../design_system/widgets/buttons.dart';
import '../design_system/widgets/inputs.dart';

/// Legacy spacing aliases → CRMSpacing (compat shim).
class AppSpacing {
  static const double xs = CRMSpacing.xxs;
  static const double s = CRMSpacing.xs;
  static const double sm = CRMSpacing.s;
  static const double m = CRMSpacing.m;
  static const double ml = CRMSpacing.md;
  static const double l = CRMSpacing.l;
  static const double xl = CRMSpacing.xl;
  static const double xxl = CRMSpacing.xxl;
  static const double xxxl = CRMSpacing.xxxl;
  static const double max = CRMSpacing.max;
}

/// Legacy color aliases → CRMColors (compat shim). Prefer CRMColors directly.
class AppColors {
  static Color get brandGreen => CRMColors.primary;
  static Color get brandGreenHighlight => CRMColors.primaryHover;
  static Color get darkBg =>
      CRMColors.isDark ? const Color(0xFF0B0B0D) : const Color(0xFF0B0B0D);
  static Color get darkSlate => CRMColors.surface;
  static Color get textLight => Colors.white;
  static Color get textMuted => CRMColors.textMuted;
  static Color get textDark => CRMColors.text;
  static Color get borderLight => CRMColors.divider;
  static Color get inputBorder => CRMColors.border;
  static Color get cardBg => CRMColors.surfaceElevated;
  static Color get inputBg => CRMColors.groupedBackground;
  static Color get success => CRMColors.success;
  static Color get warning => CRMColors.warning;
  static Color get error => CRMColors.danger;
}

class AppBorderRadius {
  static const double card = CRMBorderRadius.r24;
  static const double button = CRMBorderRadius.r28;
  static const double input = CRMBorderRadius.l;
  static const double tag = CRMBorderRadius.r20;
}

class AppShadows {
  static List<BoxShadow> get premiumCard => CRMShadows.medium;
  static List<BoxShadow> get premiumButton => [
        BoxShadow(
          color: CRMColors.primary.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTextStyles {
  static TextStyle get display => CRMTypography.largeDisplay;
  static TextStyle get headline => CRMTypography.pageTitle;
  static TextStyle get title => CRMTypography.sectionTitle;
  static TextStyle get body => CRMTypography.body;
  static TextStyle get caption => CRMTypography.caption;
}

/// @Deprecated — prefer [CRMButton]. Compat shim for auth screens.
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return CRMButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: 52,
      variant: CRMButtonVariant.primary,
    );
  }
}

/// @Deprecated — prefer [CRMTextField]. Compat shim for auth screens.
class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CRMTextField(
      controller: controller,
      labelText: labelText,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      obscureText: obscureText,
      suffixIcon: suffixIcon,
      validator: validator,
    );
  }
}
