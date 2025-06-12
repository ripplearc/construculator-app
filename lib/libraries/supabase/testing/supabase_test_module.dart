import 'package:construculator/libraries/config/testing/config_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseTestModule extends Module {
  @override
  List<Module> get imports => [
    ConfigTestModule(),
  ];
  @override
  void exportedBinds(Injector i){
    i.add<SupabaseWrapper>(
      () => FakeSupabaseWrapper(),
    );
  }
}
