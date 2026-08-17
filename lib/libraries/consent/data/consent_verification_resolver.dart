import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Resolves the outcome of a background consent-version verification.
///
/// Extracted from `ConsentRepositoryImpl` because a verification attempt has
/// exactly two shapes regardless of caller: it succeeds and produces a
/// [ConsentStatus] by comparison, or it fails and the fallback depends only on
/// whether [acceptedVersion] exists. Neither shape needs anything else the
/// repository knows — not the local data source, not the write path — so
/// isolating it keeps the repository to orchestration.
///
/// An unreachable server is an expected condition on a mobile network, not an
/// error to surface: this class always returns a [ConsentStatus], never a
/// `Failure`.
class ConsentVerificationResolver {
  final RemoteConsentDataSource _remoteDataSource;

  static final _logger = AppLogger().tag('ConsentVerificationResolver');

  const ConsentVerificationResolver(this._remoteDataSource);

  /// Resolves [type] against the server's published versions.
  ///
  /// [acceptedVersion] is the caller's already-resolved local acceptance,
  /// passed in rather than looked up here since the local read and the remote
  /// check fail independently and the caller already needed it before
  /// deciding to call this at all.
  Future<ConsentStatus> resolve({
    required ConsentType type,
    required int? acceptedVersion,
  }) async {
    try {
      final published = await _remoteDataSource.fetchPublishedVersions();
      final match = published
          .where((version) => version.consentType == type)
          .firstOrNull;

      // The server answered but publishes nothing for this type. Treated as
      // no requirement rather than as a failure: there is genuinely nothing
      // to hold the user to.
      if (match == null) return ConsentSatisfied(acceptedVersion ?? 0);

      return ConsentStatus.resolve(
        acceptedVersion: acceptedVersion,
        published: match.toDomain(),
      );
    } catch (error, stackTrace) {
      _logger.warning(
        'Consent verification failed for ${type.toJson()}',
        error,
        stackTrace,
      );

      // Deliberately a status, not a failure: which one depends entirely on
      // whether there is a prior acceptance to fall back on.
      return acceptedVersion == null
          // Nothing to fall back on and no document to present.
          ? const ConsentIndeterminate()
          // Trust the last known-good acceptance; retry next launch.
          : ConsentUnverified(acceptedVersion);
    }
  }
}
