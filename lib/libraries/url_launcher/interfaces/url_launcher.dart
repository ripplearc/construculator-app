// coverage:ignore-file
/// Opens a web URL outside the app, in the browser or whichever app handles
/// it.
///
/// Wraps the url_launcher plugin so pages never reach the platform channel
/// directly. Tests swap in `FakeUrlLauncher`, which records what was opened.
abstract class UrlLauncher {
  /// Opens [url] in an external app.
  ///
  /// Resolves to whether it opened. Never throws: a URL that cannot be parsed,
  /// is not http or https, or that no installed app can handle, resolves to
  /// false.
  Future<bool> openExternal(String url);
}
