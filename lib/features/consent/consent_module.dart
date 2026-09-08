import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/pages/consent_gate_page.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/consent/consent_gate_readiness.dart';
import 'package:construculator/libraries/consent/consent_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module for the consent gate feature.
///
/// The gate route carries [AuthGuard] **only**. It deliberately does not carry
/// [ConsentGuard]: this is where that guard redirects to, so guarding it would
/// send the redirect back to itself.
///
/// The route is registered only when [consentGateEnabled] holds. `ConsentGuard`
/// is the sole thing that redirects here, and it does not mount while the gate
/// is blocked -- but the page's Accept button is the second production consent
/// write (`ConsentGateBloc._onAccepted`), so leaving the route registered would
/// leave a way to record an acceptance this build cannot durably keep. Not
/// registering it means there is no route to reach at all.
class ConsentModule extends Module {
  final AppBootstrap appBootstrap;

  /// Seam for [consentGateEnabled]'s `persistenceReady`; AppModule never
  /// passes it, so the app always gets the source-level answer.
  final bool persistenceReady;

  ConsentModule(
    this.appBootstrap, {
    this.persistenceReady = consentPersistenceReady,
  });

  @override
  List<Module> get imports => [ConsentLibraryModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.add<ConsentGateBloc>(
      () => ConsentGateBloc(
        checkConsentStatusUseCase: i(),
        watchConsentStatusUseCase: i(),
        verifyConsentStatusUseCase: i(),
        recordConsentUseCase: i(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    if (!consentGateEnabled(
      appBootstrap.envLoader,
      persistenceReady: persistenceReady,
    )) {
      return;
    }

    r.child(
      consentGateRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => BlocProvider<ConsentGateBloc>(
        create: (_) =>
            Modular.get<ConsentGateBloc>()..add(const ConsentGateStarted()),
        child: ConsentGatePage(
          router: Modular.get<AppRouter>(),
          // Inert for now, matching the existing signup terms links
          // (`_openLink` in create_account_page.dart). Opening these
          // externally needs a URL-launcher wrapper, which the app does not
          // have yet — the page takes this as a parameter so wiring one in
          // later touches only this line.
          onOpenDocument: (_) {},
          // TODO: https://ripplearc.youtrack.cloud/issue/CA-1024 - Wire a
          // real URL launcher wrapper. Until then this stays false: the
          // callback above can't open anything, and unlike the dismissible
          // signup screen, this gate cannot be left, so a tappable-but-dead
          // link is worse than no link at all -- see
          // ConsentPrompt.documentLinksAvailable. Flip to true (or drop the
          // parameter, since it defaults true) once the launcher lands.
          documentLinksAvailable: false,
        ),
      ),
    );
  }
}
