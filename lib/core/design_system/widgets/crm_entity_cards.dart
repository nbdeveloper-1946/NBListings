import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'crm_status_chips.dart';

/// Shared elevated surface for entity list cards.
class _CRMEntityCardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;

  const _CRMEntityCardShell({
    required this.child,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
    this.borderColor,
    this.borderWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CRMBorderRadius.m);
    final borderSideColor = borderColor ?? CRMColors.border.withValues(alpha: 0.55);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: CRMColors.surfaceElevated,
        borderRadius: radius,
        border: Border.all(color: borderSideColor, width: borderWidth),
        boxShadow: CRMShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// Reusable property list card with flexible slots for screen-specific content.
class CRMPropertyCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? status;
  final Widget? statusWidget;
  final String? priceText;
  final String? locationText;
  final Widget? leading;
  final Widget? trailing;
  final Widget? actions;
  final Widget? footer;
  final Widget? badges;
  final List<Widget>? metaRows;
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;

  const CRMPropertyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.status,
    this.statusWidget,
    this.priceText,
    this.locationText,
    this.leading,
    this.trailing,
    this.actions,
    this.footer,
    this.badges,
    this.metaRows,
    this.child,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
    this.borderColor,
    this.borderWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final body = child ?? _buildDefaultContent(context);

    if (footer != null || actions != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: CRMColors.surfaceElevated,
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          border: Border.all(
            color: borderColor ?? CRMColors.border.withValues(alpha: 0.55),
            width: borderWidth,
          ),
          boxShadow: CRMShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTap != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(padding: padding, child: body),
                ),
              )
            else
              Padding(padding: padding, child: body),
            if (actions != null) ...[
              Divider(color: CRMColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CRMSpacing.s,
                  vertical: CRMSpacing.xxs,
                ),
                child: actions!,
              ),
            ],
            if (footer != null) footer!,
          ],
        ),
      );
    }

    return _CRMEntityCardShell(
      margin: margin,
      padding: padding,
      onTap: onTap,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: body,
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null || trailing != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: CRMSpacing.s),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CRMTypography.cardTitle.copyWith(
                        color: CRMColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: CRMSpacing.xxs),
                      Text(
                        subtitle!,
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          )
        else ...[
          Text(
            title,
            style: CRMTypography.cardTitle.copyWith(
              color: CRMColors.text,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: CRMSpacing.xxs),
            Text(
              subtitle!,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
        if (badges != null) ...[
          const SizedBox(height: CRMSpacing.xs),
          badges!,
        ],
        if (status != null || statusWidget != null) ...[
          const SizedBox(height: CRMSpacing.xs),
          statusWidget ?? CRMStatusChip(status: status!),
        ],
        if (locationText != null || priceText != null) ...[
          const SizedBox(height: CRMSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locationText != null)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: CRMColors.textSecondary,
                      ),
                      const SizedBox(width: CRMSpacing.xxs),
                      Expanded(
                        child: Text(
                          locationText!,
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (priceText != null)
                Text(
                  priceText!,
                  style: CRMTypography.captionBold.copyWith(
                    color: CRMColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
        if (metaRows != null) ...[
          for (final row in metaRows!) ...[
            const SizedBox(height: CRMSpacing.xs),
            row,
          ],
        ],
      ],
    );
  }
}

/// Reusable requirement list card with client, budget, and status slots.
class CRMRequirementCard extends StatelessWidget {
  final String title;
  final String clientName;
  final String? clientSubtitle;
  final String? budgetText;
  final String? status;
  final Widget? statusWidget;
  final String? locationText;
  final Widget? leading;
  final Widget? trailing;
  final Widget? actions;
  final Widget? footer;
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const CRMRequirementCard({
    super.key,
    required this.title,
    required this.clientName,
    this.clientSubtitle,
    this.budgetText,
    this.status,
    this.statusWidget,
    this.locationText,
    this.leading,
    this.trailing,
    this.actions,
    this.footer,
    this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: CRMSpacing.m),
    this.padding = const EdgeInsets.all(CRMSpacing.m),
  });

  @override
  Widget build(BuildContext context) {
    if (child != null || footer != null || actions != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: CRMColors.surfaceElevated,
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          border: Border.all(color: CRMColors.border.withValues(alpha: 0.55), width: 0.5),
          boxShadow: CRMShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (child != null)
              child!
            else
              _RequirementCardHeader(
                title: title,
                clientName: clientName,
                clientSubtitle: clientSubtitle,
                budgetText: budgetText,
                status: status,
                statusWidget: statusWidget,
                locationText: locationText,
                leading: leading,
                trailing: trailing,
                onTap: onTap,
                padding: padding,
              ),
            if (footer != null) footer!,
            if (actions != null) ...[
              Divider(color: CRMColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CRMSpacing.s,
                  vertical: CRMSpacing.xxs,
                ),
                child: actions!,
              ),
            ],
          ],
        ),
      );
    }

    return _CRMEntityCardShell(
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: _RequirementCardHeader(
        title: title,
        clientName: clientName,
        clientSubtitle: clientSubtitle,
        budgetText: budgetText,
        status: status,
        statusWidget: statusWidget,
        locationText: locationText,
        leading: leading,
        trailing: trailing,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _RequirementCardHeader extends StatelessWidget {
  final String title;
  final String clientName;
  final String? clientSubtitle;
  final String? budgetText;
  final String? status;
  final Widget? statusWidget;
  final String? locationText;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const _RequirementCardHeader({
    required this.title,
    required this.clientName,
    this.clientSubtitle,
    this.budgetText,
    this.status,
    this.statusWidget,
    this.locationText,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
  });

  @override
  Widget build(BuildContext context) {
    Widget clientNameWidget = Text(
      clientName,
      style: CRMTypography.bodyMedium.copyWith(
        color: CRMColors.primary,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (onTap != null) {
      clientNameWidget = GestureDetector(
        onTap: onTap,
        child: clientNameWidget,
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: CRMSpacing.s),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                clientNameWidget,
                if (clientSubtitle != null) ...[
                  const SizedBox(height: CRMSpacing.xxs),
                  Text(
                    clientSubtitle!,
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: CRMSpacing.xxs),
                Text(
                  title,
                  style: CRMTypography.captionBold.copyWith(
                    color: CRMColors.primary,
                    fontSize: 11,
                  ),
                ),
                if (budgetText != null) ...[
                  const SizedBox(height: CRMSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.sell_outlined,
                        size: 14,
                        color: CRMColors.textSecondary,
                      ),
                      const SizedBox(width: CRMSpacing.xxs),
                      Expanded(
                        child: Text(
                          budgetText!,
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (locationText != null) ...[
                  const SizedBox(height: CRMSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: CRMColors.textSecondary,
                      ),
                      const SizedBox(width: CRMSpacing.xxs),
                      Expanded(
                        child: Text(
                          locationText!,
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (statusWidget != null)
            statusWidget!
          else if (status != null)
            CRMStatusChip(status: status!),
          if (trailing != null) ...[
            const SizedBox(width: CRMSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}
