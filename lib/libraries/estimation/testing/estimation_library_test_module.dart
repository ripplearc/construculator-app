import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationLibraryTestModule extends Module {
  final AppBootstrap appBootstrap;

  EstimationLibraryTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [EstimationLibraryModule(appBootstrap)];
}
