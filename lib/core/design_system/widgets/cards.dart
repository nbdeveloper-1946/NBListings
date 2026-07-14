import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_shadows.dart';

class CRMCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const CRMCard({
    super.key,
    this.title,
    this.subtitle,
    this.headerAction,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.border, width: 1),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null || headerAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: CRMSpacing.m,
                right: CRMSpacing.m,
                top: CRMSpacing.m,
                bottom: CRMSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: CRMTypography.cardTitle.copyWith(color: CRMColors.text),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            subtitle!,
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerAction != null) headerAction!,
                ],
              ),
            ),
            const Divider(color: CRMColors.border, height: 1),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
          if (footer != null) ...[
            const Divider(color: CRMColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.s,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class CRMKPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double? growthPercent;
  final String? lastUpdated;

  const CRMKPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = CRMColors.primary,
    this.growthPercent,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final showGrowth = growthPercent != null;
    final isPositive = (growthPercent ?? 0.0) >= 0;

    return CRMCard(
      padding: const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(CRMSpacing.xxs),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Text(
            value,
            style: CRMTypography.display.copyWith(color: CRMColors.text),
          ),
          if (showGrowth || lastUpdated != null) ...[
            const SizedBox(height: CRMSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showGrowth)
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: isPositive ? CRMColors.success : CRMColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${isPositive ? "+" : ""}${growthPercent!.toStringAsFixed(1)}%',
                        style: CRMTypography.captionBold.copyWith(
                          color: isPositive ? CRMColors.success : CRMColors.danger,
                        ),
                      ),
                    ],
                  ),
                if (lastUpdated != null)
                  Text(
                    lastUpdated!,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
