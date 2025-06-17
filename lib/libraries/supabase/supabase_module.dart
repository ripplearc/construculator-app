import 'package:construculator/libraries/config/config_module.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
=======
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/supabase/default_supabase_wrapper.dart';
>>>>>>> 3915f4d (Fix restack errors)
=======
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
>>>>>>> 0836451 (Fix restack errors)
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  @override
  List<Module> get imports => [
    ConfigModule(),
  ];
  @override
<<<<<<< HEAD
<<<<<<< HEAD
  void exportedBinds(Injector i) async{
    final wrapperImpl = SupabaseWrapperImpl(envLoader: i());
    await wrapperImpl.initialize();
    i.addLazySingleton<SupabaseWrapper>(
      () => wrapperImpl,
=======
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(
      () => DefaultSupabaseWrapper(
        supabaseClient: i.get<Config>().supabaseClient,
      ),
>>>>>>> 3915f4d (Fix restack errors)
=======
  void exportedBinds(Injector i) async{
    final wrapperImpl = SupabaseWrapperImpl(envLoader: i());
    await wrapperImpl.initialize();
    i.addLazySingleton<SupabaseWrapper>(
      () => wrapperImpl,
>>>>>>> 0836451 (Fix restack errors)
    );
  }
}
