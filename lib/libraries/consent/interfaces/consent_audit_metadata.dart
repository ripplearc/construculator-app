// coverage:ignore-file
/// The build and platform a consent record was written from.
///
/// Stored on every `user_consents` row so a support ticket can be answered
/// with "which build was this accepted on, and on what platform". Injected
/// rather than read from `package_info_plus` or `dart:io` inside the consent
/// library, so tests can pin both values without platform channels.
abstract class ConsentAuditMetadata {
  /// The app's version name, e.g. `1.4.0`.
  String get appVersion;

  /// The platform the app runs on, lower case, e.g. `ios` or `android`.
  String get platform;
}
