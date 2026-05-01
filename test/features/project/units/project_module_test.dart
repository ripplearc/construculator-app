import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/project/data/current_project_notifier_impl.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _FakeRouteManager extends Fake implements RouteManager {}

class _ProjectModuleTestHarness extends Module {
  @override
  List<Module> get imports => [ProjectModule(FakeAppBootstrapFactory.create())];

  @override
  void binds(Injector i) {
    i.add<RouteManager>(_FakeRouteManager.new);
  }
}

void main() {
  group('ProjectModule', () {
    late ProjectModule module;

    setUp(() {
      module = ProjectModule(FakeAppBootstrapFactory.create());
      Modular.init(_ProjectModuleTestHarness());
    });

    tearDown(() {
      Modular.destroy();
    });

    test('declares expected imports and exposes an empty route map', () {
      expect(module.imports, hasLength(3));
      expect(() => module.routes(Modular.get<RouteManager>()), returnsNormally);
    });

    test('registers lazy singletons and bloc dependencies', () {
      final notifier = Modular.get<CurrentProjectNotifier>();
      final useCase = Modular.get<GetProjectHeaderUseCase>();
      final bloc = Modular.get<GetProjectBloc>();

      expect(notifier, isA<CurrentProjectNotifierImpl>());
      expect(
        (notifier as CurrentProjectNotifierImpl).currentProjectId,
        '950e8400-e29b-41d4-a716-446655440001',
      );
      expect(useCase, isA<GetProjectHeaderUseCase>());
      expect(bloc, isA<GetProjectBloc>());

      bloc.close();
    });
  });
}
