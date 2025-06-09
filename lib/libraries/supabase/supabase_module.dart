import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/supabase/default_supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  @override
  List<Module> get imports => [
    ConfigModule(),
  ];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(
      () => DefaultSupabaseWrapper(
        supabaseClient: i.get<Config>().supabaseClient,
      ),
    );
  }
}
