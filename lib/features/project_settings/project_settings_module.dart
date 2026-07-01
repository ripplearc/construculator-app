import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsModule extends Module {
  final AppBootstrap appBootstrap;

  ProjectSettingsModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectLibraryModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.add<ProjectSettingsBloc>(
      () => ProjectSettingsBloc(repository: i()),
    );
  }
}
