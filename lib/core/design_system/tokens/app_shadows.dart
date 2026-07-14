import 'package:flutter/material.dart';

class CRMShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.01),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
