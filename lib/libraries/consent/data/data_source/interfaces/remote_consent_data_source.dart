// coverage:ignore-file
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
  ///
  /// A row naming a consent type this build does not recognise is dropped
  /// from the result: it means a newer server published a document this build
  /// has no gate for, which is not a reason to fail the read. That applies
  /// only to a well-formed type value — a missing or non-textual one is a
  /// corrupt row, not a newer server, and is treated like any other unreadable
  /// field. A row of a type this build *does* gate on that cannot be read
  /// throws [FormatException] instead — dropping it would hand the caller a
  /// list that looks like "nothing required" for a requirement the user never
  /// satisfied.
  ///
  /// So the returned list is every readable, recognised published version, and
  /// callers must treat a throw as "the requirement could not be established",
  /// never as "there is none".
  Future<List<ConsentVersionDto>> fetchPublishedVersions();
}
