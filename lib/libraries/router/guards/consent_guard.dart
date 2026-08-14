import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Blocks the authenticated shell when the signed-in user's consent is stale.
///
/// Registered after [AuthGuard], so it only ever evaluates for a signed-in
/// user and never has to reason about the unauthenticated case. Like
/// [AuthGuard] — which resolves from the in-memory session rather than a round
/// trip — it answers from cached state and never awaits the network inside
/// [canActivate]. Background verification happens in `ConsentGateBloc` and
/// never delays route evaluation.
class ConsentGuard extends RouteGuard {
  final CheckConsentStatusUseCase Function() _getUseCase;

  ConsentGuard(this._getUseCase) : super(redirectTo: fullConsentGateRoute);

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    final status = await _getUseCase()(
      const ConsentStatusParams(
        consentType: ConsentType.termsAndPrivacy,
      ),
    );

    // Which states block is ConsentStatus's own definition, not this guard's.
    // Restating the mapping here would let the route and the gate page
    // disagree about the same status.
    return !status.gatesAccess;
  }
}
