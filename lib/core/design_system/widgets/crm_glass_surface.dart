import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// Translucent glass surface for chrome (nav, search, floating panels).
class CRMGlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableBlur;

  const CRMGlassSurface({
    super.key,
    required this.child,
    this.blur = CRMBlur.navigation,
    this.borderRadius,
    this.padding,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(CRMBorderRadius.m);
    final decoration = BoxDecoration(
      color: CRMColors.glassSurface,
      borderRadius: radius,
      border: Border.all(color: CRMColors.border.withOpacity(0.35), width: 0.5),
      boxShadow: CRMShadows.glass,
    );

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (!enableBlur) return content;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
