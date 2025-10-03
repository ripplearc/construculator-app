import 'package:construculator/features/project_settings/domain/repositories/project_repository.dart';
import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsTestModule extends Module {
  final FakeProjectRepository fakeProjectRepository;
  
  ProjectSettingsTestModule(this.fakeProjectRepository);
  
  @override
  List<Module> get imports => [];

  @override
  void binds(Injector i) {
    i.add<ProjectRepository>(
      () => fakeProjectRepository,
      key: 'fakeProjectRepository',
    );

    i.add<GetProjectUseCase>(
      () => GetProjectUseCase(i<ProjectRepository>(key: 'fakeProjectRepository')),
    );
  }
}
