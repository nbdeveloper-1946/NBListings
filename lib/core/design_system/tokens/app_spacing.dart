/// Spacing scale (4–64). Prefer these over ad-hoc literals.
class CRMSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double md = 20.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;
  static const double max = 64.0;
}

/// Corner radius tokens. Existing names preserved; numeric aliases added.
class CRMBorderRadius {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  /// Legacy alias — historically 24; keep for compatibility.
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double round = 999.0;

  // Numeric scale aliases from the design brief
  static const double r4 = xs;
  static const double r8 = s;
  static const double r12 = m;
  static const double r16 = l;
  static const double r20 = 20.0;
  static const double r24 = xl;
  static const double r28 = xxl;
  static const double r32 = xxxl;
  static const double r40 = huge;
}
