import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/supabase_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthTestModule extends Module {
  @override
  List<Module> get imports => [
    SupabaseTestModule(),
  ];
  @override
  void exportedBinds(Injector i) {
    i.add<AuthRepository>(
      () => FakeAuthRepository(),
      key: 'fakeAuthRepository',
    );
    i.add<AuthRepository>(
      () => SupabaseAuthRepositoryImpl(
        supabaseWrapper: i.get<SupabaseWrapper>(key: 'singletonFakeSupabaseWrapper'),
      ),
      key: 'authRepositoryWithFakeDep',
    );
    // Used by classes that depend on authRepository and need to manipulate 
    // the behavior in tests.
    i.addSingleton<AuthRepository>(
      () => FakeAuthRepository(),
      key: 'singletonFakeAuthRepository',
    );
  }
}
