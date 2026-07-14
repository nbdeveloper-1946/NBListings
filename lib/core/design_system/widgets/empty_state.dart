import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const CRMEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.folder_open_rounded,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: CRMColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: CRMColors.border, width: 1.5),
              ),
              child: Icon(
                icon,
                color: CRMColors.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            Text(
              title,
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                description,
                style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: CRMSpacing.l),
              CRMButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                variant: CRMButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
