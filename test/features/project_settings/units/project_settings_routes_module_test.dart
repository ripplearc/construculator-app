import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _RoutesModuleTestHarness extends Module {
  @override
  List<Module> get imports => [
    ProjectSettingsRoutesModule(FakeAppBootstrapFactory.create()),
  ];
}

void main() {
  group('ProjectSettingsRoutesModule', () {
    late ProjectSettingsRoutesModule module;

    setUp(() {
      module = ProjectSettingsRoutesModule(FakeAppBootstrapFactory.create());
      Modular.init(_RoutesModuleTestHarness());
    });

    tearDown(() {
      Modular.destroy();
    });

    test('declares two imports', () {
      expect(module.imports, hasLength(2));
    });

    test('binds ProjectSettingsBloc', () {
      final bloc = Modular.get<ProjectSettingsBloc>();
      expect(bloc, isA<ProjectSettingsBloc>());
      bloc.close();
    });

    test('viewProjectRoute AuthGuard redirects to login when unauthenticated',
        () async {
      // Regression for: https://github.com/ripplearc/construculator-app/pull/366
      // Verifies the guard type and redirect destination used on viewProjectRoute.
      final guard = AuthGuard(() => Modular.get<AuthManager>());
      expect(guard.redirectTo, equals(fullLoginRoute));

      // FakeSupabaseWrapper starts with no signed-in user → isAuthenticated() is false.
      // ignore: no_direct_instantiation
      final stubRoute = ChildRoute(viewProjectRoute, child: (_) => const SizedBox());
      expect(await guard.canActivate(viewProjectRoute, stubRoute), isFalse);
    });
  });
}
