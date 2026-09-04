import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/consent/consent_gate_readiness.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/fake_app_bootstrap_factory.dart';

void main() {
  // Registering routes only builds route/guard objects through deferred
  // closures (`() => Modular.get<...>()`), never resolving them -- so this
  // can run against a bare RouteManager with no Modular.init, matching the
  // pattern already used for ConsentModule's own route test.
  // persistenceReady defaults to true so these cases still test the flag
  // wiring itself; consentPersistenceReady is false today, so leaving it at
  // the production default would make every case trivially pass.
  List<RouteGuard> guardsFor(
    FakeEnvLoader envLoader, {
    bool persistenceReady = true,
  }) {
    final module = ShellModule(
      FakeAppBootstrapFactory.create(envLoader: envLoader),
      persistenceReady: persistenceReady,
    );
    // ignore: no_direct_instantiation
    final routeManager = RouteManager();

    module.routes(routeManager);

    final root = routeManager.allRoutes.firstWhere((r) => r.name == '/');
    // ignore: avoid_dynamic_calls
    return (root as dynamic).middlewares as List<RouteGuard>;
  }

  group('ShellModule', () {
    // The line deciding whether the gate mounts was previously untested --
    // a mis-targeted `==`, a missing import, or the condition inverted would
    // not fail until a human first navigated the shell with the flag on.
    test('registers ConsentGuard when the flag is "true"', () {
      final guards = guardsFor(
        FakeEnvLoader()..setEnvVar(consentGateEnabledKey, 'true'),
      );

      expect(guards.whereType<ConsentGuard>(), hasLength(1));
    });

    test('does not register ConsentGuard at the production default', () {
      // The compile-time block: consentPersistenceReady is false until
      // CA-971 lands, so the flag being on is not enough to mount a gate
      // this build cannot durably record an acceptance for.
      final guards = guardsFor(
        FakeEnvLoader()..setEnvVar(consentGateEnabledKey, 'true'),
        persistenceReady: consentPersistenceReady,
      );

      expect(guards.whereType<ConsentGuard>(), isEmpty);
    });

    test('does not register ConsentGuard when the flag is "false"', () {
      final guards = guardsFor(
        FakeEnvLoader()..setEnvVar(consentGateEnabledKey, 'false'),
      );

      expect(guards.whereType<ConsentGuard>(), isEmpty);
    });

    test('does not register ConsentGuard when the flag is unset', () {
      // The production default (assets/env/.env.template ships with no
      // value set), and the fail-safe direction if the key is ever missing
      // from a deployment's config entirely.
      final guards = guardsFor(FakeEnvLoader());

      expect(guards.whereType<ConsentGuard>(), isEmpty);
    });

    test('AuthGuard is always present regardless of the flag', () {
      for (final value in ['true', 'false', null]) {
        final envLoader = FakeEnvLoader();
        if (value != null) envLoader.setEnvVar(consentGateEnabledKey, value);

        final guards = guardsFor(envLoader);

        expect(guards.whereType<AuthGuard>(), hasLength(1));
      }
    });

    test('AuthGuard precedes ConsentGuard when both are present', () {
      // ConsentGuard's own precondition (a signed-in user) depends on
      // AuthGuard having already run.
      final guards = guardsFor(
        FakeEnvLoader()..setEnvVar(consentGateEnabledKey, 'true'),
      );

      expect(guards.indexWhere((g) => g is AuthGuard), 0);
      expect(guards.indexWhere((g) => g is ConsentGuard), 1);
    });
  });
}
