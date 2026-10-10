import 'package:construculator/libraries/url_launcher/interfaces/url_launcher.dart';

/// [UrlLauncher] that records each URL instead of leaving the app.
class FakeUrlLauncher implements UrlLauncher {
  /// Every URL passed to [openExternal], oldest first.
  final List<String> openedUrls = [];

  /// What [openExternal] resolves to; set false to simulate a failed launch.
  bool shouldOpen = true;

  @override
  Future<bool> openExternal(String url) async {
    openedUrls.add(url);
    return shouldOpen;
  }

  /// Clears [openedUrls] and makes launches succeed again.
  void reset() {
    openedUrls.clear();
    shouldOpen = true;
  }
}
