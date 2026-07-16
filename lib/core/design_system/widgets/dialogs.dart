import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMDialogs {
  static Future<bool?> showUnsavedChangesDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(ctx),
        title: Text('Unsaved Changes', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx))),
        content: Text(
          'You have unsaved form details. Are you sure you want to discard your changes and leave?',
          style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
        ),
        actions: [
          TextButton(
            child: const Text('Stay / Keep Editing'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger),
            child: const Text('Discard / Exit', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccessDialog(BuildContext context, String message, {VoidCallback? onClose}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(ctx),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: CRMColors.success, size: 28),
            const SizedBox(width: CRMSpacing.s),
            Text('Success', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx))),
          ],
        ),
        content: Text(message, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx))),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onClose != null) onClose();
            },
          ),
        ],
      ),
    );
  }

  static Future<void> showErrorDialog(BuildContext context, String error) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(ctx),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 28),
            const SizedBox(width: CRMSpacing.s),
            Text('Error', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx))),
          ],
        ),
        content: Text(error, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx))),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteConfirmation(BuildContext context, {required String title, required String content}) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(ctx),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 28),
            const SizedBox(width: CRMSpacing.s),
            Text(title, style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx))),
          ],
        ),
        content: Text(content, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx))),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
