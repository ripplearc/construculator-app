import 'package:construculator/libraries/consent/interfaces/consent_audit_metadata.dart';

/// Fixed audit metadata, so tests can assert what a consent record carries.
class FakeConsentAuditMetadata implements ConsentAuditMetadata {
  /// The version every record is stamped with.
  @override
  final String appVersion;

  /// The platform every record is stamped with.
  @override
  final String platform;

  /// Defaults stand in for a real build; pass values a test asserts on.
  FakeConsentAuditMetadata({this.appVersion = '1.0.0', this.platform = 'ios'});
}
