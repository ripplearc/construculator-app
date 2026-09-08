// coverage:ignore-file
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Records that the user accepted a consent version.
///
/// Called from two places: the consent gate, when the user presses accept, and
/// signup, which must record an initial acceptance before the new account
/// reaches the shell or the guard will block the account it just created.
///
/// Unlike the read path, this returns a real [Failure] on the left — see
/// [ConsentRepository] for why the write path is the asymmetric one.
class RecordConsentUseCase {
  final ConsentRepository _repository;

  const RecordConsentUseCase(this._repository);

  /// Appends an acceptance for the type and version named in [params].
  Future<Either<Failure, UserConsent>> call(RecordConsentParams params) =>
      _repository.recordAcceptance(
        consentType: params.consentType,
        version: params.version,
      );
}
