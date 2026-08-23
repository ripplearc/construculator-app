import 'package:construculator/features/consent/consent_module.dart';
import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ConsentModule', () {
    late ConsentModule module;

    setUp(() {
      module = ConsentModule(FakeAppBootstrapFactory.create());
      Modular.init(module);
    });

    tearDown(Modular.destroy);

    // The gate route carrying ConsentGuard is the redirect loop the module's
    // own class doc warns against: the guard would redirect to a route it
    // also blocks, with nowhere for the user to land. Before this test, that
    // invariant was guaranteed only by a comment.
    test('the gate route carries AuthGuard but not ConsentGuard', () {
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();

      module.routes(routeManager);

      final route = routeManager.allRoutes.single;
      expect(route.name, consentGateRoute);
      expect(route.middlewares, hasLength(1));
      expect(route.middlewares.single, isA<AuthGuard>());
      expect(
        route.middlewares.whereType<ConsentGuard>(),
        isEmpty,
        reason:
            'ConsentGuard redirects here; guarding this route with itself '
            'would send the redirect back to itself with no route left to '
            'admit the user.',
      );
    });

    test('registers the gate bloc', () {
      final bloc = Modular.get<ConsentGateBloc>();

      expect(bloc, isNotNull);

      bloc.close();
    });

    test('the gate bloc is not a singleton', () {
      // i.add, not addLazySingleton -- a fresh bloc per navigation, since the
      // page adds ConsentGateStarted on construction and a shared instance
      // would replay stale state on re-entry.
      final first = Modular.get<ConsentGateBloc>();
      final second = Modular.get<ConsentGateBloc>();

      expect(identical(first, second), isFalse);

      first.close();
      second.close();
    });
  });
}
