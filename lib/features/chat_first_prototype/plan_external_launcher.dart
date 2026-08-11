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

  final PlanUriLaunch _launchExternal;
  final PlanUriLaunch _launchBrowser;

  Future<bool> open(Uri? uri) async {
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
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
