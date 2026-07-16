import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMNoInternet extends StatelessWidget {
  final VoidCallback? onRetry;

  const CRMNoInternet({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: CRMColors.borderOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: CRMColors.textSecondaryOf(context),
                size: 36,
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            Text(
              'No Internet Connection',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'Please check your network settings and try connecting again.',
                style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: CRMSpacing.l),
              CRMButton(
                label: 'Try Again',
                onPressed: onRetry!,
                variant: CRMButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
