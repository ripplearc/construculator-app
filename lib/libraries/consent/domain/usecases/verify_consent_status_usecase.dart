// coverage:ignore-file
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';

/// Establishes the published consent version authoritatively.
///
/// The third startup phase, run after [CheckConsentStatusUseCase] has already
/// answered from local data. It reaches the network, so it is deliberately not
/// on the path that decides what to render first — a stalled sync must not
/// hold up the app, and a slow server must not either.
///
/// This is the only path that can produce [ConsentUnverified]: the local
/// comparison either knows the requirement or does not, whereas a failed
/// verification with a prior acceptance on file is the one case the design
/// lets through.
class VerifyConsentStatusUseCase {
  final ConsentRepository _repository;

  const VerifyConsentStatusUseCase(this._repository);

  /// Confirms the published version for the consent type named in [params].
  ///
  /// Returns a status rather than surfacing a failure, and which status
  /// depends on whether there is a prior acceptance to fall back on — see
  /// [ConsentRepository.verifyPublishedVersion].
  Future<ConsentStatus> call(ConsentStatusParams params) =>
      _repository.verifyPublishedVersion(params.consentType);
}
