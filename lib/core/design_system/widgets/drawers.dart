import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../../../../features/properties/models/property_model.dart';
import 'buttons.dart';

void showCRMPropertyDrawer(BuildContext context, PropertyModel property) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Property Details barrier',
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 480,
            height: double.infinity,
            decoration: BoxDecoration(
              color: CRMColors.cardBg,
              border: Border(left: BorderSide(color: CRMColors.border, width: 1.5)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.propertyCode,
                                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                              ),
                              Text(
                                property.title,
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: CRMColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: CRMColors.border, height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: CRMColors.background,
                              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                              border: Border.all(color: CRMColors.border),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: CRMColors.textMuted,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          _buildDetailRow('Listing Type', property.listingTypeName),
                          _buildDetailRow('Category', property.categoryName),
                          _buildDetailRow('Price', '₹${property.price.toStringAsFixed(0)}'),
                          if (property.deposit > 0)
                            _buildDetailRow('Deposit', '₹${property.deposit.toStringAsFixed(0)}'),
                          _buildDetailRow('Area Size', '${property.superBuiltupArea?.toStringAsFixed(0) ?? "N/A"} Sq.Ft'),
                          _buildDetailRow('Location', '${property.areaName}, ${property.cityName}'),
                          _buildDetailRow('Verification', property.isVerified ? 'Verified' : 'Pending Verification'),
                          _buildDetailRow('Status', property.statusDisplayName),
                          const SizedBox(height: CRMSpacing.m),
                          Divider(color: CRMColors.border),
                          const SizedBox(height: CRMSpacing.s),
                          Text('Owner Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
                          const SizedBox(height: CRMSpacing.xs),
                          _buildDetailRow('Name', property.ownerName),
                          _buildDetailRow('Mobile', property.ownerMobile),
                          const SizedBox(height: CRMSpacing.m),
                          Divider(color: CRMColors.border),
                          const SizedBox(height: CRMSpacing.s),
                          Text('Broker Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
                          const SizedBox(height: CRMSpacing.xs),
                          _buildDetailRow('Registered By', property.createdByName),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: CRMColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: CRMButton(
                            label: 'Close Detail',
                            variant: CRMButtonVariant.outline,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(anim1),
        child: child,
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
        ),
        Text(
          value,
          style: CRMTypography.body.copyWith(color: CRMColors.text, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
