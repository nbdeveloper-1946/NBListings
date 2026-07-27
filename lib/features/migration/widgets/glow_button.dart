import 'package:flutter/material.dart';
import '../../../../core/design_system/crm_design_system.dart';

class MigrationGlowButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const MigrationGlowButton({super.key, required this.label, required this.onPressed});

  @override
  State<MigrationGlowButton> createState() => _MigrationGlowButtonState();
}

class _MigrationGlowButtonState extends State<MigrationGlowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF9500)], // gold-orange premium gradient
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(_isHovered ? 0.55 : 0.35),
                blurRadius: _isHovered ? 26 : 16,
                spreadRadius: _isHovered ? 3 : 0,
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
                borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
              ),
            ),
            onPressed: widget.onPressed,
            child: Text(
              widget.label,
              style: CRMTypography.bodyMedium.copyWith(
                color: const Color(0xFF090909),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
