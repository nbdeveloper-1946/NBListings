import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/design_system/crm_design_system.dart';

class MigrationCountdownWidget extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onOpenNow;
  final VoidCallback onStayHere;

  const MigrationCountdownWidget({
    super.key,
    required this.secondsRemaining,
    required this.onOpenNow,
    required this.onStayHere,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(CRMSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.025),
            borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.12),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opening PropKart in $secondsRemaining...',
                style: CRMTypography.bodyMedium.copyWith(
                  color: const Color(0xFFFFD700), // Gold
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              // Subtle gradient progress indicator
              SizedBox(
                width: double.infinity,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: secondsRemaining / 5.0,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m + 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      onPressed: onStayHere,
                      child: Text(
                        'Stay Here',
                        style: CRMTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF9500)], // gold gradient
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m + 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                          ),
                        ),
                        onPressed: onOpenNow,
                        child: Text(
                          'Open Now',
                          style: CRMTypography.bodyMedium.copyWith(
                            color: const Color(0xFF090909),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
