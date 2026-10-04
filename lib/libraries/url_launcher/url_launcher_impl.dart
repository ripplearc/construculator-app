import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/url_launcher/interfaces/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as plugin;

/// Hands a parsed URL to the platform; resolves to whether an app opened it.
typedef LaunchExternalApplication = Future<bool> Function(Uri url);

/// [UrlLauncher] backed by the url_launcher plugin.
///
/// A failed launch is logged as a warning rather than an error: no browser
/// installed, or a URL no app handles, is a device condition, not a bug.
class UrlLauncherImpl implements UrlLauncher {
  static final _logger = AppLogger().tag('UrlLauncherImpl');

  final LaunchExternalApplication _launch;

  /// [launch] stands in for the plugin in tests; production omits it.
  UrlLauncherImpl({LaunchExternalApplication? launch})
    : _launch = launch ?? _launchWithPlugin;

  @override
  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _logger.warning('Cannot open "$url": not an absolute URL');
      return false;
    }
    try {
      final opened = await _launch(uri);
      if (!opened) _logger.warning('No app could open "$url"');
      return opened;
    } on PlatformException catch (e, stackTrace) {
      _logger.warning('Opening "$url" failed', e, stackTrace);
      return false;
    }
  }

  static Future<bool> _launchWithPlugin(Uri url) =>
      plugin.launchUrl(url, mode: plugin.LaunchMode.externalApplication);
}
