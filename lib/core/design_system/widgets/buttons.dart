import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum CRMButtonVariant { primary, secondary, outline, danger }

class CRMButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CRMButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CRMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CRMButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<CRMButton> createState() => _CRMButtonState();
}

class _CRMButtonState extends State<CRMButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case CRMButtonVariant.primary:
        bgColor = CRMColors.primary;
        fgColor = Colors.white;
        break;
      case CRMButtonVariant.secondary:
        bgColor = CRMColors.groupedBackground;
        fgColor = CRMColors.text;
        break;
      case CRMButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = CRMColors.textSecondary;
        borderSide = BorderSide(color: CRMColors.border, width: 1);
        break;
      case CRMButtonVariant.danger:
        bgColor = CRMColors.danger;
        fgColor = Colors.white;
        break;
    }

    final enabled = widget.onPressed != null && !widget.isLoading;
    if (!enabled) {
      bgColor = bgColor.withOpacity(0.45);
      fgColor = fgColor.withOpacity(0.55);
    }

    final height = widget.height ?? 44.0;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: CRMSpacing.xs),
        ] else if (widget.prefixIcon != null) ...[
          Icon(
            widget.prefixIcon,
            size: height < 36 ? 14 : 18,
            color: fgColor,
          ),
          const SizedBox(width: CRMSpacing.xs),
        ],
        Text(
          widget.label,
          style: CRMTypography.button.copyWith(
            color: fgColor,
            fontSize: height < 36 ? 12 : 15,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1.0,
      duration: CRMMotion.fast,
      curve: CRMMotion.easeOut,
      child: SizedBox(
        width: widget.width,
        height: height,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: widget.label,
          child: OutlinedButton(
            onPressed: enabled ? widget.onPressed : null,
            onHover: (_) {},
            style: OutlinedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              side: borderSide,
              elevation: 0,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              ),
            ),
            child: Listener(
              onPointerDown: enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onPointerUp: enabled
                  ? (_) => setState(() => _pressed = false)
                  : null,
              onPointerCancel: enabled
                  ? (_) => setState(() => _pressed = false)
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
