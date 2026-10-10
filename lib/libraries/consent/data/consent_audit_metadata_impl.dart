import 'package:construculator/libraries/consent/interfaces/consent_audit_metadata.dart';
import 'package:flutter/foundation.dart';

/// Reads the platform from [defaultTargetPlatform] and takes the version the
/// bootstrap already resolved, since neither changes while the app runs.
class ConsentAuditMetadataImpl implements ConsentAuditMetadata {
  @override
  final String appVersion;

  /// Creates metadata stamped with the bootstrap's [appVersion].
  ConsentAuditMetadataImpl({required this.appVersion});

  /// The lowercase platform name, the same value analytics sends as
  /// `platform`.
  @override
  String get platform => defaultTargetPlatform.name.toLowerCase();
}
