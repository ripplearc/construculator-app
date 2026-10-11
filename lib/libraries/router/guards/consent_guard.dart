import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Blocks the authenticated shell when the signed-in user's consent is stale.
///
/// Registered after [AuthGuard], so it only ever evaluates once
/// [AuthManager.isAuthenticated] is true -- but that only rules out the
/// unauthenticated case, not an unidentified one. [SupabaseWrapper] resolves
/// the application-layer user id separately, from `app_metadata` on the JWT,
/// and returns null there whenever it's missing -- a stale token issued
/// before the claim was provisioned, or any refresh race between
/// authentication and claim propagation, leaves an authenticated session
/// with no internal user id. [ConsentRepository.getCachedConsentStatus]
/// answers that case with [ConsentUserUnidentified], which gates like any
/// other blocking status.
///
/// Like [AuthGuard] — which resolves from the in-memory session rather than a
/// round trip — this answers from cached state and never awaits the network
/// inside [canActivate]. Background verification happens in
/// `ConsentGateBloc` and never delays route evaluation.
///
/// That "completes fast enough" claim is a property of the store, not of this
/// guard. It used to rest on an in-memory store answering synchronously.
/// Since CA-971 it rests on `PowerSyncLocalConsentDataSource` issuing two
/// local SQLite reads against tables holding a handful of rows each, with no
/// network call on the path — `fetchPublishedVersion` and
/// `fetchLatestUserConsent` are one indexed `SELECT` apiece, and the sync
/// stream that fills them runs elsewhere. The `await` below is still
/// unbounded, so the property to protect is that one: a read here must stay
/// local, because a hang here hangs route evaluation with no gate and no app.
/// Giving this call a timeout would make the guard independent of that
/// property rather than reliant on it.
class ConsentGuard extends RouteGuard {
  final CheckConsentStatusUseCase Function() _getUseCase;

  ConsentGuard(this._getUseCase) : super(redirectTo: fullConsentGateRoute);

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    final status = await _getUseCase()(
      const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
    );

    // Every state is ConsentStatus's own definition, not this guard's.
    // Restating the mapping here would let the route and the gate page
    // disagree about the same status.
    return !status.gatesAccess;
  }
}
