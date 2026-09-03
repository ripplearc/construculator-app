import 'package:construculator/libraries/consent/data/consent_error_mapper.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Appends one row to a user's consent history.
///
/// Extracted from `ConsentRepositoryImpl` because recording is the one
/// consent write there is — accept and withdraw differ only in
/// [ConsentAction] and in how the caller resolves `version` — so both funnel
/// through here rather than duplicating the insert-and-map-errors shape.
///
/// The only path in the consent library that returns a real `Failure`: a
/// write the user believes succeeded but which left no record is the failure
/// mode worth surfacing, so it is never swallowed.
class ConsentRecorder {
  final LocalConsentDataSource _localDataSource;
  final Clock _clock;

  static final _logger = AppLogger().tag('ConsentRecorder');

  const ConsentRecorder(this._localDataSource, this._clock);

  /// Appends a [action] record for [userId] on [consentType] at [version].
  ///
  /// [userId] is nullable so callers can pass the signed-in check straight
  /// through: there is no user to attribute an unauthenticated write to, and
  /// that is a write failure like any other rather than a separate guard each
  /// caller has to repeat.
  Future<Either<Failure, UserConsent>> record({
    required String? userId,
    required ConsentType consentType,
    required int version,
    required ConsentAction action,
  }) async {
    if (userId == null) {
      return const Left(
        ConsentFailure(errorType: ConsentErrorType.authenticationError),
      );
    }

    try {
      // TODO: [CA-1026] appVersion and platform are left null — the columns
      // and the DTO fields exist, but ConsentRepository does not expose them,
      // so there is no path for a caller to supply them yet.
      final stored = await _localDataSource.insertUserConsent(
        UserConsentDto.draft(
          userId: userId,
          consentType: consentType,
          version: version,
          action: action,
          recordedAt: _clock.now(),
        ),
      );
      return Right(stored.toDomain());
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to record ${action.toJson()} consent for '
        '${consentType.toJson()}: $error',
        error,
        stackTrace,
      );
      return Left(ConsentErrorMapper.toFailure(error));
    }
  }
}
