import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';

/// Consistent floating snackbars using CRM tokens.
class CRMSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = CRMMotion.slow,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: CRMTypography.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ??
            (CRMColors.isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E)),
        behavior: SnackBarBehavior.floating,
        duration: duration == CRMMotion.slow
            ? const Duration(seconds: 3)
            : duration,
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message) => show(
        context,
        message: message,
        backgroundColor: CRMColors.success,
        icon: Icons.check_circle_rounded,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        backgroundColor: CRMColors.danger,
        icon: Icons.error_outline_rounded,
      );

  static void info(BuildContext context, String message) => show(
        context,
        message: message,
        backgroundColor: CRMColors.information,
        icon: Icons.info_outline_rounded,
      );
}
