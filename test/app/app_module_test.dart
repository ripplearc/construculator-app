import 'package:construculator/app/app_module.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/consent/consent_module.dart';
import 'package:construculator/libraries/consent/consent_gate_readiness.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('AppModule', () {
    // The consent persistence block is a constructor default, so the module
    // that builds ShellModule and ConsentModule is the one place it could be
    // quietly overridden -- the way AuthTestModule legitimately does for
    // tests. Registering routes only constructs the modules; no Modular.init
    // is needed, matching the pattern in shell_module_test.
    List<ModuleRoute> moduleRoutes() {
      final module = AppModule(FakeAppBootstrapFactory.create());
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();

      module.routes(routeManager);

      return routeManager.allRoutes.whereType<ModuleRoute>().toList();
    }

    test('builds ShellModule at the production readiness default', () {
      final shell = moduleRoutes()
          .map((route) => route.module)
          .whereType<ShellModule>()
          .single;

      expect(
        shell.persistenceReady,
        consentPersistenceReady,
        reason: 'AppModule must not override the consent persistence block; '
            'only CA-971 flipping the const may mount ConsentGuard.',
      );
    });

    test('builds ConsentModule at the production readiness default', () {
      final consent = moduleRoutes()
          .map((route) => route.module)
          .whereType<ConsentModule>()
          .single;

      expect(
        consent.persistenceReady,
        consentPersistenceReady,
        reason: 'AppModule must not override the consent persistence block; '
            'only CA-971 flipping the const may register the gate route, '
            'whose Accept button records a consent acceptance.',
      );
    });
  });
}
