import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/features/project/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectTestModule extends Module {
  @override
  List<Module> get imports => [ClockTestModule()];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<ProjectRepository>(
      () => FakeProjectRepository(),
      key: 'fakeProjectRepository',
    );

    i.addLazySingleton<GetProjectUseCase>(
      () =>
          GetProjectUseCase(i<ProjectRepository>(key: 'fakeProjectRepository')),
      key: 'getProjectUseCaseWithFakeDep',
    );
  }
}
