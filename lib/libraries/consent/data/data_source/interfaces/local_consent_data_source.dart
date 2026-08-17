import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Reads and writes consent data held on the device.
///
/// Answers the question that unblocks app start, and owns the write path.
/// Implementations must not reach the network: the gate resolves from local
/// data precisely so a slow or absent connection cannot delay a cold start.
///
/// Methods throw on failure rather than returning a result type — the
/// repository is the single place that decides what a failure means, and for
/// the read path it deliberately means a status rather than an error.
///
/// CA-971 provides the offline-first PowerSync implementation of this port;
/// the in-memory store bound today is a temporary stand-in until it lands.
abstract class LocalConsentDataSource {
  /// Returns the published version for [type], or null when none is held
  /// locally yet.
  ///
  /// Null is a meaningful answer, not an error: it means the requirement is
  /// unknown, so there is no document to present and nothing to compare
  /// against.
  ///
  /// Reads are per-type rather than batched like the remote source's
  /// `fetchPublishedVersions`: each call is against a local store where a
  /// round trip costs nothing, and a gate check only ever needs one type at a
  /// time.
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type);

  /// Returns the newest consent record for [userId] and [type], or null when
  /// the user has none.
  ///
  /// Newest by [UserConsentDto.recordedAt] — the table is append-only, and a
  /// withdrawal supersedes the acceptance beneath it. Implementations must
  /// resolve records sharing an instant deterministically, since two records
  /// written in the same instant must still produce one answer.
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  );

  /// Emits the newest consent record for [userId] and [type] immediately on
  /// subscribe, then again whenever the underlying data changes. Emits null
  /// when the user has no record.
  ///
  /// Newest on the same terms as [fetchLatestUserConsent].
  Stream<UserConsentDto?> watchLatestUserConsent(
    String userId,
    ConsentType type,
  );

  /// Appends [dto] to the user's consent history and returns the stored
  /// record.
  Future<UserConsentDto> insertUserConsent(UserConsentDto dto);

  /// Releases any resources held by the data source.
  ///
  /// Implementations backing [watchLatestUserConsent] with a controller must
  /// close it here; the repository that owns this source is what calls it.
  Future<void> dispose();
}
