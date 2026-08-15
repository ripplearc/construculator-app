import 'dart:async';

import 'package:construculator/libraries/consent/data/consent_recorder.dart';
import 'package:construculator/libraries/consent/data/consent_verification_resolver.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Orchestrates the consent gate's decision logic.
///
/// Delegates the two self-contained pieces — resolving a background
/// verification, and appending a write — to [ConsentVerificationResolver] and
/// [ConsentRecorder]. What stays here is what only the repository can know:
/// the signed-in user, the local cache reads, and which [ConsentStatus] each
/// combination of read outcomes resolves to.
///
/// Sole logging site for the read path, per the log-once-at-the-boundary
/// rule — data sources rethrow silently; use cases and BLoCs neither log nor
/// throw.
class ConsentRepositoryImpl implements ConsentRepository {
  final LocalConsentDataSource _localDataSource;
  final SupabaseWrapper _supabaseWrapper;
  final ConsentVerificationResolver _verificationResolver;
  final ConsentRecorder _recorder;

  static final _logger = AppLogger().tag('ConsentRepositoryImpl');

  /// The answer when there is no signed-in user to gate.
  static const _ungated = ConsentSatisfied(ConsentRepository.noUserVersion);

  ConsentRepositoryImpl({
    required LocalConsentDataSource localDataSource,
    required RemoteConsentDataSource remoteDataSource,
    required this._supabaseWrapper,
    required Clock clock,
  }) : _localDataSource = localDataSource,
       _verificationResolver = ConsentVerificationResolver(remoteDataSource),
       _recorder = ConsentRecorder(localDataSource, clock);

  @override
  Future<ConsentStatus> getCachedConsentStatus(ConsentType type) async {
    final userId = _supabaseWrapper.getInternalUserId();
    if (userId == null) return _ungated;

    try {
      final published = await _localDataSource.fetchPublishedVersion(type);
      final accepted = await _localDataSource.fetchLatestUserConsent(
        userId,
        type,
      );

      // The requirement has not arrived yet: nothing to compare against, and
      // no document to present.
      if (published == null) return const ConsentIndeterminate();

      return _compare(_effectiveAcceptedVersion(accepted), published);
    } catch (error) {
      _logger.warning('Local consent read failed for ${type.toJson()}: $error');

      // A failed read establishes nothing, which is the same position as a
      // clean read that found no requirement, so it resolves to the same
      // status. Reporting it as a failure instead would let the guard treat a
      // broken read as more trustworthy than a working one.
      return const ConsentIndeterminate();
    }
  }

  @override
  Stream<ConsentStatus> watchConsentStatus(ConsentType type) {
    final userId = _supabaseWrapper.getInternalUserId();
    if (userId == null) return Stream.value(_ungated);

    return _localDataSource
        .watchLatestUserConsent(userId, type)
        .asyncMap((accepted) async {
          final published = await _localDataSource.fetchPublishedVersion(type);
          if (published == null) {
            return const ConsentIndeterminate();
          }
          return _compare(_effectiveAcceptedVersion(accepted), published);
        })
        .handleError((Object error) {
          _logger.warning(
            'Consent watch failed for ${type.toJson()}: $error',
          );
        });
  }

  // Compares an accepted version against a published one. The comparison
  // itself lives on ConsentStatus, which defines what the states mean.
  ConsentStatus _compare(int? accepted, ConsentVersionDto published) =>
      ConsentStatus.resolve(
        acceptedVersion: accepted,
        published: published.toDomain(),
      );

  // The version the user currently stands on, or null when they stand on
  // nothing.
  //
  // A newest record of [ConsentAction.withdrawn] means the user revoked their
  // consent, which puts them in exactly the same position as a user who never
  // accepted anything — so it maps to null rather than to the version being
  // revoked.
  int? _effectiveAcceptedVersion(UserConsentDto? newest) =>
      (newest == null || newest.action == ConsentAction.withdrawn)
      ? null
      : newest.version;

  @override
  Future<ConsentStatus> verifyPublishedVersion(ConsentType type) async {
    final userId = _supabaseWrapper.getInternalUserId();
    if (userId == null) return _ungated;

    // Read before the round trip, because this is the value that decides
    // whether failing open is safe below.
    final int? acceptedVersion;
    try {
      final accepted = await _localDataSource.fetchLatestUserConsent(
        userId,
        type,
      );
      acceptedVersion = _effectiveAcceptedVersion(accepted);
    } catch (error) {
      _logger.warning(
        'Local consent read failed during verification for '
        '${type.toJson()}: $error',
      );
      return const ConsentIndeterminate();
    }

    return _verificationResolver.resolve(
      type: type,
      acceptedVersion: acceptedVersion,
    );
  }

  @override
  Future<Either<Failure, UserConsent>> recordAcceptance({
    required ConsentType consentType,
    required int version,
  }) => _recorder.record(
    userId: _supabaseWrapper.getInternalUserId(),
    consentType: consentType,
    version: version,
    action: ConsentAction.accepted,
  );

  @override
  Future<Either<Failure, UserConsent>> recordWithdrawal({
    required ConsentType consentType,
  }) async {
    final userId = _supabaseWrapper.getInternalUserId();

    // The version comes from the record being revoked, not the caller. Zero
    // when there is nothing to revoke, which keeps the audit row readable.
    var version = 0;
    if (userId != null) {
      try {
        final current = await _localDataSource.fetchLatestUserConsent(
          userId,
          consentType,
        );
        version = _effectiveAcceptedVersion(current) ?? 0;
      } catch (error) {
        _logger.warning(
          'Could not read the version being withdrawn for '
          '${consentType.toJson()}: $error',
        );
      }
    }

    return _recorder.record(
      userId: userId,
      consentType: consentType,
      version: version,
      action: ConsentAction.withdrawn,
    );
  }

  // The repository handed out the data source's stream, so it is the layer
  // that knows when nobody is listening any more.
  @override
  void dispose() => unawaited(_localDataSource.dispose());
}
