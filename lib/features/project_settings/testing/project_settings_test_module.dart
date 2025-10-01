import 'package:construculator/features/project_settings/domain/repositories/project_repository.dart';
import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsTestModule extends Module {
  @override
  List<Module> get imports => [];

  @override
  void exportedBinds(Injector i) {
    i.add<ProjectRepository>(
      () => FakeProjectRepository(),
      key: 'fakeProjectRepository',
    );

    i.add<GetProjectUseCase>(
      () => GetProjectUseCase(i<ProjectRepository>(key: 'fakeProjectRepository')),
      key: 'getProjectUseCaseWithFakeDep',
    );
  }
}
