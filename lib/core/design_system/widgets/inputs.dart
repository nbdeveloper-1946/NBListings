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
    this.suffixIcon,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: CRMTypography.body.copyWith(color: CRMColors.text),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: CRMColors.textMuted,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
            ),
            filled: true,
            fillColor: CRMColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
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
