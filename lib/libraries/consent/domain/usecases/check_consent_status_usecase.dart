// coverage:ignore-file
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';

/// Resolves the user's consent status from locally held data.
///
/// This is the use case on the app start path — the route guard calls it, and
/// the gate BLoC calls it to decide what to render before any verification has
/// run. It never reaches the network, which is what keeps it off the latency
/// budget for a cold start.
class CheckConsentStatusUseCase {
  final ConsentRepository _repository;

  const CheckConsentStatusUseCase(this._repository);

  /// Returns the status for the consent type named in [params].
  ///
  /// Resolves every expected condition to a [ConsentStatus] on the right,
  /// including a failed local read — see [ConsentRepository] for why the read
  /// path does not surface failures.
  Future<ConsentStatus> call(
    ConsentStatusParams params,
  ) => _repository.getCachedConsentStatus(params.consentType);
}
