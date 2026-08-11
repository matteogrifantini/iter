import 'package:url_launcher/url_launcher.dart';

typedef PlanUriLaunch = Future<bool> Function(Uri uri);

abstract final class GoogleMapsDirectionsUri {
  static Uri? build({required double latitude, required double longitude}) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination':
          '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
    });
  }
}

class PlanExternalLauncher {
  PlanExternalLauncher({
    PlanUriLaunch? launchExternal,
    PlanUriLaunch? launchBrowser,
  }) : _launchExternal = launchExternal ?? _openExternal,
       _launchBrowser = launchBrowser ?? _openBrowser;

  /// Hosts allowed for external demo links: the purchase providers already in
  /// the plan fixtures plus the directions host the plan itself builds. Any
  /// other host is refused up front, so the UI disables the action instead of
  /// silently launching an unvetted page.
  static const Set<String> allowedHosts = <String>{
    'www.flytap.com',
    'www.ryanair.com',
    'www.iberia.com',
    'www.vueling.com',
    'www.booking.com',
    'www.hotels.com',
    'www.expedia.com',
    'www.google.com',
  };

  final PlanUriLaunch _launchExternal;
  final PlanUriLaunch _launchBrowser;

  /// Whether [uri] is a safe HTTPS link on an allowlisted host. The UI uses
  /// this to disable purchase actions that would otherwise be refused.
  bool canOpen(Uri? uri) =>
      uri != null && uri.scheme == 'https' && allowedHosts.contains(uri.host);

  Future<bool> open(Uri? uri) async {
    if (uri == null || !canOpen(uri)) return false;
    try {
      if (await _launchExternal(uri)) return true;
    } catch (_) {
      // Fall through to the browser: launch failures are recoverable UI state.
    }
    try {
      return await _launchBrowser(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<bool> _openBrowser(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.platformDefault);
}
