import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';

/// Reads published consent versions straight from the server.
///
/// Exists separately from the local source purely so background verification
/// does not depend on replication having caught up: a stalled sync must not be
/// able to mask a newly published version, which is the one thing that has to
/// be established authoritatively.
///
/// Throws on failure. The repository retries transient failures and then
/// resolves the outcome to a status — an unreachable server is an expected
/// condition on a mobile network, not an error to surface to the user.
abstract class RemoteConsentDataSource {
  /// Returns the currently published version of every consent document.
  ///
  /// Fetches all types in one round trip rather than one call per type; there
  /// are only a handful of rows and the caller filters locally.
  Future<List<ConsentVersionDto>> fetchPublishedVersions();
}
