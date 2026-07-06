import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
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
  });
}
