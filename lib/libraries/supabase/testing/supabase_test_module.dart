import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/config/testing/config_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseTestModule extends Module {
  @override
  List<Module> get imports => [ConfigTestModule(), ClockTestModule()];
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<SupabaseWrapper>(() => FakeSupabaseWrapper(clock: i()));
  }
}
