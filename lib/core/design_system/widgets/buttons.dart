import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum CRMButtonVariant { primary, secondary, outline, danger }

class CRMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CRMButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;

  const CRMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CRMButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case CRMButtonVariant.primary:
        bgColor = CRMColors.primary;
        fgColor = Colors.white;
        break;
      case CRMButtonVariant.secondary:
        bgColor = CRMColors.border;
        fgColor = CRMColors.text;
        break;
      case CRMButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = CRMColors.textSecondary;
        borderSide = BorderSide(color: CRMColors.border, width: 1.5);
        break;
      case CRMButtonVariant.danger:
        bgColor = CRMColors.danger;
        fgColor = Colors.white;
        break;
    }

    if (onPressed == null) {
      bgColor = bgColor.withOpacity(0.5);
      fgColor = fgColor.withOpacity(0.6);
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: CRMSpacing.xs),
        ] else if (prefixIcon != null) ...[
          Icon(prefixIcon, size: 18, color: fgColor),
          const SizedBox(width: CRMSpacing.xs),
        ],
        Text(
          label,
          style: CRMTypography.button.copyWith(color: fgColor),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: 44,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: borderSide,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          ),
        ),
        child: content,
      ),
    );
  }
}
