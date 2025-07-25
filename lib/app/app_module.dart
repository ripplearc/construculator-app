import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/app/module_param.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppModule extends Module {
  final ModuleParam moduleParam;
  AppModule(this.moduleParam);
  @override
  List<Module> get imports => [
    ConfigModule(moduleParam),
    SupabaseModule(moduleParam),
    AuthLibraryModule(moduleParam),
  ];
  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule(moduleParam));
  }
}