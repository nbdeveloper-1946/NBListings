import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register theme dependency to rebuild on toggle
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(CRMSpacing.l),
                decoration: BoxDecoration(
                  color: CRMColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 72,
                  color: CRMColors.primary,
                ),
              ),
              const SizedBox(height: CRMSpacing.l),
              Text(
                'Profile',
                style: CRMTypography.pageTitle.copyWith(
                  color: CRMColors.text,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CRMSpacing.s),
              Text(
                'Coming Soon',
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
