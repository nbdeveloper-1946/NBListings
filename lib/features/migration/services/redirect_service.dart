import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class MigrationRedirectService {
  Future<bool> redirectToPropKart() async {
    final Uri deepLinkUri = Uri.parse(AppConstants.deepLink);
    final Uri webUri = Uri.parse(AppConstants.migrationUrl);

    try {
      // Try deep link first
      if (await canLaunchUrl(deepLinkUri)) {
        final success = await launchUrl(deepLinkUri, mode: LaunchMode.externalApplication);
        if (success) return true;
      }
    } catch (_) {
      // Deep link scheme check can throw on certain platforms if not listed in manifest
    }

    // Fallback to web URL
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
