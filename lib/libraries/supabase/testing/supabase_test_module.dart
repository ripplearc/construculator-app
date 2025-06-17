<<<<<<< HEAD
<<<<<<< HEAD
import 'package:construculator/libraries/config/testing/config_test_module.dart';
=======
import 'package:construculator/libraries/config/config_module.dart';
>>>>>>> c96cea6 (Add test supabase module)
=======
import 'package:construculator/libraries/config/testing/config_test_module.dart';
>>>>>>> 704ddee (Update comments)
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseTestModule extends Module {
  @override
<<<<<<< HEAD
  List<Module> get imports => [ConfigTestModule()];
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<SupabaseWrapper>(() => FakeSupabaseWrapper());
=======
  List<Module> get imports => [
    ConfigTestModule(),
  ];
  @override
  void exportedBinds(Injector i){
    i.add<SupabaseWrapper>(
      () => FakeSupabaseWrapper(),
    );
>>>>>>> c96cea6 (Add test supabase module)
  }
}
