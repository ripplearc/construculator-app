import 'package:construculator/features/consent/consent_module.dart';
import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/pages/consent_gate_page.dart';
import 'package:construculator/features/consent/presentation/widgets/consent_document_links.dart';
import 'package:construculator/features/consent/testing/consent_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

/// Supplies the one dependency the route's child builder resolves that
/// [ConsentModule] does not register itself.
///
/// The builder calls `Modular.get<AppRouter>()`, which RouterModule binds in
/// production; importing this module rather than reaching past Modular keeps
/// the builder under test exactly as it ships.
class _ConsentModuleTestHarness extends Module {
  final ConsentModule consentModule;

  _ConsentModuleTestHarness(this.consentModule);

  @override
  List<Module> get imports => [consentModule];

  @override
  void binds(Injector i) {
    i.addSingleton<AppRouter>(FakeAppRouter.new);
  }
}

void main() {
  late ConsentModule module;

  setUp(() {
    // persistenceReady: true so the route-shape cases below still exercise a
    // registered route; consentPersistenceReady is false today, so the
    // production default registers nothing at all.
    module = ConsentModule(
      FakeAppBootstrapFactory.create(
        envLoader: FakeEnvLoader()..setEnvVar(consentGateEnabledKey, 'true'),
      ),
      persistenceReady: true,
    );
  });

  tearDown(Modular.destroy);

  group('ConsentModule', () {
    setUp(() => Modular.init(module));

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

    test('registers no route at the production default', () {
      // The gate page's Accept button is a consent write
      // (ConsentGateBloc._onAccepted). Until CA-971 lands there must be no
      // route that can reach it -- not merely no guard redirecting to it,
      // since a deep link or a stray router.navigate would do just as well.
      final module = ConsentModule(
        FakeAppBootstrapFactory.create(
          envLoader: FakeEnvLoader()
            ..setEnvVar(consentGateEnabledKey, 'true'),
        ),
      );
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();

      module.routes(routeManager);

      expect(routeManager.allRoutes, isEmpty);
    });

    test('registers no route when the flag is off, even if ready', () {
      final module = ConsentModule(
        FakeAppBootstrapFactory.create(
          envLoader: FakeEnvLoader()
            ..setEnvVar(consentGateEnabledKey, 'false'),
        ),
        persistenceReady: true,
      );
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();

      module.routes(routeManager);

      expect(routeManager.allRoutes, isEmpty);
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

  test('the test module disposes the repository when the module unloads', () {
    // ConsentLibraryModule registers ConsentRepository with
    // BindConfig(onDispose:) so the data source's stream controller closes on
    // unload. ConsentTestModule carries the same config; without this test
    // nothing anywhere exercises that path, and a production bind that lost
    // the config would leave the controller open with no failing test.
    Modular.init(ConsentTestModule());
    final repository =
        Modular.get<ConsentRepository>() as FakeConsentRepository;
    expect(repository.disposeCallCount, 0);

    Modular.destroy();

    expect(repository.disposeCallCount, 1);
  });

  group('the gate route builds', () {
    late RouteManager routeManager;

    setUp(() {
      Modular.init(_ConsentModuleTestHarness(module));
      // ignore: no_direct_instantiation
      routeManager = RouteManager();
      module.routes(routeManager);
    });

    Widget buildRouteChild() {
      final route = routeManager.allRoutes.single as ChildRoute;
      final builder = route.child;
      expect(
        builder,
        isNotNull,
        reason: 'the gate route must register a child builder',
      );
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: builder!),
      );
    }

    testWidgets('the registered route renders the gate page', (tester) async {
      // Everything the route composes -- the BlocProvider, the started event,
      // the page's own dependencies -- runs only when the builder is invoked.
      // Asserting the route's metadata alone left this closure unexecuted, so
      // a bind resolved against the wrong type inside it would have surfaced
      // first to a user navigating to /consent/gate.
      await tester.pumpWidget(buildRouteChild());
      await tester.pumpAndSettle();

      expect(find.byType(ConsentGatePage), findsOneWidget);
    });

    testWidgets('the gate page ships with its document links hidden', (
      tester,
    ) async {
      // The production configuration, asserted where production sets it:
      // onOpenDocument is a no-op until CA-1024, so rendering tappable links
      // that open nothing would be worse than rendering none. A future edit
      // that flips this without wiring the launcher fails here.
      await tester.pumpWidget(buildRouteChild());
      await tester.pumpAndSettle();

      expect(find.byType(ConsentDocumentLinks), findsNothing);
    });
  });
}
