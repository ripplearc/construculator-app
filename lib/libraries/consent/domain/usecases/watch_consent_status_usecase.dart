// coverage:ignore-file
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';

/// Observes the user's consent status for the lifetime of a session.
///
/// Exists so a version published while the app is open re-gates the user on
/// the next sync rather than waiting for a cold start, and so a withdrawal
/// made in settings takes effect immediately.
///
/// Callers own the subscription and must cancel it — see the stream lifecycle
/// rule.
class WatchConsentStatusUseCase {
  final ConsentRepository _repository;

  const WatchConsentStatusUseCase(this._repository);

  /// Emits the status for the consent type named in [params] whenever the
  /// underlying consent data changes.
  Stream<ConsentStatus> call(
    ConsentStatusParams params,
  ) => _repository.watchConsentStatus(params.consentType);
}
