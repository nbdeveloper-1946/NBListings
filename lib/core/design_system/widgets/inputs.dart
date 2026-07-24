import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  const CRMTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixIcon,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CRMBorderRadius.s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: CRMTypography.label.copyWith(color: CRMColors.textSecondary),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          style: CRMTypography.body.copyWith(color: CRMColors.text),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: CRMColors.textMuted, size: 20)
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
            ),
            filled: true,
            fillColor: CRMColors.groupedBackground.withOpacity(
              CRMColors.isDark ? 0.55 : 0.65,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.border.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.danger, width: 1.5),
            ),
          ),
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
