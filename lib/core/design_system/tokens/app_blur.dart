import 'dart:ui';

/// Selective backdrop blur radii for chrome (nav, sheets, dialogs, search).
/// Avoid applying blur to every surface — costly on Flutter web.
class CRMBlur {
  static const double navigation = 20.0;
  static const double dialog = 24.0;
  static const double bottomSheet = 28.0;
  static const double search = 24.0;
  static const double floatingPanel = 20.0;

  static ImageFilter filter(double sigma) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static ImageFilter get navigationFilter => filter(navigation);
  static ImageFilter get dialogFilter => filter(dialog);
  static ImageFilter get bottomSheetFilter => filter(bottomSheet);
  static ImageFilter get searchFilter => filter(search);
  static ImageFilter get floatingPanelFilter => filter(floatingPanel);
}
