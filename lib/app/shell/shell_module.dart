import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ShellModule extends Module {
  final AppBootstrap appBootstrap;
  ShellModule(this.appBootstrap);

  @override
  void binds(Injector i) {
    i.addSingleton<TabModuleManager>(() => TabModuleManager(appBootstrap));
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => const Scaffold(
        body: Center(child: Text('Shell not implemented yet')),
      ),
    );
  }
}
