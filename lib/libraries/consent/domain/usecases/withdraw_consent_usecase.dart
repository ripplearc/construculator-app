// coverage:ignore-file
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Records that the user withdrew a consent they had previously given.
///
/// Appends rather than deletes — see [ConsentRepository.recordWithdrawal].
///
/// The consequences differ by type and are the caller's to apply: withdrawing
/// [ConsentType.termsAndPrivacy] leaves the user with no acceptance on file
/// and therefore re-gated, while withdrawing [ConsentType.analytics] only
/// disables capture.
class WithdrawConsentUseCase {
  final ConsentRepository _repository;

  const WithdrawConsentUseCase(this._repository);

  /// Appends a withdrawal for the type named in [params].
  Future<Either<Failure, UserConsent>> call(WithdrawConsentParams params) =>
      _repository.recordWithdrawal(consentType: params.consentType);
}
