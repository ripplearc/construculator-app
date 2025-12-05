// coverage:ignore-file
import 'package:construculator/features/project_settings/domain/repositories/project_repository.dart';
import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsTestModule extends Module {
  @override
  List<Module> get imports => [ClockTestModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<ProjectRepository>(() => FakeProjectRepository());

    i.add<GetProjectUseCase>(() => GetProjectUseCase(i<ProjectRepository>()));

    i.add<GetProjectBloc>(() => GetProjectBloc(getProjectUseCase: i()));
  }
}
