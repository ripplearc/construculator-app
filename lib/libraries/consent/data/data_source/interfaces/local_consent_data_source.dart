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
abstract class LocalConsentDataSource {
  /// Returns the published version for [type], or null when none is held
  /// locally yet.
  ///
  /// Null is a meaningful answer, not an error: it means the requirement is
  /// unknown, so there is no document to present and nothing to compare
  /// against.
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type);

  /// Returns the newest consent record for [userId] and [type], or null when
  /// the user has none.
  ///
  /// Newest only — the table is append-only, and a withdrawal supersedes the
  /// acceptance beneath it.
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  );

  /// Emits the newest consent record for [userId] and [type] whenever the
  /// underlying data changes.
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
