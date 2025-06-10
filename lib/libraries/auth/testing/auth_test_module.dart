import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/supabase_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AutTestModule extends Module {
  @override
  List<Module> get imports => [
    SupabaseTestModule(),
  ];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AuthRepository>(
      () => FakeAuthRepository(),
    );
  }
}
